[CmdletBinding(DefaultParameterSetName = 'Configured')]
param(
    [Parameter(ParameterSetName = 'Configured')]
    [ValidateSet('stable', 'dev')]
    [string]$Target = 'dev',

    [Parameter(Mandatory, ParameterSetName = 'Worker')]
    [string]$WorkerRoot,

    [Parameter(ParameterSetName = 'Configured')]
    [Parameter(Mandatory, ParameterSetName = 'Worker')]
    [string]$IsoPath,

    [Parameter(ParameterSetName = 'Configured')]
    [string]$InputRecording,

    [Parameter(ParameterSetName = 'Configured')]
    [string]$CreateInputRecording,

    [Parameter(ParameterSetName = 'Configured')]
    [string]$InputRecordingCaptureDirectory,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments,

    [switch]$Wait,

    [switch]$PassThru,

    [Parameter(ParameterSetName = 'Configured')]
    [switch]$Hidden
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths

function Initialize-WorkerWindowApi {
    if ('UnWorkshopWorkerWindowApi' -as [type]) {
        return
    }

    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class UnWorkshopWorkerWindowApi
{
    public delegate bool EnumWindowsCallback(IntPtr window, IntPtr parameter);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(
        EnumWindowsCallback callback,
        IntPtr parameter
    );

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(
        IntPtr window,
        out uint processId
    );

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr window);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr window, int command);
}
'@
}

function Get-VisibleProcessWindows {
    param(
        [Parameter(Mandatory)]
        [int]$OwnerProcessId
    )

    $windows = [Collections.Generic.List[IntPtr]]::new()
    $callback = [UnWorkshopWorkerWindowApi+EnumWindowsCallback]{
        param([IntPtr]$window, [IntPtr]$parameter)

        [uint32]$windowProcessId = 0
        [void][UnWorkshopWorkerWindowApi]::GetWindowThreadProcessId(
            $window,
            [ref]$windowProcessId
        )
        if (
            $windowProcessId -eq [uint32]$OwnerProcessId -and
            [UnWorkshopWorkerWindowApi]::IsWindowVisible($window)
        ) {
            $windows.Add($window)
        }
        return $true
    }
    [void][UnWorkshopWorkerWindowApi]::EnumWindows($callback, [IntPtr]::Zero)
    return @($windows)
}

function Hide-WorkerProcessWindows {
    param(
        [Parameter(Mandatory)]
        [Diagnostics.Process]$Process
    )

    Initialize-WorkerWindowApi
    $deadline = [DateTime]::UtcNow.AddSeconds(5)
    do {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "Worker PCSX2 exited during launch (exit $($Process.ExitCode))."
        }

        foreach ($window in @(Get-VisibleProcessWindows -OwnerProcessId $Process.Id)) {
            [void][UnWorkshopWorkerWindowApi]::ShowWindowAsync($window, 0)
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $deadline)

    $visibleWindows = @(
        Get-VisibleProcessWindows -OwnerProcessId $Process.Id
    )
    if ($visibleWindows.Count -gt 0) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        throw (
            'Worker PCSX2 did not remain hidden; terminated process ' +
            "$($Process.Id)."
        )
    }
}

if ($PSCmdlet.ParameterSetName -eq 'Worker') {
    $workerRootFull = [IO.Path]::GetFullPath($WorkerRoot)
    $workerPcsx2 = Join-Path $workerRootFull 'pcsx2'
    if ($IsoPath) {
        $resolvedIso = [IO.Path]::GetFullPath($IsoPath)
        $allowedIsoRoot = [IO.Path]::GetFullPath(
            (Join-Path $workerRootFull 'inputs\isos')
        )
        $prefix = $allowedIsoRoot.TrimEnd(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        ) + [IO.Path]::DirectorySeparatorChar
        if (-not $resolvedIso.StartsWith(
            $prefix,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw (
                'Worker ISO must be an independent copy under ' +
                "$allowedIsoRoot."
            )
        }
    }
    $workerExecutables = @(
        Get-ChildItem -LiteralPath $workerPcsx2 -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -ceq 'pcsx2-qt.exe' -or
                $_.Name -like 'pcsx2-qtx64-*.exe'
            } |
            Sort-Object @{
                Expression = { if ($_.Name -ceq 'pcsx2-qt.exe') { 0 } else { 1 } }
            }, Name
    )
    if ($workerExecutables.Count -eq 0) {
        throw (
            'The workstream PCSX2 copy contains no supported executable: ' +
            $workerPcsx2
        )
    }
    $workerBios = Join-Path $workerPcsx2 'bios'
    if (@(
        Get-ChildItem `
            -LiteralPath $workerBios `
            -File `
            -Filter '*.bin' `
            -ErrorAction SilentlyContinue
    ).Count -eq 0) {
        throw (
            'The workstream PCSX2 copy contains no BIOS image. Recreate it with ' +
            'Workshop scripts/pcsx2/copy_worker.ps1 -WorkerRoot <task root>.'
        )
    }
    $executable = $workerExecutables[0].FullName
    $workingDirectory = $workerPcsx2
    $hidden = $true
}
else {
    if ($IsoPath) {
        $resolvedIso = if ([IO.Path]::IsPathRooted($IsoPath)) {
            [IO.Path]::GetFullPath($IsoPath)
        }
        else {
                [IO.Path]::GetFullPath($IsoPath)
        }
    }
    if ($Target -eq 'stable') {
        $executable = [IO.Path]::GetFullPath(
            (Join-Path $paths.Pcsx2Stable 'pcsx2-qt.exe')
        )
        $workingDirectory = [IO.Path]::GetFullPath(
            $paths.Pcsx2Stable
        )
    }
    else {
        $executable = [IO.Path]::GetFullPath(
            (Join-Path $paths.Pcsx2Dev 'pcsx2-qtx64-avx2-dev.exe')
        )
        $workingDirectory = [IO.Path]::GetFullPath(
            $paths.Pcsx2Dev
        )
    }
    $hidden = $Hidden.IsPresent
}

