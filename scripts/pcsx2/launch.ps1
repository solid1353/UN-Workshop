[CmdletBinding()]
param(
    [string]$IsoPath,

    [string]$InputRecording,

    [string]$CreateInputRecording,

    [string]$InputRecordingCaptureDirectory,

    [string]$InputRecordingsRoot,

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments,

    [switch]$Wait,

    [switch]$PassThru,

    [switch]$Turbo,

    [switch]$Unlimited,

    [UInt64]$UnlimitedForFrames = 0,

    [switch]$Surfaceless,

    [switch]$DiscardMemoryCardWrites,

    [switch]$ReadOnlySettings,

    [string]$MemoryCard,

    [string]$Pnach,

    [string[]]$PnachLines
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$resolvedInputRecordingsRoot = if (
    [string]::IsNullOrWhiteSpace($InputRecordingsRoot)
) {
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

if ($IsoPath) {
    $resolvedIso = if ([IO.Path]::IsPathRooted($IsoPath)) {
        [IO.Path]::GetFullPath($IsoPath)
    }
    else {
        [IO.Path]::GetFullPath($IsoPath)
    }
}
$executable = [IO.Path]::GetFullPath(
    (Join-Path $paths.Pcsx2Dev 'pcsx2-qtx64-avx2-dev.exe')
)
$workingDirectory = [IO.Path]::GetFullPath($paths.Pcsx2Dev)
$surfaceless = $Surfaceless.IsPresent

if (-not [string]::IsNullOrWhiteSpace($InputRecording)) {
    $resolvedInputRecording = if ([IO.Path]::IsPathRooted($InputRecording)) {
        [IO.Path]::GetFullPath($InputRecording)
    }
    else {
        [IO.Path]::GetFullPath(
            (Join-Path $resolvedInputRecordingsRoot $InputRecording)
        )
    }
    if (-not (
        Test-Path -LiteralPath $resolvedInputRecording -PathType Leaf
    )) {
        throw "Input recording does not exist: $resolvedInputRecording"
    }
    $inputRecordingRoot = $resolvedInputRecordingsRoot
    $inputRecordingPrefix = $inputRecordingRoot.TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    ) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedInputRecording.StartsWith(
        $inputRecordingPrefix,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Input recording must be inside $inputRecordingRoot."
    }
}

if (-not [string]::IsNullOrWhiteSpace($CreateInputRecording)) {
    $createInputRecordingRelativePath = Resolve-UnWorkshopRecordingName `
        -Name $CreateInputRecording `
        -Root $resolvedInputRecordingsRoot `
        -CreateParent
    $resolvedCreateInputRecording = [IO.Path]::GetFullPath(
        (Join-Path `
            $resolvedInputRecordingsRoot `
            $createInputRecordingRelativePath)
    )
}

if (-not [string]::IsNullOrWhiteSpace($InputRecordingCaptureDirectory)) {
    if ([string]::IsNullOrWhiteSpace($InputRecording)) {
        throw 'A capture directory requires an input recording replay.'
    }
    $resolvedInputRecordingCaptureDirectory = [IO.Path]::GetFullPath(
        $InputRecordingCaptureDirectory
    )
}

if (-not [string]::IsNullOrWhiteSpace($MemoryCard)) {
    $resolvedMemoryCard = [IO.Path]::GetFullPath($MemoryCard)
    if (-not (Test-Path -LiteralPath $resolvedMemoryCard -PathType Leaf)) {
        throw "Memory card does not exist: $resolvedMemoryCard"
    }
}

if (-not [string]::IsNullOrWhiteSpace($Pnach)) {
    $resolvedPnach = [IO.Path]::GetFullPath($Pnach)
    if (-not (Test-Path -LiteralPath $resolvedPnach -PathType Leaf)) {
        throw "PNACH file does not exist: $resolvedPnach"
    }
}

if ($IsoPath -and -not (
    Test-Path -LiteralPath $resolvedIso -PathType Leaf
)) {
    throw "ISO does not exist: $resolvedIso"
}
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw "PCSX2 executable does not exist: $executable"
}

$launchArguments = @()
if ($surfaceless) {
    $launchArguments += @('-surfaceless', '-mute')
}
if ($DiscardMemoryCardWrites) {
    $launchArguments += '-discard-memory-card-writes'
}
if ($ReadOnlySettings) {
    $launchArguments += '-read-only-settings'
}
if (-not [string]::IsNullOrWhiteSpace($MemoryCard)) {
    $launchArguments += @('-memory-card', "`"$resolvedMemoryCard`"")
}
if (-not [string]::IsNullOrWhiteSpace($Pnach)) {
    $launchArguments += @('-pnach', "`"$resolvedPnach`"")
}
if ($PSBoundParameters.ContainsKey('PnachLines')) {
    foreach ($pnachLine in @($PnachLines)) {
        $launchArguments += @('-pnach-line', "`"$pnachLine`"")
    }
}
if ($Unlimited) {
    $launchArguments += '-unlimited'
}
else {
    if ($Turbo) {
        $launchArguments += '-turbo'
    }
    if ($UnlimitedForFrames -gt 0) {
        $launchArguments += @(
            '-unlimited-for-frames',
            [string]$UnlimitedForFrames
        )
    }
}
if ($IsoPath) {
    $launchArguments += @('-batch', "`"$resolvedIso`"")
}
if (-not [string]::IsNullOrWhiteSpace($InputRecording)) {
    $launchArguments += @(
        '-input-recording',
        "`"$resolvedInputRecording`""
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
        "`"$resolvedCreateInputRecording`""
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
if ($surfaceless) {
    $startArguments.PassThru = $true
    $process = Start-Process @startArguments
    if ($Wait) {
        try {
            Wait-Process -InputObject $process
        }
        finally {
            if (-not $process.HasExited) {
                Stop-Process `
                    -Id $process.Id `
                    -Force `
                    -ErrorAction SilentlyContinue
                Wait-Process `
                    -InputObject $process `
                    -ErrorAction SilentlyContinue
            }
        }
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
