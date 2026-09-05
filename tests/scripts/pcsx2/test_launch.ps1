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
$tempRoot = Join-Path $sourceRepository 'work\temp'
$testParent = Join-Path $tempRoot 'tests'
$testRoot = Join-Path $testParent (
    'pcsx2-launch-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
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
    $inlineLines = @(
        'patch=1,EE,00100000,word,00000001'
        'patch=1,EE,00100000,word,00000002 // later write'
    )
    & $launcher -Pnach @($firstPnach, $secondPnach) -PnachLines $inlineLines
    & $launcher -Pnach $secondPnach

    Assert-Pcsx2LaunchTest `
        -Condition ($global:Pcsx2PnachLaunchTestLaunches.Count -eq 2) `
        -Message 'PCSX2 launcher did not issue two independent launches.'
    $firstArguments = @($global:Pcsx2PnachLaunchTestLaunches[0].ArgumentList)
    $firstPnachIndex = [Array]::IndexOf($firstArguments, '-pnach')
    $secondPnachIndex = [Array]::IndexOf(
        $firstArguments,
        '-pnach',
        $firstPnachIndex + 1
    )
    Assert-Pcsx2LaunchTest `
        -Condition (
            $firstPnachIndex -ge 0 -and
            $secondPnachIndex -eq $firstPnachIndex + 2 -and
            $firstArguments[$firstPnachIndex + 1] -ceq "`"$firstPnach`"" -and
            $firstArguments[$secondPnachIndex + 1] -ceq "`"$secondPnach`""
        ) `
        -Message 'PCSX2 launcher did not forward ordered -pnach pairs.'

    $firstInlineIndex = [Array]::IndexOf($firstArguments, '-pnach-line')
    $secondInlineIndex = [Array]::IndexOf(
        $firstArguments,
        '-pnach-line',
        $firstInlineIndex + 1
    )
    Assert-Pcsx2LaunchTest `
        -Condition (
            $firstInlineIndex -gt $secondPnachIndex -and
            $secondInlineIndex -eq $firstInlineIndex + 2 -and
            $firstArguments[$firstInlineIndex + 1] -ceq "`"$($inlineLines[0])`"" -and
            $firstArguments[$secondInlineIndex + 1] -ceq "`"$($inlineLines[1])`""
        ) `
        -Message 'PCSX2 launcher did not forward ordered -pnach-line pairs.'

    $secondArguments = @($global:Pcsx2PnachLaunchTestLaunches[1].ArgumentList)
    Assert-Pcsx2LaunchTest `
        -Condition (
            ([Array]::IndexOf($secondArguments, '-pnach')) -ge 0 -and
            $secondArguments[([Array]::IndexOf($secondArguments, '-pnach')) + 1] -ceq "`"$secondPnach`"" -and
            ([Array]::LastIndexOf($secondArguments, '-pnach')) -eq ([Array]::IndexOf($secondArguments, '-pnach')) -and
            -not ($secondArguments -contains '-pnach-line')
        ) `
        -Message 'PCSX2 launcher leaked PNACH state between launches.'

    $missingRejected = $false
    try {
        & $launcher -Pnach @($firstPnach, (Join-Path $testRoot 'missing.pnach'))
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

    $iso = Join-Path $testRoot 'game.iso'
    New-Item -ItemType File -Path $iso | Out-Null
    & $launcher -IsoPath $iso -CenteredWindow
    $centeredArguments = @(
        $global:Pcsx2PnachLaunchTestLaunches[-1].ArgumentList
    )
    $centeredIndex = [Array]::IndexOf(
        $centeredArguments,
        '-centered-window'
    )
    $batchIndex = [Array]::IndexOf($centeredArguments, '-batch')
    Assert-Pcsx2LaunchTest `
        -Condition (
            $centeredIndex -ge 0 -and
            $centeredIndex -lt $batchIndex -and
            @($centeredArguments | Where-Object {
                $_ -ceq '-centered-window'
            }).Count -eq 1
        ) `
        -Message 'PCSX2 launcher did not place -centered-window before the game path.'
}
finally {
    Remove-Variable `
        -Name Pcsx2PnachLaunchTestLaunches `
        -Scope Global `
        -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
    foreach ($parent in @($testParent, $tempRoot)) {
        if (
            (Test-Path -LiteralPath $parent -PathType Container) -and
            -not (Get-ChildItem -LiteralPath $parent -Force | Select-Object -First 1)
        ) {
            Remove-Item -LiteralPath $parent -Force
        }
    }
}

Write-Host 'PCSX2 launch tests passed.'
