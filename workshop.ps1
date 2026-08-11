[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments,

    [string]$p,

    [string]$r,

    [string]$t,

    [string]$mc,

    [switch]$dw
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$scripts = $paths.Roots.pcsx2_scripts

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Action)) {
    ''
} else { $Action.ToLowerInvariant() }

function Invoke-UnWorkshopGameLaunch {
    param(
        [string[]]$Games,
        [string]$Play,
        [string]$Record,
        [string]$RegressionTest,
        [string]$MemoryCard,
        [switch]$DiscardMemoryCardWrites
    )

    $games = @($Games | Where-Object { -not [string]::IsNullOrEmpty($_) })
    if ($games.Count -eq 0 -or $games.Count -gt 2) {
        throw 'Workshop launch accepts one or two games.'
    }
    $selectedModes = @(
        @($Play, $Record, $RegressionTest) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($selectedModes.Count -gt 1) {
        throw 'Use only one of -p, -r, or -t.'
    }
    if (-not [string]::IsNullOrWhiteSpace($RegressionTest) -and
        $games.Count -ne 1) {
        throw '-t requires exactly one game.'
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
    if (-not [string]::IsNullOrWhiteSpace($RegressionTest)) {
        $parameters.Play = $RegressionTest
        $parameters.Test = $true
    }
    & $paths.Files.pcsx2_game_launch_command @parameters
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
            '  workshop [game] [game] [-p name|-r name] [-mc card] [-dw]  Launch one or two games; turbo except nominal-speed recording; pairs close existing user PCSX2 first.'
            '  workshop <game> -t name [-mc card]  Replay one game at unlimited speed and capture regression markers.'
            '  workshop input [profile]             Regenerate all profiles; optionally assign one.'
            '  workshop pcsx2                       Launch development PCSX2 without a game.'
            '  workshop resolve [game] [property]   Resolve all games, one game, or one property.'
            '  workshop ss extract <subpath|folder-or-savestates...>  Extract embedded PNGs into screenshots/.'
            '  workshop ss move <game> <subpath> [-t dev|stable] [-c]  Move savestates.'
            ''
            '  Launch options:'
            '    -p <name>        Replay an input recording.'
            '    -r <name>        Create an input recording; paired launches record the rightmost game.'
            '    -t <name>        Replay one game and capture regression markers; card writes are discarded.'
            '    -mc <card>       Use one shared card or template; .ps2 is added automatically.'
            '    -dw              Discard memory-card writes for an ordinary launch.'
            ''
            '  Savestate move options:'
            '    -t <dev|stable>  Select the PCSX2 installation containing the savestates.'
            '    -c               Recycle the existing destination before moving savestates.'
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
        $launchModes = @(
            @($p, $r, $t, $mc) |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
        if ($argumentList.Count -gt 0 -or
            $launchModes.Count -gt 0 -or $dw) {
            throw 'workshop pcsx2 accepts no arguments.'
        }
        & $paths.Files.pcsx2_launch_command
    }
    'ss' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -eq 0) {
            throw 'Usage: workshop ss move|extract ...'
        }
        if (-not [string]::IsNullOrWhiteSpace($mc) -or $dw) {
            throw '-mc and -dw apply only to game launches.'
        }
        $cleanup = $false
        $forwardedArguments = @(
            foreach ($argument in $argumentList) {
                if ($argument -ceq '-c') {
                    $cleanup = $true
                }
                elseif ($argument -ieq '-Cleanup' -or $argument -ieq '-Target') {
                    throw 'Use workshop ss short options: -t dev|stable and -c.'
                }
                else {
                    $argument
                }
            }
        )
        $parameters = @{}
        if ($cleanup) { $parameters.Cleanup = $true }
        if (-not [string]::IsNullOrWhiteSpace($t)) { $parameters.Target = $t }
        & (Join-Path $scripts 'savestates.ps1') @forwardedArguments @parameters
    }
    default {
        $games = @(
            $Action
            $Arguments | Where-Object { -not [string]::IsNullOrEmpty($_) }
        )
        Invoke-UnWorkshopGameLaunch `
            -Games $games `
            -Play $p `
            -Record $r `
            -RegressionTest $t `
            -MemoryCard $mc `
            -DiscardMemoryCardWrites:$dw
    }
}
