[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Normal')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateCount(1, 3)]
    [string[]]$Games,

    [Parameter(ParameterSetName = 'Play')]
    [string]$Play,

    [Parameter(ParameterSetName = 'Play')]
    [switch]$AgentReplay,

    [switch]$Surfaceless,

    [string]$LogFile,

    [string]$SavestateFolder,

    [Parameter(ParameterSetName = 'Play')]
    [switch]$Snapshots,

    [Parameter(ParameterSetName = 'Play')]
    [string]$CaptureDirectory,

    [Parameter(ParameterSetName = 'Play')]
    [ValidateSet('full', 'screenshots')]
    [string]$InputRecordingCaptureMode = 'full',

    [Parameter(ParameterSetName = 'Record')]
    [string]$Record,

    [string]$MemoryCard,

    [switch]$DiscardMemoryCardWrites,

    [switch]$VolatileMemoryCard,

    [switch]$ReadOnlySettings,

    [hashtable]$PnachByGame,

    [string[]]$AdditionalPnach,

    [hashtable]$PnachLinesByGame,

    [switch]$Turbo,

    [switch]$Unlimited,

    [UInt64]$UnlimitedForFrames = 0,

    [hashtable]$UnlimitedForFramesByGame,

    [switch]$ClosePcsx2,

    [switch]$LastGameAudio,

    # The game -aud unmutes and -r records, by selector; the last by default.
    [string]$MainGame,

    [switch]$Mute,

    [string]$ProjectRoot,

    [string]$InputRecordingsRoot,

    [string]$CaptureRoot,

    [ValidateRange(5, 120)]
    [int]$WindowWaitSeconds = 30
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'launch_arguments.ps1')
if ($DiscardMemoryCardWrites -and $VolatileMemoryCard) {
    throw 'Use only one of -dmc or -vmc.'
}
if ($Snapshots -and $ClosePcsx2) {
    throw '-k cannot be combined with -rps.'
}
if ($Surfaceless -and ($Snapshots -or $AgentReplay)) {
    throw '-rps and -agent-replay already run surfaceless.'
}
# These launches have no window to wait for, tile or make room for.
$noWindow = $AgentReplay -or $Surfaceless
if ($LastGameAudio -and ($noWindow -or $Snapshots)) {
    throw '-aud needs a windowed launch.'
}
if ($LastGameAudio -and $Mute) {
    throw 'Use only one of -aud or -mute.'
}
if ($AgentReplay) {
    if ([string]::IsNullOrWhiteSpace($Play) -or $Snapshots) {
        throw '-agent-replay requires -rp and cannot be combined with -rps.'
    }
    if ($Turbo -or $Unlimited) {
        throw '-agent-replay cannot be combined with fast-forward options.'
    }
    if ([string]::IsNullOrWhiteSpace($LogFile)) {
        throw 'Agent replay requires -logfile.'
    }
}
if (-not [string]::IsNullOrWhiteSpace($LogFile) -and $Games.Count -ne 1) {
    throw '-logfile requires a single game.'
}
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
$inputRecordingsRoot = if ([string]::IsNullOrWhiteSpace($InputRecordingsRoot)) {
    [IO.Path]::GetFullPath($paths.InputRecordings)
}
else {
    [IO.Path]::GetFullPath($InputRecordingsRoot)
}

if ($Turbo -and $Unlimited) {
    throw 'Use only one of -Turbo or -Unlimited.'
}
if ($PSBoundParameters.ContainsKey('UnlimitedForFrames') -and
    $UnlimitedForFrames -eq 0) {
    throw '-UnlimitedForFrames requires a positive frame count.'
}
$frameLimitedUnlimited = $UnlimitedForFrames -gt 0 -or
    ($null -ne $UnlimitedForFramesByGame -and $UnlimitedForFramesByGame.Count -gt 0)
if ($null -ne $UnlimitedForFramesByGame -and
    @($UnlimitedForFramesByGame.Values | Where-Object { [UInt64]$_ -eq 0 }).Count -gt 0) {
    throw '-UnlimitedForFramesByGame requires positive frame counts.'
}
if ($Unlimited -and $frameLimitedUnlimited) {
    throw 'Permanent Unlimited cannot be combined with frame-limited Unlimited.'
}
if ($Snapshots -and ($Turbo -or $Unlimited -or $frameLimitedUnlimited)) {
    throw 'Snapshot replay owns its permanent Unlimited speed mode.'
}
if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory) -and -not $Snapshots) {
    throw 'Snapshot output directory (-o) requires -rps.'
}

