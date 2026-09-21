[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[^\\/:*?"<>|]+$')]
    [string]$Target,
    [string]$Program,
    [Parameter(Mandatory)]
    [ValidateRange(1, 65535)]
    [int]$Port,
    [string]$JavaHome,
    [ValidateRange(10, 300)]
    [int]$StartupTimeoutSeconds = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-SharedChildPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )

    $resolvedPath = [IO.Path]::GetFullPath($Path)
    $resolvedRoot = [IO.Path]::GetFullPath($Root)
    $prefix = $resolvedRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use a GhidrAssistMCP path outside @ghidra_mcp_work: $resolvedPath"
    }
    $resolvedPath
}

function Remove-SharedChild {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )

    $resolvedPath = Assert-SharedChildPath -Path $Path -Root $Root
    if (Test-Path -LiteralPath $resolvedPath) {
        Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    }
}

function Test-LocalPort {
    param([Parameter(Mandatory)][int]$CandidatePort)

    @(
        [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    ).Port -contains $CandidatePort
}

function Stop-OwnedProcessTree {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    if (-not $Process.HasExited) {
        & taskkill.exe /PID $Process.Id /T /F | Out-Null
    }
}

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory)][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    '"' + $Value.Replace('"', '\"') + '"'
}

function Get-ProjectPrograms {
    param(
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string]$ProjectLocation,
        [Parameter(Mandatory)][string]$ProjectName
    )

    $manifestPath = Join-Path $TargetRoot 'manifest.tsv'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        return @(
            Import-Csv -LiteralPath $manifestPath -Delimiter "`t" |
                ForEach-Object program |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    $indexPath = Join-Path $ProjectLocation "$ProjectName.rep\idata\~index.dat"
    if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
        return @()
    }
    @(
        Get-Content -LiteralPath $indexPath |
            ForEach-Object {
                if ($_ -match '^\s+\d+:(?<program>[^:]+):') {
                    $Matches.program
                }
            }
    )
}

. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
. (Join-Path $PSScriptRoot 'runtime.ps1')

$paths = Get-UnWorkshopPaths -NoProject
$ghidraRoot = Join-Path $paths.Tools 'ghidra'
$extensionRoot = Join-Path $ghidraRoot 'Ghidra\Extensions\GhidrAssistMCP'
$scriptPath = Join-Path $extensionRoot 'ghidra_scripts'
$serverScript = Join-Path $scriptPath 'GAMCPStartServerScript.java'
$headless = Join-Path $ghidraRoot 'support\analyzeHeadless.bat'

if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
    throw (
        'The hardened GhidrAssistMCP extension is not installed. Run ' +
        '@ghidra_scripts/install_ghidrassist_mcp.ps1 first.'
    )
}
if (-not (Test-Path -LiteralPath $headless -PathType Leaf)) {
    throw "Ghidra headless launcher was not found: $headless"
}

$sharedRoot = if ([string]::IsNullOrWhiteSpace($paths.GhidraMcpWork)) {
    throw 'The configured @ghidra_mcp_work root is missing.'
} else {
    [IO.Path]::GetFullPath($paths.GhidraMcpWork)
}
$targetRuntimeRoot = Assert-SharedChildPath `
    -Path (Join-Path $sharedRoot $Target) `
    -Root $sharedRoot
$runtimeProjectLocation = Assert-SharedChildPath `
    -Path (Join-Path $targetRuntimeRoot 'project') `
    -Root $sharedRoot
$logsRoot = Assert-SharedChildPath `
    -Path (Join-Path $targetRuntimeRoot 'logs') `
    -Root $sharedRoot
$controlRoot = Assert-SharedChildPath `
    -Path (Join-Path $targetRuntimeRoot 'control') `
    -Root $sharedRoot
$completionFile = Join-Path $controlRoot 'complete'
$hostPidFile = Join-Path $controlRoot 'host.pid'
$ghidraPidFile = Join-Path $controlRoot 'ghidra.pid'
$portFile = Join-Path $controlRoot 'port'
$hostLog = Join-Path $logsRoot 'host.log'
$applicationLog = Join-Path $logsRoot 'application.log'
$scriptLog = Join-Path $logsRoot 'script.log'

New-Item -ItemType Directory -Force -Path $logsRoot, $controlRoot | Out-Null
foreach ($logPath in @($hostLog, $applicationLog, $scriptLog)) {
    $previousPath = "$logPath.previous"
    if (Test-Path -LiteralPath $previousPath -PathType Leaf) {
        Remove-Item -LiteralPath $previousPath -Force
    }
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
        Move-Item -LiteralPath $logPath -Destination $previousPath
    }
}

$mutex = $null
$headlessProcess = $null

function Write-BackendHostLog {
    param([Parameter(Mandatory)][string]$Message)

    $line = "$(Get-Date -Format o) $Message"
    Add-Content -LiteralPath $hostLog -Value $line -Encoding utf8
    Write-Output $Message
}

