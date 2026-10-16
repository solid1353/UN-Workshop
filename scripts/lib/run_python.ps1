[CmdletBinding(DefaultParameterSetName = 'Script')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Script')]
    [string]$Script,

    [Parameter(Mandatory = $true, ParameterSetName = 'Module')]
    [string]$Module,

    [Parameter(Mandatory = $true, ParameterSetName = 'Command')]
    [string]$Command,

    [string[]]$ArgumentList = @(),

    [switch]$NoBytecode,

    # A repository whose packages.json pins packages runs in its environment;
    # without one, the pinned interpreter runs directly.
    [string]$Repository
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'python_environment.ps1')
$runtime = Get-UnPython -Repository $Repository

$pythonArguments = [Collections.Generic.List[string]]::new()
if ($NoBytecode) {
    $pythonArguments.Add('-B')
}
switch ($PSCmdlet.ParameterSetName) {
    'Script' {
        $pythonArguments.Add($Script)
    }
    'Module' {
        $pythonArguments.Add('-m')
        $pythonArguments.Add($Module)
    }
    'Command' {
        $pythonArguments.Add('-c')
        $pythonArguments.Add($Command)
    }
}
foreach ($argument in $ArgumentList) {
    $pythonArguments.Add($argument)
}

& $runtime @pythonArguments
exit $LASTEXITCODE
