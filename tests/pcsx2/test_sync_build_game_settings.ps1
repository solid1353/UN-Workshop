[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$command = Join-Path $repository 'scripts\pcsx2\sync_build_game_settings.ps1'
$testRoot = Join-Path (
    [IO.Path]::GetTempPath()
) "workshop-game-settings-tests-$PID-$([guid]::NewGuid().ToString('N'))"

function Assert-WorkshopTest {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) { throw $Message }
}

try {
    $buildRoot = Join-Path $testRoot 'build'
    $settingsRoot = Join-Path $testRoot 'game_settings'
    $cardRoot = Join-Path $testRoot 'memory_cards'
    [void](New-Item -ItemType Directory -Force -Path $buildRoot, $settingsRoot, $cardRoot)
    $normalIso = Join-Path $buildRoot 'NA v2.28 - E2E Test.iso'
    $paddedIso = Join-Path $buildRoot 'NA v2.28 - E2E Test Padded.iso'
    [IO.File]::WriteAllBytes($normalIso, [byte[]](1, 2, 3))
    [IO.File]::WriteAllBytes($paddedIso, [byte[]](4, 5, 6))
    $settings = Join-Path $settingsRoot 'SLOP-NA228.ini'
    [IO.File]::WriteAllText(
        $settings,
        (
            "[MemoryCards]`n" +
            "Slot1_Filename = NA v2.28.ps2`n`n" +
            "[CRC.AAAAAAAA.MemoryCards]`n" +
            "Slot1_Filename = NA v2.28 - E2E Test.ps2`n`n" +
            "[CRC.11111111.MemoryCards]`n" +
            "Slot1_Filename = Legacy Test.ps2`n"
        ),
        [Text.UTF8Encoding]::new($false)
    )
    $normalCard = Join-Path $cardRoot 'NA v2.28 - E2E Test.ps2'
    $paddedCard = Join-Path $cardRoot 'NA v2.28 - E2E Test Padded.ps2'
    $resolvedBuilds = @{
        e2e_test = [pscustomobject]@{
            iso = $normalIso
            game_settings = $settings
            memory_card = $normalCard
        }
        e2e_test_padded = [pscustomobject]@{
            iso = $paddedIso
            game_settings = $settings
            memory_card = $paddedCard
        }
    }
    $identities = @{
        $normalIso = [pscustomobject]@{ Serial = 'SLOP-NA228'; CRC = '11111111' }
        $paddedIso = [pscustomobject]@{ Serial = 'SLOP-NA228'; CRC = '22222222' }
    }
    $catalog = [pscustomobject]@{
        Serial = 'SLOP-NA228'
        Builds = [pscustomobject][ordered]@{
            e2e_test = [pscustomobject]@{}
            e2e_test_padded = [pscustomobject]@{}
        }
    }
    $gameResolver = {
        param([string]$Selector)
        return $resolvedBuilds[$Selector]
    }.GetNewClosure()
    $identityResolver = {
        param([string]$IsoPath)
        return $identities[[IO.Path]::GetFullPath($IsoPath)]
    }.GetNewClosure()
    $common = @{
        WorkshopPaths = [pscustomobject]@{ Project = $testRoot }
        Catalog = $catalog
        GameResolver = $gameResolver
        IdentityResolver = $identityResolver
        PassThru = $true
    }

    $result = & $command -BuildSelector e2e_test, e2e_test_padded @common
    Assert-WorkshopTest `
        -Condition ($result.Builds.Count -eq 2 -and $result.Changed) `
        -Message 'Initial GameSettings synchronization returned the wrong result.'
    $text = [IO.File]::ReadAllText($settings)
    Assert-WorkshopTest `
        -Condition (
            $text -match '(?ms)\[CRC\.11111111\.MemoryCards\].*?Slot1_Filename = NA v2\.28 - E2E Test\.ps2' -and
            $text -match '(?ms)\[CRC\.22222222\.MemoryCards\].*?Slot1_Filename = NA v2\.28 - E2E Test Padded\.ps2' -and
            $text -notmatch '\[CRC\.AAAAAAAA\.MemoryCards\]'
        ) `
        -Message 'GameSettings CRC sections were not generated or retired correctly.'
    Assert-WorkshopTest `
        -Condition (
            -not (Test-Path -LiteralPath $normalCard) -and
            -not (Test-Path -LiteralPath $paddedCard)
        ) `
        -Message 'GameSettings synchronization touched memory-card files.'

    $identities[$normalIso].CRC = '33333333'
    $null = & $command -BuildSelector e2e_test @common
    $text = [IO.File]::ReadAllText($settings)
    Assert-WorkshopTest `
        -Condition (
            $text -match '\[CRC\.33333333\.MemoryCards\]' -and
            $text -notmatch '\[CRC\.11111111\.MemoryCards\]' -and
            $text -match '\[CRC\.22222222\.MemoryCards\]'
        ) `
        -Message 'A changed build CRC did not replace only its stale role section.'

    $identities[$paddedIso].CRC = '33333333'
    $collisionRejected = $false
    try {
        $null = & $command -BuildSelector e2e_test, e2e_test_padded @common
    }
    catch {
        $collisionRejected = $_.Exception.Message -match 'same PCSX2 CRC'
    }
    Assert-WorkshopTest `
        -Condition $collisionRejected `
        -Message 'Two distinct role cards were allowed to claim the same CRC section.'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

Write-Host 'Build GameSettings synchronization tests passed.'
