param(
    [Parameter(Mandatory = $true)]
    [string]$From,
    [Parameter(Mandatory = $true)]
    [string]$FromProgram,
    [Parameter(Mandatory = $true)]
    [string]$To,
    [Parameter(Mandatory = $true)]
    [string]$ToProgram,
    # Addresses such as 0x00178AD0, which PowerShell may pass as numbers, or listing names.
    [Parameter(Mandatory = $true)]
    [object[]]$Functions,
    [int]$Count = 3
)

# Ranks a program's functions by how closely their instructions match given functions of
# another program (similar_functions.py), to find counterparts match_annotations.ps1 cannot
# pair exactly.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'target_inputs.ps1')
Assert-GhidraTarget $From
Assert-GhidraTarget $To

& (Join-Path $PSScriptRoot '..\lib\run_python.ps1') `
    -Script (Join-Path $PSScriptRoot 'similar_functions.py') `
    -ArgumentList (@($From, $FromProgram, $To, $ToProgram) + @($Functions | ForEach-Object {
        if ($_ -is [ValueType]) { '0x{0:X8}' -f $_ } else { [string]$_ }
    }) + @('--count', [string]$Count))
