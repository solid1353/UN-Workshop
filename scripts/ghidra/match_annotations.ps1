param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('NA2', 'NUN3', 'NUN4', 'NUN5', 'shared')]
    [string]$From,
    [Parameter(Mandatory = $true)]
    [ValidateSet('NA2', 'NUN3', 'NUN4', 'NUN5', 'shared')]
    [string]$To,
    [switch]$Apply
)

# Copies the annotations of exactly matching functions from one game to another: the same
# instructions apart from jump, call and address operands, with exactly one candidate on each
# side. Names and comments are copied, and prototypes whose types the target already declares;
# types are never copied and existing target rows are never replaced. Without -Apply it only
# reports the matches; with -Apply it records them through the MCP annotate_symbol tool.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
. (Join-Path $PSScriptRoot 'task_context.ps1')
$taskContext = Get-UnWorkshopGhidraTaskContext
$paths = $taskContext.Paths
. $paths.files.ghidra_runtime

if ($From -eq $To) { throw 'From and To must be different games.' }
# Master Mode is out of scope.
$excludedPrograms = @('ADV.BIN')
$minimumInstructions = 6

function Format-Address([string]$Address) {
    return '0x' + $Address.Substring(2).ToUpper()
}

function Read-Symbols([string]$Game, [string]$Program) {
    $path = Join-Path $paths.Annotations "$Game\$Program\symbols.tsv"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
    return @(Import-Csv -LiteralPath $path -Delimiter "`t" -Encoding UTF8)
}

function Get-Programs([string]$Game) {
    $manifest = Join-Path $paths.disassembly "$Game\manifest.tsv"
    return @(Import-Csv -LiteralPath $manifest -Delimiter "`t" |
        ForEach-Object program | Where-Object { $_ -notin $excludedPrograms })
}

function Get-DeclaredTypes([string]$Game) {
    $path = Join-Path $paths.Annotations "$Game\types.h"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @{} }
    $names = @{}
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($text, '\}\s*([A-Za-z_]\w*)\s*;|typedef[^;{}]*?\b([A-Za-z_]\w*)\s*;|\b(?:struct|union|enum)\s+([A-Za-z_]\w*)')) {
        foreach ($group in 1..3) {
            if ($match.Groups[$group].Success) { $names[$match.Groups[$group].Value] = $true }
        }
    }
    return $names
}

# True when every type a prototype names is a C base type or declared by the target game.
function Test-PrototypeTypes([string]$Prototype, [hashtable]$Declared) {
    $base = 'void', 'char', 'short', 'int', 'long', 'float', 'double', 'signed', 'unsigned',
        'const', 'volatile', 'struct', 'union', 'enum', 'bool', 'byte', 'uint', 'ushort', 'ulong',
        'undefined', 'undefined1', 'undefined2', 'undefined4', 'undefined8'
    $code = $Prototype -replace '\[[^\]]*\]', ''
    $open = $code.IndexOf('(')
    if ($open -lt 0) { return $false }
    $parts = @($code.Substring(0, $open)) + ($code.Substring($open + 1).TrimEnd(')', ' ') -split ',')
    foreach ($part in $parts) {
        $tokens = @([regex]::Matches($part, '[A-Za-z_]\w*') | ForEach-Object Value)
        # The last identifier of each part is the function or parameter name.
        if ($tokens.Count -gt 1) { $tokens = $tokens[0..($tokens.Count - 2)] }
        foreach ($token in $tokens) {
            if ($token -notin $base -and -not $Declared.ContainsKey($token)) { return $false }
        }
    }
    return $true
}

