param(
    [ValidateSet('all', 'NA2', 'NUN3', 'NUN4', 'NUN5', 'shared')]
    [string]$Target = 'all'
)

# Applies each game's annotation files to a fresh copy of its project, the way the MCP does
# when a backend starts, and lists every type or row that fails. It does not touch the MCP.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$taskContext = Get-UnWorkshopTaskContext
$paths = $taskContext.Paths
. $paths.files.ghidra_runtime

$games = if ($Target -eq 'all') {
    @(Get-ChildItem -LiteralPath $paths.Annotations -Directory | ForEach-Object Name)
} else { @($Target) }

$tempRoot = Join-Path $taskContext.Root 'temp'
$runtimeRoot = Join-Path $tempRoot ('ghidra_check-' + [Guid]::NewGuid().ToString('N'))
$runtimeEnvironment = @{}
foreach ($name in @('USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'JAVA_HOME', 'PATH', 'GHIDRA_HEADLESS_MAXMEM')) {
    $runtimeEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$failed = $false
try {
    $ghidra = Initialize-GhidraRuntime -RuntimeRoot $runtimeRoot -ToolsRoot $paths.Tools
    foreach ($game in $games) {
        $annotations = Join-Path $paths.Annotations $game
        $source = Join-Path $paths.disassembly "$game\ghidra"
        if (-not (Test-Path -LiteralPath $annotations -PathType Container) -or
            -not (Test-Path -LiteralPath $source -PathType Container)) { continue }
        $copy = Join-Path $runtimeRoot "project_$game"
        New-Item -ItemType Directory -Force -Path $copy | Out-Null
        Get-ChildItem -LiteralPath $source -Force | Where-Object Name -notlike '*.lock*' |
            Copy-Item -Destination $copy -Recurse -Force
        Get-ChildItem -LiteralPath $copy -Recurse -File | ForEach-Object { $_.IsReadOnly = $false }
        $project = (Get-ChildItem -LiteralPath $copy -Filter '*.gpr').BaseName
        $output = & $ghidra.Headless $copy $project -process -readOnly -noanalysis `
            -scriptPath $ghidra.ScriptPath -postScript CheckAnnotations.java $annotations 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Checking $game failed with exit code $LASTEXITCODE" }
        foreach ($line in $output) {
            $text = [string]$line
            $index = $text.IndexOf('CheckAnnotations.java> ')
            if ($index -lt 0) { continue }
            $message = $text.Substring($index + 'CheckAnnotations.java> '.Length) -replace '\s*\(GhidraScript\)\s*$', ''
            if ($message.StartsWith('FAIL ')) { $failed = $true }
            Write-Host "${game}: $message"
        }
        Remove-Item -LiteralPath $copy -Recurse -Force
    }
}
finally {
    foreach ($name in $runtimeEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $runtimeEnvironment[$name], 'Process')
    }
    if (Test-Path -LiteralPath $runtimeRoot -PathType Container) {
        Remove-Item -LiteralPath $runtimeRoot -Recurse -Force
    }
    if ((Test-Path -LiteralPath $tempRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $tempRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $tempRoot -Force
    }
}
if ($failed) { exit 1 }
