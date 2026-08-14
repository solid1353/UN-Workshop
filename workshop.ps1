$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$scripts = $paths.Roots.pcsx2_scripts

$rawArguments = @($args)
$Action = if ($rawArguments.Count -gt 0) { $rawArguments[0] } else { '' }
$Arguments = @(
    if ($rawArguments.Count -gt 1) {
        $rawArguments[1..($rawArguments.Count - 1)]
    }
)

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Action)) {
    ''
} else { $Action.ToLowerInvariant() }

function Invoke-UnWorkshopGameLaunch {
    param(
        [string[]]$Games,
        [string]$Play,
        [string]$Record,
        [string]$Snapshots,
        [string]$CaptureDirectory,
        [string]$MemoryCard,
        [switch]$DiscardMemoryCardWrites,
        [switch]$Turbo,
        [switch]$Unlimited
    )

    $games = @($Games | Where-Object { -not [string]::IsNullOrEmpty($_) })
    if ($games.Count -eq 0 -or $games.Count -gt 2) {
        throw 'Workshop launch accepts one or two games.'
    }
    $selectedModes = @(
        @($Play, $Record, $Snapshots) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($selectedModes.Count -gt 1) {
        throw 'Use only one of -p, -r, or -s.'
    }
    if (-not [string]::IsNullOrWhiteSpace($Snapshots) -and
        $games.Count -ne 1) {
        throw '-s requires exactly one game.'
    }
    if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory) -and
        [string]::IsNullOrWhiteSpace($Snapshots)) {
        throw 'A snapshot capture path requires -s.'
    }
    if ($Turbo -and $Unlimited) {
        throw 'Use only one of -t or -u.'
    }
    if (-not [string]::IsNullOrWhiteSpace($Snapshots) -and
        ($Turbo -or $Unlimited)) {
        throw '-s owns its permanent Unlimited speed mode.'
    }
    $parameters = @{
        Games = @($games)
        ProjectRoot = $paths.Project
    }
    if (-not [string]::IsNullOrWhiteSpace($Play)) { $parameters.Play = $Play }
    if (-not [string]::IsNullOrWhiteSpace($Record)) { $parameters.Record = $Record }
    if (-not [string]::IsNullOrWhiteSpace($MemoryCard)) {
        $parameters.MemoryCard = $MemoryCard
    }
    if ($DiscardMemoryCardWrites) {
        $parameters.DiscardMemoryCardWrites = $true
    }
    if ($Turbo) { $parameters.Turbo = $true }
    if ($Unlimited) { $parameters.Unlimited = $true }
    if (-not [string]::IsNullOrWhiteSpace($Snapshots)) {
        $parameters.Play = $Snapshots
        $parameters.Snapshots = $true
        if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory)) {
            $parameters.CaptureDirectory = $CaptureDirectory
        }
    }
    & $paths.Files.pcsx2_game_launch_command @parameters
}

