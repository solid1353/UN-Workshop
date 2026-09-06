[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-P2m2MarkerTest {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) { throw $Message }
}

function Get-TestFileSha256 {
    param([Parameter(Mandatory)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$testParent = Join-Path $sourceRepository 'work\tests'
$testRoot = Join-Path $testParent (
    'edit-p2m2-markers-' + [Guid]::NewGuid().ToString('N')
)
$recording = Join-Path $testRoot 'synthetic.p2m2'
$editor = Join-Path $sourceRepository 'scripts\pcsx2\edit_p2m2_markers.ps1'

try {
    [void](New-Item -ItemType Directory -Path $testRoot -Force)
    $lastFrame = 20
    $headerSize = 570
    $frameSize = 36
    $controllerSize = 18
    [byte[]]$bytes = [byte[]]::new($headerSize + (($lastFrame + 1) * $frameSize))
    $bytes[0] = 1
    [BitConverter]::GetBytes([uint32]$lastFrame).CopyTo($bytes, 561)
    for ($frame = 1; $frame -le $lastFrame; $frame++) {
        $offset = $headerSize + ($frame * $frameSize)
        $bytes[$offset] = 0xFF
        $bytes[$offset + $controllerSize] = 0xFF
    }
    foreach ($frame in 3, 4) {
        $bytes[$headerSize + ($frame * $frameSize)] = 0xF9
    }
    foreach ($frame in 8, 9, 10) {
        $bytes[$headerSize + ($frame * $frameSize) + $controllerSize] = 0xF1
    }
    $bytes[$headerSize + (15 * $frameSize)] = 0xF9
    [IO.File]::WriteAllBytes($recording, $bytes)

    $originalLength = ([IO.FileInfo]$recording).Length
    $originalHash = Get-TestFileSha256 -Path $recording
    $markers = @(& $editor $recording -List)
    Assert-P2m2MarkerTest `
        -Condition (($markers.StartFrame -join ',') -ceq '3,8,15') `
        -Message 'Marker listing did not identify the three rising edges or ignored frame zero.'

    $null = & $editor $recording -RemoveMarker 2
    $afterRemoveHash = Get-TestFileSha256 -Path $recording
    $markers = @(& $editor $recording -List)
    Assert-P2m2MarkerTest `
        -Condition (($markers.StartFrame -join ',') -ceq '3,15') `
        -Message 'Marker removal changed the wrong marker ranges.'
    Assert-P2m2MarkerTest `
        -Condition ((Get-TestFileSha256 -Path "$recording.bak1") -ceq $originalHash) `
        -Message 'First edit did not preserve the original recording as .bak1.'
    [byte[]]$removedBytes = [IO.File]::ReadAllBytes($recording)
    Assert-P2m2MarkerTest `
        -Condition ($removedBytes[$headerSize + (8 * $frameSize) + $controllerSize] -eq 0xF7) `
        -Message 'Marker removal changed unrelated controller bits.'

    $null = & $editor $recording -MoveMarker 2 -OffsetFrames 2
    $markers = @(& $editor $recording -List)
    Assert-P2m2MarkerTest `
        -Condition (($markers.StartFrame -join ',') -ceq '3,17') `
        -Message 'Marker move did not preserve order at the requested destination.'
    Assert-P2m2MarkerTest `
        -Condition ((Get-TestFileSha256 -Path "$recording.bak1") -ceq $afterRemoveHash) `
        -Message 'Second edit did not rotate the immediately previous recording to .bak1.'
    Assert-P2m2MarkerTest `
        -Condition ((Get-TestFileSha256 -Path "$recording.bak2") -ceq $originalHash) `
        -Message 'Second edit did not rotate the original recording to .bak2.'
    Assert-P2m2MarkerTest `
        -Condition (([IO.FileInfo]$recording).Length -eq $originalLength) `
        -Message 'Marker edits changed the recording length.'

    $beforeConflict = @(
        Get-TestFileSha256 -Path $recording
        Get-TestFileSha256 -Path "$recording.bak1"
        Get-TestFileSha256 -Path "$recording.bak2"
    )
    $conflictRejected = $false
    try {
        $null = & $editor $recording -MoveMarker 1 -OffsetFrames 14
    }
    catch {
        $conflictRejected = $_.Exception.Message -match 'already uses L3 or R3'
    }
    $afterConflict = @(
        Get-TestFileSha256 -Path $recording
        Get-TestFileSha256 -Path "$recording.bak1"
        Get-TestFileSha256 -Path "$recording.bak2"
    )
    Assert-P2m2MarkerTest `
        -Condition $conflictRejected `
        -Message 'Marker move accepted a destination containing another marker.'
    Assert-P2m2MarkerTest `
        -Condition (($beforeConflict -join ',') -ceq ($afterConflict -join ',')) `
        -Message 'Rejected marker move changed the recording or its backups.'

    Write-Host 'Workshop P2M2 marker-editor tests passed.' -ForegroundColor Green
}
finally {
    $resolvedTestParent = [IO.Path]::GetFullPath($testParent)
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
    if (-not $resolvedTestRoot.StartsWith(
        $resolvedTestParent + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing to remove test path outside its parent: $resolvedTestRoot"
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
