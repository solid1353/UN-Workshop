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
    -Condition (
        $help.Contains(
            'workshop <game|iso-path> [game|iso-path] ' +
            '[-p name|-r name|-s name]'
        )
    ) `
    -Message 'Workshop help did not present one unified launch command.'
foreach ($expectedOption in @(
    '-p <name>',
    '-r <name>',
    '-s <name>',
    '-o <path>',
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
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'game.json')
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
    [switch]$ReadOnlySettings,
    [hashtable]$PnachByGame,
    [hashtable]$PnachLinesByGame,
    [switch]$Turbo,
    [switch]$Unlimited,
    [UInt64]$UnlimitedForFrames,
    [string]$ProjectRoot
)
$pnachCount = if ($null -eq $PnachByGame) { 0 } else { $PnachByGame.Count }
$lineSetCount = if ($null -eq $PnachLinesByGame) { 0 } else { $PnachLinesByGame.Count }
"[fake] games=$($Games -join ',') play=$Play record=$Record snapshots=$Snapshots capture=$CaptureDirectory memory=$MemoryCard discard=$DiscardMemoryCardWrites readOnly=$ReadOnlySettings pnaches=$pnachCount lineSets=$lineSetCount turbo=$Turbo unlimited=$Unlimited frames=$UnlimitedForFrames project=$ProjectRoot"
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

        $pairedSnapshots = (
            & .\workshop.ps1 NUN5 latest -s practice-menu
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $pairedSnapshots -match (
                    'games=NUN5,latest play=practice-menu record= snapshots=True'
                )
            ) `
            -Message 'Paired snapshot playback was not forwarded to the shared launcher.'

        $snapshotsWithPath = (
            & .\workshop.ps1 NUN5 -s practice-menu -o 'captures/custom'
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
            & .\workshop.ps1 $isoTarget -s practice-menu -o 'captures/worker'
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

        $captureWithoutSnapshotsRejected = $false
        try { & .\workshop.ps1 NUN5 -o 'captures/invalid' }
        catch { $captureWithoutSnapshotsRejected = $_.Exception.Message -ceq '-o requires -s.' }
        Assert-WorkshopLaunchTest `
            -Condition $captureWithoutSnapshotsRejected `
            -Message 'Workshop accepted -o without snapshot replay.'

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
                (Join-Path $repository 'pcsx2_files\games\NUN5'), `
                (Join-Path $repository 'pcsx2_files\games\NA228'), `
                (Join-Path $repository 'pcsx2_files\input_recordings') | Out-Null
        New-Item `
            -ItemType File `
            -Force `
            -Path (Join-Path $repository 'source\NUN5.iso'), `
                (Join-Path $repository 'pcsx2_files\games\NUN5\NUN5.pnach'), `
                (Join-Path $repository 'pcsx2_files\games\NUN5\NUN5.ini'), `
                (Join-Path $repository 'pcsx2_files\games\NUN5\NUN5.ps2'), `
                (Join-Path $repository 'pcsx2_files\games\NA228\NA228.pnach'), `
                (Join-Path $repository 'pcsx2_files\games\NA228\NA228.ini'), `
                (Join-Path $repository 'pcsx2_files\games\NA228\NA228.ps2'), `
                (Join-Path $repository 'pcsx2_files\input_recordings\practice-menu.p2m2') | Out-Null
        @'
param(
    [string]$IsoPath,
    [string]$MemoryCard,
    [string]$InputRecordingsRoot,
    [string]$InputRecording,
    [string]$InputRecordingCaptureDirectory,
    [switch]$Surfaceless,
    [switch]$DiscardMemoryCardWrites,
    [switch]$ReadOnlySettings,
    [string]$Pnach,
    [string[]]$PnachLines,
    [switch]$Turbo,
    [switch]$Unlimited,
    [UInt64]$UnlimitedForFrames,
    [switch]$Wait,
    [switch]$PassThru,
    [string[]]$Arguments
)
$message = "[fake] iso=$IsoPath input=$InputRecording capture=$InputRecordingCaptureDirectory memory=$MemoryCard arguments=$($Arguments -join ',') surfaceless=$Surfaceless discard=$DiscardMemoryCardWrites readOnly=$ReadOnlySettings pnach=$Pnach lines=$($PnachLines -join '|') turbo=$Turbo unlimited=$Unlimited frames=$UnlimitedForFrames wait=$Wait passThru=$PassThru"
$message
if ($PassThru) {
    Start-Process `
        -FilePath ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) `
        -ArgumentList @('-NoProfile', '-Command', 'Start-Sleep -Milliseconds 50') `
        -WindowStyle Hidden `
        -PassThru
}
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch.ps1')

        New-Item -ItemType Directory -Force -Path (
            Join-Path $repository 'pcsx2\inis'
        ) | Out-Null
        'PINESlot = 28011' | Set-Content -NoNewline -LiteralPath (
            Join-Path $repository 'pcsx2\inis\PCSX2.ini'
        )

        $resolver = Join-Path $repository 'scripts\lib\resolve_game.py'
        $resolvedSource = (
            & python -B $resolver NUN5 --project-root $repository
        ) | ConvertFrom-Json
        Assert-WorkshopLaunchTest `
            -Condition (
                [string]$resolvedSource.cheats -ceq
                (Join-Path $repository 'pcsx2_files\games\NUN5\NUN5.pnach')
            ) `
            -Message 'The project-owned NUN5 PNACH did not resolve from its game bundle.'
        $resolvedBuild = (
            & python -B $resolver latest --project-root $repository
        ) | ConvertFrom-Json
        Assert-WorkshopLaunchTest `
            -Condition (
                [string]$resolvedBuild.cheats -ceq
                (Join-Path $repository 'pcsx2_files\games\NA228\NA228.pnach')
            ) `
            -Message 'Build PNACH resolution did not use the NA228 game bundle.'

        $defaultSnapshotLaunch = (
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games NUN5 `
                -Play practice-menu `
                -Snapshots `
                -CaptureDirectory (Join-Path $repository 'captures-default') `
                -ProjectRoot $repository
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $defaultSnapshotLaunch -match (
                    'pnach=' + [regex]::Escape(
                        (Join-Path $repository 'pcsx2_files\games\NUN5\NUN5.pnach')
                    ) + ' lines='
                )
            ) `
            -Message 'The configured default PNACH was not passed to PCSX2.'

        $practicePnach = Join-Path $repository 'practice.pnach'
        Set-Content `
            -NoNewline `
            -LiteralPath $practicePnach `
            -Value '[+Practice]'
        $practicePnachByGame = @{ nun5 = $practicePnach }
        $practiceLinesByGame = @{
            nun5 = [string[]]@(
                'patch=1,EE,003D0FF0,word,00000039',
                'patch=1,EE,003D0FF4,word,00000025'
            )
        }

        $snapshotLaunch = (
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games NUN5 `
                -Play practice-menu `
                -Snapshots `
                -InputRecordingCaptureMode screenshots `
                -CaptureDirectory (Join-Path $repository 'captures') `
                -PnachByGame $practicePnachByGame `
                -PnachLinesByGame $practiceLinesByGame `
                -ProjectRoot $repository
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition (
                $snapshotLaunch -match (
                    'arguments=-input-recording-capture-mode,screenshots ' +
                    'surfaceless=True discard=True readOnly=True ' +
                    'pnach=' + [regex]::Escape($practicePnach) +
                    ' lines=patch=1,EE,003D0FF0,word,00000039\|' +
                    'patch=1,EE,003D0FF4,word,00000025 ' +
                    'turbo=False unlimited=True frames=0 wait=False passThru=True'
                )
            ) `
            -Message 'Snapshot playback did not forward the selected game PNACH and inline lines.'

        $secondIso = Join-Path $repository 'source\NUN3.iso'
        New-Item -ItemType File -Force -Path $secondIso | Out-Null
        $pairedCaptureRoot = Join-Path $repository 'captures-paired'
        $pairedSnapshotLaunch = @(
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games @('NUN5', $secondIso) `
                -Play practice-menu `
                -Snapshots `
                -InputRecordingCaptureMode screenshots `
                -CaptureDirectory $pairedCaptureRoot `
                -ProjectRoot $repository
        )
        $pairedText = $pairedSnapshotLaunch -join "`n"
        $leftCapture = Join-Path $pairedCaptureRoot 'nun5'
        $rightCapture = Join-Path $pairedCaptureRoot 'NUN3'
        $pinePorts = @(
            [regex]::Matches($pairedText, 'arguments=-pine-port,(\d+)') |
                ForEach-Object { $_.Groups[1].Value }
        )
        Assert-WorkshopLaunchTest `
            -Condition (
                $pairedSnapshotLaunch.Count -eq 2 -and
                @($pairedText -split "`n" | Where-Object {
                    $_ -match 'input=practice-menu\.p2m2'
                }).Count -eq 2 -and
                $pairedText.Contains("capture=$leftCapture") -and
                $pairedText.Contains("capture=$rightCapture") -and
                @($pinePorts | Select-Object -Unique).Count -eq 2 -and
                @($pairedText -split "`n" | Where-Object {
                    $_ -match 'surfaceless=True' -and
                    $_ -match 'discard=True' -and
                    $_ -match 'unlimited=True' -and
                    $_ -match 'wait=False passThru=True'
                }).Count -eq 2 -and
                (Test-Path -LiteralPath $leftCapture -PathType Container) -and
                (Test-Path -LiteralPath $rightCapture -PathType Container) -and
                -not (Test-Path -LiteralPath (
                    Join-Path $repository 'pcsx2_files\input_recordings\__generated'
                ))
            ) `
            -Message (
                'Paired snapshot replay did not share the canonical recording while ' +
                "using isolated captures and PINE ports. Output: $pairedText"
            )

        $unselectedPnachRejected = $false
        try {
            & (Join-Path $repository 'scripts\pcsx2\launch_games.ps1') `
                -Games NUN5 `
                -Play practice-menu `
                -Snapshots `
                -CaptureDirectory (Join-Path $repository 'captures-invalid') `
                -PnachByGame @{ na2 = $practicePnach } `
                -ProjectRoot $repository
        }
        catch {
            $unselectedPnachRejected = $_.Exception.Message -match (
                '^PNACH override targets an unselected game:'
            )
        }
        Assert-WorkshopLaunchTest `
            -Condition $unselectedPnachRejected `
            -Message 'Paired launcher accepted a PNACH override for an unselected game.'

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
                $isoSnapshotLaunch.Contains("iso=$workerIso input=practice-menu.p2m2") -and
                $isoSnapshotLaunch.Contains(
                    "capture=$(Join-Path $repository 'captures-worker') memory="
                ) -and
                $isoSnapshotLaunch -match (
                    'arguments= surfaceless=True discard=True readOnly=True ' +
                    'pnach= lines= turbo=False unlimited=True frames=0 ' +
                    'wait=False passThru=True'
                )
            ) `
            -Message (
                "Snapshot playback did not accept an explicit ISO path. " +
                "Output: $isoSnapshotLaunch"
            )

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
