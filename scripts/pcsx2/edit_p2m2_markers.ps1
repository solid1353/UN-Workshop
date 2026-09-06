[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RecordingPath,

    [Parameter(ParameterSetName = 'List')]
    [switch]$List,

    [Parameter(Mandatory = $true, ParameterSetName = 'Remove')]
    [ValidateNotNullOrEmpty()]
    [int[]]$RemoveMarker,

    [Parameter(Mandatory = $true, ParameterSetName = 'Move')]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MoveMarker,

    [Parameter(Mandatory = $true, ParameterSetName = 'Move')]
    [int]$OffsetFrames,

    [Parameter(Mandatory = $true, ParameterSetName = 'Recycle')]
    [switch]$RecycleBackups
)

$ErrorActionPreference = 'Stop'
$script:P2m2HeaderSize = 570
$script:P2m2FrameSize = 36
$script:P2m2ControllerSize = 18
$script:P2m2MarkerMask = 0x06

function Read-P2m2Recording {
    param([Parameter(Mandatory = $true)][string]$Path)

    [byte[]]$bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt $script:P2m2HeaderSize) {
        throw "P2M2 file is shorter than its version 1 header: $Path"
    }
    if ($bytes[0] -ne 1) {
        throw "Unsupported P2M2 version $($bytes[0]): $Path"
    }

    $lastFrame = [BitConverter]::ToUInt32($bytes, 561)
    $expectedLength = $script:P2m2HeaderSize +
        (([int64]$lastFrame + 1) * $script:P2m2FrameSize)
    if ($bytes.LongLength -ne $expectedLength) {
        throw "Invalid P2M2 length $($bytes.LongLength); expected $expectedLength from last frame $lastFrame."
    }

    return [pscustomobject]@{
        Bytes = $bytes
        LastFrame = $lastFrame
    }
}

function Test-P2m2MarkerChord {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Frame,
        [Parameter(Mandatory = $true)][ValidateRange(0, 1)][int]$Port
    )

    $offset = $script:P2m2HeaderSize + ($Frame * $script:P2m2FrameSize) +
        ($Port * $script:P2m2ControllerSize)
    return (($Bytes[$offset] -band $script:P2m2MarkerMask) -eq 0)
}

function Get-P2m2Markers {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][uint32]$LastFrame
    )

    $markers = [Collections.Generic.List[object]]::new()
    $startFrame = $null
    for ($frame = 1; $frame -le $LastFrame; $frame++) {
        $down = (Test-P2m2MarkerChord -Bytes $Bytes -Frame $frame -Port 0) -or
            (Test-P2m2MarkerChord -Bytes $Bytes -Frame $frame -Port 1)
        if ($down -and $null -eq $startFrame) {
            $startFrame = $frame
        }
        elseif (-not $down -and $null -ne $startFrame) {
            $markers.Add([pscustomobject]@{
                    Marker = $markers.Count + 1
                    StartFrame = $startFrame
                    EndFrame = $frame - 1
                    FrameCount = $frame - $startFrame
                })
            $startFrame = $null
        }
    }
    if ($null -ne $startFrame) {
        $markers.Add([pscustomobject]@{
                Marker = $markers.Count + 1
                StartFrame = $startFrame
                EndFrame = [int]$LastFrame
                FrameCount = ([int]$LastFrame - $startFrame) + 1
            })
    }
    return $markers.ToArray()
}

function Get-P2m2MarkerKey {
    param([Parameter(Mandatory = $true)][object[]]$Markers)
    return @($Markers | ForEach-Object { "$($_.StartFrame)-$($_.EndFrame)" })
}

function Assert-P2m2MarkersEqual {
    param(
        [Parameter(Mandatory = $true)][object[]]$Expected,
        [Parameter(Mandatory = $true)][object[]]$Actual
    )

    $expectedKey = @(Get-P2m2MarkerKey -Markers $Expected)
    $actualKey = @(Get-P2m2MarkerKey -Markers $Actual)
    if ($null -ne (Compare-Object -ReferenceObject $expectedKey -DifferenceObject $actualKey -SyncWindow 0)) {
        throw "Marker validation failed; expected [$($expectedKey -join ', ')], actual [$($actualKey -join ', ')]."
    }
}

function Get-P2m2Backups {
    param([Parameter(Mandatory = $true)][string]$Path)

    $directory = [IO.Path]::GetDirectoryName($Path)
    $fileName = [IO.Path]::GetFileName($Path)
    $pattern = '^' + [regex]::Escape($fileName) + '\.bak(?<number>[1-9][0-9]*)$'
    return @(
        Get-ChildItem -LiteralPath $directory -Force |
            Where-Object { -not $_.PSIsContainer -and $_.Name -match $pattern } |
            ForEach-Object {
                if (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Refusing backup reparse point: $($_.FullName)"
                }
                [pscustomobject]@{
                    Path = $_.FullName
                    Number = [int64]$Matches.number
                }
            } |
            Sort-Object Number
    )
}

