[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
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
        'pcsx2\fork',
        'pcsx2\sstates',
        'pcsx2_files\games\NUN5',
        'pcsx2_files\input_profiles',
        'pcsx2_files\input_recordings',
        'pcsx2_files\memory_cards'
    )) {
        [void](New-Item -ItemType Directory -Path (Join-Path $workshop $path) -Force)
    }
    [void](New-Item -ItemType Directory -Path (Join-Path $project 'game_data') -Force)

    foreach ($name in @('paths.ps1', 'paths.py', 'game_catalog.py', 'resolve_game.py')) {
        Copy-Item `
            -LiteralPath (Join-Path $repository "scripts\lib\$name") `
            -Destination (Join-Path $workshop "scripts\lib\$name")
    }
    Copy-Item `
        -LiteralPath (Join-Path $repository 'scripts\pcsx2\move_savestates.ps1') `
        -Destination (Join-Path $workshop 'scripts\pcsx2\move_savestates.ps1')

    Set-Content -LiteralPath (Join-Path $workshop 'paths.json') -Value @'
{
  "roots": {
    "source": "source",
    "disassembly": "@work/disassembly",
    "tools": "tools",
    "work": "work",
    "savestates": "@work/sstates",
    "scripts": "scripts",
    "pcsx2_fork": "pcsx2/fork",
    "pcsx2_dev": "pcsx2",
    "pcsx2_files": "pcsx2_files",
    "pcsx2_input_profiles": "@pcsx2_files/input_profiles",
    "pcsx2_input_recordings": "@pcsx2_files/input_recordings",
    "pcsx2_memory_cards": "@pcsx2_files/memory_cards"
  },
  "files": {
    "source_catalog": "games.json",
    "project_settings": "game.json",
    "game_resolver": "@scripts/lib/resolve_game.py"
  }
}
'@
    Set-Content -LiteralPath (Join-Path $workshop 'games.json') -Value @'
{
  "sources": {
    "NUN5": { "serial": "SLES-55605", "crc": "C071D4C1" }
  }
}
'@
    Set-Content -LiteralPath (Join-Path $project 'game.json') -Value @'
{
  "title": "NA v2.28",
  "serial": "SLOP-NA228"
}
'@
    Set-Content -LiteralPath (Join-Path $project 'paths.json') -Value @'
{
  "imports": { "workshop": "../workshop/paths.json" },
  "roots": {
    "pcsx2_files": "game_data"
  },
  "files": { "project_settings": "game.json" }
}
'@
    foreach ($extension in @('ini', 'pnach', 'ps2')) {
        Set-Content `
            -LiteralPath (Join-Path $workshop "pcsx2_files\games\NUN5\NUN5.$extension") `
            -Value 'test'
    }

    $resolvedSource = (
        & python `
            (Join-Path $workshop 'scripts\lib\resolve_game.py') `
            NUN5 `
            --project-root $project
    ) | ConvertFrom-Json
    $expectedSourceCard = Join-Path $workshop 'pcsx2_files\games\NUN5\NUN5.ps2'
    if (
        [IO.Path]::GetFullPath([string]$resolvedSource.memory_card) -cne
        [IO.Path]::GetFullPath($expectedSourceCard)
    ) {
        throw 'Source memory-card path did not resolve from the Workshop-owned NUN5 bundle.'
    }

    $states = Join-Path $workshop 'pcsx2\sstates'
    $sourceCase = Join-Path $workshop 'work\sstates\source-case'
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

    $cleanupTarget = Join-Path $workshop 'work\sstates\cleanup-case'
    [void](New-Item -ItemType Directory -Path $cleanupTarget -Force)
    Set-Content -LiteralPath (Join-Path $cleanupTarget 'stale.p2s') -Value 'stale'
    Set-Content -LiteralPath (Join-Path $states 'SLES-55605 (C071D4C1).02.p2s') -Value 'new'
    & (Join-Path $workshop 'scripts\pcsx2\move_savestates.ps1') `
        NUN5 cleanup-case -ProjectRoot $project -c -WhatIf
    Assert-Exists `
        (Join-Path $cleanupTarget 'stale.p2s') `
        'Cleanup -WhatIf changed the existing destination.'
    Assert-Exists `
        (Join-Path $states 'SLES-55605 (C071D4C1).02.p2s') `
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
