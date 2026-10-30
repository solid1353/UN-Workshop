$ErrorActionPreference = 'Stop'

$pythonArguments = [Collections.Generic.List[string]]::new()
foreach ($token in $args) {
    $value = [string]$token
    $pythonArguments.Add($(switch ($value.ToLowerInvariant()) {
        '-line' { '--line' }
        '-port' { '--port' }
        '-watch' { '--watch' }
        '-expect' { '--expect' }
        default { $value }
    }))
}

& (Join-Path $PSScriptRoot '..\lib\run_python.ps1') `
    -Script (Join-Path $PSScriptRoot 'pnach.py') `
    -Repository (Join-Path $PSScriptRoot '..\..') `
    -NoBytecode `
    -ArgumentList @($pythonArguments)
exit $LASTEXITCODE