function Move-P2m2BackupsUp {
    param([Parameter(Mandatory = $true)][string]$Path)

    $moves = [Collections.Generic.List[object]]::new()
    try {
        foreach ($backup in @(Get-P2m2Backups -Path $Path | Sort-Object Number -Descending)) {
            if ($backup.Number -eq [int64]::MaxValue) {
                throw "Backup number cannot be incremented: $($backup.Path)"
            }
            $destination = "$Path.bak$($backup.Number + 1)"
            [IO.File]::Move($backup.Path, $destination)
            $moves.Add([pscustomobject]@{ Source = $backup.Path; Destination = $destination })
        }
    }
    catch {
        for ($index = $moves.Count - 1; $index -ge 0; $index--) {
            [IO.File]::Move($moves[$index].Destination, $moves[$index].Source)
        }
        throw
    }
    return $moves.ToArray()
}

function Restore-P2m2BackupRotation {
    param([Parameter(Mandatory = $true)][object[]]$Moves)

    for ($index = $Moves.Count - 1; $index -ge 0; $index--) {
        [IO.File]::Move($Moves[$index].Destination, $Moves[$index].Source)
    }
}

function Assert-P2m2ByteChanges {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Before,
        [Parameter(Mandatory = $true)][byte[]]$After
    )

    if ($Before.Length -ne $After.Length) {
        throw 'Marker edit changed the P2M2 file length.'
    }

    $changed = [Collections.Generic.List[int]]::new()
    for ($offset = 0; $offset -lt $Before.Length; $offset++) {
        if ($Before[$offset] -eq $After[$offset]) {
            continue
        }
        $relativeOffset = $offset - $script:P2m2HeaderSize
        $withinFrame = if ($relativeOffset -ge 0) {
            $relativeOffset % $script:P2m2FrameSize
        } else { -1 }
        if ($withinFrame -ne 0 -and $withinFrame -ne $script:P2m2ControllerSize) {
            throw "Marker edit changed a non-marker byte at offset $offset."
        }
        $changedBits = $Before[$offset] -bxor $After[$offset]
        if (($changedBits -band 0xF9) -ne 0) {
            throw "Marker edit changed non-L3/R3 bits at offset $offset."
        }
        $changed.Add($offset)
    }
    if ($changed.Count -eq 0) {
        throw 'Marker edit made no byte changes.'
    }
    return $changed.ToArray()
}

function Set-P2m2MarkerChord {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Frame,
        [Parameter(Mandatory = $true)][ValidateRange(0, 1)][int]$Port,
        [Parameter(Mandatory = $true)][bool]$Pressed
    )

    $offset = $script:P2m2HeaderSize + ($Frame * $script:P2m2FrameSize) +
        ($Port * $script:P2m2ControllerSize)
    if ($Pressed) {
        $Bytes[$offset] = [byte]($Bytes[$offset] -band 0xF9)
    }
    else {
        $Bytes[$offset] = [byte]($Bytes[$offset] -bor $script:P2m2MarkerMask)
    }
}

function Save-P2m2Edit {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Before,
        [Parameter(Mandatory = $true)][byte[]]$After,
        [Parameter(Mandatory = $true)][object[]]$ExpectedMarkers
    )

    $changedOffsets = @(Assert-P2m2ByteChanges -Before $Before -After $After)
    $temporaryPath = "$Path.edit-$([guid]::NewGuid().ToString('N')).tmp"
    $rotation = @()
    try {
        [IO.File]::WriteAllBytes($temporaryPath, $After)
        $temporaryRecording = Read-P2m2Recording -Path $temporaryPath
        $temporaryMarkers = @(Get-P2m2Markers -Bytes $temporaryRecording.Bytes -LastFrame $temporaryRecording.LastFrame)
        Assert-P2m2MarkersEqual -Expected $ExpectedMarkers -Actual $temporaryMarkers

        $rotation = @(Move-P2m2BackupsUp -Path $Path)
        try {
            [IO.File]::Replace($temporaryPath, $Path, "$Path.bak1", $true)
        }
        catch {
            if ($rotation.Count -gt 0) {
                Restore-P2m2BackupRotation -Moves $rotation
            }
            throw
        }

        $writtenRecording = Read-P2m2Recording -Path $Path
        $writtenMarkers = @(Get-P2m2Markers -Bytes $writtenRecording.Bytes -LastFrame $writtenRecording.LastFrame)
        Assert-P2m2MarkersEqual -Expected $ExpectedMarkers -Actual $writtenMarkers
        return [pscustomobject]@{
            Recording = $Path
            Backup = "$Path.bak1"
            InputSha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Before))
            OutputSha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($After))
            ChangedBytes = $changedOffsets.Count
            Markers = $writtenMarkers
        }
    }
    finally {
        if ([IO.File]::Exists($temporaryPath)) {
            [IO.File]::Delete($temporaryPath)
        }
    }
}

$resolvedRecordingPath = (Resolve-Path -LiteralPath $RecordingPath).Path

