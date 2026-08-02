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
$defaultMemoryCard = Join-Path ([IO.Path]::GetFullPath($paths.MemoryCards)) 'Default.ps2'
if (-not (Test-Path -LiteralPath $template -PathType Container)) {
    throw "Worker PCSX2 template does not exist: $template"
}
if (-not (Test-Path -LiteralPath $sharedBios -PathType Container)) {
    throw "Shared PCSX2 BIOS directory does not exist: $sharedBios"
}
if (@(Get-ChildItem -LiteralPath $sharedBios -File -Filter '*.bin').Count -eq 0) {
    throw "Shared PCSX2 BIOS directory contains no BIOS image: $sharedBios"
}
if (-not (Test-Path -LiteralPath $defaultMemoryCard -PathType Leaf)) {
    throw "Default PCSX2 memory card does not exist: $defaultMemoryCard"
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
$workerMemoryCards = Join-Path $workerPcsx2 'memcards'
New-Item -ItemType Directory -Force -Path $workerMemoryCards | Out-Null
Copy-Item -LiteralPath $defaultMemoryCard -Destination $workerMemoryCards -Force
$workerIni = Join-Path $workerPcsx2 'inis\PCSX2.ini'
$workerIniText = Get-Content -Raw -LiteralPath $workerIni
$workerIniText = $workerIniText -replace `
    '(?m)^Slot1_Filename\s*=.*$', `
    'Slot1_Filename = Default.ps2'
Set-Content -LiteralPath $workerIni -Value $workerIniText -NoNewline

Write-Host "[pcsx2] Worker runtime created: $workerPcsx2"
Write-Host "[pcsx2] BIOS copied from: $sharedBios"
Write-Host "[pcsx2] Default memory card copied from: $defaultMemoryCard"