function ConvertFrom-UnWorkshopLaunchArguments {
    param([string[]]$Tokens)

    $games = [Collections.Generic.List[string]]::new()
    $values = [ordered]@{
        Play = ''
        Record = ''
        Snapshots = ''
        MemoryCard = ''
    }
    $discardMemoryCardWrites = $false
    $turbo = $false
    $unlimited = $false
    $captureDirectory = ''
    $valueOptions = @{
        '-p' = 'Play'
        '-r' = 'Record'
        '-s' = 'Snapshots'
        '-mc' = 'MemoryCard'
    }

    for ($index = 0; $index -lt $Tokens.Count; $index++) {
        $token = [string]$Tokens[$index]
        $option = $token.ToLowerInvariant()
        if ($valueOptions.ContainsKey($option)) {
            $name = $valueOptions[$option]
            if (-not [string]::IsNullOrWhiteSpace([string]$values[$name])) {
                throw "$option may be specified only once."
            }
            if ($index + 1 -ge $Tokens.Count) {
                throw "$option requires a value."
            }
            $index++
            $values[$name] = [string]$Tokens[$index]
            continue
        }
        switch ($option) {
            '-dw' {
                if ($discardMemoryCardWrites) {
                    throw '-dw may be specified only once.'
                }
                $discardMemoryCardWrites = $true
            }
            '-t' {
                if ($turbo) { throw '-t may be specified only once.' }
                $turbo = $true
            }
            '-u' {
                if ($unlimited) { throw '-u may be specified only once.' }
                $unlimited = $true
            }
            default {
                if ($token.StartsWith('-')) {
                    throw "Unknown Workshop launch option: $token"
                }
                $games.Add($token)
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$values.Snapshots)) {
        if ($games.Count -gt 2) {
            throw '-s accepts one game and one optional capture path.'
        }
        if ($games.Count -eq 2) {
            $captureDirectory = $games[1]
            $games.RemoveAt(1)
        }
    }

    [pscustomobject]@{
        Games = @($games)
        Play = $values.Play
        Record = $values.Record
        Snapshots = $values.Snapshots
        CaptureDirectory = $captureDirectory
        MemoryCard = $values.MemoryCard
        DiscardMemoryCardWrites = $discardMemoryCardWrites
        Turbo = $turbo
        Unlimited = $unlimited
    }
}

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
            '  workshop [game] [game] [-p name|-r name] [-mc card] [-dw] [-t|-u]  Launch one or two games; pairs close existing user PCSX2 first.'
            '  workshop <game> -s name [path] [-mc card]  Replay one game at unlimited speed and take snapshots.'
            '  workshop input [profile]             Regenerate all profiles; optionally assign one.'
            '  workshop pcsx2                       Launch development PCSX2 without a game.'
            '  workshop resolve [game] [property]   Resolve all games, one game, or one property.'
            '  workshop ss extract <subpath|folder-or-savestates...>  Extract embedded PNGs into screenshots/.'
            '  workshop ss move <game> <subpath> [-c]  Move development savestates.'
            ''
            '  Launch options:'
            '    -p <name>        Replay an input recording.'
            '    -r <name>        Create an input recording; paired launches record the rightmost game.'
            '    -s <name> [path] Replay one game and take snapshots; optionally select the capture directory.'
            '    -mc <card>       Use one shared card or template; .ps2 is added automatically.'
            '    -dw              Discard memory-card writes for an ordinary launch.'
            '    -t               Launch in Turbo.'
            '    -u               Launch in Unlimited.'
            ''
            '  Savestate move options:'
            '    -c  Recycle the existing destination before moving savestates.'
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
        if ($argumentList.Count -gt 0) {
            throw 'workshop pcsx2 accepts no arguments.'
        }
        & $paths.Files.pcsx2_launch_command -Turbo
    }
    'ss' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -eq 0) {
            throw 'Usage: workshop ss move|extract ...'
        }
        $cleanup = $false
        $forwardedArguments = [Collections.Generic.List[string]]::new()
        for ($index = 0; $index -lt $argumentList.Count; $index++) {
            $argument = [string]$argumentList[$index]
            if ($argument -ceq '-c') {
                $cleanup = $true
            }
            elseif ($argument -ieq '-Cleanup') {
                throw 'Use the workshop ss -c short option.'
            }
            else {
                $forwardedArguments.Add($argument)
            }
        }
        $parameters = @{}
        if ($cleanup) { $parameters.Cleanup = $true }
        $forwardedArgumentArray = @($forwardedArguments)
        & (Join-Path $scripts 'savestates.ps1') @forwardedArgumentArray @parameters
    }
    default {
        $launch = ConvertFrom-UnWorkshopLaunchArguments -Tokens @(
            $Action
            $Arguments
        )
        Invoke-UnWorkshopGameLaunch `
            -Games $launch.Games `
            -Play $launch.Play `
            -Record $launch.Record `
            -Snapshots $launch.Snapshots `
            -CaptureDirectory $launch.CaptureDirectory `
            -MemoryCard $launch.MemoryCard `
            -DiscardMemoryCardWrites:$launch.DiscardMemoryCardWrites `
            -Turbo:$launch.Turbo `
            -Unlimited:$launch.Unlimited
    }
}
