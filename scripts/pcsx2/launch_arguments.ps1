Set-StrictMode -Version Latest

function Test-UnWorkshopLaunchOption {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Token)

    return $Token.ToLowerInvariant() -in @(
        '-p', '-r', '-s', '-o', '-mc', '-pnach', '-dmc', '-vmc', '-t', '-u', '-agent-replay', '-logfile'
    )
}

function ConvertFrom-UnWorkshopLaunchArguments {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Tokens = @(),
        [switch]$OptionsOnly
    )

    $games = [Collections.Generic.List[string]]::new()
    $values = [ordered]@{
        Play = ''
        Record = ''
        Snapshots = ''
        CaptureDirectory = ''
        MemoryCard = ''
        LogFile = ''
    }
    $pnach = [Collections.Generic.List[string]]::new()
    $discardMemoryCardWrites = $false
    $volatileMemoryCard = $false
    $turbo = $false
    $unlimited = $false
    $agentReplay = $false
    $valueOptions = @{
        '-p' = 'Play'
        '-r' = 'Record'
        '-s' = 'Snapshots'
        '-o' = 'CaptureDirectory'
        '-mc' = 'MemoryCard'
        '-logfile' = 'LogFile'
    }

    for ($index = 0; $index -lt $Tokens.Count; $index++) {
        $token = [string]$Tokens[$index]
        $option = $token.ToLowerInvariant()
        if ($option -eq '-pnach') {
            if ($index + 1 -ge $Tokens.Count) {
                throw '-pnach requires a value.'
            }
            $pnach.Add([string]$Tokens[++$index])
            continue
        }
        if ($valueOptions.ContainsKey($option)) {
            $name = $valueOptions[$option]
            if (-not [string]::IsNullOrWhiteSpace([string]$values[$name])) {
                throw "$option may be specified only once."
            }
            if ($index + 1 -ge $Tokens.Count) {
                throw "$option requires a value."
            }
            $values[$name] = [string]$Tokens[++$index]
            continue
        }
        switch ($option) {
            '-agent-replay' {
                if ($agentReplay) { throw '-agent-replay may be specified only once.' }
                $agentReplay = $true
            }
            '-dmc' {
                if ($discardMemoryCardWrites) {
                    throw '-dmc may be specified only once.'
                }
                $discardMemoryCardWrites = $true
            }
            '-vmc' {
                if ($volatileMemoryCard) {
                    throw '-vmc may be specified only once.'
                }
                $volatileMemoryCard = $true
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
                if ($token.StartsWith('-') -or $OptionsOnly) {
                    throw "Unknown Workshop launch option: $token"
                }
                $games.Add($token)
            }
        }
        if ($option -in @('-dmc', '-vmc') -and $index + 1 -lt $Tokens.Count -and
            -not ([string]$Tokens[$index + 1]).StartsWith('-')) {
            if (-not [string]::IsNullOrWhiteSpace($values.MemoryCard)) {
                throw 'Memory card may be specified only once.'
            }
            $values.MemoryCard = [string]$Tokens[++$index]
        }
    }

    if ($discardMemoryCardWrites -and $volatileMemoryCard) {
        throw 'Use only one of -dmc or -vmc.'
    }
    if ($agentReplay -and ($turbo -or $unlimited)) {
        throw '-agent-replay cannot be combined with -t or -u.'
    }

    $launchParameters = @{}
    foreach ($name in $values.Keys) {
        if (-not [string]::IsNullOrWhiteSpace([string]$values[$name])) {
            $launchParameters[$name] = [string]$values[$name]
        }
    }
    if ($pnach.Count -gt 0) {
        $launchParameters.AdditionalPnach = @($pnach)
    }
    if ($discardMemoryCardWrites) {
        $launchParameters.DiscardMemoryCardWrites = $true
    }
    if ($volatileMemoryCard) { $launchParameters.VolatileMemoryCard = $true }
    if ($turbo) { $launchParameters.Turbo = $true }
    if ($unlimited) { $launchParameters.Unlimited = $true }
    if ($agentReplay) { $launchParameters.AgentReplay = $true }

    [pscustomobject]@{
        Games = @($games)
        Play = $values.Play
        Record = $values.Record
        Snapshots = $values.Snapshots
        CaptureDirectory = $values.CaptureDirectory
        MemoryCard = $values.MemoryCard
        LogFile = $values.LogFile
        Pnach = @($pnach)
        DiscardMemoryCardWrites = $discardMemoryCardWrites
        VolatileMemoryCard = $volatileMemoryCard
        Turbo = $turbo
        Unlimited = $unlimited
        AgentReplay = $agentReplay
        LaunchParameters = $launchParameters
    }
}

function Resolve-UnWorkshopMemoryCardMode {
    [CmdletBinding()]
    param(
        [switch]$DiscardMemoryCardWrites,
        [switch]$VolatileMemoryCard,
        [switch]$DefaultDiscard
    )

    if ($DiscardMemoryCardWrites -and $VolatileMemoryCard) {
        throw 'Use only one of -dmc or -vmc.'
    }
    [pscustomobject]@{
        VolatileMemoryCard = $VolatileMemoryCard.IsPresent
        DiscardMemoryCardWrites = $DiscardMemoryCardWrites.IsPresent -or
            ($DefaultDiscard.IsPresent -and -not $VolatileMemoryCard)
    }
}

function Resolve-UnWorkshopMemoryCardPath {
    [CmdletBinding()]
    param(
        [string]$MemoryCard,
        [Parameter(Mandatory)][string]$MemoryCardsRoot
    )

    if ($MemoryCard -ieq 'none') { return 'none' }
    if ([string]::IsNullOrWhiteSpace($MemoryCard)) { return $null }
    $fileName = if ($MemoryCard.EndsWith('.ps2', [StringComparison]::OrdinalIgnoreCase)) {
        $MemoryCard
    }
    else { "$MemoryCard.ps2" }
    if ([IO.Path]::IsPathRooted($fileName)) {
        return [IO.Path]::GetFullPath($fileName)
    }
    $candidate = Join-Path $MemoryCardsRoot $fileName
    if ((Test-Path -LiteralPath $candidate -PathType Leaf) -or
        [IO.Path]::GetFileName($fileName) -cne $fileName) {
        return [IO.Path]::GetFullPath($candidate)
    }

    $templates = Join-Path $MemoryCardsRoot 'templates'
    $candidate = Join-Path $templates $fileName
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return [IO.Path]::GetFullPath($candidate)
    }
    $selector = [IO.Path]::GetFileNameWithoutExtension($fileName)
    $matchingTemplates = @(
        if (Test-Path -LiteralPath $templates -PathType Container) {
            Get-ChildItem -LiteralPath $templates -File -Filter '*.ps2' |
                Where-Object {
                    $_.BaseName -match '^([0-9]+)_(.+)$' -and
                        ($selector -ieq $Matches[1] -or $selector -ieq $Matches[2])
                }
        }
    )
    if ($matchingTemplates.Count -gt 1) {
        throw "Ambiguous memory-card template '$MemoryCard': $($matchingTemplates.Name -join ', ')"
    }
    if ($matchingTemplates.Count -eq 1) {
        return $matchingTemplates[0].FullName
    }
    return [IO.Path]::GetFullPath($candidate)
}
