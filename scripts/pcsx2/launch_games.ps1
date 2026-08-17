[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Normal')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateCount(1, 2)]
    [string[]]$Games,

    [Parameter(ParameterSetName = 'Play')]
    [string]$Play,

    [Parameter(ParameterSetName = 'Play')]
    [switch]$Snapshots,

    [Parameter(ParameterSetName = 'Play')]
    [string]$CaptureDirectory,

    [Parameter(ParameterSetName = 'Play')]
    [ValidateSet('full', 'screenshots')]
    [string]$InputRecordingCaptureMode,

    [Parameter(ParameterSetName = 'Record')]
    [string]$Record,

    [string]$MemoryCard,

    [switch]$DiscardMemoryCardWrites,

    [switch]$ReadOnlySettings,

    [hashtable]$PnachByGame,

    [hashtable]$PnachLinesByGame,

    [switch]$Turbo,

    [switch]$Unlimited,

    [UInt64]$UnlimitedForFrames = 0,

    [string]$ProjectRoot,

    [string]$InputRecordingsRoot,

    [ValidateRange(5, 120)]
    [int]$WindowWaitSeconds = 30
)

$ErrorActionPreference = 'Stop'
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
if ($Unlimited -and $UnlimitedForFrames -gt 0) {
    throw 'Permanent Unlimited cannot be combined with frame-limited Unlimited.'
}
if ($Snapshots -and ($Turbo -or $Unlimited -or $UnlimitedForFrames -gt 0)) {
    throw 'Snapshot replay owns its permanent Unlimited speed mode.'
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

function Get-UnWorkshopUserPcsx2Processes {
    param(
        [Parameter(Mandatory)]
        [string[]]$Roots
    )

    $rootPrefixes = @(
        foreach ($root in $Roots) {
            [IO.Path]::GetFullPath($root).TrimEnd(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ) + [IO.Path]::DirectorySeparatorChar
        }
    )
    foreach ($process in @(Get-Process -Name 'pcsx2*' -ErrorAction SilentlyContinue)) {
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

function Wait-UnWorkshopPcsx2Window {
    param(
        [Parameter(Mandatory)]
        [Diagnostics.Process]$Process,

        [Parameter(Mandatory)]
        [string]$Game,

        [Parameter(Mandatory)]
        [int]$TimeoutSeconds
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "PCSX2 process $($Process.Id) for $Game exited before creating a window."
        }
        if ($Process.MainWindowHandle -ne [IntPtr]::Zero) {
            return
        }
        Start-Sleep -Milliseconds 100
    }
    throw "PCSX2 did not create a window for $Game within $TimeoutSeconds seconds."
}

function New-UnWorkshopPlaybackRecordings {
    param(
        [Parameter(Mandatory)][string]$RecordingName,
        [Parameter(Mandatory)][string]$RecordingRoot,
        [Parameter(Mandatory)][ValidateRange(1, 2)][int]$GameCount
    )

    if ($GameCount -eq 1) {
        return $RecordingName
    }

    $generatedDirectory = Join-Path $RecordingRoot '__generated'
    if (Test-Path -LiteralPath $generatedDirectory) {
        Remove-Item -LiteralPath $generatedDirectory -Recurse -Force
    }
    [void](New-Item -ItemType Directory -Path $generatedDirectory)

    $sourceRecording = Join-Path $RecordingRoot $RecordingName
    $playbackRecordings = @(
        '__generated\left.p2m2',
        '__generated\right.p2m2'
    )
    foreach ($stagedRecording in $playbackRecordings) {
        Copy-Item `
            -LiteralPath $sourceRecording `
            -Destination (Join-Path $RecordingRoot $stagedRecording)
    }
    return $playbackRecordings
}

$recordingName = if ($PSCmdlet.ParameterSetName -eq 'Play') {
    Resolve-UnWorkshopRecordingName `
        -Name $Play `
        -Root $inputRecordingsRoot
}
elseif ($PSCmdlet.ParameterSetName -eq 'Record') {
    Resolve-UnWorkshopRecordingName `
        -Name $Record `
        -Root $inputRecordingsRoot
}
else {
    $null
}

$memoryCardOverridePath = if (-not [string]::IsNullOrWhiteSpace($MemoryCard)) {
    $memoryCardName = if ($MemoryCard.EndsWith(
        '.ps2',
        [StringComparison]::OrdinalIgnoreCase
    )) {
        $MemoryCard
    }
    else {
        "$MemoryCard.ps2"
    }
    $isRootedMemoryCard = [IO.Path]::IsPathRooted($memoryCardName)
    $candidate = if ($isRootedMemoryCard) {
        $memoryCardName
    }
    else {
        Join-Path $paths.MemoryCards $memoryCardName
    }
    if (
        -not $isRootedMemoryCard -and
        -not (Test-Path -LiteralPath $candidate -PathType Leaf) -and
        [IO.Path]::GetFileName($memoryCardName) -ceq $memoryCardName
    ) {
        $candidate = Join-Path `
            (Join-Path $paths.MemoryCards 'templates') `
            $memoryCardName
    }
    [IO.Path]::GetFullPath($candidate)
}
else {
    $null
}

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
    if ($isIsoPath -and -not $Snapshots) {
        throw 'Explicit ISO paths are supported only with -Snapshots.'
    }
    $defaultPnach = $null
    if ($isIsoPath) {
        $isoPath = [IO.Path]::GetFullPath($target)
        if (-not (Test-Path -LiteralPath $isoPath -PathType Leaf)) {
            throw "ISO does not exist: $isoPath"
        }
        $selector = [IO.Path]::GetFileNameWithoutExtension($isoPath)
        $resolvedMemoryCardPath = $memoryCardOverridePath
    }
    else {
        $selector = $target.ToLowerInvariant()
        $resolved = Resolve-UnWorkshopGame `
            -Game $selector `
            -ProjectRoot $paths.Project
        $isoPath = [IO.Path]::GetFullPath([string]$resolved.iso)
        $resolvedMemoryCardPath = if ($null -ne $memoryCardOverridePath) {
            $memoryCardOverridePath
        }
        else {
            [IO.Path]::GetFullPath([string]$resolved.memory_card)
        }
        $resolvedDefaultPnach = [IO.Path]::GetFullPath(
            [string]$resolved.cheats
        )
        if (Test-Path -LiteralPath $resolvedDefaultPnach -PathType Leaf) {
            $defaultPnach = $resolvedDefaultPnach
        }
    }
    if (-not $seenImages.Add($isoPath)) {
        throw "Each resolved game image may be launched only once: $selector"
    }
    [void]$seenSelectors.Add($selector)
    $pnach = if (
        $null -ne $PnachByGame -and
        $PnachByGame.ContainsKey($selector)
    ) {
        [IO.Path]::GetFullPath([string]$PnachByGame[$selector])
    }
    else {
        $defaultPnach
    }
    $pnachLines = if (
        $null -ne $PnachLinesByGame -and
        $PnachLinesByGame.ContainsKey($selector)
    ) {
        [string[]]@($PnachLinesByGame[$selector])
    }
    else {
        [string[]]@()
    }
    $selectedGames.Add([pscustomobject]@{
        Selector = $selector
        IsoPath = $isoPath
        MemoryCardPath = $resolvedMemoryCardPath
        Pnach = $pnach
        PnachLines = $pnachLines
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

$pcsx2Root = $paths.Pcsx2Dev
$pcsx2Launcher = [IO.Path]::GetFullPath(
    $paths.Files.pcsx2_launch_command
)
$requiredFiles = @($pcsx2Launcher)
$requiredFiles += @($selectedGames.IsoPath)
$requiredFiles += @(
    $selectedGames.MemoryCardPath |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)
$requiredFiles += @(
    $selectedGames.Pnach |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file does not exist: $requiredFile"
    }
}

if ($Snapshots) {
    $captureRoot = if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory)) {
        [IO.Path]::GetFullPath($CaptureDirectory)
    }
    else {
        $recordingStem = [IO.Path]::GetFileNameWithoutExtension($recordingName)
        $captureRepositoryRoot = if ($paths.Project) {
            $paths.Project
        } else {
            $paths.Workshop
        }
        Join-Path $captureRepositoryRoot "work\captures\$recordingStem"
    }
    $captureDirectories = @(
        for ($index = 0; $index -lt $selectedGames.Count; $index++) {
            if ($selectedGames.Count -eq 1 -and
                -not [string]::IsNullOrWhiteSpace($CaptureDirectory)) {
                $captureRoot
            }
            else {
                Join-Path $captureRoot $selectedGames[$index].Selector
            }
        }
    )
    $gameList = $selectedGames.Selector -join ', '
    $action = "replay $gameList and capture snapshot markers"
    if (-not $PSCmdlet.ShouldProcess(($captureDirectories -join ', '), $action)) {
        return
    }

    if ($selectedGames.Count -eq 2) {
        $userProcesses = @(
            Get-UnWorkshopUserPcsx2Processes -Roots @($paths.Pcsx2Dev)
        )
        foreach ($process in $userProcesses) {
            $targetDescription = "PCSX2 process $($process.Id) ($($process.Path))"
            if ($PSCmdlet.ShouldProcess(
                $targetDescription,
                'close before the two-game snapshot replay'
            )) {
                if (-not $process.HasExited) {
                    [void]$process.CloseMainWindow()
                    if (-not $process.WaitForExit(5000)) {
                        Stop-Process -Id $process.Id -Force
                        Wait-Process -Id $process.Id -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }

    $snapshotPinePorts = @()
    if ($selectedGames.Count -eq 2) {
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

    $playbackRecordings = @(
        New-UnWorkshopPlaybackRecordings `
            -RecordingName $recordingName `
            -RecordingRoot $inputRecordingsRoot `
            -GameCount $selectedGames.Count
    )
    foreach ($directory in $captureDirectories) {
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }

    $snapshotProcesses = [Collections.Generic.List[Diagnostics.Process]]::new()
    try {
        for ($index = 0; $index -lt $selectedGames.Count; $index++) {
            $game = $selectedGames[$index]
            $launchParameters = @{
                IsoPath = $game.IsoPath
                InputRecording = $playbackRecordings[$index]
                InputRecordingCaptureDirectory = $captureDirectories[$index]
                Surfaceless = $true
                DiscardMemoryCardWrites = $true
                Unlimited = $true
                PassThru = $true
                InputRecordingsRoot = $inputRecordingsRoot
            }
            $arguments = [Collections.Generic.List[string]]::new()
            if ($snapshotPinePorts.Count -gt 0) {
                $arguments.Add('-pine-port')
                $arguments.Add([string]$snapshotPinePorts[$index])
            }
            if (-not [string]::IsNullOrWhiteSpace($InputRecordingCaptureMode)) {
                $arguments.Add('-input-recording-capture-mode')
                $arguments.Add($InputRecordingCaptureMode)
            }
            if ($arguments.Count -gt 0) {
                $launchParameters.Arguments = @($arguments)
            }
            if (-not [string]::IsNullOrWhiteSpace($game.MemoryCardPath)) {
                $launchParameters.MemoryCard = $game.MemoryCardPath
            }
            if (-not [string]::IsNullOrWhiteSpace($game.Pnach)) {
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
$gameList = $selectedGames.Selector -join ', '
$action = if ($selectedGames.Count -eq 2) {
    "close configured user PCSX2 instances, launch $gameList, and tile their windows"
}
else {
    "launch $gameList and tile its window"
}
if (-not $PSCmdlet.ShouldProcess($pcsx2Root, $action)) {
    return
}

if ($selectedGames.Count -eq 2) {
    $userProcesses = @(
        Get-UnWorkshopUserPcsx2Processes -Roots @($paths.Pcsx2Dev)
    )
    foreach ($process in $userProcesses) {
        $targetDescription = "PCSX2 process $($process.Id) ($($process.Path))"
        if ($PSCmdlet.ShouldProcess(
            $targetDescription,
            'close before the two-game launch'
        )) {
            if (-not $process.HasExited) {
                [void]$process.CloseMainWindow()
                if (-not $process.WaitForExit(5000)) {
                    Stop-Process -Id $process.Id -Force
                    Wait-Process -Id $process.Id -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

$playbackRecordings = if ($PSCmdlet.ParameterSetName -eq 'Play') {
    @(
        New-UnWorkshopPlaybackRecordings `
            -RecordingName $recordingName `
            -RecordingRoot $inputRecordingsRoot `
            -GameCount $selectedGames.Count
    )
}
else { @() }

$usedPinePorts = [Collections.Generic.HashSet[int]]::new()
foreach ($endpoint in [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()) {
    [void]$usedPinePorts.Add($endpoint.Port)
}

$launchedGames = [Collections.Generic.List[object]]::new()
try {
    $nextPinePort = $pinePortBase
    for ($index = 0; $index -lt $selectedGames.Count; $index++) {
        $game = $selectedGames[$index]
        while ($usedPinePorts.Contains($nextPinePort)) {
            $nextPinePort++
        }
        if ($nextPinePort -gt 65535) {
            throw 'No free PINE port remains in the configured range.'
        }
        $pinePort = $nextPinePort
        [void]$usedPinePorts.Add($pinePort)
        $nextPinePort++

        $launchParameters = @{
            IsoPath = $game.IsoPath
            MemoryCard = $game.MemoryCardPath
            Arguments = @('-pine-port', [string]$pinePort)
            PassThru = $true
            InputRecordingsRoot = $inputRecordingsRoot
        }
        if ($Turbo) {
            $launchParameters.Turbo = $true
        }
        if ($Unlimited) {
            $launchParameters.Unlimited = $true
        }
        elseif ($UnlimitedForFrames -gt 0) {
            $launchParameters.UnlimitedForFrames = $UnlimitedForFrames
        }
        if ($DiscardMemoryCardWrites) {
            $launchParameters.DiscardMemoryCardWrites = $true
        }
        if ($ReadOnlySettings) {
            $launchParameters.ReadOnlySettings = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($game.Pnach)) {
            $launchParameters.Pnach = $game.Pnach
        }
        if (@($game.PnachLines).Count -gt 0) {
            $launchParameters.PnachLines = $game.PnachLines
        }
        if ($PSCmdlet.ParameterSetName -eq 'Play') {
            $launchParameters.InputRecording = $playbackRecordings[$index]
        }
        elseif (
            $PSCmdlet.ParameterSetName -eq 'Record' -and
            $index -eq $selectedGames.Count - 1
        ) {
            $launchParameters.CreateInputRecording = $recordingName
        }
        $process = & $pcsx2Launcher @launchParameters

        $launchedGames.Add([pscustomobject]@{
            Index = $index
            Game = $game.Selector
            Process = $process
            PinePort = $pinePort
        })
        Wait-UnWorkshopPcsx2Window `
            -Process $process `
            -Game $game.Selector `
            -TimeoutSeconds $WindowWaitSeconds
    }

    $gameCount = $launchedGames.Count
    $columns = $gameCount
    $rows = 1
    foreach ($launch in $launchedGames) {
        [UnWorkshopLaunchWindow]::ShowWindowAsync(
            $launch.Process.MainWindowHandle,
            9
        ) | Out-Null
    }
    Start-Sleep -Milliseconds 100

    for ($index = 0; $index -lt $gameCount; $index++) {
        $launch = $launchedGames[$index]
        $left = $workingArea.X + [Math]::Floor(
            $workingArea.Width * $index / $columns
        )
        $right = $workingArea.X + [Math]::Floor(
            $workingArea.Width * ($index + 1) / $columns
        )
        $moved = [UnWorkshopLaunchWindow]::MoveWindow(
            $launch.Process.MainWindowHandle,
            $left,
            $workingArea.Y,
            $right - $left,
            $workingArea.Height,
            $true
        )
        if (-not $moved) {
            throw "Windows rejected the PCSX2 window-placement request for $($launch.Game)."
        }

        [pscustomobject]@{
            Index = $index
            Game = $launch.Game
            ProcessId = $launch.Process.Id
            PinePort = $launch.PinePort
            Position = if ($gameCount -eq 1) {
                'single'
            }
            elseif ($index -eq 0) {
                'left'
            }
            else {
                'right'
            }
        }
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
