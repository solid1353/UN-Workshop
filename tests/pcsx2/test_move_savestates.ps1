[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$root = Join-Path ([IO.Path]::GetTempPath()) (
    'un-workshop-move-savestates-{0}' -f [guid]::NewGuid().ToString('N')
)
$workshop = Join-Path $root 'workshop'
$project = Join-Path $root 'project'

function Assert-Exists([string]$Path, [string]$Message) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw $Message }
}

try {
    foreach ($path in @(
        'scripts\lib',
        'scripts\pcsx2',
        'source',
        'tools',
        'work',
        'pcsx2\clean',
        'pcsx2\dev\sstates',
        'pcsx2\stable',
        'pcsx2\shared\bios',
        'pcsx2\shared\cheats',
        'pcsx2\shared\game_settings',
        'pcsx2\shared\input_profiles',
        'pcsx2\shared\input_recordings',
        'pcsx2\shared\memory_cards'
    )) {
        [void](New-Item -ItemType Directory -Path (Join-Path $workshop $path) -Force)
    }
    [void](New-Item -ItemType Directory -Path (Join-Path $project 'build') -Force)

    foreach ($name in @('paths.ps1', 'paths.py', 'game_catalog.py', 'resolve_game.py')) {
        Copy-Item `
            -LiteralPath (Join-Path $repository "scripts\lib\$name") `
            -Destination (Join-Path $workshop "scripts\lib\$name")
    }
    Copy-Item `
        -LiteralPath (Join-Path $repository 'scripts\pcsx2\move_savestates.ps1') `
        -Destination (Join-Path $workshop 'scripts\pcsx2\move_savestates.ps1')
    Set-Content `
        -LiteralPath (Join-Path $workshop 'scripts\pcsx2\iso_identity.ps1') `
        -Value @'
function Get-Pcsx2IsoIdentity {
    [pscustomobject]@{ Serial = 'SLOP-NA228'; CRC = '12345678' }
}
'@

    Set-Content -LiteralPath (Join-Path $workshop 'paths.json') -Value @'
{
  "schema_version": 1,
  "roots": {
    "repository": ".",
    "source": "source",
    "analysis": "@work",
    "tools": "tools",
    "work": "work",
    "savestates": "@work/__sstates",
    "scripts": "scripts",
    "pcsx2_clean": "pcsx2/clean",
    "pcsx2_dev": "pcsx2/dev",
    "pcsx2_stable": "pcsx2/stable",
    "pcsx2_files": "pcsx2/shared",
    "pcsx2_bios": "@pcsx2_files/bios",
    "pcsx2_cheats": "@pcsx2_files/cheats",
    "pcsx2_game_settings": "@pcsx2_files/game_settings",
    "pcsx2_input_profiles": "@pcsx2_files/input_profiles",
    "pcsx2_input_recordings": "@pcsx2_files/input_recordings",
    "pcsx2_memory_cards": "@pcsx2_files/memory_cards"
  },
  "files": {
    "game_catalog": "@repository/games.json",
    "game_resolver": "@repository/scripts/lib/resolve_game.py"
  }
}
'@
    Set-Content -LiteralPath (Join-Path $workshop 'games.json') -Value @'
{
  "schema_version": 1,
  "sources": {
    "NUN5": { "serial": "SLES-55605", "crc": "C071D4C1" }
  }
}
'@
    Set-Content -LiteralPath (Join-Path $project 'product.json') -Value @'
{
  "schema_version": 1,
  "title": "NA v2.28",
  "serial": "SLOP-NA228",
  "builds": { "latest": { "aliases": ["l"], "postfix": "Latest" } }
}
'@
    Set-Content -LiteralPath (Join-Path $project 'build\NA v2.28 - Latest.iso') -Value 'test'

    $states = Join-Path $workshop 'pcsx2\dev\sstates'
    Set-Content -LiteralPath (Join-Path $states 'SLOP-NA228 (12345678).00.p2s') -Value 'build'
    & (Join-Path $workshop 'scripts\pcsx2\move_savestates.ps1') `
        latest build-case -ProjectRoot $project | Out-Null
    Assert-Exists `
        (Join-Path $project 'work\__sstates\build-case\SLOP-NA228 (12345678).00.p2s') `
        'Build savestate was not filed under the invoking project work/__sstates root.'

    $sourceCase = Join-Path $workshop 'work\__sstates\source-case'
    [void](New-Item -ItemType Directory -Path $sourceCase -Force)
    Set-Content `
        -LiteralPath (Join-Path $sourceCase 'SLES-55605 (C071D4C1).03.p2s') `
        -Value 'existing'
    Set-Content -LiteralPath (Join-Path $states 'SLES-55605 (C071D4C1).01.p2s') -Value 'first'
    Set-Content -LiteralPath (Join-Path $states 'SLES-55605 (C071D4C1).09.p2s') -Value 'second'
    & (Join-Path $workshop 'scripts\pcsx2\move_savestates.ps1') `
        NUN5 source-case -ProjectRoot $project | Out-Null
    Assert-Exists `
        (Join-Path $sourceCase 'SLES-55605 (C071D4C1).04.p2s') `
        'The first source savestate did not use the next destination number.'
    Assert-Exists `
        (Join-Path $sourceCase 'SLES-55605 (C071D4C1).05.p2s') `
        'The second source savestate did not continue destination numbering.'
    if (Test-Path -LiteralPath (Join-Path $sourceCase 'SLES-55605 (C071D4C1).11.p2s')) {
        throw 'Savestate conflict numbering still advances by ten.'
    }

    $cleanupTarget = Join-Path $project 'work\__sstates\cleanup-case'
    [void](New-Item -ItemType Directory -Path $cleanupTarget -Force)
    Set-Content -LiteralPath (Join-Path $cleanupTarget 'stale.p2s') -Value 'stale'
    Set-Content -LiteralPath (Join-Path $states 'SLOP-NA228 (12345678).02.p2s') -Value 'new'
    & (Join-Path $workshop 'scripts\pcsx2\move_savestates.ps1') `
        latest cleanup-case -ProjectRoot $project -c -WhatIf
    Assert-Exists `
        (Join-Path $cleanupTarget 'stale.p2s') `
        'Cleanup -WhatIf changed the existing destination.'
    Assert-Exists `
        (Join-Path $states 'SLOP-NA228 (12345678).02.p2s') `
        'Cleanup -WhatIf moved the incoming savestate.'

    $shortAliasForwarded = $false
    try {
        & (Join-Path $repository 'workshop.ps1') `
            ss move __unknown_game__ destination -c
    }
    catch {
        $shortAliasForwarded = (
            $_.Exception.Message -like 'Unknown game or alias*'
        )
    }
    if (-not $shortAliasForwarded) {
        throw 'The Workshop dispatcher did not forward the -c cleanup alias.'
    }

    Write-Host 'Savestate filing tests passed.'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
