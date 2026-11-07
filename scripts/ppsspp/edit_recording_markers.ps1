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
$resolvedRecordingPath = (Resolve-Path -LiteralPath $RecordingPath).Path

if ($PSCmdlet.ParameterSetName -eq 'Recycle') {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $pattern = '^' + [regex]::Escape([IO.Path]::GetFileName($resolvedRecordingPath)) +
        '\.bak[1-9][0-9]*$'
    $backups = @(
        Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($resolvedRecordingPath)) -Force |
            Where-Object { -not $_.PSIsContainer -and $_.Name -match $pattern }
    )
    foreach ($backup in $backups) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
            $backup.FullName,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
        if ([IO.File]::Exists($backup.FullName)) {
            throw "Backup remains after Recycle Bin operation: $($backup.FullName)"
        }
    }
    return [pscustomobject]@{
        Recording = $resolvedRecordingPath
        RecycledBackups = @($backups | ForEach-Object FullName)
    }
}

$pythonArguments = [Collections.Generic.List[string]]::new()
$pythonArguments.Add($resolvedRecordingPath)
if ($PSCmdlet.ParameterSetName -eq 'Remove') {
    $pythonArguments.Add('--remove')
    foreach ($marker in $RemoveMarker) { $pythonArguments.Add([string]$marker) }
}
elseif ($PSCmdlet.ParameterSetName -eq 'Move') {
    $pythonArguments.Add('--move')
    $pythonArguments.Add([string]$MoveMarker)
    $pythonArguments.Add("--offset-frames=$OffsetFrames")
}

& (Join-Path $PSScriptRoot '..\lib\run_python.ps1') `
    -Script (Join-Path $PSScriptRoot 'recording_markers.py') `
    -Repository (Join-Path $PSScriptRoot '..\..') `
    -NoBytecode `
    -ArgumentList @($pythonArguments)
exit $LASTEXITCODE