try {
    $createdNew = $false
    $mutexName = "Local\UNWorkshop_GhidrAssistMCP_$Target"
    $mutex = [Threading.Mutex]::new($true, $mutexName, [ref]$createdNew)
    if (-not $createdNew) {
        throw "A GhidrAssistMCP backend is already running for $Target."
    }
    if (Test-LocalPort -CandidatePort $Port) {
        throw "Temporary backend port $Port is already in use."
    }

    Set-Content -LiteralPath $hostPidFile -Value $PID -Encoding ascii
    Set-Content -LiteralPath $portFile -Value $Port -Encoding ascii
    if (Test-Path -LiteralPath $completionFile -PathType Leaf) {
        Remove-Item -LiteralPath $completionFile -Force
    }

    $targetRoot = Join-Path $paths.Disassembly $Target
    $projectLocation = Join-Path $targetRoot 'ghidra'
    $projectFiles = @(Get-ChildItem -LiteralPath $projectLocation -Filter '*.gpr' -File)
    if ($projectFiles.Count -ne 1) {
        throw "@disassembly/$Target must contain exactly one Ghidra project."
    }
    $projectName = $projectFiles[0].BaseName
    $programs = @(Get-ProjectPrograms `
        -TargetRoot $targetRoot `
        -ProjectLocation $projectLocation `
        -ProjectName $projectName)
    if ($programs.Count -eq 0) {
        throw "No programs were discovered in @disassembly/$Target."
    }
    if ([string]::IsNullOrWhiteSpace($Program)) {
        $Program = [string]$programs[0]
    }
    if ($Program -cnotin $programs) {
        throw (
            "Program '$Program' is not in @disassembly/$Target. " +
            "Available programs: $($programs -join ', ')"
        )
    }

    Remove-SharedChild -Path $runtimeProjectLocation -Root $sharedRoot
    Copy-Item -LiteralPath $projectLocation -Destination $runtimeProjectLocation -Recurse

    Get-ChildItem -LiteralPath $runtimeProjectLocation -Directory -Force -Recurse |
        ForEach-Object {
            $_.Attributes = $_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
        }
    $runtimeRepository = Join-Path $runtimeProjectLocation "$projectName.rep"
    $writableMetadata = @(
        (Join-Path $runtimeProjectLocation "$projectName.gpr"),
        (Join-Path $runtimeRepository 'project.prp')
    ) + @(
        Get-ChildItem -LiteralPath $runtimeRepository -File -Force -Recurse |
            Where-Object Name -Like '~index.*' |
            Select-Object -ExpandProperty FullName
    )
    foreach ($metadataPath in $writableMetadata) {
        if (Test-Path -LiteralPath $metadataPath -PathType Leaf) {
            $metadata = Get-Item -LiteralPath $metadataPath -Force
            $metadata.Attributes = $metadata.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
        }
    }

    $runtimeProjectFile = Join-Path $runtimeProjectLocation "$projectName.gpr"
    if (-not (Test-Path -LiteralPath $runtimeProjectFile -PathType Leaf)) {
        throw "Transient runtime project copy is incomplete: $runtimeProjectFile"
    }

    if (-not $JavaHome) {
        $JavaHome = Find-GhidraJavaHome
    }
    $resolvedJavaHome = [IO.Path]::GetFullPath($JavaHome)
    $env:JAVA_HOME = $resolvedJavaHome
    $env:PATH = (Join-Path $resolvedJavaHome 'bin') + ';' + $env:PATH
    $env:GHIDRA_HEADLESS_MAXMEM = '4G'

    $arguments = @(
        $runtimeProjectLocation,
        $projectName,
        '-process',
        $Program,
        '-readOnly',
        '-noanalysis',
        '-log',
        $applicationLog,
        '-scriptlog',
        $scriptLog,
        '-scriptPath',
        $scriptPath,
        '-postScript',
        'GAMCPStartServerScript.java',
        'host=127.0.0.1',
        "port=$Port",
        'wait=true',
        "completion_file=$completionFile"
    )
    $processArguments = @($arguments | ForEach-Object {
        ConvertTo-ProcessArgument -Value ([string]$_)
    })

    Write-BackendHostLog "GhidrAssistMCP target: @disassembly/$Target ($Program)"
    Write-BackendHostLog "Transient project: @ghidra_mcp_work/$Target/project"
    $headlessProcess = Start-Process `
        -FilePath $headless `
        -ArgumentList $processArguments `
        -PassThru `
        -WindowStyle Hidden
    Set-Content -LiteralPath $ghidraPidFile -Value $headlessProcess.Id -Encoding ascii

    $deadline = [datetime]::UtcNow.AddSeconds($StartupTimeoutSeconds)
    while ([datetime]::UtcNow -lt $deadline) {
        if ($headlessProcess.HasExited) {
            throw "Ghidra exited during MCP startup with code $($headlessProcess.ExitCode)."
        }
        if (Test-LocalPort -CandidatePort $Port) {
            Write-BackendHostLog "GhidrAssistMCP backend is ready for $Target."
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not (Test-LocalPort -CandidatePort $Port)) {
        Stop-OwnedProcessTree -Process $headlessProcess
        throw "GhidrAssistMCP did not bind its temporary port within $StartupTimeoutSeconds seconds."
    }

    $headlessProcess.WaitForExit()
    if ($headlessProcess.ExitCode -ne 0) {
        throw "Ghidra headless MCP host exited with code $($headlessProcess.ExitCode)."
    }
}
catch {
    Add-Content `
        -LiteralPath $hostLog `
        -Value "$(Get-Date -Format o) ERROR: $($_.Exception.Message)" `
        -Encoding utf8
    throw
}
finally {
    if ($null -ne $headlessProcess -and -not $headlessProcess.HasExited) {
        Stop-OwnedProcessTree -Process $headlessProcess
    }
    Remove-SharedChild -Path $runtimeProjectLocation -Root $sharedRoot
    foreach ($controlFile in @($completionFile, $hostPidFile, $ghidraPidFile, $portFile)) {
        if (Test-Path -LiteralPath $controlFile -PathType Leaf) {
            Remove-Item -LiteralPath $controlFile -Force
        }
    }
    if ($null -ne $mutex) {
        try {
            $mutex.ReleaseMutex()
        }
        catch [ApplicationException] {
        }
        $mutex.Dispose()
    }
}
