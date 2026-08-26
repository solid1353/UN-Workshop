Set-StrictMode -Version Latest

function Test-UnWorkshopLaunchOption {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Token)

    return $Token.ToLowerInvariant() -in @(
        '-p', '-r', '-s', '-o', '-mc', '-pnach', '-dw', '-t', '-u'
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
    }
    $pnach = [Collections.Generic.List[string]]::new()
    $discardMemoryCardWrites = $false
    $turbo = $false
    $unlimited = $false
    $valueOptions = @{
        '-p' = 'Play'
        '-r' = 'Record'
        '-s' = 'Snapshots'
        '-o' = 'CaptureDirectory'
        '-mc' = 'MemoryCard'
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
                if ($token.StartsWith('-') -or $OptionsOnly) {
                    throw "Unknown Workshop launch option: $token"
                }
                $games.Add($token)
            }
        }
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
    if ($turbo) { $launchParameters.Turbo = $true }
    if ($unlimited) { $launchParameters.Unlimited = $true }

    [pscustomobject]@{
        Games = @($games)
        Play = $values.Play
        Record = $values.Record
        Snapshots = $values.Snapshots
        CaptureDirectory = $values.CaptureDirectory
        MemoryCard = $values.MemoryCard
        Pnach = @($pnach)
        DiscardMemoryCardWrites = $discardMemoryCardWrites
        Turbo = $turbo
        Unlimited = $unlimited
        LaunchParameters = $launchParameters
    }
}
