[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Action,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$scripts = $paths.Roots.pcsx2_scripts

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Action)) {
    ''
} else { $Action.ToLowerInvariant() }

switch ($normalizedCommand) {
    '' {
        & (Join-Path $scripts 'input.ps1') -All
    }
    'ss' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -eq 0) {
            throw 'Usage: workshop ss move|extract ...'
        }
        $cleanup = $false
        $forwardedArguments = @(
            foreach ($argument in $argumentList) {
                if ($argument -ieq '-c' -or $argument -ieq '-Cleanup') {
                    $cleanup = $true
                }
                else {
                    $argument
                }
            }
        )
        $parameters = @{}
        if ($cleanup) { $parameters.Cleanup = $true }
        & (Join-Path $scripts 'savestates.ps1') @forwardedArguments @parameters
    }
    'help' {
        @(
            'UN Workshop'
            ''
            '  ws                     Regenerate every input profile'
            '  ws <profile>           Regenerate and assign one input profile'
            '  ws ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]'
            '  ws ss extract <paths...>'
            ''
        ) | Write-Output
    }
    default {
        if (@($Arguments).Count -gt 0) {
            throw 'Usage: workshop [profile]'
        }
        & (Join-Path $scripts 'input.ps1') -Profile $Action
    }
}
