[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDir
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$context = Get-UnWorkshopTaskContext
& (Join-Path $PSScriptRoot '..\lib\run_python.ps1') -NoBytecode `
    -Script (Join-Path $PSScriptRoot 'expand_source_textures.py') `
    -ArgumentList @('--source-dir', $SourceDir)
if ($LASTEXITCODE -ne 0) { throw 'Source texture expansion failed.' }
