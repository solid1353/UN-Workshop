[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$WorkRoot,
    [string]$GhidraRoot = (Join-Path $PSScriptRoot '..\..\tools\ghidra'),
    [string]$JavaHome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$upstreamUrl = 'https://github.com/symgraph/GhidrAssistMCP.git'
$upstreamCommit = '0d412d1fe3203e98a32f7dc70df21dc8f6f57131'
$releaseUrl = (
    'https://github.com/symgraph/GhidrAssistMCP/releases/download/2.11.0/' +
    'ghidra_12.1_PUBLIC_20260802_GhidrAssistMCP.zip'
)
$releaseSha256 = 'BABA204A9FE839921A1487BE9DFB15526FAEA787E5E4312C8404281D82B3A1A7'
$patchPath = Join-Path $PSScriptRoot 'ghidrassistmcp-2.11.0-read-only.patch'
$routerProject = Join-Path $PSScriptRoot 'GhidrAssistMcpRouter\GhidrAssistMcpRouter.csproj'
$managerScript = Join-Path $PSScriptRoot 'manage_ghidrassist_mcp.ps1'

function Assert-ChildPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Root
    )

    $resolvedPath = [IO.Path]::GetFullPath($Path)
    $resolvedRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if (-not $resolvedPath.StartsWith(
        $resolvedRoot + '\',
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Path is outside the expected root: $resolvedPath"
    }
    return $resolvedPath
}

function Remove-ExactChild {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Root
    )

    $resolvedPath = Assert-ChildPath -Path $Path -Root $Root
    if (Test-Path -LiteralPath $resolvedPath) {
        Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    }
}

function Stop-InstalledRouterProcesses {
    param([Parameter(Mandatory)][string]$Executable)

    $taskName = 'UNWorkshop-GhidrAssistMCP'
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    $restartTask = $null -ne $task -and [string]$task.State -eq 'Running'
    if ($restartTask) {
        & $managerScript -Action Stop | Out-Null
    }

    $resolvedExecutable = [IO.Path]::GetFullPath($Executable)
    $deadline = [datetime]::UtcNow.AddSeconds(10)
    do {
        $routerProcesses = @(
            Get-CimInstance Win32_Process -Filter "Name = 'GhidrAssistMcpRouter.exe'" |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.ExecutablePath) -and
                    [string]::Equals(
                        [IO.Path]::GetFullPath($_.ExecutablePath),
                        $resolvedExecutable,
                        [StringComparison]::OrdinalIgnoreCase
                    )
                }
        )
        if ($routerProcesses.Count -eq 0) {
            return $restartTask
        }
        foreach ($process in $routerProcesses) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 100
    } while ([datetime]::UtcNow -lt $deadline)

    throw "Installed GhidrAssist MCP router processes did not stop: $resolvedExecutable"
}

function Open-ZipArchiveForUpdate {
    param([Parameter(Mandatory)][string]$Path)

    $attempts = 20
    for ($attempt = 1; $attempt -le $attempts; $attempt++) {
        try {
            return [IO.Compression.ZipFile]::Open(
                $Path,
                [IO.Compression.ZipArchiveMode]::Update
            )
        }
        catch [IO.IOException] {
            if ($attempt -eq $attempts) {
                throw
            }
            Start-Sleep -Milliseconds 250
        }
    }
}

$resolvedWorkRoot = [IO.Path]::GetFullPath($WorkRoot)
$resolvedGhidraRoot = [IO.Path]::GetFullPath($GhidraRoot)
$applicationProperties = Join-Path $resolvedGhidraRoot 'Ghidra\application.properties'
$headless = Join-Path $resolvedGhidraRoot 'support\analyzeHeadless.bat'
$installedExtensions = Assert-ChildPath `
    -Path (Join-Path $resolvedGhidraRoot 'Ghidra\Extensions') `
    -Root $resolvedGhidraRoot
