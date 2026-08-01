[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourceRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Assert-Condition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$synchronizer = Join-Path $sourceRepository 'scripts\pcsx2\input.ps1'
$temporaryRoot = Join-Path (
    [IO.Path]::GetTempPath()
) ('un-workshop-input-profile-test-{0}' -f [guid]::NewGuid().ToString('N'))

New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
try {
    $templatePath = Join-Path $temporaryRoot 'Default.ini'
    $overridePath = Join-Path $temporaryRoot 'sources\overrides\games\NA2.ini'
    $captureOverridePath = Join-Path $temporaryRoot 'sources\overrides\TestCapture.ini'
    $outputPath = Join-Path $temporaryRoot 'TestCapture_NA2.ini'
    $linkedOutputPath = Join-Path $temporaryRoot 'PCSX2_TestCapture_NA2.ini'
    $templateText = @'
[Pad1]
Type = DualShock2

Triangle = SDL-0/FaceNorth
Circle = SDL-0/FaceEast
Cross = SDL-0/FaceSouth
Square = SDL-0/FaceWest

Triangle = Keyboard/I
Circle = Keyboard/L
Cross = Keyboard/K
Square = Keyboard/J
L2 = Keyboard/Z
R2 = Keyboard/C

[Pad2]
Triangle = untouched

[Hotkeys]
PreviousSaveStateSlot = Keyboard/Shift & Keyboard/F2
NextSaveStateSlot = Keyboard/F2
SaveStateAndSelectNextSlot = Keyboard/F1
TakeScreenshot = Keyboard/F1
'@ -replace "`r`n", "`n"
    [IO.File]::WriteAllBytes(
        $templatePath,
        [Text.Encoding]::Latin1.GetBytes($templateText)
    )
    New-Item `
        -ItemType Directory `
        -Path ([IO.Path]::GetDirectoryName($overridePath)), `
            ([IO.Path]::GetDirectoryName($captureOverridePath)) |
        Out-Null
    [IO.File]::WriteAllText(
        $overridePath,
        "[Pad1]`nTriangle = SDL-0/FaceEast`nCircle = SDL-0/FaceSouth`nCross = SDL-0/FaceNorth`n",
        [Text.Encoding]::Latin1
    )
    [IO.File]::WriteAllText(
        $captureOverridePath,
        (
            "[Pad1]`nL3 = Keyboard/F1`nR3 = Keyboard/F1`n`n" +
            "[Hotkeys]`nPreviousSaveStateSlot = Keyboard/Q`n" +
            "NextSaveStateSlot = Keyboard/E`n" +
            "SaveStateAndSelectNextSlot = Keyboard/Alt`n"
        ),
        [Text.Encoding]::Latin1
    )
    [IO.File]::WriteAllText($outputPath, "stale`r`n")
    New-Item `
        -ItemType HardLink `
        -Path $linkedOutputPath `
        -Target $outputPath |
        Out-Null

    $first = & $synchronizer `
        -TemplatePath $templatePath `
        -OverridePath @($captureOverridePath, $overridePath) `
        -OutputPath $outputPath `
        -PassThru
    Assert-Condition $first.Changed 'The stale generated profile was not updated.'

    $actualBytes = [IO.File]::ReadAllBytes($outputPath)
    $actualText = [Text.Encoding]::Latin1.GetString($actualBytes)
    $pad1Match = [regex]::Match(
        $actualText,
        '(?ms)^\[Pad1\]\r?\n(?<body>.*?)(?=^\[Pad2\])'
    )
    Assert-Condition $pad1Match.Success 'Generated profile omitted [Pad1].'
    $pad1Text = $pad1Match.Groups['body'].Value
    foreach ($bindingName in @('Triangle', 'Circle', 'Cross')) {
        Assert-Condition `
            (@([regex]::Matches(
                $pad1Text,
                "(?m)^$bindingName\s*=\s*SDL-"
            )).Count -eq 1) `
            "The generated profile did not replace one $bindingName SDL binding."
        Assert-Condition `
            (@([regex]::Matches(
                $pad1Text,
                "(?m)^$bindingName\s*=\s*Keyboard/"
            )).Count -eq 1) `
            "The SDL override changed the $bindingName keyboard binding."
    }
    foreach ($expected in @(
        'Triangle = SDL-0/FaceEast',
        'Circle = SDL-0/FaceSouth',
        'Cross = SDL-0/FaceNorth',
        'Triangle = Keyboard/I',
        'Circle = Keyboard/L',
        'Cross = Keyboard/K',
        'L3 = Keyboard/F1',
        'R3 = Keyboard/F1',
        'PreviousSaveStateSlot = Keyboard/Q',
        'NextSaveStateSlot = Keyboard/E',
        'SaveStateAndSelectNextSlot = Keyboard/Alt',
        'Square = SDL-0/FaceWest',
        'Square = Keyboard/J',
        'Triangle = untouched'
    )) {
        Assert-Condition `
            ($actualText.Contains($expected)) `
            "Generated profile omitted expected binding: $expected"
    }
    Assert-Condition `
        (-not $actualText.Contains('TakeScreenshot = Keyboard/F1')) `
        'The override left another action bound to Keyboard/F1.'
    foreach ($replaced in @(
        'PreviousSaveStateSlot = Keyboard/Shift & Keyboard/F2',
        'NextSaveStateSlot = Keyboard/F2'
    )) {
        Assert-Condition `
            (-not $actualText.Contains($replaced)) `
            "The override left a replaced binding in the generated profile: $replaced"
    }
    Assert-Condition `
        ($actualText.IndexOf('Triangle = SDL-0/FaceEast') -lt
            $actualText.IndexOf('Square = SDL-0/FaceWest')) `
        'The generated profile moved an existing binding out of position.'
    Assert-Condition `
        ([regex]::IsMatch(
            $actualText,
            (
                'R2 = Keyboard/C\r?\n\r?\n' +
                'L3 = Keyboard/F1\r?\n' +
                'R3 = Keyboard/F1\r?\n\r?\n' +
                '\[Pad2\]'
            )
        )) `
        'New bindings do not have exactly one blank line around their block.'
    Assert-Condition `
        ([Convert]::ToHexString([IO.File]::ReadAllBytes($linkedOutputPath)) -ceq
            [Convert]::ToHexString($actualBytes)) `
        'Updating the generated profile broke its existing hardlink.'

    $firstWriteTime = (Get-Item -LiteralPath $outputPath).LastWriteTimeUtc
    Start-Sleep -Milliseconds 50
    $second = & $synchronizer `
        -TemplatePath $templatePath `
        -OverridePath @($captureOverridePath, $overridePath) `
        -OutputPath $outputPath `
        -PassThru
    Assert-Condition (-not $second.Changed) 'The second run was not idempotent.'
    Assert-Condition `
        ((Get-Item -LiteralPath $outputPath).LastWriteTimeUtc -eq $firstWriteTime) `
        'The second run rewrote an already-current generated profile.'

    Write-Host 'Input-profile synchronization tests passed.'
}
finally {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}
