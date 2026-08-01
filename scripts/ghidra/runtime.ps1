Set-StrictMode -Version Latest

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
        [string]$Version = '12.1.2_PUBLIC',
        [string]$MaximumMemory = '2G'
    )

    $runtime = [IO.Path]::GetFullPath($RuntimeRoot)
    $tools = [IO.Path]::GetFullPath($ToolsRoot)
    $settingsRoot = Join-Path $runtime "AppData\Roaming\ghidra\ghidra_$Version"
    $extensionsRoot = Join-Path $settingsRoot 'Extensions'
    $extensionDirectory = Join-Path $extensionsRoot 'ghidra-emotionengine-reloaded'
    $extensionZip = Join-Path $tools (
        "ghidra\ghidra_${Version}_20260607_ghidra-emotionengine-reloaded.zip"
    )
    $headless = Join-Path $tools 'ghidra\support\analyzeHeadless.bat'
    if (-not (Test-Path -LiteralPath $headless -PathType Leaf)) {
        throw "Ghidra headless launcher was not found: $headless"
    }
    if (-not (Test-Path -LiteralPath $extensionZip -PathType Leaf)) {
        throw "Ghidra EmotionEngine extension was not found: $extensionZip"
    }

    New-Item -ItemType Directory -Force -Path $runtime, $extensionsRoot | Out-Null
    if (-not (Test-Path -LiteralPath $extensionDirectory -PathType Container)) {
        Expand-Archive -LiteralPath $extensionZip -DestinationPath $extensionsRoot
    }

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
