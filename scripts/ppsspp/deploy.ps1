[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths -NoProject
$logDirectory = [string]$paths.Roots.logs
$logPath = Join-Path $logDirectory 'ppsspp-deploy.log'
[void][IO.Directory]::CreateDirectory($logDirectory)

function Write-DeploymentLog {
    param([string]$Message)

    $Message = $Message.Replace($paths.PpssppFork, '@ppsspp_fork').Replace(
        $paths.PpssppDev, '@ppsspp_dev'
    )
    Write-Host $Message
    $line = '[{0}] {1}{2}' -f (
        [DateTimeOffset]::Now.ToString('o'), $Message, [Environment]::NewLine
    )
    [IO.File]::AppendAllText($logPath, $line)
}

# The executables and symbols, and every file under assets except Git's own.
function Get-PpssppDeploymentFiles {
    $build = Join-Path $paths.PpssppFork 'Windows\x64\Release'
    $sources = @(
        [pscustomobject]@{
            Source = Join-Path $paths.PpssppFork 'PPSSPPWindows64.exe'
            Name = 'PPSSPPWindows64.exe'
        }
        [pscustomobject]@{
            Source = Join-Path $paths.PpssppFork 'PPSSPPWindows64.pdb'
            Name = 'PPSSPPWindows64.pdb'
        }
        [pscustomobject]@{
            Source = Join-Path $build 'PPSSPPHeadless.exe'
            Name = 'PPSSPPHeadless.exe'
        }
    )
    $assets = Join-Path $paths.PpssppFork 'assets'
    $sources += @(
        Get-ChildItem -LiteralPath $assets -Recurse -File -Force |
            Where-Object { $_.Name -ne '.git' -and $_.FullName -notmatch '\\\.git\\' } |
            ForEach-Object {
                [pscustomobject]@{
                    Source = $_.FullName
                    Name = 'assets\' + $_.FullName.Substring($assets.Length + 1)
                }
            }
    )
    foreach ($entry in $sources) {
        $info = Get-Item -LiteralPath $entry.Source
        [pscustomobject]@{
            Name = $entry.Name
            Source = $entry.Source
            Destination = Join-Path $paths.PpssppDev $entry.Name
            Length = $info.Length
            WriteTime = $info.LastWriteTimeUtc.Ticks
            Hash = (Get-FileHash -LiteralPath $entry.Source -Algorithm SHA256).Hash
        }
    }
}

function Test-PpssppInstallationBusy {
    param([Parameter(Mandatory)][string[]]$Paths)

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }
        try {
            [IO.File]::Open(
                $path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None
            ).Dispose()
        }
        catch {
            $cause = $_.Exception.GetBaseException()
            if ($cause -is [IO.IOException] -and ($cause.HResult -band 0xFFFF) -in @(32, 33)) {
                return $true
            }
            throw
        }
    }
    return $false
}

try {
    Write-DeploymentLog 'Deploying PPSSPP from @ppsspp_fork to @ppsspp_dev.'
    if (-not (Test-Path -LiteralPath $paths.PpssppDev -PathType Container)) {
        throw 'The configured @ppsspp_dev installation directory does not exist.'
    }
    $files = @(Get-PpssppDeploymentFiles)

    $executables = @(
        $files | Where-Object { $_.Name -like '*.exe' } | ForEach-Object Destination
    )
    $waitingReported = $false
    while (Test-PpssppInstallationBusy -Paths $executables) {
        if (-not $waitingReported) {
            Write-DeploymentLog (
                'Waiting for installation files to become available. ' +
                'Close PPSSPP when convenient.'
            )
            $waitingReported = $true
        }
        Start-Sleep -Seconds 1
    }

    $changed = 0
    # The executables last, so a failure never leaves a new build on old assets.
    foreach ($file in @($files | Sort-Object { $_.Name -like '*.exe' })) {
        $info = Get-Item -LiteralPath $file.Source
        if ($info.Length -ne $file.Length -or $info.LastWriteTimeUtc.Ticks -ne $file.WriteTime) {
            throw "Deployment cancelled: build output changed: $($file.Name)"
        }
        if ((Test-Path -LiteralPath $file.Destination) -and
            (Get-FileHash -LiteralPath $file.Destination -Algorithm SHA256).Hash -eq $file.Hash) {
            continue
        }
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file.Destination))
        Copy-Item -LiteralPath $file.Source -Destination $file.Destination -Force
        if ((Get-FileHash -LiteralPath $file.Destination -Algorithm SHA256).Hash -ne $file.Hash) {
            throw "Deployed file hash does not match the build: $($file.Name)"
        }
        $changed++
        Write-DeploymentLog "Deployed and SHA-256 verified: $($file.Name)"
    }
    Write-DeploymentLog "PPSSPP deployment completed: $changed of $($files.Count) files changed."
}
catch {
    Write-DeploymentLog "PPSSPP deployment failed: $($_.Exception.Message)"
    throw
}
