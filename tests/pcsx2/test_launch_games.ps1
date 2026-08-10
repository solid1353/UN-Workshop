[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-WorkshopLaunchTest {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) { throw $Message }
}

$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$help = (& (Join-Path $sourceRepository 'workshop.ps1') help) -join "`n"
foreach ($expectedOption in @(
    '-p <name>',
    '-r <name>',
    '-t <name>',
    '-mc <card>',
    '-dw',
    '-t <dev|stable>',
    '-c'
)) {
    Assert-WorkshopLaunchTest `
        -Condition ($help.Contains($expectedOption)) `
        -Message "Workshop help did not document public option: $expectedOption"
}

$testRoot = Join-Path `
    ([IO.Path]::GetTempPath()) `
    "workshop-launch-tests-$PID-$([Guid]::NewGuid().ToString('N'))"
$repository = Join-Path $testRoot 'repo'

try {
    . (Join-Path $sourceRepository 'scripts\lib\paths.ps1')
    $recordingRoot = Join-Path $testRoot 'recordings'
    $nestedRecording = Resolve-UnWorkshopRecordingName `
        -Name 'font/collection/generic' `
        -Root $recordingRoot `
        -CreateParent
    Assert-WorkshopLaunchTest `
        -Condition (
            $nestedRecording -ceq 'font\collection\generic.p2m2' -and
            (Test-Path -LiteralPath (
                Join-Path $recordingRoot 'font\collection'
            ) -PathType Container)
        ) `
        -Message 'Nested recording creation did not resolve below the shared root.'
    $escapingRecordingRejected = $false
    try {
        Resolve-UnWorkshopRecordingName `
            -Name '..\outside' `
            -Root $recordingRoot `
            -CreateParent
    }
    catch {
        $escapingRecordingRejected = $_.Exception.Message -match 'must be inside'
    }
    Assert-WorkshopLaunchTest `
        -Condition $escapingRecordingRejected `
        -Message 'Nested recording creation accepted a path outside the shared root.'

    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'scripts\lib') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'scripts\pcsx2') | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRepository 'workshop.ps1') -Destination $repository
    Copy-Item `
        -LiteralPath (Join-Path $sourceRepository 'scripts\lib\paths.ps1') `
        -Destination (Join-Path $repository 'scripts\lib')

    @'
{
  "schema_version": 1,
  "roots": {
    "repository": ".",
    "source": "source",
    "analysis": "work",
    "tools": "tools",
    "work": "work",
    "savestates": "@work/sstates",
    "scripts": "scripts",
    "pcsx2_scripts": "@scripts/pcsx2",
    "pcsx2": "pcsx2",
    "pcsx2_stable": "@pcsx2/stable",
    "pcsx2_dev": "@pcsx2/dev",
    "pcsx2_clean": "pcsx2/clean",
    "pcsx2_files": "pcsx2_shared",
    "pcsx2_bios": "@pcsx2_files/bios",
    "pcsx2_cheats": "@pcsx2_files/cheats",
    "pcsx2_game_settings": "@pcsx2_files/game_settings",
    "pcsx2_input_profiles": "@pcsx2_files/input_profiles",
    "pcsx2_input_recordings": "@pcsx2_files/input_recordings",
    "pcsx2_memory_cards": "@pcsx2_files/memory_cards"
  },
  "files": {
    "game_catalog": "@repository/games.json",
    "game_resolver": "@repository/scripts/lib/resolve_game.py",
    "workshop_command": "@repository/workshop.ps1",
    "pcsx2_launch_command": "@repository/scripts/pcsx2/launch.ps1",
    "pcsx2_game_launch_command": "@repository/scripts/pcsx2/launch_games.ps1"
  }
}
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'paths.json')
    '{"schema_version":1,"sources":{"NUN5":{"serial":"SLES-55605","crc":"C071D4C1"}}}' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'games.json')
    '{"schema_version":1,"title":"NA v2.28","serial":"SLOP-NA228","builds":{"latest":{"aliases":["l"]}}}' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'product.json')
    'raise SystemExit("fake resolver must not run")' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\lib\resolve_game.py')
    @'
param()
'[fake] launch PCSX2 UI'
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch.ps1')
    @'
param(
    [string[]]$Games,
    [string]$Play,
    [string]$Record,
    [switch]$Test,
    [string]$CaptureDirectory,
    [string]$MemoryCard,
    [switch]$DiscardMemoryCardWrites,
    [string]$ProjectRoot
)
"[fake] games=$($Games -join ',') play=$Play record=$Record test=$Test capture=$CaptureDirectory memory=$MemoryCard discard=$DiscardMemoryCardWrites project=$ProjectRoot"
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch_games.ps1')

    Push-Location $repository
    try {
        $play = (& .\workshop.ps1 NUN5 latest -p practice-menu) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($play -match 'games=NUN5,latest play=practice-menu record=') `
            -Message 'Paired playback was not forwarded to the shared launcher.'

        $memoryCardLaunch = (
            & .\workshop.ps1 NUN5 latest -mc 'Custom.ps2' -dw
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $memoryCardLaunch -match 'memory=Custom\.ps2 discard=True'
            ) `
            -Message 'Memory-card override and discard-write mode were not forwarded.'

        $record = (& .\workshop.ps1 NUN5 latest -r font/collection/generic) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($record -match 'games=NUN5,latest play= record=font/collection/generic') `
            -Message 'Nested rightmost recording was not forwarded to the shared launcher.'

        $test = (& .\workshop.ps1 NUN5 -t practice-menu) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($test -match 'games=NUN5 play=practice-menu record= test=True') `
            -Message 'Regression playback was not forwarded to the shared launcher.'

        $outputOverrideRejected = $false
        try { & .\workshop.ps1 NUN5 -t practice-menu -o ignored }
        catch { $outputOverrideRejected = $true }
        Assert-WorkshopLaunchTest `
            -Condition $outputOverrideRejected `
            -Message 'Retired public -o capture override remained accepted.'

        $barePcsx2 = (& .\workshop.ps1 pcsx2) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($barePcsx2 -match '\[fake\] launch PCSX2 UI') `
            -Message 'Bare PCSX2 launch was not preserved.'

        $oldCommandRejected = $false
        try { & .\workshop.ps1 rec NUN5 practice-menu }
        catch { $oldCommandRejected = $true }
        Assert-WorkshopLaunchTest `
            -Condition $oldCommandRejected `
            -Message 'The retired rec command remains active.'
    }
    finally {
        Pop-Location
    }

    Write-Host 'Workshop paired-launch tests passed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
