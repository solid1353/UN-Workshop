[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $sourceRepository 'scripts\pcsx2\iso_identity.ps1')

if ((Get-Pcsx2DiscSerialFromBootPath 'SLPS_258.37') -cne 'SLPS-25837') {
    throw 'Numeric boot-path serial parsing regressed.'
}
if ((Get-Pcsx2DiscSerialFromBootPath 'SLOP_NA2.28') -cne 'SLOP-NA228') {
    throw 'Alphanumeric boot-path serial parsing failed.'
}

$rejected = $false
try {
    $null = Get-Pcsx2DiscSerialFromBootPath 'INVALID.ELF'
}
catch {
    $rejected = $true
}
if (-not $rejected) {
    throw 'Invalid boot-path serial was accepted.'
}

Write-Host 'ISO identity tests passed.'
