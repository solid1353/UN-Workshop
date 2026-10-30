[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))

# Exercise the public PowerShell routing with an invalid port, before any PINE
# connection can occur, including repeated inline lines and expectations.
$output = @(& (Join-Path $repository 'workshop.ps1') pcsx2 pnach `
    -line 'patch=1,EE,00001000,word,1' `
    -line 'patch=1,EE,00001004,word,2' `
    -expect '1000:00000000' -expect '1004:00000000' -port 0 2>&1)
if ($LASTEXITCODE -eq 0 -or ($output -join "`n") -notmatch 'port must be inside 1\.\.65535') {
    throw "PNACH inline routing did not preserve its arguments: $($output -join "`n")"
}
$output = @(& (Join-Path $repository 'workshop.ps1') pcsx2 pnach `
    edits.pnach -watch -port 0 2>&1)
if ($LASTEXITCODE -eq 0 -or ($output -join "`n") -notmatch 'port must be inside 1\.\.65535') {
    throw "PNACH file/watch routing did not preserve its arguments: $($output -join "`n")"
}

Push-Location $repository
try {
    & (Join-Path $repository 'scripts\lib\run_python.ps1') `
        -Repository $repository -NoBytecode -Module unittest `
        -ArgumentList @('tests.scripts.pcsx2.test_pnach')
    if ($LASTEXITCODE -ne 0) {
        throw "PNACH application tests failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
