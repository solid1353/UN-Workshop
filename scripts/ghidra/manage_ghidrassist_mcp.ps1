[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Install', 'Start', 'Status', 'Restart', 'Stop', 'Uninstall')]
    [string]$Action,
    [ValidateRange(10, 300)]
    [int]$WaitTimeoutSeconds = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\lib\paths.ps1')

$paths = Get-UnWorkshopPaths -NoProject
$runtimeRoot = if ([string]::IsNullOrWhiteSpace($paths.GhidraMcpWork)) {
    throw 'The configured @ghidra_mcp_work root is missing.'
} else {
    [IO.Path]::GetFullPath($paths.GhidraMcpWork)
}
$expectedRuntimeRoot = [IO.Path]::GetFullPath((Join-Path $paths.Work 'ghidraMCP'))
if (-not [IO.Path]::Equals($runtimeRoot, $expectedRuntimeRoot)) {
    throw "The configured @ghidra_mcp_work root must be @work/ghidraMCP: $runtimeRoot"
}

$controlRoot = Join-Path $runtimeRoot 'control'
$logsRoot = Join-Path $runtimeRoot 'logs'
$readyFile = Join-Path $controlRoot 'ready'
$stopFile = Join-Path $controlRoot 'stop'
$stateFile = Join-Path $controlRoot 'backends.json'
$hostScript = Join-Path $PSScriptRoot 'start_ghidrassist_mcp.ps1'
$routerRoot = Join-Path $paths.Tools 'ghidra\GhidrAssistMcpRouter'
$router = Join-Path $routerRoot 'GhidrAssistMcpRouter.exe'
$taskName = 'UNWorkshop-GhidrAssistMCP'
$codexUtilsInstaller = 'D:\Games\Modding\codex-utils\install.ps1'

function Get-McpTask {
    Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
}

function Get-BackendState {
    if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
        return @()
    }
    @((Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json))
}

function Get-McpStatus {
    $task = Get-McpTask
    $taskInfo = if ($null -ne $task) {
        Get-ScheduledTaskInfo -TaskName $taskName
    }
    [pscustomobject]@{
        TaskName = $taskName
        Installed = $null -ne $task
        State = if ($null -ne $task) { [string]$task.State } else { 'NotInstalled' }
        Ready = Test-Path -LiteralPath $readyFile -PathType Leaf
        Backends = @(Get-BackendState)
        LastRunTime = if ($null -ne $taskInfo) { $taskInfo.LastRunTime } else { $null }
        LastTaskResult = if ($null -ne $taskInfo) { $taskInfo.LastTaskResult } else { $null }
        RuntimeRoot = $runtimeRoot
        Logs = $logsRoot
        Transport = 'stdio'
    }
}

function Wait-McpReady {
    param([Parameter(Mandatory)][bool]$Ready)

    $deadline = [datetime]::UtcNow.AddSeconds($WaitTimeoutSeconds)
    do {
        if ((Test-Path -LiteralPath $readyFile -PathType Leaf) -eq $Ready) {
            return $true
        }
        Start-Sleep -Milliseconds 500
    } while ([datetime]::UtcNow -lt $deadline)
    $false
}

function Wait-McpStopped {
    $deadline = [datetime]::UtcNow.AddSeconds($WaitTimeoutSeconds)
    do {
        $task = Get-McpTask
        if (($null -eq $task -or $task.State -ne 'Running') -and
            -not (Test-Path -LiteralPath $readyFile -PathType Leaf)) {
            return $true
        }
        Start-Sleep -Milliseconds 500
    } while ([datetime]::UtcNow -lt $deadline)
    $false
}

function Wait-ScheduledTaskStopped {
    $deadline = [datetime]::UtcNow.AddSeconds($WaitTimeoutSeconds)
    do {
        $task = Get-McpTask
        if ($null -eq $task -or $task.State -ne 'Running') {
            return $true
        }
        Start-Sleep -Milliseconds 500
    } while ([datetime]::UtcNow -lt $deadline)
    $false
}