function Invoke-Fingerprints([string]$Game, [string]$OutputRoot) {
    $source = Join-Path $paths.disassembly "$Game\ghidra"
    $copy = Join-Path $runtimeRoot "project_$Game"
    New-Item -ItemType Directory -Force -Path $copy, $OutputRoot | Out-Null
    Get-ChildItem -LiteralPath $source -Force | Where-Object Name -notlike '*.lock*' |
        Copy-Item -Destination $copy -Recurse -Force
    Get-ChildItem -LiteralPath $copy -Recurse -File | ForEach-Object { $_.IsReadOnly = $false }
    $project = (Get-ChildItem -LiteralPath $copy -Filter '*.gpr').BaseName
    $arguments = @($copy, $project, '-process', '-readOnly', '-noanalysis',
        '-scriptPath', $ghidra.ScriptPath, '-postScript', 'FunctionSignatures.java', $OutputRoot)
    & $ghidra.Headless @arguments | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Fingerprinting $Game failed with exit code $LASTEXITCODE" }
}

function Invoke-AnnotateBatches([string]$Program, [object[]]$Rows) {
    $router = Join-Path $paths.Tools 'ghidra\GhidrAssistMcpRouter\GhidrAssistMcpRouter.exe'
    $start = [Diagnostics.ProcessStartInfo]::new($router)
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.UseShellExecute = $false
    $start.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $start.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    $process = [Diagnostics.Process]::Start($start)
    try {
        $state = @{ id = 0 }
        $send = {
            param($method, $params)
            $state.id++
            $process.StandardInput.WriteLine((@{ jsonrpc = '2.0'; id = $state.id; method = $method; params = $params } |
                ConvertTo-Json -Depth 10 -Compress))
            $process.StandardInput.Flush()
            return $process.StandardOutput.ReadLine() | ConvertFrom-Json
        }
        $null = & $send 'initialize' @{ protocolVersion = '2025-03-26'; capabilities = @{}; clientInfo = @{ name = 'match_annotations'; version = '1' } }
        $applied = 0
        for ($offset = 0; $offset -lt $Rows.Count; $offset += 200) {
            $batch = @($Rows[$offset..([Math]::Min($offset + 199, $Rows.Count - 1))] | ForEach-Object {
                @{ address = $_.address; kind = $_.kind; name = $_.name; type = $_.type; comment = $_.comment }
            })
            $response = & $send 'tools/call' @{ name = 'annotate_symbol'; arguments = @{ target = $To; program_name = $Program; rows = $batch } }
            $text = ($response.result.content | ForEach-Object text) -join ' '
            if ($response.result.isError) { throw "$Program rejected a batch: $text" }
            $applied += $batch.Count
        }
        return $applied
    }
    finally {
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(30000)) { $process.Kill() }
        $process.Dispose()
    }
}

