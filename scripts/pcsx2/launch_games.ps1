[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Normal')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateCount(1, 2)]
    [string[]]$Games,

    [Parameter(ParameterSetName = 'Play')]
    [string]$Play,

    [Parameter(ParameterSetName = 'Play')]
    [switch]$Test,

    [Parameter(ParameterSetName = 'Play')]
    [string]$CaptureDirectory,

    [Parameter(ParameterSetName = 'Record')]
    [string]$Record,

    [ValidateSet('stable', 'dev')]
    [string]$Target = 'dev',

    [string]$ProjectRoot,

    [ValidateRange(5, 120)]
    [int]$WindowWaitSeconds = 30
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot

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

function Resolve-UnWorkshopRecordingName {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Root,

        [switch]$AllowRelativePath
    )

    if (
        [string]::IsNullOrWhiteSpace($Name) -or
        [IO.Path]::IsPathRooted($Name)
    ) {
        throw 'Input recording must be a relative path.'
    }
    if (-not $AllowRelativePath -and [IO.Path]::GetFileName($Name) -cne $Name) {
        throw 'New input recording must be a filename.'
    }
    if (-not $Name.EndsWith(
        '.p2m2',
        [StringComparison]::OrdinalIgnoreCase
    )) {
        $Name = "$Name.p2m2"
    }
    if ($AllowRelativePath) {
        $recordingRoot = [IO.Path]::GetFullPath($Root)
        $recordingPrefix = $recordingRoot.TrimEnd(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ) + [IO.Path]::DirectorySeparatorChar
        $recordingPath = [IO.Path]::GetFullPath((Join-Path $recordingRoot $Name))
        if (-not $recordingPath.StartsWith(
            $recordingPrefix,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Input recording must be inside $recordingRoot."
        }
        return [IO.Path]::GetRelativePath($recordingRoot, $recordingPath)
    }
    return $Name
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

$recordingName = if ($PSCmdlet.ParameterSetName -eq 'Play') {
    Resolve-UnWorkshopRecordingName `
        -Name $Play `
        -Root $paths.InputRecordings `
        -AllowRelativePath
}
elseif ($PSCmdlet.ParameterSetName -eq 'Record') {
    Resolve-UnWorkshopRecordingName -Name $Record
}
else {
    $null
}

$selectedGames = [Collections.Generic.List[object]]::new()
$seenImages = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($requestedGame in $Games) {
    $selector = $requestedGame.Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($selector)) {
        throw 'Game selectors must not be empty.'
    }
    $resolved = Resolve-UnWorkshopGame `
        -Game $selector `
        -ProjectRoot $paths.Project
    $isoPath = [IO.Path]::GetFullPath([string]$resolved.iso)
    if (-not $seenImages.Add($isoPath)) {
        throw "Each resolved game image may be launched only once: $selector"
    }
    $selectedGames.Add([pscustomobject]@{
        Selector = $selector
        IsoPath = $isoPath
    })
}

$pcsx2Root = if ($Target -eq 'stable') {
    $paths.Pcsx2Stable
}
else {
    $paths.Pcsx2Dev
}
$pcsx2Launcher = [IO.Path]::GetFullPath(
    $paths.Files.pcsx2_launch_command
)
$requiredFiles = @($pcsx2Launcher)
$requiredFiles += @($selectedGames.IsoPath)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file does not exist: $requiredFile"
    }
}

if ($Test) {
    if ($selectedGames.Count -ne 1) {
        throw '-Test requires exactly one game.'
    }
    $captureDirectory = if (-not [string]::IsNullOrWhiteSpace($CaptureDirectory)) {
        [IO.Path]::GetFullPath($CaptureDirectory)
    }
    else {
        $recordingStem = [IO.Path]::GetFileNameWithoutExtension($recordingName)
        $captureRepositoryRoot = if ($paths.Project) {
            $paths.Project
        } else {
            $paths.Workshop
        }
        Join-Path $captureRepositoryRoot "work\captures\$recordingStem\$($selectedGames[0].Selector)"
    }
    $action = "replay $($selectedGames[0].Selector) and capture regression markers"
    if (-not $PSCmdlet.ShouldProcess($captureDirectory, $action)) {
        return
    }
    [void](New-Item -ItemType Directory -Path $captureDirectory -Force)
    $process = & $pcsx2Launcher `
        -Target $Target `
        -IsoPath $selectedGames[0].IsoPath `
        -InputRecording $recordingName `
        -InputRecordingCaptureDirectory $captureDirectory `
        -Hidden `
        -PassThru
    try {
        Wait-Process -InputObject $process
    }
    finally {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            Wait-Process -InputObject $process -ErrorAction SilentlyContinue
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
        Get-UnWorkshopUserPcsx2Processes -Roots @(
            $paths.Pcsx2Dev,
            $paths.Pcsx2Stable
        )
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

$playbackRecordings = @()
if ($PSCmdlet.ParameterSetName -eq 'Play') {
    if ($selectedGames.Count -eq 2) {
        $generatedDirectory = Join-Path $paths.InputRecordings 'generated'
        if (Test-Path -LiteralPath $generatedDirectory) {
            Remove-Item -LiteralPath $generatedDirectory -Recurse -Force
        }
        [void](New-Item -ItemType Directory -Path $generatedDirectory)

        $sourceRecording = Join-Path $paths.InputRecordings $recordingName
        $playbackRecordings = @(
            'generated\left.p2m2',
            'generated\right.p2m2'
        )
        foreach ($stagedRecording in $playbackRecordings) {
            Copy-Item `
                -LiteralPath $sourceRecording `
                -Destination (Join-Path $paths.InputRecordings $stagedRecording)
        }
    }
    else {
        $playbackRecordings = @($recordingName)
    }
}

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
            Target = $Target
            IsoPath = $game.IsoPath
            Arguments = @('-pine-port', [string]$pinePort)
            PassThru = $true
        }
        if (
            $selectedGames.Count -eq 2 -and
            $PSCmdlet.ParameterSetName -eq 'Record'
        ) {
            $launchParameters.Capped = $true
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
