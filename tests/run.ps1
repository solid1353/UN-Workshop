[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tests = @(
    Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -File -Filter 'test_*.ps1' |
        Sort-Object FullName
)
Push-Location $root
try {
    foreach ($test in $tests) {
        Write-Host "[tests] $([IO.Path]::GetRelativePath($root, $test.FullName))"
        & $test.FullName
    }
}
finally {
    Pop-Location
}

Write-Host 'All UN Workshop tests passed.'