$tempRoot = Join-Path $taskContext.Root 'temp'
$runtimeRoot = Join-Path $tempRoot ('ghidra_match-' + [Guid]::NewGuid().ToString('N'))
$runtimeEnvironment = @{}
foreach ($name in @('USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'JAVA_HOME', 'PATH', 'GHIDRA_HEADLESS_MAXMEM')) {
    $runtimeEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
try {
    $ghidra = Initialize-GhidraRuntime -RuntimeRoot $runtimeRoot -ToolsRoot $paths.Tools

    $sourceRows = @{}
    foreach ($program in Get-Programs $From) {
        $rows = @(Read-Symbols $From $program | Where-Object kind -eq 'function')
        if ($rows.Count -eq 0) { continue }
        $sourceRows[$program] = @{}
        foreach ($row in $rows) { $sourceRows[$program][(Format-Address $row.address)] = $row }
    }
    if ($sourceRows.Count -eq 0) { throw "$From has no function annotations." }

    # Every source function is fingerprinted so that an annotated function whose code also
    # appears elsewhere in the source game counts as ambiguous.
    $sourcePrints = Join-Path $runtimeRoot 'source'
    $targetPrints = Join-Path $runtimeRoot 'target'
    Invoke-Fingerprints $From $sourcePrints
    Invoke-Fingerprints $To $targetPrints

    $targetPrograms = Get-Programs $To
    $targetByHash = @{}
    foreach ($program in $targetPrograms) {
        $file = Join-Path $targetPrints "$program.tsv"
        if (-not (Test-Path -LiteralPath $file)) { continue }
        foreach ($print in Import-Csv -LiteralPath $file -Delimiter "`t") {
            if ([int]$print.instructions -lt $minimumInstructions) { continue }
            if (-not $targetByHash.ContainsKey($print.hash)) { $targetByHash[$print.hash] = @() }
            $targetByHash[$print.hash] += [pscustomobject]@{ Program = $program; Address = (Format-Address $print.address) }
        }
    }
    $sourceHashCounts = @{}
    $sourcePrintList = @()
    foreach ($program in Get-Programs $From) {
        $file = Join-Path $sourcePrints "$program.tsv"
        if (-not (Test-Path -LiteralPath $file)) { continue }
        foreach ($print in Import-Csv -LiteralPath $file -Delimiter "`t") {
            $sourceHashCounts[$print.hash] = 1 + [int]$sourceHashCounts[$print.hash]
            if ([int]$print.instructions -lt $minimumInstructions) { continue }
            $address = Format-Address $print.address
            if ($sourceRows.ContainsKey($program) -and $sourceRows[$program].ContainsKey($address)) {
                $sourcePrintList += [pscustomobject]@{ Program = $program; Address = $address; Hash = $print.hash }
            }
        }
    }

    $declared = Get-DeclaredTypes $To
    $candidates = @{}
    $counts = [ordered]@{ fingerprinted = $sourcePrintList.Count; ambiguous = 0; unmatched = 0
        already_annotated = 0; name_taken = 0; matched = 0; prototypes_kept = 0 }
    $existing = @{}
    $takenNames = @{}
    foreach ($program in $targetPrograms) {
        $existing[$program] = @{}
        $takenNames[$program] = @{}
        foreach ($row in Read-Symbols $To $program) {
            $existing[$program][(Format-Address $row.address)] = $true
            $takenNames[$program][$row.name] = $true
        }
    }
    foreach ($print in $sourcePrintList) {
        $hits = @($targetByHash[$print.Hash] | Where-Object { $_ })
        if ($sourceHashCounts[$print.Hash] -ne 1 -or $hits.Count -gt 1) { $counts.ambiguous++; continue }
        if ($hits.Count -eq 0) { $counts.unmatched++; continue }
        $target = $hits[0]
        if ($existing[$target.Program].ContainsKey($target.Address)) { $counts.already_annotated++; continue }
        $row = $sourceRows[$print.Program][$print.Address]
        if ($takenNames[$target.Program].ContainsKey($row.name)) { $counts.name_taken++; continue }
        $type = ''
        if ($row.type -and (Test-PrototypeTypes $row.type $declared)) { $type = $row.type; $counts.prototypes_kept++ }
        $comment = "Inferred from an exact code match with $From $($print.Program) $($print.Address)."
        if ($row.comment) { $comment += " $($row.comment)" }
        if (-not $candidates.ContainsKey($target.Program)) { $candidates[$target.Program] = @() }
        $candidates[$target.Program] += [pscustomobject]@{ address = $target.Address; kind = 'function'
            name = $row.name; type = $type; comment = $comment }
        $takenNames[$target.Program][$row.name] = $true
        $counts.matched++
    }

    Write-Host "Annotation matches from $From to ${To}:"
    $counts.GetEnumerator() | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }
    foreach ($program in $candidates.Keys) {
        Write-Host ("  {0}: {1} matches" -f $program, $candidates[$program].Count)
        if ($Apply) {
            $applied = Invoke-AnnotateBatches $program $candidates[$program]
            Write-Host ("  {0}: {1} rows recorded" -f $program, $applied)
        }
    }
    if (-not $Apply -and $counts.matched -gt 0) { Write-Host 'Run again with -Apply to record them.' }
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
