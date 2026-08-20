[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& python -B (Join-Path $PSScriptRoot 'test_pine_agent.py')
if ($LASTEXITCODE -ne 0) {
    throw "PINE agent-input tests failed with exit code $LASTEXITCODE."
}

Write-Host 'PINE agent-input tests passed.'
