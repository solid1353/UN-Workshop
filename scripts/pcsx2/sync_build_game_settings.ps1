# Synchronize serial-wide CRC memory-card overrides for built project images.
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$BuildSelector,

    [string]$ProjectRoot,
    [psobject]$WorkshopPaths,
    [psobject]$Catalog,
    [scriptblock]$GameResolver,
    [scriptblock]$IdentityResolver,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
. (Join-Path $PSScriptRoot 'ini.ps1')
. (Join-Path $PSScriptRoot 'iso_identity.ps1')

if ($null -eq $WorkshopPaths) {
    $WorkshopPaths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
}
if ($null -eq $Catalog) {
    $Catalog = Get-UnWorkshopCatalog -ProjectRoot $WorkshopPaths.Project
}
if ($null -eq $Catalog.Builds) {
    throw 'Build GameSettings synchronization requires a project build catalog.'
}
if ($null -eq $GameResolver) {
    $GameResolver = {
        param([string]$Selector)
        Resolve-UnWorkshopGame -Game $Selector -ProjectRoot $WorkshopPaths.Project
    }
}
if ($null -eq $IdentityResolver) {
    $IdentityResolver = {
        param([string]$IsoPath)
        Get-Pcsx2IsoIdentity -Path $IsoPath
    }
}

function Set-UnWorkshopTextAtomic {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Text
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $directory = [IO.Path]::GetDirectoryName($fullPath)
    $temporary = Join-Path $directory (
        '.{0}.{1}.tmp' -f [IO.Path]::GetFileName($fullPath), [guid]::NewGuid().ToString('N')
    )
    try {
        [IO.File]::WriteAllText($temporary, $Text, [Text.UTF8Encoding]::new($false))
        [IO.File]::Move($temporary, $fullPath, $true)
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

function Get-UnWorkshopSettingsMutexName {
    param([Parameter(Mandatory)][string]$Path)

    $bytes = [Text.Encoding]::UTF8.GetBytes(
        [IO.Path]::GetFullPath($Path).ToUpperInvariant()
    )
    $digest = [Security.Cryptography.SHA256]::HashData($bytes)
    return 'Local\UNWorkshop.PCSX2.GameSettings.' + [Convert]::ToHexString($digest)
}

function Enter-UnWorkshopSettingsMutex {
    param([Parameter(Mandatory)][string]$Path)

    $mutex = [Threading.Mutex]::new(
        $false,
        (Get-UnWorkshopSettingsMutexName -Path $Path)
    )
    try {
        try {
            $entered = $mutex.WaitOne([TimeSpan]::FromMinutes(2))
        }
        catch [Threading.AbandonedMutexException] {
            $entered = $true
        }
        if (-not $entered) {
            throw "Timed out waiting to update GameSettings: $Path"
        }
        return $mutex
    }
    catch {
        $mutex.Dispose()
        throw
    }
}

$allBuilds = [ordered]@{}
foreach ($property in $Catalog.Builds.PSObject.Properties) {
    $resolved = & $GameResolver $property.Name
    if ($null -eq $resolved) {
        throw "Game resolver returned no result for build $($property.Name)."
    }
    $allBuilds[$property.Name] = $resolved
}

$selected = [Collections.Generic.List[object]]::new()
foreach ($requested in $BuildSelector) {
    $matches = @($allBuilds.Keys | Where-Object { $_ -ieq $requested })
    if ($matches.Count -ne 1) {
        throw "Unknown project build selector: $requested"
    }
    $selector = [string]$matches[0]
    $resolved = $allBuilds[$selector]
    $isoPath = [IO.Path]::GetFullPath([string]$resolved.iso)
    if (-not (Test-Path -LiteralPath $isoPath -PathType Leaf)) {
        throw "Built project ISO was not found: $isoPath"
    }
    $identity = & $IdentityResolver $isoPath
    if (
        $null -eq $identity -or
        [string]$identity.Serial -cnotmatch '^[A-Z0-9]{4}-[A-Z0-9]{5}$' -or
        [string]$identity.CRC -cnotmatch '^[0-9A-Fa-f]{8}$'
    ) {
        throw "Identity resolver returned an invalid result for $isoPath"
    }
    $serial = ([string]$identity.Serial).ToUpperInvariant()
    if ($serial -cne ([string]$Catalog.Serial).ToUpperInvariant()) {
        throw "Build $selector serial $serial does not match project serial $($Catalog.Serial)."
    }
    $selected.Add([pscustomobject]@{
        Selector = $selector
        Iso = $isoPath
        Serial = $serial
        CRC = ([string]$identity.CRC).ToUpperInvariant()
        Settings = [IO.Path]::GetFullPath([string]$resolved.game_settings)
        MemoryCard = [IO.Path]::GetFullPath([string]$resolved.memory_card)
    })
}

$duplicateCrcs = @(
    $selected |
        Group-Object { $_.Settings.ToUpperInvariant() + ':' + $_.CRC } |
        Where-Object { @($_.Group.MemoryCard | Select-Object -Unique).Count -gt 1 }
)
if ($duplicateCrcs.Count -gt 0) {
    throw (
        'Multiple selected builds resolve to the same PCSX2 CRC but require ' +
        'different memory cards.'
    )
}

$updatedSettings = [Collections.Generic.List[string]]::new()
$results = [Collections.Generic.List[object]]::new()
foreach ($settingsGroup in @($selected | Group-Object Settings)) {
    $settingsPath = [IO.Path]::GetFullPath([string]$settingsGroup.Name)
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        throw "Configured serial-wide GameSettings file was not found: $settingsPath"
    }
    $mutex = Enter-UnWorkshopSettingsMutex -Path $settingsPath
    try {
        $text = [IO.File]::ReadAllText($settingsPath)
        foreach ($mapping in $settingsGroup.Group) {
            $sections = @(
                [regex]::Matches(
                    $text,
                    '(?im)^[ \t]*\[(?<section>CRC\.(?<crc>[0-9A-F]{8})\.MemoryCards)\][ \t]*$'
                )
            )
            $cardName = [IO.Path]::GetFileName($mapping.MemoryCard)
            foreach ($sectionMatch in $sections) {
                $section = $sectionMatch.Groups['section'].Value
                $sectionCrc = $sectionMatch.Groups['crc'].Value.ToUpperInvariant()
                $configuredCard = Get-Pcsx2IniValue $text $section 'Slot1_Filename'
                if ($configuredCard -ceq $cardName -and $sectionCrc -cne $mapping.CRC) {
                    $text = Remove-Pcsx2IniSection $text $section
                }
            }

            $targetSection = "CRC.$($mapping.CRC).MemoryCards"
            $text = Set-Pcsx2IniValue $text $targetSection 'Slot1_Filename' $cardName
            $results.Add([pscustomobject]@{
                Selector = $mapping.Selector
                Serial = $mapping.Serial
                CRC = $mapping.CRC
                MemoryCard = $mapping.MemoryCard
                GameSettings = $settingsPath
            })
        }

        $current = [IO.File]::ReadAllText($settingsPath)
        if ($text -cne $current) {
            Set-UnWorkshopTextAtomic $settingsPath $text
            $updatedSettings.Add($settingsPath)
        }
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}

$result = [pscustomobject]@{
    Builds = @($results)
    UpdatedGameSettings = @($updatedSettings | Select-Object -Unique)
    Changed = ($updatedSettings.Count -gt 0)
}
if ($PassThru) {
    $result
}
else {
    Write-Host (
        "Build GameSettings: synchronized $($results.Count) build(s); " +
        "updated files $($updatedSettings.Count)."
    )
}