function Get-UnWorkshopConfiguredPinePort {
    param(
        [Parameter(Mandatory)]
        [string]$Pcsx2Root
    )

    $iniPath = Join-Path $Pcsx2Root 'inis\PCSX2.ini'
    if (-not (Test-Path -LiteralPath $iniPath -PathType Leaf)) {
        throw "PCSX2 configuration was not found: $iniPath"
    }
    $match = Select-String `
        -LiteralPath $iniPath `
        -Pattern '^\s*PINESlot\s*=\s*(\d+)\s*$' |
        Select-Object -First 1
    if ($null -eq $match) {
        throw "PCSX2 PINESlot is not configured in $iniPath"
    }
    $port = [int]$match.Matches[0].Groups[1].Value
    if ($port -lt 1024 -or $port -gt 65535) {
        throw "PCSX2 PINESlot is invalid: $port"
    }
    return $port
}

function Get-UnWorkshopUserEmulatorProcesses {
    param(
        [Parameter(Mandatory)]
        [string[]]$Roots,
        # Only the windows a launch of several games tiled: PCSX2 started with
        # -no-recenter and PPSSPP with --window, which no other launch passes.
        [switch]$Tiled
    )

    $rootPrefixes = @(
        foreach ($root in $Roots) {
            [IO.Path]::GetFullPath($root).TrimEnd(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ) + [IO.Path]::DirectorySeparatorChar
        }
    )
    $commandLines = @{}
    foreach ($instance in @(Get-CimInstance -ClassName Win32_Process -Filter "Name LIKE 'pcsx2%' OR Name LIKE 'PPSSPP%'" -ErrorAction SilentlyContinue)) {
        $commandLines[[int]$instance.ProcessId] = [string]$instance.CommandLine
    }
    foreach ($process in @(Get-Process -Name 'pcsx2*', 'PPSSPP*' -ErrorAction SilentlyContinue)) {
        $commandLine = [string]$commandLines[$process.Id]
        # Surfaceless PCSX2 instances, which agents and replays drive, are not the
        # user's: they started with -surfaceless or -agent-replay.
        if ($process.Name -like 'pcsx2*' -and
            $commandLine -match '(?:^|\s)-(?:surfaceless|agent-replay)(?:\s|$)') {
            continue
        }
        if ($Tiled -and $commandLine -notmatch '(?:^|[\s"])(?:-no-recenter(?:[\s"]|$)|--window=)') {
            continue
        }
        try {
            $processPath = [IO.Path]::GetFullPath([string]$process.Path)
        }
        catch {
            continue
        }
        if (@($rootPrefixes | Where-Object {
            $processPath.StartsWith($_, [StringComparison]::OrdinalIgnoreCase)
        }).Count -gt 0) {
            $process
        }
    }
}

# Ask each visible development emulator, or with -Tiled each tiled one, to
# close; force-stop it after five seconds.
function Close-UnWorkshopUserEmulatorProcesses {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$Roots,
        [switch]$Tiled
    )

    foreach ($process in @(Get-UnWorkshopUserEmulatorProcesses -Roots $Roots -Tiled:$Tiled)) {
        if (-not $PSCmdlet.ShouldProcess(
            "Emulator process $($process.Id) ($($process.Path))",
            'close before launch'
        )) {
            continue
        }
        if (-not $process.HasExited) {
            [void]$process.CloseMainWindow()
            if (-not $process.WaitForExit(5000)) {
                Stop-Process -Id $process.Id -Force
                Wait-Process -Id $process.Id -ErrorAction SilentlyContinue
            }
        }
    }
}

# A PSP UMD image's ISO 9660 system identifier is PSP GAME, as PPSSPP's loader
# checks; anything else is a PS2 image.
function Get-UnWorkshopIsoPlatform {
    param(
        [Parameter(Mandatory)]
        [string]$IsoPath
    )

    $buffer = [byte[]]::new(40)
    $stream = [IO.File]::OpenRead($IsoPath)
    try {
        [void]$stream.Seek(16 * 2048, [IO.SeekOrigin]::Begin)
        $read = $stream.Read($buffer, 0, $buffer.Length)
    }
    finally {
        $stream.Dispose()
    }
    $systemId = [Text.Encoding]::ASCII.GetString($buffer, 8, 32).Trim(" `0")
    if ($read -eq $buffer.Length -and $systemId -cin @('PSP GAME', '"PSP GAME"')) {
        return 'psp'
    }
    return 'ps2'
}

