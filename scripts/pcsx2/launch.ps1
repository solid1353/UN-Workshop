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
    [switch]$Capped,

    [Parameter(ParameterSetName = 'Configured')]
    [switch]$Turbo,

    [Parameter(ParameterSetName = 'Configured')]
    [switch]$Unlimited,

    [Parameter(ParameterSetName = 'Configured')]
    [switch]$Surfaceless,

    [Parameter(ParameterSetName = 'Configured')]
    [switch]$DiscardMemoryCardWrites,

    [Parameter(ParameterSetName = 'Configured')]
    [string]$MemoryCard
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths

if ($Turbo -and $Unlimited) {
    throw 'Use only one of -Turbo or -Unlimited.'
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
    $surfaceless = $true
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
    $surfaceless = $Surfaceless.IsPresent
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
    $inputRecordingRoot = [IO.Path]::GetFullPath($paths.InputRecordings)
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
    $inputRecordingRelativePath = [IO.Path]::GetRelativePath(
        $inputRecordingRoot,
        $resolvedInputRecording
    )
}

if (-not [string]::IsNullOrWhiteSpace($CreateInputRecording)) {
    $createInputRecordingRelativePath = Resolve-UnWorkshopRecordingName `
        -Name $CreateInputRecording `
        -Root $paths.InputRecordings `
        -CreateParent
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
if ($surfaceless) {
    $launchArguments += @('-nogui', '-surfaceless')
}
if ($DiscardMemoryCardWrites) {
    $launchArguments += '-discard-memory-card-writes'
}
if (-not [string]::IsNullOrWhiteSpace($MemoryCard)) {
    $launchArguments += @('-memory-card', "`"$resolvedMemoryCard`"")
}
if ($Unlimited) {
    $launchArguments += '-unlimited'
}
elseif (
    $Turbo -or (
        $PSCmdlet.ParameterSetName -eq 'Configured' -and
        $Target -eq 'dev' -and
        -not $Capped -and
        [string]::IsNullOrWhiteSpace($CreateInputRecording)
    )
) {
    $launchArguments += '-turbo'
}
if ($IsoPath) {
    $launchArguments += @('-batch', "`"$resolvedIso`"")
}
if (-not [string]::IsNullOrWhiteSpace($InputRecording)) {
    $launchArguments += @(
        '-input-recording',
        "`"$inputRecordingRelativePath`""
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
        "`"$createInputRecordingRelativePath`""
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
