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
        $buildSelectors = if ($null -ne $catalog.Builds) {
            @(
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
            )
        }
        else { @() }
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
            '  workshop input [profile]            Regenerate all profiles, or regenerate and assign one.'
            '  workshop ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]  Move savestates; -c recycles the destination first.'
            '  workshop ss extract <folder-or-savestates...>  Extract embedded PNGs into screenshots/.'
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
