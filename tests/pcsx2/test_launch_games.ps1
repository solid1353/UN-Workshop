[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-WorkshopLaunchTest {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) { throw $Message }
}

$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$testRoot = Join-Path `
    ([IO.Path]::GetTempPath()) `
    "workshop-launch-tests-$PID-$([Guid]::NewGuid().ToString('N'))"
$repository = Join-Path $testRoot 'repo'

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'scripts\lib') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $repository 'scripts\pcsx2') | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRepository 'workshop.ps1') -Destination $repository
    Copy-Item `
        -LiteralPath (Join-Path $sourceRepository 'scripts\lib\paths.ps1') `
        -Destination (Join-Path $repository 'scripts\lib')

    @'
{
  "schema_version": 1,
  "roots": {
    "repository": ".",
    "source": "source",
    "analysis": "work",
    "tools": "tools",
    "work": "work",
    "savestates": "@work/sstates",
    "scripts": "scripts",
    "pcsx2_scripts": "@scripts/pcsx2",
    "pcsx2": "pcsx2",
    "pcsx2_stable": "@pcsx2/stable",
    "pcsx2_dev": "@pcsx2/dev",
    "pcsx2_clean": "pcsx2/clean",
    "pcsx2_files": "pcsx2_shared",
    "pcsx2_bios": "@pcsx2_files/bios",
    "pcsx2_cheats": "@pcsx2_files/cheats",
    "pcsx2_game_settings": "@pcsx2_files/game_settings",
    "pcsx2_input_profiles": "@pcsx2_files/input_profiles",
    "pcsx2_input_recordings": "@pcsx2_files/input_recordings",
    "pcsx2_memory_cards": "@pcsx2_files/memory_cards"
  },
  "files": {
    "game_catalog": "@repository/games.json",
    "game_resolver": "@repository/scripts/lib/resolve_game.py",
    "workshop_command": "@repository/workshop.ps1",
    "pcsx2_launch_command": "@repository/scripts/pcsx2/launch.ps1",
    "pcsx2_game_launch_command": "@repository/scripts/pcsx2/launch_games.ps1"
  }
}
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'paths.json')
    '{"schema_version":1,"sources":{"NUN5":{"serial":"SLES-55605","crc":"C071D4C1"}}}' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'games.json')
    '{"schema_version":1,"title":"NA v2.28","serial":"SLOP-NA228","builds":{"latest":{"aliases":["l"],"postfix":"Latest"}}}' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'product.json')
    'raise SystemExit("fake resolver must not run")' |
        Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\lib\resolve_game.py')
    @'
param()
'[fake] launch PCSX2 UI'
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch.ps1')
    @'
param(
    [string[]]$Games,
    [string]$Play,
    [string]$Record,
    [switch]$Test,
    [string]$CaptureDirectory,
    [string]$ProjectRoot
)
"[fake] games=$($Games -join ',') play=$Play record=$Record test=$Test capture=$CaptureDirectory project=$ProjectRoot"
'@ | Set-Content -NoNewline -LiteralPath (Join-Path $repository 'scripts\pcsx2\launch_games.ps1')

    Push-Location $repository
    try {
        $play = (& .\workshop.ps1 NUN5 latest -p practice-menu) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($play -match 'games=NUN5,latest play=practice-menu record=') `
            -Message 'Paired playback was not forwarded to the shared launcher.'

        $record = (& .\workshop.ps1 NUN5 latest -r practice-menu) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($record -match 'games=NUN5,latest play= record=practice-menu') `
            -Message 'Rightmost recording was not forwarded to the shared launcher.'

        $test = (& .\workshop.ps1 NUN5 -t practice-menu) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($test -match 'games=NUN5 play=practice-menu record= test=True') `
            -Message 'Regression playback was not forwarded to the shared launcher.'

        $capturePath = Join-Path $repository 'direct-capture'
        $directCapture = (
            & .\workshop.ps1 NUN5 -t practice-menu -o $capturePath
        ) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($directCapture -match ('capture=' + [regex]::Escape($capturePath))) `
            -Message 'Explicit regression capture output was not forwarded to the shared launcher.'

        $outputWithoutTestRejected = $false
        try { & .\workshop.ps1 NUN5 -o $capturePath }
        catch { $outputWithoutTestRejected = $_.Exception.Message -match 'valid only with -t' }
        Assert-WorkshopLaunchTest `
            -Condition $outputWithoutTestRejected `
            -Message 'Explicit capture output was accepted without regression replay.'

        $barePcsx2 = (& .\workshop.ps1 pcsx2) -join "`n"
        Assert-WorkshopLaunchTest `
            -Condition ($barePcsx2 -match '\[fake\] launch PCSX2 UI') `
            -Message 'Bare PCSX2 launch was not preserved.'

        $oldCommandRejected = $false
        try { & .\workshop.ps1 rec NUN5 practice-menu }
        catch { $oldCommandRejected = $true }
        Assert-WorkshopLaunchTest `
            -Condition $oldCommandRejected `
            -Message 'The retired rec command remains active.'
    }
    finally {
        Pop-Location
    }

    Write-Host 'Workshop paired-launch tests passed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