function Remove-StaleSupervisorState {
    foreach ($path in @($readyFile, $stateFile, $stopFile)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Stop-McpHost {
    $task = Get-McpTask
    if ($null -eq $task) {
        return
    }
    if ($task.State -ne 'Running') {
        Remove-StaleSupervisorState
        return
    }

    New-Item -ItemType Directory -Force -Path $controlRoot | Out-Null
    Set-Content -LiteralPath $stopFile -Value '' -Encoding ascii
    if (-not (Wait-McpStopped)) {
        Stop-ScheduledTask -TaskName $taskName
        if (-not (Wait-ScheduledTaskStopped)) {
            throw "Scheduled task '$taskName' did not stop cleanly."
        }
        Remove-StaleSupervisorState
    }
}

function Start-McpHost {
    $task = Get-McpTask
    if ($null -eq $task) {
        throw "Scheduled task '$taskName' is not installed."
    }
    if (Test-Path -LiteralPath $readyFile -PathType Leaf) {
        return
    }
    if (Test-Path -LiteralPath $stopFile -PathType Leaf) {
        Remove-Item -LiteralPath $stopFile -Force
    }
    Start-ScheduledTask -TaskName $taskName
    if (-not (Wait-McpReady -Ready $true)) {
        $status = Get-McpStatus
        throw (
            "GhidrAssistMCP did not become ready within $WaitTimeoutSeconds seconds. " +
            "Task state: $($status.State); result: $($status.LastTaskResult); " +
            "logs: $logsRoot"
        )
    }
}

function Install-CodexRegistration {
    if (-not (Test-Path -LiteralPath $codexUtilsInstaller -PathType Leaf)) {
        throw "The canonical Codex utilities installer was not found: $codexUtilsInstaller"
    }
    & $codexUtilsInstaller -GhidrAssistMCP -NoReload
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to install the global Codex GhidrAssist MCP registration.'
    }
}

function Remove-CodexRegistration {
    if (-not (Test-Path -LiteralPath $codexUtilsInstaller -PathType Leaf)) {
        throw "The canonical Codex utilities installer was not found: $codexUtilsInstaller"
    }
    & $codexUtilsInstaller -RemoveGhidrAssistMCP -NoReload
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to remove the global Codex GhidrAssist MCP registration.'
    }
}

switch ($Action) {
    'Install' {
        if (-not (Test-Path -LiteralPath $router -PathType Leaf)) {
            throw (
                'The GhidrAssist MCP router is not installed. Run ' +
                '@ghidra_scripts/install_ghidrassist_mcp.ps1 first.'
            )
        }
        if (-not (Test-Path -LiteralPath $hostScript -PathType Leaf)) {
            throw "GhidrAssist MCP backend host was not found: $hostScript"
        }
        if ($null -ne (Get-McpTask)) {
            Stop-McpHost
        }
        $powerShell = (Get-Command pwsh.exe -ErrorAction Stop).Source
        $arguments = @(
            '--supervisor',
            '--disassembly', $paths.Disassembly,
            '--runtime', $runtimeRoot,
            '--host-script', $hostScript,
            '--pwsh', $powerShell
        ) | ForEach-Object {
            if ($_ -match '[\s"]') {
                '"' + $_.Replace('"', '\"') + '"'
            } else {
                $_
            }
        }
        $scheduledAction = New-ScheduledTaskAction `
            -Execute $router `
            -Argument ($arguments -join ' ') `
            -WorkingDirectory $paths.Workshop
        $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $userName
        $principal = New-ScheduledTaskPrincipal `
            -UserId $userName `
            -LogonType Interactive `
            -RunLevel Limited
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit ([timespan]::Zero) `
            -Hidden `
            -MultipleInstances IgnoreNew `
            -RestartCount 3 `
            -RestartInterval (New-TimeSpan -Minutes 1) `
            -StartWhenAvailable
        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $scheduledAction `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Description 'Shared read-only GhidrAssist MCP supervisor maintained by UN Workshop.' `
            -Force | Out-Null
        Start-McpHost
        Install-CodexRegistration
        Get-McpStatus
    }
    'Start' {
        Start-McpHost
        Get-McpStatus
    }
    'Status' {
        Get-McpStatus
    }
    'Restart' {
        Stop-McpHost
        Start-McpHost
        Get-McpStatus
    }
    'Stop' {
        Stop-McpHost
        Get-McpStatus
    }
    'Uninstall' {
        $task = Get-McpTask
        if ($null -ne $task) {
            Stop-McpHost
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        Remove-CodexRegistration
        if (Test-Path -LiteralPath $runtimeRoot) {
            if (-not [IO.Path]::Equals(
                [IO.Path]::GetFullPath($runtimeRoot),
                $expectedRuntimeRoot
            )) {
                throw "Refusing to remove an unexpected runtime root: $runtimeRoot"
            }
            Remove-Item -LiteralPath $runtimeRoot -Recurse -Force
        }
        Get-McpStatus
    }
}
