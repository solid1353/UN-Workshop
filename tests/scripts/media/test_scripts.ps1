[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
. (Join-Path $workshop 'scripts\lib\paths.ps1')
$paths = Get-UnWorkshopPaths

foreach ($name in 'extract_iso.ps1', 'extract_afs.ps1', 'split_cvm_rofs.ps1') {
    $path = Join-Path $paths.Roots.media_scripts $name
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile(
        $path,
        [ref]$tokens,
        [ref]$errors
    )
    if ($errors.Count -ne 0) {
        throw "$name has PowerShell parse errors: $($errors -join '; ')"
    }
}

Write-Host 'Media-tool tests passed.'
