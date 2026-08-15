[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Pcsx2LaunchTest {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) { throw $Message }
}

$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$testRoot = Join-Path $sourceRepository (
    'work\temp\tests\pcsx2-launch-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
)
$global:Pcsx2PnachLaunchTestLaunches = @()

function Start-Process {
    param(
        [string]$FilePath,
        [string]$WorkingDirectory,
        [string[]]$ArgumentList,
        [switch]$Wait,
        [switch]$PassThru
    )
    $global:Pcsx2PnachLaunchTestLaunches += ,([pscustomobject]@{
        FilePath = $FilePath
        WorkingDirectory = $WorkingDirectory
        ArgumentList = @($ArgumentList)
    })
}

try {
    New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
    $firstPnach = Join-Path $testRoot 'first custom file.pnach'
    $secondPnach = Join-Path $testRoot 'second.pnach'
    Set-Content -LiteralPath $firstPnach -Value '[+First]' -Encoding utf8NoBOM
    Set-Content -LiteralPath $secondPnach -Value '[+Second]' -Encoding utf8NoBOM

    $launcher = Join-Path $sourceRepository 'scripts\pcsx2\launch.ps1'
    & $launcher -Pnach $firstPnach
    & $launcher -Pnach $secondPnach

    Assert-Pcsx2LaunchTest `
        -Condition ($global:Pcsx2PnachLaunchTestLaunches.Count -eq 2) `
        -Message 'PCSX2 launcher did not issue two independent launches.'
    for ($index = 0; $index -lt 2; $index++) {
        $expectedPath = if ($index -eq 0) { $firstPnach } else { $secondPnach }
        $arguments = @($global:Pcsx2PnachLaunchTestLaunches[$index].ArgumentList)
        $pnachIndex = [Array]::IndexOf($arguments, '-pnach')
        Assert-Pcsx2LaunchTest `
            -Condition (
                $pnachIndex -ge 0 -and
                $pnachIndex + 1 -lt $arguments.Count -and
                $arguments[$pnachIndex + 1] -ceq "`"$expectedPath`""
            ) `
            -Message "Launch $index did not receive its own PNACH path."
    }

    $missingRejected = $false
    try {
        & $launcher -Pnach (Join-Path $testRoot 'missing.pnach')
    }
    catch {
        $missingRejected = $_.Exception.Message -match '^PNACH file does not exist:'
    }
    Assert-Pcsx2LaunchTest `
        -Condition (
            $missingRejected -and
            $global:Pcsx2PnachLaunchTestLaunches.Count -eq 2
        ) `
        -Message 'PCSX2 launcher did not reject a missing PNACH before launch.'
}
finally {
    Remove-Variable `
        -Name Pcsx2PnachLaunchTestLaunches `
        -Scope Global `
        -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-Host 'PCSX2 launch tests passed.'
