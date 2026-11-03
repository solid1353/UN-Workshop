Set-StrictMode -Version Latest

# The launch options that take a value, and the switches, each by the result
# property it sets; -pnach takes a value and may repeat.
function Get-UnWorkshopLaunchOptions {
    [pscustomobject]@{
        Values = [ordered]@{
            '-rp' = 'Play'
            '-r' = 'Record'
            '-rps' = 'Snapshots'
            '-o' = 'CaptureDirectory'
            '-mc' = 'MemoryCard'
            '-logfile' = 'LogFile'
        }
        Switches = [ordered]@{
            '-dmc' = 'DiscardMemoryCardWrites'
            '-vmc' = 'VolatileMemoryCard'
            '-t' = 'Turbo'
            '-u' = 'Unlimited'
            '-k' = 'ClosePcsx2'
            '-agent-replay' = 'AgentReplay'
        }
    }
}

function ConvertFrom-UnWorkshopLaunchArguments {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Tokens = @(),
        [switch]$OptionsOnly
    )

    $options = Get-UnWorkshopLaunchOptions
    $games = [Collections.Generic.List[string]]::new()
    $values = [ordered]@{}
    foreach ($name in $options.Values.Values) { $values[$name] = '' }
    $switches = [ordered]@{}
    foreach ($name in $options.Switches.Values) { $switches[$name] = $false }
    $pnach = [Collections.Generic.List[string]]::new()

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
        if ($options.Values.Contains($option)) {
            $name = $options.Values[$option]
            if (-not [string]::IsNullOrWhiteSpace([string]$values[$name])) {
                throw "$option may be specified only once."
            }
            if ($index + 1 -ge $Tokens.Count) {
                throw "$option requires a value."
            }
            $values[$name] = [string]$Tokens[++$index]
            continue
        }
        if (-not $options.Switches.Contains($option)) {
            if ($token.StartsWith('-') -or $OptionsOnly) {
                throw "Unknown Workshop launch option: $token"
            }
            $games.Add($token)
            continue
        }
        $name = $options.Switches[$option]
        if ($switches[$name]) { throw "$option may be specified only once." }
        $switches[$name] = $true
        # -dmc and -vmc may name the memory card they apply to.
        if ($option -in @('-dmc', '-vmc') -and $index + 1 -lt $Tokens.Count -and
            -not ([string]$Tokens[$index + 1]).StartsWith('-')) {
            if (-not [string]::IsNullOrWhiteSpace($values.MemoryCard)) {
                throw 'Memory card may be specified only once.'
            }
            $values.MemoryCard = [string]$Tokens[++$index]
        }
    }

    if ($switches.DiscardMemoryCardWrites -and $switches.VolatileMemoryCard) {
        throw 'Use only one of -dmc or -vmc.'
    }
    if ($switches.AgentReplay -and ($switches.Turbo -or $switches.Unlimited)) {
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
    foreach ($name in $switches.Keys) {
        if ($switches[$name]) { $launchParameters[$name] = $true }
    }

    $result = [ordered]@{ Games = @($games) }
    foreach ($name in $values.Keys) { $result[$name] = $values[$name] }
    $result.Pnach = @($pnach)
    foreach ($name in $switches.Keys) { $result[$name] = $switches[$name] }
    $result.LaunchParameters = $launchParameters
    [pscustomobject]$result
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
    if ((Test-Path -LiteralPath $candidate) -or
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