$emotionEngineZip = Join-Path $resolvedGhidraRoot (
    'ghidra_12.1.2_PUBLIC_20260607_ghidra-emotionengine-reloaded.zip'
)

if (-not (Test-Path -LiteralPath $applicationProperties -PathType Leaf)) {
    throw "Ghidra application properties were not found: $applicationProperties"
}
if (-not (Test-Path -LiteralPath $headless -PathType Leaf)) {
    throw "Ghidra headless launcher was not found: $headless"
}
if (-not (Test-Path -LiteralPath $emotionEngineZip -PathType Leaf)) {
    throw "EmotionEngine extension was not found: $emotionEngineZip"
}
if (-not (Test-Path -LiteralPath $patchPath -PathType Leaf)) {
    throw "GhidrAssistMCP hardening patch was not found: $patchPath"
}
if (-not (Test-Path -LiteralPath $routerProject -PathType Leaf)) {
    throw "GhidrAssist MCP router project was not found: $routerProject"
}

$properties = Get-Content -LiteralPath $applicationProperties
if ($properties -notcontains 'application.version=12.1.2' -or
    $properties -notcontains 'application.release.name=PUBLIC') {
    throw "The configured Ghidra installation is not 12.1.2 PUBLIC: $resolvedGhidraRoot"
}

if (-not $JavaHome) {
    . (Join-Path $PSScriptRoot 'runtime.ps1')
    $JavaHome = Find-GhidraJavaHome
}
$resolvedJavaHome = [IO.Path]::GetFullPath($JavaHome)
$javac = Join-Path $resolvedJavaHome 'bin\javac.exe'
if (-not (Test-Path -LiteralPath $javac -PathType Leaf)) {
    throw "JDK compiler was not found: $javac"
}
$javaVersion = & (Join-Path $resolvedJavaHome 'bin\java.exe') -version 2>&1
if ($LASTEXITCODE -ne 0 -or $javaVersion[0] -notmatch 'version "(2[5-9]|[3-9][0-9])') {
    throw "GhidrAssistMCP source builds require JDK 25 or newer: $resolvedJavaHome"
}

New-Item -ItemType Directory -Force -Path $resolvedWorkRoot | Out-Null
$runRoot = Assert-ChildPath `
    -Path (Join-Path $resolvedWorkRoot 'ghidrassistmcp-install') `
    -Root $resolvedWorkRoot
if (Test-Path -LiteralPath $runRoot) {
    throw "Installer work directory already exists: $runRoot"
}

$sourceRoot = Join-Path $runRoot 'source'
$releaseZip = Join-Path $runRoot 'release.zip'
$unpackRoot = Join-Path $runRoot 'unpacked'
$classesRoot = Join-Path $runRoot 'classes'
$routerStage = Join-Path $runRoot 'router\publish'
$routerObjectRoot = Join-Path $runRoot 'router\obj'
$routerBinaryRoot = Join-Path $runRoot 'router\bin'
$restartRouterTask = $false