function Wait-UnWorkshopGameWindow {
    param(
        [Parameter(Mandatory)]
        [Diagnostics.Process]$Process,

        [Parameter(Mandatory)]
        [string]$Game,

        [Parameter(Mandatory)]
        [string]$Emulator,

        [Parameter(Mandatory)]
        [int]$TimeoutSeconds
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "$Emulator process $($Process.Id) for $Game exited before creating a window."
        }
        if ($Process.MainWindowHandle -ne [IntPtr]::Zero) {
            return
        }
        Start-Sleep -Milliseconds 100
    }
    throw "$Emulator did not create a window for $Game within $TimeoutSeconds seconds."
}

$memoryCardOverridePath = Resolve-UnWorkshopMemoryCardPath `
    -MemoryCard $MemoryCard `
    -MemoryCardsRoot $paths.MemoryCards

$additionalPnachPaths = @(
    if ($null -ne $AdditionalPnach) {
        foreach ($pnachPath in @($AdditionalPnach)) {
            if ([string]::IsNullOrWhiteSpace([string]$pnachPath)) {
                throw 'Additional PNACH path must not be empty.'
            }
            [IO.Path]::GetFullPath([string]$pnachPath)
        }
    }
)

$selectedGames = [Collections.Generic.List[object]]::new()
$seenImages = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
$seenSelectors = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($requestedGame in $Games) {
    $target = $requestedGame.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) {
        throw 'Game or ISO targets must not be empty.'
    }
    $isIsoPath = $target.EndsWith(
        '.iso',
        [StringComparison]::OrdinalIgnoreCase
    )
    $defaultPnach = [string[]]@()
    if ($isIsoPath) {
        $isoPath = [IO.Path]::GetFullPath($target)
        if (-not (Test-Path -LiteralPath $isoPath -PathType Leaf)) {
            throw "ISO does not exist: $isoPath"
        }
        $selector = [IO.Path]::GetFileNameWithoutExtension($isoPath)
        $platform = Get-UnWorkshopIsoPlatform -IsoPath $isoPath
    }
    else {
        $selector = $target.ToLowerInvariant()
        $resolved = Resolve-UnWorkshopGame `
            -Game $selector `
            -ProjectRoot $paths.Project
        $isoPath = [IO.Path]::GetFullPath([string]$resolved.iso)
        $platform = [string]$resolved.platform
        if ($platform -eq 'ps2') {
            $cheatsPath = [IO.Path]::GetFullPath([string]$resolved.cheats)
            if (Test-Path -LiteralPath $cheatsPath -PathType Leaf) {
                $defaultPnach = [string[]]@($cheatsPath)
            }
        }
    }
    if (-not $seenImages.Add($isoPath)) {
        throw "Each resolved game image may be launched only once: $selector"
    }
    [void]$seenSelectors.Add($selector)
    $pnach = [string[]]@(if (
        $null -ne $PnachByGame -and
        $PnachByGame.ContainsKey($selector)
    ) {
        foreach ($pnachPath in @($PnachByGame[$selector])) {
            [IO.Path]::GetFullPath([string]$pnachPath)
        }
    }
    else {
        $defaultPnach
    }
    if ($platform -eq 'ps2') {
        $additionalPnachPaths
    })
    $pnachLines = if (
        $null -ne $PnachLinesByGame -and
        $PnachLinesByGame.ContainsKey($selector)
    ) {
        [string[]]@($PnachLinesByGame[$selector])
    }
    else {
        [string[]]@()
    }
    # A PSP recording holds its saves, so replays run on a copy instead of discarding them.
    $pspAnalysis = $platform -eq 'psp' -and ($Snapshots -or $AgentReplay)
    $memoryCardMode = Resolve-UnWorkshopMemoryCardMode `
        -DiscardMemoryCardWrites:$DiscardMemoryCardWrites `
        -VolatileMemoryCard:($VolatileMemoryCard -or $pspAnalysis) `
        -DefaultDiscard:($Snapshots -and -not $pspAnalysis)
    $gameUnlimitedForFrames = if (
        $null -ne $UnlimitedForFramesByGame -and
        $UnlimitedForFramesByGame.ContainsKey($selector)
    ) {
        [UInt64]$UnlimitedForFramesByGame[$selector]
    }
    else {
        $UnlimitedForFrames
    }
    $selectedGames.Add([pscustomobject]@{
        Selector = $selector
        Platform = $platform
        IsoPath = $isoPath
        MemoryCardPath = if ($platform -eq 'psp') {
            Resolve-UnWorkshopSavesPath -Saves $MemoryCard -SavesRoot $paths.PpssppSaves
        }
        else { $memoryCardOverridePath }
        MemoryCardMode = $memoryCardMode
        Pnach = $pnach
        PnachLines = $pnachLines
        UnlimitedForFrames = $gameUnlimitedForFrames
    })
}

foreach ($mapping in @($PnachByGame, $PnachLinesByGame)) {
    if ($null -eq $mapping) {
        continue
    }
    foreach ($selector in $mapping.Keys) {
        if (-not $seenSelectors.Contains([string]$selector)) {
            throw "PNACH override targets an unselected game: $selector"
        }
    }
}
if ($null -ne $UnlimitedForFramesByGame) {
    foreach ($selector in $UnlimitedForFramesByGame.Keys) {
        if (-not $seenSelectors.Contains([string]$selector)) {
            throw "Frame-limited Unlimited targets an unselected game: $selector"
        }
    }
}
$mainIndex = $selectedGames.Count - 1
if (-not [string]::IsNullOrWhiteSpace($MainGame)) {
    $mainCandidates = @(
        for ($candidate = 0; $candidate -lt $selectedGames.Count; $candidate++) {
            if ($selectedGames[$candidate].Selector -ieq $MainGame) { $candidate }
        }
    )
    if ($mainCandidates.Count -eq 0) {
        throw "The main game is not selected: $MainGame"
    }
    $mainIndex = $mainCandidates[0]
}

# PSP games run in PPSSPP. A recording belongs to the emulator that made it.
$pspGames = @($selectedGames | Where-Object { $_.Platform -eq 'psp' })
$pspRecording = $pspGames.Count -gt 0 -and $PSCmdlet.ParameterSetName -ne 'Normal'
if ($pspRecording -and $pspGames.Count -ne $selectedGames.Count) {
    throw "A recording cannot span PSP and PS2 games: $($pspGames.Selector -join ', ')"
}
if ($pspRecording -and $DiscardMemoryCardWrites) {
    throw "A PSP recording holds its saves; use -vmc instead of -dmc: $($pspGames.Selector -join ', ')"
}
if ($pspRecording) {
    $inputRecordingsRoot = [IO.Path]::GetFullPath($paths.PpssppInputRecordings)
}
$recordingExtension = if ($pspRecording) { '.ppr' } else { '.p2m2' }
$recordingName = if ($PSCmdlet.ParameterSetName -eq 'Play') {
    Resolve-UnWorkshopRecordingName `
        -Name $Play `
        -Root $inputRecordingsRoot `
        -Extension $recordingExtension
}
elseif ($PSCmdlet.ParameterSetName -eq 'Record') {
    Resolve-UnWorkshopRecordingName `
        -Name $Record `
        -Root $inputRecordingsRoot `
        -Extension $recordingExtension `
        -CreateParent:$pspRecording
}
else {
    $null
}
$pspRecordingPath = if ($pspRecording) {
    Join-Path $inputRecordingsRoot $recordingName
}
else {
    $null
}
if ($PSCmdlet.ParameterSetName -eq 'Play' -and $pspRecording -and
    -not (Test-Path -LiteralPath $pspRecordingPath -PathType Leaf)) {
    throw "Input recording does not exist: $pspRecordingPath"
}

