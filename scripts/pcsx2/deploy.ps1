[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
$paths = Get-UnWorkshopPaths -NoProject
$logDirectory = [string]$paths.Roots.logs
$logPath = Join-Path $logDirectory 'pcsx2-deploy.log'
$script:deploymentLogAvailable = $true

try {
    [void][IO.Directory]::CreateDirectory($logDirectory)
}
catch {
    $script:deploymentLogAvailable = $false
    Write-Warning "Deployment log is unavailable: $($_.Exception.Message)"
}

function Write-DeploymentLog {
    param([string]$Message)

    $Message = $Message.Replace($paths.Pcsx2Fork, '@pcsx2_fork').Replace(
        $paths.Pcsx2Dev, '@pcsx2_dev'
    )
    Write-Host $Message
    if ($script:deploymentLogAvailable) {
        try {
            $line = '[{0}] {1}{2}' -f (
                [DateTimeOffset]::Now.ToString('o'), $Message,
                [Environment]::NewLine
            )
            [IO.File]::AppendAllText($logPath, $line)
        }
        catch {
            $script:deploymentLogAvailable = $false
            Write-Warning "Deployment log is unavailable: $($_.Exception.Message)"
        }
    }
}

$files = @()
try {
    Write-DeploymentLog 'Deploying PCSX2 from @pcsx2_fork to @pcsx2_dev.'
    if (-not (Test-Path -LiteralPath $paths.Pcsx2Dev -PathType Container)) {
        throw 'The configured @pcsx2_dev installation directory does not exist.'
    }
    if ([string]::Equals(
        [IO.Path]::GetFullPath($paths.Pcsx2Fork).TrimEnd('\', '/'),
        [IO.Path]::GetFullPath($paths.Pcsx2Dev).TrimEnd('\', '/'),
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw '@pcsx2_fork and @pcsx2_dev must be different directories.'
    }

    $files = @(
        foreach ($name in @(
            'pcsx2-qtx64-avx2-dev.exe',
            'pcsx2-qtx64-avx2-dev.pdb'
        )) {
            $source = Join-Path $paths.Pcsx2Fork $name
            $info = Get-Item -LiteralPath $source
            if ($info.PSIsContainer -or $info.Length -eq 0) {
                throw "Build output is not a nonempty file: @pcsx2_fork/$name"
            }
            [pscustomobject]@{
                Name = $name
                Source = $source
                Destination = Join-Path $paths.Pcsx2Dev $name
                Length = $info.Length
                WriteTime = $info.LastWriteTimeUtc.Ticks
                Hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
                SourceStream = $null
                DestinationStream = $null
            }
        }
    )

    $waitingReported = $false
    while ($true) {
        foreach ($file in $files) {
            $info = Get-Item -LiteralPath $file.Source
            if ($info.Length -ne $file.Length -or
                $info.LastWriteTimeUtc.Ticks -ne $file.WriteTime) {
                throw "Deployment cancelled: build output changed: $($file.Name)"
            }
        }

        try {
            # Acquire every existing destination without truncating anything.
            # Holding the executable also prevents a launch during deployment.
            foreach ($file in $files) {
                if (Test-Path -LiteralPath $file.Destination) {
                    $file.DestinationStream = [IO.File]::Open(
                        $file.Destination, [IO.FileMode]::Open,
                        [IO.FileAccess]::ReadWrite, [IO.FileShare]::None
                    )
                }
            }
            break
        }
        catch {
            foreach ($file in $files) {
                if ($null -ne $file.DestinationStream) {
                    $file.DestinationStream.Dispose()
                    $file.DestinationStream = $null
                }
            }
            $cause = $_.Exception.GetBaseException()
            $errorCode = $cause.HResult -band 0xFFFF
            if ($cause -isnot [IO.IOException] -or
                $errorCode -notin @(32, 33)) {
                throw
            }
            if (-not $waitingReported) {
                Write-DeploymentLog (
                    'Waiting for installation files to become available. ' +
                    'Close PCSX2 when convenient.'
                )
                $waitingReported = $true
            }
            Start-Sleep -Seconds 1
        }
    }

    # Keep the checked source files open only during deployment, so later
    # builds remain possible while this command waits for the installation.
    foreach ($file in $files) {
        $file.SourceStream = [IO.File]::Open(
            $file.Source, [IO.FileMode]::Open,
            [IO.FileAccess]::Read, [IO.FileShare]::Read
        )
        $hash = (Get-FileHash -InputStream $file.SourceStream -Algorithm SHA256).Hash
        if ($hash -ne $file.Hash) {
            throw "Deployment cancelled: build output changed: $($file.Name)"
        }
        $file.SourceStream.Position = 0
    }
    foreach ($file in $files) {
        if ($null -eq $file.DestinationStream) {
            $file.DestinationStream = [IO.File]::Open(
                $file.Destination, [IO.FileMode]::CreateNew,
                [IO.FileAccess]::ReadWrite, [IO.FileShare]::None
            )
        }
    }

    # Install symbols first, then the executable, while keeping both locked.
    for ($fileIndex = $files.Count - 1; $fileIndex -ge 0; $fileIndex--) {
        $file = $files[$fileIndex]
        $file.DestinationStream.SetLength($file.SourceStream.Length)
        $file.SourceStream.CopyTo($file.DestinationStream)
        $file.DestinationStream.Flush($true)
        $file.DestinationStream.Position = 0
        $hash = (Get-FileHash -InputStream $file.DestinationStream -Algorithm SHA256).Hash
        if ($hash -ne $file.Hash) {
            throw "Deployed file hash does not match the build: $($file.Name)"
        }
        Write-DeploymentLog "Deployed and SHA-256 verified: $($file.Name)"
    }
    Write-DeploymentLog 'PCSX2 deployment completed.'
}
catch {
    Write-DeploymentLog "PCSX2 deployment failed: $($_.Exception.Message)"
    throw
}
finally {
    foreach ($file in $files) {
        if ($null -ne $file.SourceStream) {
            $file.SourceStream.Dispose()
        }
        if ($null -ne $file.DestinationStream) {
            $file.DestinationStream.Dispose()
        }
    }
}
