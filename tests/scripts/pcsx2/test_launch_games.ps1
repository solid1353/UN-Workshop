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

$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$help = (& (Join-Path $sourceRepository 'workshop.ps1') help) -join "`n"
Assert-WorkshopLaunchTest `
    -Condition ($help.Contains('workshop <game|iso-path> -s name')) `
    -Message 'Workshop help did not document ISO-path snapshot replay.'
foreach ($expectedOption in @(
    '-p <name>',
    '-r <name>',
    '-s <name>',
    '-mc <card>',
    '-dw',
    '-t',
    '-u',
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
    "disassembly": "@work/disassembly",
    "tools": "tools",
    "work": "work",
    "savestates": "@work/sstates",
    "scripts": "scripts",
    "pcsx2_scripts": "@scripts/pcsx2",
    "pcsx2": "pcsx2",
    "pcsx2_dev": "@pcsx2",
    "pcsx2_fork": "pcsx2/fork",
    "pcsx2_files": "pcsx2_files",
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
    '{"schema_version":1,"title":"NA v2.28","serial":"SLOP-NA228","output_boot_path":"SLOP_NA2.28","startup_fast_forward_frames":321,"builds":{"latest":{"aliases":["l"]}}}' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'settings.json')
    'raise SystemExit("fake resolver must not run")' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\lib\resolve_game.py')
    @'
param([switch]$Turbo)
"[fake] launch PCSX2 UI turbo=$Turbo"
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch.ps1')
    @'
param(
    [string[]]$Games,
    [string]$Play,
    [string]$Record,
    [switch]$Snapshots,
    [string]$CaptureDirectory,
    [string]$MemoryCard,
    [switch]$DiscardMemoryCardWrites,
    [switch]$Turbo,
    [switch]$Unlimited,
    [UInt64]$UnlimitedForFrames,
    [string]$ProjectRoot
)
"[fake] games=$($Games -join ',') play=$Play record=$Record snapshots=$Snapshots capture=$CaptureDirectory memory=$MemoryCard discard=$DiscardMemoryCardWrites turbo=$Turbo unlimited=$Unlimited frames=$UnlimitedForFrames project=$ProjectRoot"
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

        $turboLaunch = (& .\workshop.ps1 NUN5 -t) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($turboLaunch -match 'games=NUN5 .*turbo=True unlimited=False') `
            -Message 'Turbo launch was not forwarded to the shared launcher.'

        $unlimitedLaunch = (& .\workshop.ps1 NUN5 -u) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($unlimitedLaunch -match 'games=NUN5 .*turbo=False unlimited=True') `
            -Message 'Unlimited launch was not forwarded to the shared launcher.'

        $record = (& .\workshop.ps1 NUN5 latest -r font/collection/generic) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($record -match 'games=NUN5,latest play= record=font/collection/generic') `
            -Message 'Nested rightmost recording was not forwarded to the shared launcher.'

        $snapshots = (& .\workshop.ps1 NUN5 -s practice-menu) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($snapshots -match 'games=NUN5 play=practice-menu record= snapshots=True') `
            -Message 'Snapshot playback was not forwarded to the shared launcher.'

        $snapshotsWithPath = (
            & .\workshop.ps1 NUN5 -s practice-menu 'captures/custom'
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $snapshotsWithPath -match (
                    'games=NUN5 play=practice-menu record= snapshots=True ' +
                    'capture=captures/custom'
                )
            ) `
            -Message 'The optional snapshot capture path was not forwarded.'

        $isoTarget = 'work/Docs chat/build/candidate.iso'
        $isoSnapshots = (
            & .\workshop.ps1 $isoTarget -s practice-menu 'captures/worker'
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $isoSnapshots -match (
                    'games=work/Docs chat/build/candidate\.iso ' +
                    'play=practice-menu record= snapshots=True ' +
                    'capture=captures/worker'
                )
            ) `
            -Message 'The ISO snapshot target was not forwarded.'

        $conflictingSpeedRejected = $false
        try { & .\workshop.ps1 NUN5 -t -u }
        catch { $conflictingSpeedRejected = $true }
        Assert-WorkshopLaunchTest `
            -Condition $conflictingSpeedRejected `
            -Message 'Turbo and Unlimited were accepted together.'

        $barePcsx2 = (& .\workshop.ps1 pcsx2) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($barePcsx2 -match '\[fake\] launch PCSX2 UI turbo=True') `
            -Message 'Bare PCSX2 launch did not preserve permanent Turbo.'

        Copy-Item `
            -LiteralPath (Join-Path $sourceRepository 'scripts\pcsx2\launch_games.ps1') `
            -Destination (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
            -Force
        foreach ($name in @('resolve_game.py', 'game_catalog.py', 'paths.py')) {
            Copy-Item `
                -LiteralPath (Join-Path $sourceRepository "scripts\lib\$name") `
                -Destination (Join-Path $repository "scripts\lib\$name")
        }
        New-Item `
            -ItemType Directory `
            -Force `
            -Path (Join-Path $repository 'source'), `
                (Join-Path $repository 'pcsx2_files\memory_cards') | Out-Null
        New-Item `
            -ItemType File `
            -Force `
            -Path (Join-Path $repository 'source\NUN5.iso'), `
                (Join-Path $repository 'pcsx2_files\memory_cards\NUN5.ps2') | Out-Null
        @'
param(
    [string]$IsoPath,
    [string]$MemoryCard,
    [string]$InputRecording,
    [string]$InputRecordingCaptureDirectory,
    [switch]$Surfaceless,
    [switch]$DiscardMemoryCardWrites,
    [switch]$ReadOnlySettings,
    [switch]$Turbo,
    [switch]$Unlimited,
    [UInt64]$UnlimitedForFrames,
    [switch]$Wait,
    [string[]]$Arguments
)
"[fake] iso=$IsoPath memory=$MemoryCard arguments=$($Arguments -join ',') surfaceless=$Surfaceless discard=$DiscardMemoryCardWrites readOnly=$ReadOnlySettings turbo=$Turbo unlimited=$Unlimited frames=$UnlimitedForFrames wait=$Wait"
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch.ps1')

        $snapshotLaunch = (
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games NUN5 `
                -Play practice-menu `
                -Snapshots `
                -CaptureDirectory (Join-Path $repository 'captures') `
                -ProjectRoot $repository
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $snapshotLaunch -match 'arguments= surfaceless=True discard=True readOnly=True turbo=False unlimited=True frames=0 wait=True'
            ) `
            -Message 'Snapshot playback did not delegate background muting while forcing read-only settings.'

        $workerIso = Join-Path $repository 'work\Docs chat\build\candidate.iso'
        New-Item `
            -ItemType Directory `
            -Force `
            -Path ([IO.Path]::GetDirectoryName($workerIso)) | Out-Null
        New-Item -ItemType File -Force -Path $workerIso | Out-Null
        $isoSnapshotLaunch = (
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games $workerIso `
                -Play practice-menu `
                -Snapshots `
                -CaptureDirectory (Join-Path $repository 'captures-worker') `
                -ProjectRoot $repository
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $isoSnapshotLaunch.Contains("iso=$workerIso memory=") -and
                $isoSnapshotLaunch -match 'arguments= surfaceless=True discard=True readOnly=True turbo=False unlimited=True frames=0 wait=True'
            ) `
            -Message 'Snapshot playback did not accept an explicit ISO path.'

        $missingIsoRejected = $false
        try {
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games (Join-Path $repository 'work\missing.iso') `
                -Play practice-menu `
                -Snapshots `
                -CaptureDirectory (Join-Path $repository 'captures-missing') `
                -ProjectRoot $repository
        }
        catch {
            $missingIsoRejected = $_.Exception.Message -match 'ISO does not exist'
        }
        Assert-WorkshopLaunchTest `
            -Condition $missingIsoRejected `
            -Message 'Snapshot playback did not reject a missing explicit ISO path.'

        Copy-Item `
            -LiteralPath (Join-Path $sourceRepository 'scripts\pcsx2\launch.ps1') `
            -Destination (Join-Path $repository 'scripts\pcsx2\launch.ps1') `
            -Force
        $fakeDevRoot = Join-Path $repository 'pcsx2'
        New-Item -ItemType Directory -Force -Path $fakeDevRoot | Out-Null
        New-Item `
            -ItemType File `
            -Force `
            -Path (Join-Path $fakeDevRoot 'pcsx2-qtx64-avx2-dev.exe') | Out-Null
        function Start-Process {
            param(
                [string]$FilePath,
                [string]$WorkingDirectory,
                [string[]]$ArgumentList,
                [switch]$Wait,
                [switch]$PassThru
            )
            $global:UnWorkshopCapturedStartArguments = @($ArgumentList)
        }

        & (Join-Path $repository 'scripts\pcsx2\launch.ps1') `
            -IsoPath (Join-Path $repository 'source\NUN5.iso') `
            -ReadOnlySettings `
            -Turbo `
            -UnlimitedForFrames 321
        $timedArguments = @($global:UnWorkshopCapturedStartArguments)
        Assert-WorkshopLaunchTest `
            -Condition (
                ($timedArguments -join '|') -match (
                    '^-read-only-settings\|-turbo\|-unlimited-for-frames\|321\|-batch\|'
                )
            ) `
            -Message 'Configured launcher did not compose read-only settings with timed Unlimited and a Turbo fallback.'

        & (Join-Path $repository 'scripts\pcsx2\launch.ps1') `
            -IsoPath (Join-Path $repository 'source\NUN5.iso') `
            -Unlimited
        $unlimitedArguments = @($global:UnWorkshopCapturedStartArguments)
        Assert-WorkshopLaunchTest `
            -Condition (
                $unlimitedArguments -contains '-unlimited' -and
                $unlimitedArguments -notcontains '-turbo' -and
                $unlimitedArguments -notcontains '-unlimited-for-frames'
            ) `
            -Message 'Configured launcher did not compose permanent Unlimited independently.'

        & (Join-Path $repository 'scripts\pcsx2\launch.ps1') `
            -IsoPath (Join-Path $repository 'source\NUN5.iso') `
            -Surfaceless
        $backgroundArguments = @($global:UnWorkshopCapturedStartArguments)
        Assert-WorkshopLaunchTest `
            -Condition (
                $backgroundArguments -contains '-surfaceless' -and
                $backgroundArguments -contains '-mute' -and
                $backgroundArguments -notcontains '-nogui' -and
                @($backgroundArguments | Where-Object { $_ -eq '-mute' }).Count -eq 1
            ) `
            -Message 'Surfaceless launcher did not centrally select one mute flag without redundant no-GUI.'

        & (Join-Path $repository 'scripts\pcsx2\launch.ps1') `
            -IsoPath (Join-Path $repository 'source\NUN5.iso')
        $normalArguments = @($global:UnWorkshopCapturedStartArguments)
        Assert-WorkshopLaunchTest `
            -Condition (
                $normalArguments -notcontains '-turbo' -and
                $normalArguments -notcontains '-unlimited' -and
                $normalArguments -notcontains '-unlimited-for-frames'
            ) `
            -Message 'Configured launcher no longer has a Normal fallback.'
    }
    finally {
        Remove-Variable `
            -Name UnWorkshopCapturedStartArguments `
            -Scope Global `
            -ErrorAction SilentlyContinue
        Pop-Location
    }

    Write-Host 'Workshop paired-launch tests passed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
