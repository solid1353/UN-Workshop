[CmdletBinding()]
param(
    [string]$IsoPath,

    [string[]]$Cheats,

    [string[]]$CheatLines,

    [UInt64]$FastForwardForFrames = 0,

    # Left, top, width and height.
    [int[]]$Window,

    [switch]$CenteredWindow,

    [switch]$Mute,

    [switch]$Turbo,

    [switch]$Unlimited,

    [switch]$ReadOnlySettings,

    [string]$LogFile,

    # A save folder, or none for no memory stick.
    [string]$Saves,

    [switch]$DiscardSaves,

    [switch]$VolatileSaves,

    [string]$InputRecording,

    [string]$CreateInputRecording,

    # Runs PPSSPPHeadless, without a window.
    [switch]$Headless,

    [string]$CaptureDirectory,

    [ValidateSet('full', 'screenshots', 'savestates')]
    [string]$CaptureMode = 'full',

    [int]$DebuggerPort = 0,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments,

    [switch]$Wait,

    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths

if ($PSBoundParameters.ContainsKey('FastForwardForFrames') -and
    $FastForwardForFrames -eq 0) {
    throw '-FastForwardForFrames requires a positive frame count.'
}
if ($PSBoundParameters.ContainsKey('Window') -and (
    @($Window).Count -ne 4 -or $Window[2] -lt 20 -or $Window[3] -lt 20
)) {
    throw '-Window requires left, top, width and height, with a width and height of at least 20.'
}
if ($Headless -and ($Window -or $CenteredWindow -or $Mute -or
    $ReadOnlySettings -or $CreateInputRecording)) {
    throw '-Headless takes no window, sound, settings or recording options.'
}
if ($Turbo -and $Unlimited) {
    throw 'Use only one of -Turbo or -Unlimited.'
}
if ($Headless -and $InputRecording -and ($Turbo -or $Unlimited)) {
    throw 'A headless replay takes no speed options.'
}
if ($CaptureDirectory -and -not $Headless) {
    throw '-CaptureDirectory requires -Headless.'
}

$installation = [IO.Path]::GetFullPath($paths.PpssppDev)
# A closing quote after a backslash would be taken for an escaped one.
function Format-PpssppArgument {
    param(
        [Parameter(Mandatory)][string]$Option,
        [Parameter(Mandatory)][string]$Value
    )

    return "`"$Option=$($Value -replace '\\+$', '$0$0')`""
}

if ($LogFile) {
    $LogFile = [IO.Path]::GetFullPath($LogFile)
    $logDirectory = Split-Path -Parent $LogFile
    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        throw "Log directory does not exist: $logDirectory"
    }
}

$executable = Join-Path $installation $(
    if ($Headless) { 'PPSSPPHeadless.exe' } else { 'PPSSPPWindows64.exe' }
)
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "PPSSPP executable does not exist: $executable"
}
if ($IsoPath) {
    $resolvedIso = [IO.Path]::GetFullPath($IsoPath)
    if (-not (Test-Path -LiteralPath $resolvedIso -PathType Leaf)) {
        throw "ISO does not exist: $resolvedIso"
    }
}
$resolvedCheats = @(
    foreach ($cheatPath in @($Cheats)) {
        if ([string]::IsNullOrWhiteSpace($cheatPath)) {
            continue
        }
        $resolvedPath = [IO.Path]::GetFullPath($cheatPath)
        if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
            throw "Cheat file does not exist: $resolvedPath"
        }
        $resolvedPath
    }
)

# The fork's run-only options: none of them is saved to ppsspp.ini.
$launchArguments = @()
if ($Headless) {
    # Headless reads no config of its own. Replays need the settings they were recorded with.
    $memstick = Join-Path $installation 'memstick'
    $launchArguments += @(
        (Format-PpssppArgument '--memstick' $memstick),
        (Format-PpssppArgument '--appendconfig' (Join-Path $memstick 'PSP\SYSTEM\ppsspp.ini')),
        '--graphics=vulkan'
    )
}
else {
    $launchArguments += Format-PpssppArgument '--controlconfig' (
        [IO.Path]::GetFullPath($paths.Files.ppsspp_controls)
    )
}
foreach ($cheatPath in $resolvedCheats) {
    $launchArguments += Format-PpssppArgument '--cheats' $cheatPath
}
foreach ($cheatLine in @($CheatLines)) {
    if (-not [string]::IsNullOrWhiteSpace($cheatLine)) {
        $launchArguments += "`"--cheat-line=$cheatLine`""
    }
}
if ($FastForwardForFrames -gt 0) {
    $launchArguments += "--fast-forward-for-frames=$FastForwardForFrames"
}
if ($PSBoundParameters.ContainsKey('Window')) {
    $launchArguments += @('--windowed', "--window=$($Window -join ',')")
}
if ($CenteredWindow) {
    $launchArguments += '--centered-window'
}
if ($Mute) {
    $launchArguments += '--mute'
}
if ($Headless -and -not $InputRecording) {
    # A live run: at PSP speed, Turbo's 200%, or flat out for -Unlimited.
    if ($Turbo) {
        $launchArguments += @('--realtime', '--speed=200')
    }
    elseif (-not $Unlimited) {
        $launchArguments += '--realtime'
    }
}
elseif ($Turbo) {
    $launchArguments += '--turbo'
}
elseif ($Unlimited) {
    $launchArguments += '--unlimited'
}
if ($ReadOnlySettings) {
    $launchArguments += '--read-only-settings'
}
if ($LogFile) {
    $launchArguments += if ($Headless) { '--log' } else { Format-PpssppArgument '--log' $LogFile }
}
if ($Saves -ieq 'none') {
    $launchArguments += '--no-memstick'
}
elseif ($Saves) {
    $launchArguments += Format-PpssppArgument '--savedata' ([IO.Path]::GetFullPath($Saves))
}
if ($DiscardSaves) {
    $launchArguments += '--discard-savedata'
}
if ($VolatileSaves) {
    $launchArguments += '--volatile-savedata'
}
if ($InputRecording) {
    $launchArguments += Format-PpssppArgument '--input-recording' $InputRecording
}
if ($CreateInputRecording) {
    $launchArguments += Format-PpssppArgument '--input-recording-create' $CreateInputRecording
}
if ($CaptureDirectory) {
    $launchArguments += @(
        (Format-PpssppArgument '--input-recording-capture-dir' $CaptureDirectory),
        "--input-recording-capture-mode=$CaptureMode"
    )
}
if ($DebuggerPort -gt 0) {
    # Headless stops at the start for --debugger; a live run shouldn't.
    $debugger = if ($Headless -and -not $InputRecording) { '--debugger-run' } else { '--debugger' }
    $launchArguments += @("$debugger=$DebuggerPort", '--debugger-local')
}
if ($Arguments) {
    $launchArguments += @(
        $Arguments | Where-Object { -not [string]::IsNullOrEmpty($_) }
    )
}
if ($IsoPath) {
    if (-not $Headless) {
        # Stopping the game (Esc) closes PPSSPP, as it closes PCSX2.
        $launchArguments += '--pause-menu-exit'
    }
    $launchArguments += "`"$resolvedIso`""
}

$startArguments = @{
    FilePath = $executable
    WorkingDirectory = $installation
}
if ($launchArguments.Count -gt 0) {
    $startArguments.ArgumentList = $launchArguments
}
if ($Headless) {
    $startArguments.NoNewWindow = $true
    if ($LogFile) {
        $startArguments.RedirectStandardError = $LogFile
    }
}
if ($Wait) {
    $startArguments.Wait = $true
}
if ($PassThru) {
    $startArguments.PassThru = $true
}
Start-Process @startArguments
