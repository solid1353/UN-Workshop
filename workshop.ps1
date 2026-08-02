[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$scripts = $paths.Roots.pcsx2_scripts

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Action)) {
    ''
} else { $Action.ToLowerInvariant() }

switch ($normalizedCommand) {
    { [string]::IsNullOrWhiteSpace($_) -or $_ -eq 'help' } {
        $catalog = Get-UnWorkshopCatalog -ProjectRoot $paths.Project
        $sourceSelectors = @(
            foreach ($entry in $catalog.Sources.PSObject.Properties) {
                $aliasesProperty = $entry.Value.PSObject.Properties['aliases']
                $aliases = @(
                    if ($null -ne $aliasesProperty) {
                        $aliasesProperty.Value
                    }
                )
                if ($aliases.Count -gt 0) {
                    "$($entry.Name) ($($aliases -join ', '))"
                }
                else { $entry.Name }
            }
        )
        $buildSelectors = @(
            if ($null -ne $catalog.Builds) {
                foreach ($entry in $catalog.Builds.PSObject.Properties) {
                    $aliasesProperty = $entry.Value.PSObject.Properties['aliases']
                    $aliases = @(
                        if ($null -ne $aliasesProperty) {
                            $aliasesProperty.Value
                        }
                    )
                    if ($aliases.Count -gt 0) {
                        "$($entry.Name) ($($aliases -join ', '))"
                    }
                    else { $entry.Name }
                }
            }
        )
        $canonicalSelectors = @(
            $catalog.Sources.PSObject.Properties |
                ForEach-Object { [string]$_.Name }
            if ($null -ne $catalog.Builds) {
                $catalog.Builds.PSObject.Properties |
                    ForEach-Object { [string]$_.Name }
            }
        )
        $resolvedProperties = @(
            foreach ($selector in $canonicalSelectors) {
                $resolved = Resolve-UnWorkshopGame `
                    -Game $selector `
                    -ProjectRoot $paths.Project
                $resolved.PSObject.Properties |
                    ForEach-Object { [string]$_.Name }
            }
        ) | Select-Object -Unique

        @(
            'UN Workshop'
            ''
            '  workshop resolve [game] [property]  Resolve all games, one game, or one property.'
            '  workshop pcsx2 [game]               Launch development PCSX2, optionally with a game.'
            '  workshop rec <game> <recording-name> [-r|-t]  Replay; -r records, -t captures regression markers.'
            '  workshop input [profile]            Regenerate all profiles; optionally assign one.'
            '  workshop ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]  Move savestates; -c recycles the destination first.'
            '  workshop ss extract <subpath|folder-or-savestates...>  Extract embedded PNGs into screenshots/.'
            ''
            "  Sources: $($sourceSelectors -join ', ')"
            $(if ($buildSelectors.Count -gt 0) {
                "  Project builds: $($buildSelectors -join ', ')"
            } else {
                '  Project builds: available inside a configured project'
            })
            "  Properties: $($resolvedProperties -join ', ')"
            ''
        ) | Write-Output
    }
    'resolve' {
        $argumentList = @(
            $Arguments |
                Where-Object { -not [string]::IsNullOrEmpty($_) }
        )
        if ($argumentList.Count -gt 2) {
            throw 'Usage: workshop resolve [game] [property]'
        }
        if ($argumentList.Count -eq 0) {
            $catalog = Get-UnWorkshopCatalog -ProjectRoot $paths.Project
            $selectors = @(
                $catalog.Sources.PSObject.Properties |
                    ForEach-Object { [string]$_.Name }
                if ($null -ne $catalog.Builds) {
                    $catalog.Builds.PSObject.Properties |
                        ForEach-Object { [string]$_.Name }
                }
            )
            foreach ($selector in $selectors) {
                $values = Resolve-UnWorkshopGame `
                    -Game $selector `
                    -ProjectRoot $paths.Project
                $result = [ordered]@{ game = $selector }
                foreach ($property in $values.PSObject.Properties) {
                    $result[$property.Name] = $property.Value
                }
                [pscustomobject]$result | Write-Output
            }
            break
        }
        $resolved = Resolve-UnWorkshopGame `
            -Game $argumentList[0] `
            -ProjectRoot $paths.Project
        if ($argumentList.Count -eq 1) {
            $resolved | Write-Output
            break
        }
        $property = @(
            $resolved.PSObject.Properties |
                Where-Object { $_.Name -ieq $argumentList[1] }
        )
        if ($property.Count -ne 1) {
            throw "Unknown resolved game property: $($argumentList[1])"
        }
        $property[0].Value | Write-Output
    }
    'input' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -gt 1) {
            throw 'Usage: workshop input [profile]'
        }
        if ($argumentList.Count -eq 0) {
            & (Join-Path $scripts 'input.ps1')
        }
        else {
            & (Join-Path $scripts 'input.ps1') -Profile $argumentList[0]
        }
    }
    'pcsx2' {
        $argumentList = @(
            $Arguments |
                Where-Object { -not [string]::IsNullOrEmpty($_) }
        )
        if ($argumentList.Count -gt 1) {
            throw 'Usage: workshop pcsx2 [game]'
        }
        $parameters = @{}
        if ($argumentList.Count -eq 1) {
            $resolved = Resolve-UnWorkshopGame `
                -Game $argumentList[0] `
                -ProjectRoot $paths.Project
            $parameters.IsoPath = [string]$resolved.iso
        }
        & (Join-Path $scripts 'launch.ps1') @parameters
    }
    'rec' {
        $argumentList = @(
            $Arguments |
                Where-Object { -not [string]::IsNullOrEmpty($_) }
        )
        $record = $false
        $regressionTest = $false
        $positionalArguments = @(
            foreach ($argument in $argumentList) {
                if ($argument -ieq '-r') {
                    $record = $true
                }
                elseif ($argument -ieq '-t') {
                    $regressionTest = $true
                }
                else {
                    $argument
                }
            }
        )
        if (
            $positionalArguments.Count -ne 2 -or
            ($record -and $regressionTest)
        ) {
            throw 'Usage: workshop rec <game> <recording-name> [-r|-t]'
        }
        $resolved = Resolve-UnWorkshopGame `
            -Game $positionalArguments[0] `
            -ProjectRoot $paths.Project
        $recordingName = [string]$positionalArguments[1]
        if (-not $recordingName.EndsWith(
            '.p2m2',
            [StringComparison]::OrdinalIgnoreCase
        )) {
            $recordingName += '.p2m2'
        }
        $parameters = @{
            IsoPath = [string]$resolved.iso
        }
        if ($record) {
            $parameters.CreateInputRecording = $recordingName
        }
        else {
            $parameters.InputRecording = $recordingName
        }
        if ($regressionTest) {
            $recordingStem = [IO.Path]::GetFileNameWithoutExtension($recordingName)
            $buildName = ([string]$positionalArguments[0]).ToLowerInvariant()
            $parameters.InputRecordingCaptureDirectory = Join-Path `
                (Join-Path $paths.Savestates $recordingStem) `
                $buildName
            [void](New-Item `
                -ItemType Directory `
                -Path $parameters.InputRecordingCaptureDirectory `
                -Force)
            $parameters.Hidden = $true
            $parameters.Wait = $true
        }
        & (Join-Path $scripts 'launch.ps1') @parameters
    }
    'ss' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -eq 0) {
            throw 'Usage: workshop ss move|extract ...'
        }
        $cleanup = $false
        $forwardedArguments = @(
            foreach ($argument in $argumentList) {
                if ($argument -ieq '-c' -or $argument -ieq '-Cleanup') {
                    $cleanup = $true
                }
                else {
                    $argument
                }
            }
        )
        $parameters = @{}
        if ($cleanup) { $parameters.Cleanup = $true }
        & (Join-Path $scripts 'savestates.ps1') @forwardedArguments @parameters
    }
    default {
        throw "Unknown Workshop command: $Action"
    }
}
