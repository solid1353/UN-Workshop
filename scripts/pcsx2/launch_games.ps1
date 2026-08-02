[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Normal')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateCount(1, 2)]
    [string[]]$Games,

    [Parameter(ParameterSetName = 'Play')]
    [string]$Play,

    [Parameter(ParameterSetName = 'Play')]
    [switch]$Test,

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
        [string]$Name
    )

    if (
        [string]::IsNullOrWhiteSpace($Name) -or
        [IO.Path]::IsPathRooted($Name) -or
        [IO.Path]::GetFileName($Name) -cne $Name
    ) {
        throw 'Input recording must be a filename.'
    }
    if (-not $Name.EndsWith(
        '.p2m2',
        [StringComparison]::OrdinalIgnoreCase
    )) {
        return "$Name.p2m2"
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

$recordingName = if ($PSCmdlet.ParameterSetName -eq 'Play') {
    Resolve-UnWorkshopRecordingName -Name $Play
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
    $recordingStem = [IO.Path]::GetFileNameWithoutExtension($recordingName)
    $captureDirectory = Join-Path `
        (Join-Path $paths.Savestates $recordingStem) `
        $selectedGames[0].Selector
    $action = "replay $($selectedGames[0].Selector) and capture regression markers"
    if (-not $PSCmdlet.ShouldProcess($captureDirectory, $action)) {
        return
    }
    [void](New-Item -ItemType Directory -Path $captureDirectory -Force)
    & $pcsx2Launcher `
        -Target $Target `
        -IsoPath $selectedGames[0].IsoPath `
        -InputRecording $recordingName `
        -InputRecordingCaptureDirectory $captureDirectory `
        -Hidden `
        -Wait
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
            Stop-Process -Id $process.Id -Force
            Wait-Process -Id $process.Id -ErrorAction SilentlyContinue
        }
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
        if ($PSCmdlet.ParameterSetName -eq 'Play') {
            $launchParameters.InputRecording = $recordingName
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
    }

    $deadline = [DateTime]::UtcNow.AddSeconds($WindowWaitSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        foreach ($launch in $launchedGames) {
            $launch.Process.Refresh()
            if ($launch.Process.HasExited) {
                throw "PCSX2 process $($launch.Process.Id) for $($launch.Game) exited before creating a window."
            }
        }

        $missingWindows = @(
            $launchedGames |
                Where-Object { $_.Process.MainWindowHandle -eq [IntPtr]::Zero }
        )
        if ($missingWindows.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 100
    }

    $missingWindows = @(
        $launchedGames |
            Where-Object { $_.Process.MainWindowHandle -eq [IntPtr]::Zero }
    )
    if ($missingWindows.Count -gt 0) {
        throw "PCSX2 did not create every window within $WindowWaitSeconds seconds: $($missingWindows.Game -join ', ')."
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
