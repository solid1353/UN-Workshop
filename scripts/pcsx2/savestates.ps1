param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('move', 'extract')]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments,

    [Alias('c')]
    [switch]$Cleanup,

    [string]$ProjectRoot,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')

switch ($Command) {
    'move' {
        if ($Arguments.Count -ne 2) {
            throw 'Usage: savestates.ps1 move <game> <subpath> [-Cleanup|-c]'
        }

        $parameters = @{
            Game = $Arguments[0]
            SubPath = $Arguments[1]
        }
        if ($Cleanup) {
            $parameters.Cleanup = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
            $parameters.ProjectRoot = $ProjectRoot
        }
        if ($WhatIf) {
            $parameters.WhatIf = $true
        }
        & (Join-Path $PSScriptRoot 'move_savestates.ps1') @parameters
    }
    'extract' {
        if ($Cleanup -or $WhatIf) {
            throw '-Cleanup and -WhatIf apply only to the move command.'
        }
        $extractArguments = @($Arguments)
        if (
            $extractArguments.Count -eq 1 -and
            -not (Test-Path -LiteralPath $extractArguments[0])
        ) {
            $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
            $extractArguments[0] = Join-Path `
                -Path $paths.Savestates `
                -ChildPath $extractArguments[0]
        }
        & (Join-Path $PSScriptRoot 'extract_savestate_screenshots.ps1') @extractArguments
    }
}