try {
    New-Item -ItemType Directory -Path $runRoot | Out-Null
    & git clone --filter=blob:none --no-checkout $upstreamUrl $sourceRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to clone the pinned GhidrAssistMCP source.'
    }
    & git -C $sourceRoot checkout --detach $upstreamCommit
    if ($LASTEXITCODE -ne 0 -or
        (& git -C $sourceRoot rev-parse HEAD) -cne $upstreamCommit) {
        throw "GhidrAssistMCP checkout did not resolve to $upstreamCommit."
    }
    & git -C $sourceRoot apply --check $patchPath
    if ($LASTEXITCODE -ne 0) {
        throw 'The read-only hardening patch does not apply to the pinned source.'
    }
    & git -C $sourceRoot apply --whitespace=nowarn $patchPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to apply the read-only hardening patch.'
    }
    & git -C $sourceRoot diff --check
    if ($LASTEXITCODE -ne 0) {
        throw 'The hardened GhidrAssistMCP source has whitespace errors.'
    }

    Invoke-WebRequest -Uri $releaseUrl -OutFile $releaseZip
    $actualReleaseHash = (Get-FileHash -LiteralPath $releaseZip -Algorithm SHA256).Hash
    if ($actualReleaseHash -cne $releaseSha256) {
        throw (
            "GhidrAssistMCP release hash mismatch: expected $releaseSha256, " +
            "got $actualReleaseHash"
        )
    }
    Expand-Archive -LiteralPath $releaseZip -DestinationPath $unpackRoot
    $extensionRoot = Join-Path $unpackRoot 'GhidrAssistMCP'
    $libRoot = Join-Path $extensionRoot 'lib'

    $retiredLibraries = @(
        'itu-1.10.3.jar',
        'jackson-annotations-2.18.3.jar',
        'jackson-core-2.18.3.jar',
        'jackson-databind-2.18.3.jar',
        'jackson-dataformat-yaml-2.18.3.jar',
        'json-schema-validator-1.5.7.jar',
        'mcp-0.14.1.jar',
        'mcp-0.17.0.jar',
        'mcp-core-0.14.1.jar',
        'mcp-core-0.17.0.jar',
        'mcp-json-0.14.1.jar',
        'mcp-json-0.17.0.jar',
        'mcp-json-jackson2-0.14.1.jar',
        'mcp-json-jackson2-0.17.0.jar',
        'slf4j-api-2.0.16.jar',
        'snakeyaml-2.3.jar'
    )
    foreach ($library in $retiredLibraries) {
        $libraryPath = Assert-ChildPath -Path (Join-Path $libRoot $library) -Root $libRoot
        if (-not (Test-Path -LiteralPath $libraryPath -PathType Leaf)) {
            throw "Expected stale release library was not found: $library"
        }
        Remove-Item -LiteralPath $libraryPath -Force
    }

    New-Item -ItemType Directory -Path $classesRoot | Out-Null
    $ghidraLibraryDirectories = Get-ChildItem `
        -LiteralPath (Join-Path $resolvedGhidraRoot 'Ghidra') `
        -Recurse `
        -Filter '*.jar' `
        -File |
        ForEach-Object DirectoryName |
        Sort-Object -Unique
    $classPath = (@(Join-Path $libRoot '*') + @(
        $ghidraLibraryDirectories | ForEach-Object { Join-Path $_ '*' }
    )) -join ';'
    $sourceFiles = Get-ChildItem `
        -LiteralPath (Join-Path $sourceRoot 'src\main\java') `
        -Recurse `
        -Filter '*.java' `
        -File |
        Select-Object -ExpandProperty FullName
    & $javac --release 21 -cp $classPath -d $classesRoot $sourceFiles
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to compile the pinned hardened GhidrAssistMCP source.'
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $mainJar = Join-Path $libRoot 'GhidrAssistMCP.jar'
    $jarArchive = Open-ZipArchiveForUpdate -Path $mainJar
    try {
        @($jarArchive.Entries | Where-Object FullName -Like '*.class') |
            ForEach-Object Delete
        Get-ChildItem -LiteralPath $classesRoot -Recurse -Filter '*.class' -File |
            ForEach-Object {
                $entryName = $_.FullName.Substring($classesRoot.Length + 1).Replace('\', '/')
                [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $jarArchive,
                    $_.FullName,
                    $entryName,
                    [IO.Compression.CompressionLevel]::Optimal
                ) | Out-Null
            }
    }
    finally {
        $jarArchive.Dispose()
    }

    $generatedDebris = @(
        '.claude',
        'CLAUDE.md',
        'ghidrassist_analysis.db',
        'ghidrassist_rlhf.db',
        'lucene',
        'lib\GhidrAssistMCP-src.zip'
    )
    foreach ($relativePath in $generatedDebris) {
        Remove-ExactChild `
            -Path (Join-Path $extensionRoot $relativePath) `
            -Root $extensionRoot
    }

    $extensionProperties = Join-Path $extensionRoot 'extension.properties'
    $extensionText = [IO.File]::ReadAllText($extensionProperties)
    $extensionText = [Text.RegularExpressions.Regex]::Replace(
        $extensionText,
        '(?m)^version=.*$',
        'version=12.1.2'
    )
    [IO.File]::WriteAllText(
        $extensionProperties,
        $extensionText,
        [Text.UTF8Encoding]::new($false)
    )

    $dotnet = (Get-Command dotnet.exe -ErrorAction Stop).Source
    & $dotnet publish $routerProject `
        --configuration Release `
        --output $routerStage `
        -p:DebugType=None `
        -p:DebugSymbols=false `
        "-p:BaseIntermediateOutputPath=$routerObjectRoot\" `
        "-p:BaseOutputPath=$routerBinaryRoot\"
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to publish the GhidrAssist MCP stdio router.'
    }
    $routerExecutable = Join-Path $routerStage 'GhidrAssistMcpRouter.exe'
    if (-not (Test-Path -LiteralPath $routerExecutable -PathType Leaf)) {
        throw "Published GhidrAssist MCP router was not found: $routerExecutable"
    }

    $installedRouter = Assert-ChildPath `
        -Path (Join-Path $resolvedGhidraRoot 'GhidrAssistMcpRouter') `
        -Root $resolvedGhidraRoot
    $installedRouterExecutable = Join-Path $installedRouter 'GhidrAssistMcpRouter.exe'
    $restartRouterTask = Stop-InstalledRouterProcesses `
        -Executable $installedRouterExecutable

    New-Item -ItemType Directory -Force -Path $installedExtensions | Out-Null
    $installedMcp = Assert-ChildPath `
        -Path (Join-Path $installedExtensions 'GhidrAssistMCP') `
        -Root $installedExtensions
    Remove-ExactChild -Path $installedMcp -Root $installedExtensions
    Copy-Item -LiteralPath $extensionRoot -Destination $installedMcp -Recurse

    $installedEmotionEngine = Assert-ChildPath `
        -Path (Join-Path $installedExtensions 'ghidra-emotionengine-reloaded') `
        -Root $installedExtensions
    if (-not (Test-Path -LiteralPath $installedEmotionEngine -PathType Container)) {
        Expand-Archive -LiteralPath $emotionEngineZip -DestinationPath $installedExtensions
    }
    $emotionProperties = Join-Path $installedEmotionEngine 'extension.properties'
    if (-not (Test-Path -LiteralPath $emotionProperties -PathType Leaf) -or
        (Get-Content -LiteralPath $emotionProperties) -notcontains 'version=12.1.2') {
        throw 'The installed EmotionEngine extension is not compatible with Ghidra 12.1.2.'
    }

    Remove-ExactChild -Path $installedRouter -Root $resolvedGhidraRoot
    Copy-Item -LiteralPath $routerStage -Destination $installedRouter -Recurse
    if (-not (Test-Path -LiteralPath $installedRouterExecutable -PathType Leaf)) {
        throw 'The installed GhidrAssist MCP router is incomplete.'
    }

    if ($restartRouterTask) {
        & $managerScript -Action Start | Out-Null
    }

    $installedJar = Join-Path $installedMcp 'lib\GhidrAssistMCP.jar'
    [pscustomobject]@{
        UpstreamCommit = $upstreamCommit
        ReleaseSha256 = $releaseSha256
        InstalledJarSha256 = (
            Get-FileHash -LiteralPath $installedJar -Algorithm SHA256
        ).Hash
        ExtensionPath = $installedMcp
        EmotionEnginePath = $installedEmotionEngine
        BridgePath = $installedRouterExecutable
        Transport = 'stdio'
    }
}
finally {
    if (Test-Path -LiteralPath $runRoot) {
        Remove-ExactChild -Path $runRoot -Root $resolvedWorkRoot
    }
}
