param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('NA2', 'NUN3', 'NUN4', 'NUN5', 'shared')]
    [string]$Target,
    [string]$Program
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
. (Join-Path $PSScriptRoot 'task_context.ps1')
$taskContext = Get-UnWorkshopGhidraTaskContext
$paths = $taskContext.Paths
. $paths.files.ghidra_runtime

$analysisRoot = Join-Path $paths.disassembly $Target
$projectRoot = Join-Path $analysisRoot 'ghidra'
$tempRoot = Join-Path $taskContext.Root 'temp'
$runtimeRoot = Join-Path $tempRoot (
    "ghidra_export_$Target-" + [Guid]::NewGuid().ToString('N')
)
$runtimeEnvironment = @{}
foreach ($name in @(
    'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'JAVA_HOME', 'PATH',
    'GHIDRA_HEADLESS_MAXMEM'
)) {
    $runtimeEnvironment[$name] = [Environment]::GetEnvironmentVariable(
        $name, 'Process'
    )
}

try {
    $ghidra = Initialize-GhidraRuntime `
        -RuntimeRoot $runtimeRoot `
        -ToolsRoot $paths.Tools
    $headless = $ghidra.Headless
    $sharedScriptPath = $ghidra.ScriptPath

    $exportRoot = Join-Path $analysisRoot 'exports'
    New-Item -ItemType Directory -Force -Path $exportRoot | Out-Null
    $arguments = @($projectRoot, $Target, '-process')
    if ($Program) { $arguments += $Program }
    $arguments += @(
        '-readOnly', '-noanalysis',
        '-scriptPath', $sharedScriptPath,
        '-postScript', 'ExportAnalysis.java', $exportRoot
    )
    & $headless @arguments
    if ($LASTEXITCODE -ne 0) { throw "Ghidra export failed with exit code $LASTEXITCODE" }
    & (Join-Path $PSScriptRoot 'build_manifest.ps1') -Target $Target
}
finally {
    foreach ($name in $runtimeEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable(
            $name, $runtimeEnvironment[$name], 'Process'
        )
    }
    if (Test-Path -LiteralPath $runtimeRoot -PathType Container) {
        Remove-Item -LiteralPath $runtimeRoot -Recurse -Force
    }
    if ((Test-Path -LiteralPath $tempRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $tempRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $tempRoot -Force
    }
}
