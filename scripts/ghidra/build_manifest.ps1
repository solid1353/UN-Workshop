param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('NA2', 'NUN3', 'NUN4', 'NUN5', 'shared')]
    [string]$Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
. (Join-Path $PSScriptRoot '..\lib\source_paths.ps1')
$paths = Get-UnWorkshopPaths -NoProject

function Resolve-SourceAlias([string]$Alias) {
    return Resolve-UnWorkshopSourceAlias -Alias $Alias -Paths $paths
}

function Get-SharingGames([object]$Item) {
    $child = [regex]::Match($Item.source, '^@source_[^/\\]+[/\\](?<child>.+)$').Groups['child'].Value
    @(foreach ($root in Get-UnWorkshopSourceRoots -Paths $paths) {
        $candidate = Join-Path $root.Path $child
        if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and
            (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -eq $Item.expected_sha256) {
            $root.Game
        }
    }) -join ' '
}

$analysisRoot = Join-Path $paths.disassembly $Target
$targets = @(Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'targets.tsv') -Delimiter "`t" |
    Where-Object target -eq $Target)
if ($targets.Count -eq 0) { throw "No manifest targets found for $Target" }

$versionLine = Get-Content -LiteralPath (Join-Path $paths.Tools 'ghidra\Ghidra\application.properties') |
    Where-Object { $_ -like 'application.version=*' } |
    Select-Object -First 1
if (-not $versionLine) { throw 'Ghidra application version was not found.' }
$ghidraVersion = $versionLine.Substring('application.version='.Length)

$rows = foreach ($item in $targets) {
    $summaryPath = Join-Path $analysisRoot "summaries\$($item.program).tsv"
    $exportRoot = Join-Path $analysisRoot "exports\$($item.program)"
    $cPath = Join-Path $exportRoot "$($item.program).c"
    $asciiPath = Join-Path $exportRoot "$($item.program).txt"
    $markerPath = Join-Path $exportRoot 'export.complete'
    foreach ($required in @($summaryPath, $cPath, $asciiPath, $markerPath)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing analysis artifact: $required" }
    }

    $summary = Import-Csv -LiteralPath $summaryPath -Delimiter "`t"
    if ($summary.source -ne $item.source -or $summary.sha256 -ne $item.expected_sha256) {
        throw "Summary identity mismatch: $Target/$($item.program)"
    }
    $sourcePath = Resolve-SourceAlias $item.source
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    if ($sourceHash -ne $item.expected_sha256) { throw "Source hash mismatch: $($item.source)" }

    $cFile = Get-Item -LiteralPath $cPath
    $asciiFile = Get-Item -LiteralPath $asciiPath
    if ($cFile.Length -eq 0 -or $asciiFile.Length -eq 0) { throw "Empty export: $Target/$($item.program)" }
    $marker = ConvertFrom-StringData (Get-Content -Raw -LiteralPath $markerPath)
    if ([int64]$marker.c_bytes -ne $cFile.Length -or
        [int64]$marker.ascii_bytes -ne $asciiFile.Length -or
        $marker.ascii_undefined_data -ne 'false') {
        throw "Export marker mismatch: $Target/$($item.program)"
    }

    $row = [ordered]@{
        program = $item.program
        source = $item.source
        source_sha256 = $item.expected_sha256
        source_bytes = (Get-Item -LiteralPath $sourcePath).Length
        format = $item.format
        language = $summary.language
        load_base = $summary.load_base
        memory_blocks = $summary.memory_blocks
        functions = $summary.functions
        instructions = $summary.instructions
        c_export_bytes = $cFile.Length
        ascii_export_bytes = $asciiFile.Length
        ascii_undefined_data = 'false'
        ghidra_version = $ghidraVersion
    }
    if ($Target -eq 'shared') { $row.Insert(1, 'games', (Get-SharingGames $item)) }
    [pscustomobject]$row
}

$manifestPath = Join-Path $analysisRoot 'manifest.tsv'
$rows | Export-Csv -LiteralPath $manifestPath -Delimiter "`t" -NoTypeInformation -Encoding utf8
Write-Host "Verified analysis manifest: $(ConvertTo-UnWorkshopConfiguredPath -Path $manifestPath -Paths $paths)"
Write-Host "Programs: $($rows.Count)"
