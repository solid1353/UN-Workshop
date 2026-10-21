Set-StrictMode -Version Latest

$GhidraVersion = '12.1.3'
# Processor extension release zips, kept in @tools/ghidra beside the installation.
$GhidraProcessorExtensions = @(
    'ghidra_12.1.3_PUBLIC_20261004_ghidra-emotionengine-reloaded.zip'
    'ghidra_12.1.3_PUBLIC_20260825_ghidra-allegrex.zip'
)

# Unpacks each processor extension that is not installed yet; -Replace unpacks all of them again.
function Install-GhidraProcessorExtensions {
    param(
        [Parameter(Mandatory)]
        [string]$GhidraRoot,
        [switch]$Replace
    )

    $extensionsRoot = Join-Path $GhidraRoot 'Ghidra\Extensions'
    New-Item -ItemType Directory -Force -Path $extensionsRoot | Out-Null
    foreach ($zipName in $GhidraProcessorExtensions) {
        $zip = Join-Path $GhidraRoot $zipName
        if (-not (Test-Path -LiteralPath $zip -PathType Leaf)) {
            throw "Ghidra processor extension was not found: $zip"
        }
        $name = [regex]::Match($zipName, '^ghidra_[^_]+_PUBLIC_\d+_(?<name>.+)\.zip$').Groups['name'].Value
        $directory = Join-Path $extensionsRoot $name
        if ($Replace -and (Test-Path -LiteralPath $directory)) {
            Remove-Item -LiteralPath $directory -Recurse -Force
        }
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            Expand-Archive -LiteralPath $zip -DestinationPath $extensionsRoot
        }
        $properties = Join-Path $directory 'extension.properties'
        if (-not (Test-Path -LiteralPath $properties -PathType Leaf) -or
            (Get-Content -LiteralPath $properties) -notcontains "version=$GhidraVersion") {
            throw "Ghidra processor extension is not built for Ghidra ${GhidraVersion}: $name"
        }
    }
}

function Find-GhidraJavaHome {
    $java = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($java) {
        return Split-Path (Split-Path $java.Source -Parent) -Parent
    }
    $jetBrainsRoot = Join-Path $env:ProgramFiles 'JetBrains'
    $javaItem = Get-ChildItem `
        -LiteralPath $jetBrainsRoot `
        -Directory `
        -Filter 'JetBrains Rider *' `
        -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object {
            Get-Item `
                -LiteralPath (Join-Path $_.FullName 'jbr\bin\java.exe') `
                -ErrorAction SilentlyContinue
        } |
        Select-Object -First 1
    if (-not $javaItem) { throw 'A Ghidra-compatible JDK was not found.' }
    return Split-Path (Split-Path $javaItem.FullName -Parent) -Parent
}

function Initialize-GhidraRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RuntimeRoot,
        [string]$ToolsRoot = (Join-Path $PSScriptRoot '..\..\tools'),
        [string]$MaximumMemory = '2G'
    )

    $runtime = [IO.Path]::GetFullPath($RuntimeRoot)
    $tools = [IO.Path]::GetFullPath($ToolsRoot)
    $headless = Join-Path $tools 'ghidra\support\analyzeHeadless.bat'
    if (-not (Test-Path -LiteralPath $headless -PathType Leaf)) {
        throw "Ghidra headless launcher was not found: $headless"
    }
    Install-GhidraProcessorExtensions -GhidraRoot (Join-Path $tools 'ghidra')
    New-Item -ItemType Directory -Force -Path $runtime | Out-Null

    $javaHome = Find-GhidraJavaHome
    $env:USERPROFILE = $runtime
    $env:APPDATA = Join-Path $runtime 'AppData\Roaming'
    $env:LOCALAPPDATA = Join-Path $runtime 'AppData\Local'
    $env:JAVA_HOME = $javaHome
    $env:PATH = (Join-Path $javaHome 'bin') + ';' + $env:PATH
    $env:GHIDRA_HEADLESS_MAXMEM = $MaximumMemory
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA |
        Out-Null

    [pscustomobject]@{
        Headless = $headless
        ScriptPath = $PSScriptRoot
        RuntimeRoot = $runtime
    }
}