$pcsx2Root = $paths.Pcsx2Dev
$pcsx2Launcher = [IO.Path]::GetFullPath(
    $paths.Files.pcsx2_launch_command
)
$ppssppLauncher = [IO.Path]::GetFullPath(
    $paths.Files.ppsspp_launch_command
)
$requiredFiles = @($pcsx2Launcher)
if ($pspGames.Count -gt 0) {
    $requiredFiles += $ppssppLauncher
}
$requiredFiles += @($selectedGames.IsoPath)
$requiredFiles += @(
    foreach ($game in $selectedGames) {
        foreach ($pnachPath in @($game.Pnach)) {
            if (-not [string]::IsNullOrWhiteSpace($pnachPath)) {
                $pnachPath
            }
        }
    }
)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file does not exist: $requiredFile"
    }
}
foreach ($memoryCardPath in @($selectedGames.MemoryCardPath)) {
    if (-not [string]::IsNullOrWhiteSpace($memoryCardPath) -and
        $memoryCardPath -ine 'none' -and
        -not (Test-Path -LiteralPath $memoryCardPath)) {
        throw "Memory card does not exist: $memoryCardPath"
    }
}

if ($Snapshots) {
    $recordingCaptureRoot = if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory)) {
        [IO.Path]::GetFullPath($CaptureDirectory)
    }
    else {
        $captureParent = if ([string]::IsNullOrWhiteSpace($CaptureRoot)) {
            Join-Path $paths.Project 'captures'
        }
        else {
            [IO.Path]::GetFullPath($CaptureRoot)
        }
        $recordingStem = [IO.Path]::GetFileNameWithoutExtension($recordingName)
        Join-Path $captureParent $recordingStem
    }
    $captureDirectories = @(
        for ($index = 0; $index -lt $selectedGames.Count; $index++) {
            if ($selectedGames.Count -eq 1 -and
                -not [string]::IsNullOrWhiteSpace($CaptureDirectory)) {
                $recordingCaptureRoot
            }
            else {
                Join-Path $recordingCaptureRoot $selectedGames[$index].Selector
            }
        }
    )
    $captureInputs = @($requiredFiles) + @(
        Join-Path $inputRecordingsRoot $recordingName
    )
    foreach ($directory in $captureDirectories) {
        $resolvedDirectory = [IO.Path]::GetFullPath($directory).TrimEnd('\', '/')
        if ($resolvedDirectory -eq [IO.Path]::GetPathRoot($directory).TrimEnd('\', '/')) {
            throw "Capture directory cannot be a filesystem root: $directory"
        }
        $capturePrefix = $resolvedDirectory + [IO.Path]::DirectorySeparatorChar
        foreach ($inputPath in $captureInputs) {
            $resolvedInput = [IO.Path]::GetFullPath($inputPath)
            if ($resolvedInput.Equals($resolvedDirectory, [StringComparison]::OrdinalIgnoreCase) -or
                $resolvedInput.StartsWith($capturePrefix, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Capture directory contains a required input: $inputPath"
            }
        }
    }
    $gameList = $selectedGames.Selector -join ', '
    $action = "replace capture directories, replay $gameList, and capture snapshot markers"
    if (-not $PSCmdlet.ShouldProcess(($captureDirectories -join ', '), $action)) {
        return
    }

    $snapshotPinePorts = @()
    if ($selectedGames.Count -gt 1 -and -not $pspRecording) {
        $nextPinePort = Get-UnWorkshopConfiguredPinePort -Pcsx2Root $pcsx2Root
        $usedPinePorts = [Collections.Generic.HashSet[int]]::new()
        foreach ($endpoint in [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()) {
            [void]$usedPinePorts.Add($endpoint.Port)
        }
        for ($index = 0; $index -lt $selectedGames.Count; $index++) {
            while ($usedPinePorts.Contains($nextPinePort)) {
                $nextPinePort++
            }
            if ($nextPinePort -gt 65535) {
                throw 'No free PINE port remains in the configured range.'
            }
            $snapshotPinePorts += $nextPinePort
            [void]$usedPinePorts.Add($nextPinePort)
            $nextPinePort++
        }
    }

    foreach ($directory in $captureDirectories) {
        if (Test-Path -LiteralPath $directory) {
            Remove-Item -LiteralPath $directory -Recurse -Force
        }
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }

    $snapshotProcesses = [Collections.Generic.List[Diagnostics.Process]]::new()
    try {
        for ($index = 0; $index -lt $selectedGames.Count; $index++) {
            $game = $selectedGames[$index]
            if ($game.Platform -eq 'psp') {
                $ppssppParameters = @{
                    IsoPath = $game.IsoPath
                    Headless = $true
                    InputRecording = $pspRecordingPath
                    CaptureDirectory = $captureDirectories[$index]
                    CaptureMode = $InputRecordingCaptureMode
                    DiscardSaves = $game.MemoryCardMode.DiscardMemoryCardWrites
                    VolatileSaves = $game.MemoryCardMode.VolatileMemoryCard
                    PassThru = $true
                }
                if (-not [string]::IsNullOrWhiteSpace($game.MemoryCardPath)) {
                    $ppssppParameters.Saves = $game.MemoryCardPath
                }
                if (@($game.Pnach).Count -gt 0) {
                    $ppssppParameters.Cheats = $game.Pnach
                }
                if (@($game.PnachLines).Count -gt 0) {
                    $ppssppParameters.CheatLines = $game.PnachLines
                }
                $snapshotProcesses.Add((& $ppssppLauncher @ppssppParameters))
                continue
            }
            $launchParameters = @{
                IsoPath = $game.IsoPath
                InputRecording = $recordingName
                InputRecordingCaptureDirectory = $captureDirectories[$index]
                Surfaceless = $true
                DiscardMemoryCardWrites = $game.MemoryCardMode.DiscardMemoryCardWrites
                VolatileMemoryCard = $game.MemoryCardMode.VolatileMemoryCard
                Unlimited = $true
                PassThru = $true
                InputRecordingsRoot = $inputRecordingsRoot
            }
            $arguments = [Collections.Generic.List[string]]::new()
            if ($snapshotPinePorts.Count -gt 0) {
                $arguments.Add('-pine-port')
                $arguments.Add([string]$snapshotPinePorts[$index])
            }
            $arguments.Add('-input-recording-capture-mode')
            $arguments.Add($InputRecordingCaptureMode)
            $launchParameters.Arguments = @($arguments)
            if (-not [string]::IsNullOrWhiteSpace($game.MemoryCardPath)) {
                $launchParameters.MemoryCard = $game.MemoryCardPath
            }
            if (@($game.Pnach).Count -gt 0) {
                $launchParameters.Pnach = $game.Pnach
            }
            if (@($game.PnachLines).Count -gt 0) {
                $launchParameters.PnachLines = $game.PnachLines
            }
            $launchParameters.ReadOnlySettings = $true
            $launchResult = @(& $pcsx2Launcher @launchParameters)
            $processes = @(
                $launchResult | Where-Object { $_ -is [Diagnostics.Process] }
            )
            if ($processes.Count -ne 1) {
                throw "PCSX2 launcher did not return one process for $($game.Selector)."
            }
            $launchResult |
                Where-Object { $_ -isnot [Diagnostics.Process] } |
                Write-Output
            $snapshotProcesses.Add($processes[0])
        }
        foreach ($process in $snapshotProcesses) {
            Wait-Process -InputObject $process
        }
    }
    finally {
        foreach ($process in $snapshotProcesses) {
            try {
                if (-not $process.HasExited) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                    Wait-Process -InputObject $process -ErrorAction SilentlyContinue
                }
            }
            catch {
                # Preserve the original launch or replay failure.
            }
        }
    }
    return
}

$pinePortBase = Get-UnWorkshopConfiguredPinePort -Pcsx2Root $pcsx2Root
if ($pinePortBase + $selectedGames.Count - 1 -gt 65535) {
    throw "Not enough PINE ports remain after configured port $pinePortBase."
}

if (-not $noWindow) {
    Add-Type -AssemblyName System.Windows.Forms
    if (-not ('UnWorkshopLaunchWindow' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class UnWorkshopLaunchWindow
{
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindowAsync(IntPtr window, int command);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool MoveWindow(
        IntPtr window,
        int x,
        int y,
        int width,
        int height,
        [MarshalAs(UnmanagedType.Bool)] bool repaint
    );
}
'@
    }

    $workingArea = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
}

# A game's tile in the working area, left to right in launch order: left, top,
# width and height.
function Get-UnWorkshopWindowTile {
    param(
        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter(Mandatory)]
        [int]$Count
    )

    $left = $workingArea.X + [Math]::Floor($workingArea.Width * $Index / $Count)
    $right = $workingArea.X + [Math]::Floor($workingArea.Width * ($Index + 1) / $Count)
    return [int[]]@($left, $workingArea.Y, ($right - $left), $workingArea.Height)
}
$gameList = $selectedGames.Selector -join ', '
$action = if ($AgentReplay) {
    "launch surfaceless agent replay for $gameList"
}
elseif ($Surfaceless) {
    "launch $gameList surfaceless"
}
elseif ($selectedGames.Count -gt 1) {
    "close earlier tiled emulators, launch $gameList, and tile their windows"
}
else {
    "launch $gameList"
}
if (-not $PSCmdlet.ShouldProcess($pcsx2Root, $action)) {
    return
}

if ($ClosePcsx2) {
    Close-UnWorkshopUserEmulatorProcesses -Roots @($paths.Pcsx2Dev, $paths.PpssppDev)
}
elseif ($selectedGames.Count -gt 1 -and -not $noWindow) {
    Close-UnWorkshopUserEmulatorProcesses -Roots @($paths.Pcsx2Dev, $paths.PpssppDev) -Tiled
}

$usedPinePorts = [Collections.Generic.HashSet[int]]::new()
foreach ($endpoint in [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()) {
    [void]$usedPinePorts.Add($endpoint.Port)
}

$launchedGames = [Collections.Generic.List[object]]::new()
try {
    $nextPinePort = $pinePortBase
    $nextDebuggerPort = 28111
    for ($index = 0; $index -lt $selectedGames.Count; $index++) {
        $game = $selectedGames[$index]
        if ($game.Platform -eq 'psp') {
            while ($usedPinePorts.Contains($nextDebuggerPort)) {
                $nextDebuggerPort++
            }
            if ($nextDebuggerPort -gt 65535) {
                throw 'No free debugger port remains in the configured range.'
            }
            $debuggerPort = $nextDebuggerPort
            [void]$usedPinePorts.Add($debuggerPort)
            $nextDebuggerPort++

            $ppssppParameters = @{
                IsoPath = $game.IsoPath
                DebuggerPort = $debuggerPort
                PassThru = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($game.MemoryCardPath)) {
                $ppssppParameters.Saves = $game.MemoryCardPath
            }
            if ($game.MemoryCardMode.DiscardMemoryCardWrites) {
                $ppssppParameters.DiscardSaves = $true
            }
            if ($game.MemoryCardMode.VolatileMemoryCard) {
                $ppssppParameters.VolatileSaves = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
                $ppssppParameters.LogFile = $LogFile
            }
            if ($PSCmdlet.ParameterSetName -eq 'Play') {
                $ppssppParameters.InputRecording = $pspRecordingPath
            }
            elseif (
                $PSCmdlet.ParameterSetName -eq 'Record' -and
                $index -eq $mainIndex
            ) {
                $ppssppParameters.CreateInputRecording = $pspRecordingPath
            }
            if (@($game.Pnach).Count -gt 0) {
                $ppssppParameters.Cheats = $game.Pnach
            }
            if (@($game.PnachLines).Count -gt 0) {
                $ppssppParameters.CheatLines = $game.PnachLines
            }
            if ($Surfaceless) {
                throw '-surfaceless runs PCSX2 games only.'
            }
            if ($AgentReplay) {
                $ppssppParameters.Headless = $true
            }
            else {
                if ($game.UnlimitedForFrames -gt 0) {
                    $ppssppParameters.FastForwardForFrames = $game.UnlimitedForFrames
                }
                if ($Turbo) {
                    $ppssppParameters.Turbo = $true
                }
                if ($Unlimited) {
                    $ppssppParameters.Unlimited = $true
                }
                if ($ReadOnlySettings) {
                    $ppssppParameters.ReadOnlySettings = $true
                }
                if ($Mute) {
                    $ppssppParameters.Mute = $true
                }
                if ($selectedGames.Count -gt 1) {
                    $ppssppParameters.Mute = -not ($LastGameAudio -and
                        $index -eq $mainIndex)
                    # Start in its tile; PPSSPP doesn't save it as its window position.
                    $ppssppParameters.Window = Get-UnWorkshopWindowTile `
                        -Index $index `
                        -Count $selectedGames.Count
                }
                else {
                    $ppssppParameters.CenteredWindow = $true
                }
            }
            $process = & $ppssppLauncher @ppssppParameters
            $launchedGames.Add([pscustomobject]@{
                Index = $index
                Game = $game.Selector
                Emulator = 'PPSSPP'
                Process = $process
                PinePort = $null
                DebuggerPort = $debuggerPort
                PauseAt = $game.UnlimitedForFrames
            })
            if (-not $AgentReplay) {
                Wait-UnWorkshopGameWindow `
                    -Process $process `
                    -Game $game.Selector `
                    -Emulator 'PPSSPP' `
                    -TimeoutSeconds $WindowWaitSeconds
            }
            continue
        }

        while ($usedPinePorts.Contains($nextPinePort)) {
            $nextPinePort++
        }
        if ($nextPinePort -gt 65535) {
            throw 'No free PINE port remains in the configured range.'
        }
        $pinePort = $nextPinePort
        [void]$usedPinePorts.Add($pinePort)
        $nextPinePort++

        $pcsx2Arguments = @('-pine-port', [string]$pinePort)
        if ($Mute -or ($selectedGames.Count -gt 1 -and
            -not ($LastGameAudio -and $index -eq $mainIndex))) {
            $pcsx2Arguments += '-mute'
        }
        $launchParameters = @{
            IsoPath = $game.IsoPath
            MemoryCard = $game.MemoryCardPath
            Arguments = $pcsx2Arguments
            PassThru = $true
            InputRecordingsRoot = $inputRecordingsRoot
        }
        if ($AgentReplay) {
            $launchParameters.AgentReplay = $true
            $launchParameters.PinePort = $pinePort
            $launchParameters.Remove('Arguments')
        }
        if ($Surfaceless) {
            $launchParameters.Surfaceless = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
            $launchParameters.LogFile = $LogFile
        }
        if (-not [string]::IsNullOrWhiteSpace($SavestateFolder)) {
            $launchParameters.SavestateFolder = $SavestateFolder
        }
        if (-not $AgentReplay) {
            if ($Turbo) {
                $launchParameters.Turbo = $true
            }
            if ($Unlimited) {
                $launchParameters.Unlimited = $true
            }
            elseif ($game.UnlimitedForFrames -gt 0) {
                $launchParameters.UnlimitedForFrames = $game.UnlimitedForFrames
            }
        }
        if ($selectedGames.Count -eq 1 -and -not $noWindow) {
            $launchParameters.CenteredWindow = $true
        }
        elseif (-not $noWindow) {
            # Keep the tiled position: game starts would otherwise recenter it.
            $launchParameters.NoRecenter = $true
        }
        if ($game.MemoryCardMode.DiscardMemoryCardWrites) {
            $launchParameters.DiscardMemoryCardWrites = $true
        }
        if ($game.MemoryCardMode.VolatileMemoryCard) {
            $launchParameters.VolatileMemoryCard = $true
        }
        if ($ReadOnlySettings) {
            $launchParameters.ReadOnlySettings = $true
        }
        if (@($game.Pnach).Count -gt 0) {
            $launchParameters.Pnach = $game.Pnach
        }
        if (@($game.PnachLines).Count -gt 0) {
            $launchParameters.PnachLines = $game.PnachLines
        }
        if ($PSCmdlet.ParameterSetName -eq 'Play') {
            $launchParameters.InputRecording = $recordingName
        }
        elseif (
            $PSCmdlet.ParameterSetName -eq 'Record' -and
            $index -eq $mainIndex
        ) {
            $launchParameters.CreateInputRecording = $recordingName
        }
        $process = & $pcsx2Launcher @launchParameters

        $launchedGames.Add([pscustomobject]@{
            Index = $index
            Game = $game.Selector
            Emulator = 'PCSX2'
            Process = $process
            PinePort = $pinePort
            DebuggerPort = $null
        })
        if (-not $noWindow) {
            Wait-UnWorkshopGameWindow `
                -Process $process `
                -Game $game.Selector `
                -Emulator 'PCSX2' `
                -TimeoutSeconds $WindowWaitSeconds
        }
    }

    $gameCount = $launchedGames.Count
    # A PSP game launched beside other games stops where its startup
    # fast-forward ends, a Practice launch's fight start, or right after boot
    # without one, so a comparison starts from a still frame.
    if ($gameCount -gt 1 -and -not $noWindow -and $PSCmdlet.ParameterSetName -eq 'Normal') {
        foreach ($launch in @($launchedGames | Where-Object { $_.Emulator -eq 'PPSSPP' })) {
            & (Join-Path $PSScriptRoot '..\lib\run_python.ps1') `
                -Script (Join-Path $PSScriptRoot '..\ppsspp\debugger.py') `
                -Repository (Join-Path $PSScriptRoot '..\..') `
                -NoBytecode `
                -ArgumentList @('--port', $launch.DebuggerPort, 'pause-at', $launch.PauseAt) | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "PPSSPP kept running for $($launch.Game): its debugger did not pause it."
            }
        }
    }
    if ($gameCount -gt 1 -and -not $noWindow) {
        foreach ($launch in $launchedGames) {
            [UnWorkshopLaunchWindow]::ShowWindowAsync(
                $launch.Process.MainWindowHandle,
                9
            ) | Out-Null
        }
        Start-Sleep -Milliseconds 100
    }

    for ($index = 0; $index -lt $gameCount; $index++) {
        $launch = $launchedGames[$index]
        if ($gameCount -gt 1 -and -not $noWindow) {
            $tile = Get-UnWorkshopWindowTile -Index $index -Count $gameCount
            $moved = [UnWorkshopLaunchWindow]::MoveWindow(
                $launch.Process.MainWindowHandle,
                $tile[0],
                $tile[1],
                $tile[2],
                $tile[3],
                $true
            )
            if (-not $moved) {
                throw "Windows rejected the $($launch.Emulator) window-placement request for $($launch.Game)."
            }
        }

        $result = [ordered]@{
            Index = $index
            Game = $launch.Game
            ProcessId = $launch.Process.Id
            PinePort = $launch.PinePort
            DebuggerPort = $launch.DebuggerPort
            Position = if ($noWindow) {
                'surfaceless'
            }
            elseif ($gameCount -eq 1) {
                'single'
            }
            elseif ($index -eq 0) {
                'left'
            }
            elseif ($index -eq $gameCount - 1) {
                'right'
            }
            else {
                'middle'
            }
        }
        if ($noWindow) {
            $result.Process = $launch.Process
        }
        [pscustomobject]$result
    }
}
catch {
    foreach ($launch in $launchedGames) {
        try {
            if (-not $launch.Process.HasExited) {
                Stop-Process -Id $launch.Process.Id -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Preserve the original launch or placement failure.
        }
    }
    throw
}