if (-not [string]::IsNullOrWhiteSpace($InputRecording)) {
    $resolvedInputRecording = if ([IO.Path]::IsPathRooted($InputRecording)) {
        [IO.Path]::GetFullPath($InputRecording)
    }
    else {
        [IO.Path]::GetFullPath(
            (Join-Path $paths.InputRecordings $InputRecording)
        )
    }
    if (-not (
        Test-Path -LiteralPath $resolvedInputRecording -PathType Leaf
    )) {
        throw "Input recording does not exist: $resolvedInputRecording"
    }
    $inputRecordingFileName = [IO.Path]::GetFileName(
        $resolvedInputRecording
    )
}

if (-not [string]::IsNullOrWhiteSpace($CreateInputRecording)) {
    if (
        [IO.Path]::IsPathRooted($CreateInputRecording) -or
        [IO.Path]::GetFileName($CreateInputRecording) -cne $CreateInputRecording
    ) {
        throw 'New input recording must be a filename.'
    }
}

if (-not [string]::IsNullOrWhiteSpace($InputRecordingCaptureDirectory)) {
    if ([string]::IsNullOrWhiteSpace($InputRecording)) {
        throw 'A capture directory requires an input recording replay.'
    }
    $resolvedInputRecordingCaptureDirectory = [IO.Path]::GetFullPath(
        $InputRecordingCaptureDirectory
    )
}

if ($IsoPath -and -not (
    Test-Path -LiteralPath $resolvedIso -PathType Leaf
)) {
    throw "ISO does not exist: $resolvedIso"
}
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    if ($PSCmdlet.ParameterSetName -eq 'Worker') {
        throw (
            'The workstream PCSX2 copy does not exist. Run ' +
            'Workshop scripts/pcsx2/copy_worker.ps1 -WorkerRoot <task root> before launching.'
        )
    }
    throw "PCSX2 executable does not exist: $executable"
}

$launchArguments = @()
if ($hidden) {
    $launchArguments += '-nogui'
}
if (
    $PSCmdlet.ParameterSetName -eq 'Configured' -and
    $Target -eq 'dev'
) {
    $launchArguments += '-unlimited'
}
if ($IsoPath) {
    $launchArguments += @('-batch', "`"$resolvedIso`"")
}
if (-not [string]::IsNullOrWhiteSpace($InputRecording)) {
    $launchArguments += @(
        '-input-recording',
        "`"$inputRecordingFileName`""
    )
}
if (-not [string]::IsNullOrWhiteSpace($InputRecordingCaptureDirectory)) {
    $launchArguments += @(
        '-input-recording-capture-directory',
        "`"$resolvedInputRecordingCaptureDirectory`""
    )
}
if (-not [string]::IsNullOrWhiteSpace($CreateInputRecording)) {
    $launchArguments += @(
        '-input-recording-create',
        "`"$CreateInputRecording`""
    )
}
if ($Arguments) {
    $launchArguments += @(
        $Arguments | Where-Object { -not [string]::IsNullOrEmpty($_) }
    )
}
$startArguments = @{
    FilePath = $executable
    WorkingDirectory = $workingDirectory
}
if ($launchArguments.Count -gt 0) {
    $startArguments.ArgumentList = $launchArguments
}
if ($hidden) {
    $startArguments.WindowStyle = 'Hidden'
    $startArguments.PassThru = $true
    $process = Start-Process @startArguments
    try {
        Hide-WorkerProcessWindows -Process $process
    }
    catch {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        throw
    }
    if ($Wait) {
        $process.WaitForExit()
    }
    if ($PassThru) {
        $process
    }
    return
}
if ($Wait) {
    $startArguments.Wait = $true
}
if ($PassThru) {
    $startArguments.PassThru = $true
}
Start-Process @startArguments
