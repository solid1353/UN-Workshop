[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\lib\paths.ps1')
$paths = Get-UnWorkshopPaths
$scripts = $paths.Roots.pcsx2_scripts

$normalizedCommand = if ([string]::IsNullOrWhiteSpace($Command)) {
    ''
} else { $Command.ToLowerInvariant() }

switch ($normalizedCommand) {
    'input' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -gt 1) {
            throw 'Usage: workshop input [profile]'
        }
        $parameters = @{}
        if ($argumentList.Count -eq 1) {
            $parameters.Profile = $argumentList[0]
        }
        & (Join-Path $scripts 'input.ps1') @parameters
    }
    'ss' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -eq 0) {
            throw 'Usage: workshop ss move|extract ...'
        }
        & (Join-Path $scripts 'savestates.ps1') @argumentList
    }
    { [string]::IsNullOrWhiteSpace($_) -or $_ -eq 'help' } {
        @(
            'UN Workshop'
            ''
            '  ws input [profile]'
            '  ws ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]'
            '  ws ss extract <paths...>'
            ''
        ) | Write-Output
    }
    default {
        throw "Unknown Workshop command: $Command"
    }
}
