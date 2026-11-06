[CmdletBinding()]
param(
    [string]$IsoPath,

    [string[]]$Cheats,

    [string[]]$CheatLines,

    [UInt64]$FastForwardForFrames = 0,

    # Left, top, width and height.
    [int[]]$Window,

    [switch]$Mute,

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

$executable = [IO.Path]::GetFullPath(
    (Join-Path $paths.PpssppDev 'PPSSPPWindows64.exe')
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
foreach ($cheatPath in $resolvedCheats) {
    $launchArguments += "`"--cheats=$cheatPath`""
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
if ($Mute) {
    $launchArguments += '--mute'
}
if ($Arguments) {
    $launchArguments += @(
        $Arguments | Where-Object { -not [string]::IsNullOrEmpty($_) }
    )
}
if ($IsoPath) {
    $launchArguments += "`"$resolvedIso`""
}

$startArguments = @{
    FilePath = $executable
    WorkingDirectory = [IO.Path]::GetFullPath($paths.PpssppDev)
}
if ($launchArguments.Count -gt 0) {
    $startArguments.ArgumentList = $launchArguments
}
if ($Wait) {
    $startArguments.Wait = $true
}
if ($PassThru) {
    $startArguments.PassThru = $true
}
Start-Process @startArguments
