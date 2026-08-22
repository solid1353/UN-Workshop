[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
Push-Location $repository
try {
    & python -B -m unittest tests.scripts.pcsx2.test_pine_agent
    if ($LASTEXITCODE -ne 0) {
        throw "PINE agent-input tests failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Host 'PINE agent-input tests passed.'
