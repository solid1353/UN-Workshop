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
    'resolve' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -lt 1 -or $argumentList.Count -gt 2) {
            throw 'Usage: workshop resolve <game> [property]'
        }
        $resolved = Resolve-UnWorkshopGame `
            -Game $argumentList[0] `
            -ProjectRoot $paths.Project
        if ($argumentList.Count -eq 1) {
            $resolved | Write-Output
            break
        }
        $property = @(
            $resolved.PSObject.Properties |
                Where-Object { $_.Name -ieq $argumentList[1] }
        )
        if ($property.Count -ne 1) {
            throw "Unknown resolved game property: $($argumentList[1])"
        }
        $property[0].Value | Write-Output
    }
    'input' {
        $argumentList = @($Arguments)
        if ($argumentList.Count -gt 1) {
            throw 'Usage: workshop input [profile]'
        }
        $parameters = @{}
        if ($argumentList.Count -eq 0) {
            $parameters.All = $true
        }
        else {
            $parameters.Profile = $argumentList[0]
        }
        & (Join-Path $scripts 'input.ps1') @parameters
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
    { [string]::IsNullOrWhiteSpace($_) -or $_ -eq 'help' } {
        @(
            'UN Workshop'
            ''
            '  workshop resolve <game> [property]'
            '  workshop input [profile]'
            '  workshop ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]'
            '  workshop ss extract <paths...>'
            ''
        ) | Write-Output
    }
    default {
        throw "Unknown Workshop command: $Action"
    }
}
