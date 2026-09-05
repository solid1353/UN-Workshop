Set-StrictMode -Version Latest

function Get-UnConsoleHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][Collections.IDictionary]$Values
    )

    $help = Get-Content -Raw -LiteralPath $Path
    foreach ($entry in $Values.GetEnumerator()) {
        $placeholder = '{{' + [string]$entry.Key + '}}'
        if (-not $help.Contains($placeholder)) {
            throw "Help placeholder not found: $placeholder"
        }
        $help = $help.Replace($placeholder, [string]$entry.Value)
    }

    $unresolved = [regex]::Match($help, '\{\{[A-Z][A-Z0-9_]*\}\}')
    if ($unresolved.Success) {
        throw "Help placeholder has no value: $($unresolved.Value)"
    }

    $help.TrimEnd([char[]]"`r`n") -split '\r?\n'
}
