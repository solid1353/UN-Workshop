param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('move', 'extract')]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments,

    [ValidateSet('stable', 'dev')]
    [string]$Target,

    [Alias('c')]
    [switch]$Cleanup,

    [string]$ProjectRoot,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

switch ($Command) {
    'move' {
        if ($Arguments.Count -ne 2) {
            throw 'Usage: savestates.ps1 move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]'
        }

        $parameters = @{
            Game = $Arguments[0]
            SubPath = $Arguments[1]
        }
        if ($PSBoundParameters.ContainsKey('Target')) {
            $parameters.Target = $Target
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
        if ($PSBoundParameters.ContainsKey('Target') -or $Cleanup -or $WhatIf) {
            throw '-Target, -Cleanup, and -WhatIf apply only to the move command.'
        }
        & (Join-Path $PSScriptRoot 'extract_savestate_screenshots.ps1') @Arguments
    }
}
