[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $repository 'scripts\lib\console_help.ps1')
. (Join-Path $repository 'tests\console_help_assertions.ps1')

# User-requested contract: each help block has one explanation column,
# four spaces after its longest command, including continuation alignment.
$lines = @(Get-UnConsoleHelp -Path (Join-Path $repository 'CLI.txt') -Values @{
    SOURCES = 'EXAMPLE'
    PROPERTIES = 'example'
})
Assert-ConsoleHelpLayout -Lines $lines -Label 'Workshop CLI.txt'
