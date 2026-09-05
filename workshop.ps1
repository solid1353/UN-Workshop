$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\lib\paths.ps1')

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

if ([string]::IsNullOrWhiteSpace($normalizedCommand) -or
    $normalizedCommand -eq 'help') {
    . (Join-Path $PSScriptRoot 'scripts\lib\console_help.ps1')
    $catalog = Get-UnWorkshopCatalog
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
    $propertySelectors = Get-UnWorkshopResolvedPropertyNames
    Get-UnConsoleHelp `
        -Path (Join-Path $PSScriptRoot 'CLI.txt') `
        -Values @{
            SOURCES = $sourceSelectors -join ', '
            PROPERTIES = $propertySelectors -join ', '
        }
    return
}

$paths = Get-UnWorkshopPaths
$scripts = $paths.Roots.pcsx2_scripts
. (Join-Path $scripts 'launch_arguments.ps1')

function Invoke-UnWorkshopGameLaunch {
    param(
        [string[]]$Games,
        [string]$Play,
        [string]$Record,
        [string]$Snapshots,
        [string]$CaptureDirectory,
        [string]$MemoryCard,
        [string[]]$Pnach,
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
    if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory) -and
        [string]::IsNullOrWhiteSpace($Snapshots)) {
        throw '-o requires -s.'
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
    if (@($Pnach).Count -gt 0) {
        $parameters.AdditionalPnach = @($Pnach)
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

switch ($normalizedCommand) {
    'resolve' {
        $argumentList = @(
            $Arguments |
                Where-Object { -not [string]::IsNullOrEmpty($_) }
        )
        if ($argumentList.Count -gt 2) {
            throw 'Usage: workshop resolve [source] [property]'
        }
        if ($argumentList.Count -eq 0) {
            $catalog = Get-UnWorkshopCatalog
            $selectors = @(
                $catalog.Sources.PSObject.Properties |
                    ForEach-Object { [string]$_.Name }
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
            -Pnach $launch.Pnach `
            -DiscardMemoryCardWrites:$launch.DiscardMemoryCardWrites `
            -Turbo:$launch.Turbo `
            -Unlimited:$launch.Unlimited
    }
}