if ($PSCmdlet.ParameterSetName -eq 'Recycle') {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $backups = @(Get-P2m2Backups -Path $resolvedRecordingPath)
    foreach ($backup in $backups) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
            $backup.Path,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
        if ([IO.File]::Exists($backup.Path)) {
            throw "Backup remains after Recycle Bin operation: $($backup.Path)"
        }
    }
    return [pscustomobject]@{
        Recording = $resolvedRecordingPath
        RecycledBackups = @($backups | ForEach-Object Path)
    }
}

$recording = Read-P2m2Recording -Path $resolvedRecordingPath
$markersBefore = @(Get-P2m2Markers -Bytes $recording.Bytes -LastFrame $recording.LastFrame)
if ($PSCmdlet.ParameterSetName -eq 'List') {
    $markersBefore | Write-Output
    return
}

[byte[]]$edited = $recording.Bytes.Clone()
$expectedMarkers = [Collections.Generic.List[object]]::new()
foreach ($marker in $markersBefore) {
    $expectedMarkers.Add($marker)
}

if ($PSCmdlet.ParameterSetName -eq 'Remove') {
    $selected = @($RemoveMarker | Sort-Object -Unique)
    foreach ($markerNumber in $selected) {
        if ($markerNumber -lt 1 -or $markerNumber -gt $markersBefore.Count) {
            throw "Marker $markerNumber is outside the recording's marker range 1-$($markersBefore.Count)."
        }
    }
    foreach ($markerNumber in $selected) {
        $marker = $markersBefore[$markerNumber - 1]
        for ($frame = $marker.StartFrame; $frame -le $marker.EndFrame; $frame++) {
            foreach ($port in 0, 1) {
                if (Test-P2m2MarkerChord -Bytes $recording.Bytes -Frame $frame -Port $port) {
                    Set-P2m2MarkerChord -Bytes $edited -Frame $frame -Port $port -Pressed $false
                }
            }
        }
    }
    $expectedMarkers = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $markersBefore.Count; $index++) {
        if (($index + 1) -notin $selected) {
            $expectedMarkers.Add($markersBefore[$index])
        }
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Move') {
    if ($MoveMarker -gt $markersBefore.Count) {
        throw "Marker $MoveMarker is outside the recording's marker range 1-$($markersBefore.Count)."
    }
    if ($OffsetFrames -eq 0) {
        throw 'OffsetFrames must not be zero.'
    }

    $marker = $markersBefore[$MoveMarker - 1]
    $destinationStart = [int64]$marker.StartFrame + $OffsetFrames
    $destinationEnd = [int64]$marker.EndFrame + $OffsetFrames
    if ($destinationStart -lt 1 -or $destinationEnd -gt $recording.LastFrame) {
        throw "Moved marker would be outside frames 1-$($recording.LastFrame): $destinationStart-$destinationEnd."
    }

    $sourcePattern = @()
    for ($frame = $marker.StartFrame; $frame -le $marker.EndFrame; $frame++) {
        $sourcePattern += ,@(
            (Test-P2m2MarkerChord -Bytes $recording.Bytes -Frame $frame -Port 0),
            (Test-P2m2MarkerChord -Bytes $recording.Bytes -Frame $frame -Port 1)
        )
        foreach ($port in 0, 1) {
            if (Test-P2m2MarkerChord -Bytes $recording.Bytes -Frame $frame -Port $port) {
                Set-P2m2MarkerChord -Bytes $edited -Frame $frame -Port $port -Pressed $false
            }
        }
    }

    for ($frame = [int]$destinationStart; $frame -le [int]$destinationEnd; $frame++) {
        if ($frame -ge $marker.StartFrame -and $frame -le $marker.EndFrame) {
            continue
        }
        foreach ($port in 0, 1) {
            $offset = $script:P2m2HeaderSize + ($frame * $script:P2m2FrameSize) +
                ($port * $script:P2m2ControllerSize)
            if (($recording.Bytes[$offset] -band $script:P2m2MarkerMask) -ne $script:P2m2MarkerMask) {
                throw "Destination frame $frame port $port already uses L3 or R3."
            }
        }
    }

    for ($patternIndex = 0; $patternIndex -lt $sourcePattern.Count; $patternIndex++) {
        $frame = [int]$destinationStart + $patternIndex
        foreach ($port in 0, 1) {
            if ($sourcePattern[$patternIndex][$port]) {
                Set-P2m2MarkerChord -Bytes $edited -Frame $frame -Port $port -Pressed $true
            }
        }
    }

    $expectedMarkers = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $markersBefore.Count; $index++) {
        if ($index -ne ($MoveMarker - 1)) {
            $expectedMarkers.Add($markersBefore[$index])
        }
    }
    $expectedMarkers.Add([pscustomobject]@{
            Marker = 0
            StartFrame = [int]$destinationStart
            EndFrame = [int]$destinationEnd
            FrameCount = $marker.FrameCount
        })
    $expectedMarkers = [Collections.Generic.List[object]]@(
        $expectedMarkers | Sort-Object StartFrame
    )
}

$result = Save-P2m2Edit `
    -Path $resolvedRecordingPath `
    -Before $recording.Bytes `
    -After $edited `
    -ExpectedMarkers $expectedMarkers.ToArray()
$result | Write-Output
