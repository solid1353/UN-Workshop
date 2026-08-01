[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$WorkerRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$workerRootFull = [IO.Path]::GetFullPath($WorkerRoot)
$workerPcsx2 = Join-Path $workerRootFull 'pcsx2'
$workerName = Split-Path $workerRootFull -Leaf
$template = [IO.Path]::GetFullPath($paths.Pcsx2Clean)
$sharedBios = [IO.Path]::GetFullPath($paths.Bios)
if (-not (Test-Path -LiteralPath $template -PathType Container)) {
    throw "Worker PCSX2 template does not exist: $template"
}
if (-not (Test-Path -LiteralPath $sharedBios -PathType Container)) {
    throw "Shared PCSX2 BIOS directory does not exist: $sharedBios"
}
if (@(Get-ChildItem -LiteralPath $sharedBios -File -Filter '*.bin').Count -eq 0) {
    throw "Shared PCSX2 BIOS directory contains no BIOS image: $sharedBios"
}
if (Test-Path -LiteralPath $workerPcsx2) {
    throw (
        "Worker PCSX2 destination already exists: $workerPcsx2. " +
        'Audit and remove the old task-owned runtime before copying a fresh one.'
    )
}

if (-not $PSCmdlet.ShouldProcess(
    $workerPcsx2,
    "copy the clean PCSX2 template and shared BIOS for $workerName"
)) {
    return
}

New-Item -ItemType Directory -Force -Path $workerRootFull | Out-Null
Copy-Item -LiteralPath $template -Destination $workerPcsx2 -Recurse
$workerBios = Join-Path $workerPcsx2 'bios'
New-Item -ItemType Directory -Force -Path $workerBios | Out-Null
Get-ChildItem -LiteralPath $sharedBios -Force | Copy-Item `
    -Destination $workerBios `
    -Recurse `
    -Force

Write-Host "[pcsx2] Worker runtime created: $workerPcsx2"
Write-Host "[pcsx2] BIOS copied from: $sharedBios"
