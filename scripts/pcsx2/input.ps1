# Generate selected PCSX2 input profiles from canonical source inputs.
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Profile,

    [string]$TemplatePath,
    [string[]]$OverridePath,
    [string]$OutputPath,
    [string]$ProjectRoot,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-ByteArrayEqual {
    param(
        [Parameter(Mandatory)]
        [byte[]]$Left,

        [Parameter(Mandatory)]
        [byte[]]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return $false
    }

    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }

    return $true
}

function Get-InputBindingFamily {
    param([Parameter(Mandatory)][string]$Value)

    if ($Value -match '^SDL-[^/]+/') {
        return 'SDL'
    }
    if ($Value -match '^(?<family>[^/]+)/') {
        return $Matches['family']
    }
    return $null
}

function Get-InputAssignmentKey {
    param(
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][string]$Family
    )

    return (
        $Name.ToLowerInvariant() + "`0" +
        $(if ($null -eq $Family) { '' } else { $Family.ToLowerInvariant() })
    )
}

$usingConfiguredPaths = [string]::IsNullOrWhiteSpace($TemplatePath)
if ($usingConfiguredPaths) {
    . (Join-Path $PSScriptRoot '..\lib\paths.ps1')
    . (Join-Path $PSScriptRoot 'ini.ps1')
    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $catalog = Get-UnWorkshopCatalog -ProjectRoot $paths.Project
    $profileRoot = $paths.InputProfiles
    $baseName = 'Default'
    $sourcesRoot = Join-Path $profileRoot 'sources'
    $templateFullPath = Join-Path $sourcesRoot "$baseName.ini"
    $profileOverridesRoot = Join-Path $sourcesRoot 'overrides'
    $availableProfiles = [ordered]@{}
    $availableProfiles[$baseName] = @()
    Get-ChildItem -LiteralPath $profileOverridesRoot -Filter '*.ini' -File |
        Sort-Object Name |
        ForEach-Object {
            $profileName = $_.BaseName
            if ($profileName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$') {
                throw "Invalid input profile name: $profileName"
            }
            $availableProfiles[$profileName] = @($_.FullName)
        }

    $selectedName = $null
    if (-not [string]::IsNullOrWhiteSpace($Profile)) {
        $requestedName = $Profile
        if ($requestedName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$') {
            throw "Invalid input profile name: $requestedName"
        }
        $selectorKey = ($requestedName -replace '[_-]', '').ToLowerInvariant()
        $matchingNames = @(
            $availableProfiles.Keys |
                Where-Object {
                    (($_ -replace '[_-]', '').ToLowerInvariant()) -ceq
                        $selectorKey
                }
        )
        if ($matchingNames.Count -eq 0) {
            throw "Input-profile override not found: $requestedName"
        }
        if ($matchingNames.Count -gt 1) {
            throw "Ambiguous input-profile override: $requestedName"
        }
        $selectedName = [string]$matchingNames[0]
    }
    $generationProfiles = @(
        foreach ($profileName in $availableProfiles.Keys) {
            [pscustomobject]@{
                Name = $profileName
                Overrides = @($availableProfiles[$profileName])
            }
        }
    )

    $plans = [ordered]@{}
    $settingsProfiles = [ordered]@{}
    $entries = @(
        foreach ($property in $catalog.Sources.PSObject.Properties) {
            [pscustomobject]@{ Name = $property.Name; Category = 'sources' }
        }
        if ($null -ne $catalog.Builds) {
            foreach ($property in $catalog.Builds.PSObject.Properties) {
                [pscustomobject]@{ Name = $property.Name; Category = 'builds' }
            }
        }
    )
    $resolvedEntries = @(
        foreach ($entry in $entries) {
            $resolved = Resolve-UnWorkshopGame `
                -Game $entry.Name `
                -ProjectRoot $paths.Project
            $gameOverrideProperty = $resolved.PSObject.Properties[
                'input_profile_overrides'
            ]
            [pscustomobject]@{
                Name = $entry.Name
                Resolved = $resolved
                HasGameOverride = $null -ne $gameOverrideProperty
                GameOverride = if ($null -ne $gameOverrideProperty) {
                    [string]$gameOverrideProperty.Value
                }
                else { $null }
            }
        }
    )
    foreach ($profileDefinition in $generationProfiles) {
        foreach ($entry in $resolvedEntries) {
            $profileName = if ($entry.HasGameOverride) {
                "$($profileDefinition.Name)_$($entry.Name)"
            }
            else {
                $profileDefinition.Name
            }
            $overrides = @($profileDefinition.Overrides)
            if ($entry.HasGameOverride) {
                $overrides += $entry.GameOverride
            }
            if (-not $plans.Contains($profileName)) {
                $plans[$profileName] = [pscustomobject]@{
                    Name = $profileName
                    Overrides = $overrides
                    Output = Join-Path $profileRoot "$profileName.ini"
                }
            }

            if (
                $null -ne $selectedName -and
                $profileDefinition.Name -ceq $selectedName
            ) {
                $settingsPath = [string]$entry.Resolved.game_settings
                $settingsProfiles[$settingsPath] = $profileName
            }
        }
    }

    $generated = @(
        foreach ($plan in $plans.Values) {
            & $PSCommandPath `
                -TemplatePath $templateFullPath `
                -OverridePath $plan.Overrides `
                -OutputPath $plan.Output `
                -PassThru
        }
    )
    $updatedSettings = [Collections.Generic.List[string]]::new()
    foreach ($settingsPath in $settingsProfiles.Keys) {
        if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
            throw "Configured GameSettings file not found: $settingsPath"
        }
        $text = [IO.File]::ReadAllText($settingsPath)
        $updated = Set-Pcsx2IniValue `
            -Text $text `
            -Section 'EmuCore' `
            -Key 'InputProfileName' `
            -Value ([string]$settingsProfiles[$settingsPath])
        if ($updated -cne $text) {
            [IO.File]::WriteAllText(
                $settingsPath,
                $updated,
                [Text.UTF8Encoding]::new($false)
            )
            $updatedSettings.Add($settingsPath)
        }
    }

    $configuredResult = [pscustomobject]@{
        Profile = $selectedName
        GeneratedProfiles = $generated
        UpdatedGameSettings = @($updatedSettings)
        Changed = (
            @($generated | Where-Object Changed).Count -gt 0 -or
            $updatedSettings.Count -gt 0
        )
    }
    if ($PassThru) {
        $configuredResult
    }
    else {
        if ($null -eq $selectedName) {
            Write-Host (
                "Input profiles: generated $($generated.Count); " +
                'GameSettings unchanged.'
            )
        }
        else {
            Write-Host (
                "Input profiles: generated $($generated.Count); " +
                "assigned '$selectedName', " +
                "updated GameSettings $($updatedSettings.Count)."
            )
        }
    }
    return
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    throw 'TemplatePath and OutputPath must be supplied together.'
}

$templateFullPath = [IO.Path]::GetFullPath($TemplatePath)
$overrideFullPaths = @($OverridePath | ForEach-Object {
    [IO.Path]::GetFullPath($_)
})
$outputFullPath = [IO.Path]::GetFullPath($OutputPath)
if ([IO.Path]::Equals($templateFullPath, $outputFullPath)) {
    throw 'The template and generated input profiles must be different files.'
}
if (-not (Test-Path -LiteralPath $templateFullPath -PathType Leaf)) {
    throw "Input-profile template not found: $templateFullPath"
}
foreach ($overrideFullPath in $overrideFullPaths) {
    if (-not (Test-Path -LiteralPath $overrideFullPath -PathType Leaf)) {
        throw "Input-profile override not found: $overrideFullPath"
    }
}

$outputDirectory = [IO.Path]::GetDirectoryName($outputFullPath)
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    throw "Generated input-profile directory not found: $outputDirectory"
}

$templateBytes = [IO.File]::ReadAllBytes($templateFullPath)
$generatedText = [Text.Encoding]::Latin1.GetString($templateBytes)
$sectionPattern = (
    '(?ms)^\[(?<name>[^\]\r\n]+)\][^\r\n]*(?:\r\n|\n|\r)' +
    '(?<body>.*?)' +
    '(?=^\[[^\r\n]+\][^\r\n]*(?:\r\n|\n|\r)|\z)'
)
$assignmentPattern = (
    '(?im)^[ \t]*(?<name>[^;#\s][^=\r\n]*?)[ \t]*=' +
    '[ \t]*(?<value>[^\r\n]*)' +
    '(?<ending>\r\n|\n|\r|$)'
)
$newline = if ($generatedText.Contains("`r`n")) { "`r`n" } else { "`n" }
$effectiveSections = [ordered]@{}
foreach ($overrideFullPath in $overrideFullPaths) {
    $overrideText = [Text.Encoding]::Latin1.GetString(
        [IO.File]::ReadAllBytes($overrideFullPath)
    )
    $overrideSections = @([regex]::Matches($overrideText, $sectionPattern))
    if ($overrideSections.Count -eq 0) {
        throw "Input-profile override contains no sections: $overrideFullPath"
    }

    foreach ($overrideSection in $overrideSections) {
        $sectionName = $overrideSection.Groups['name'].Value
        $overrideLines = @(
            $overrideSection.Groups['body'].Value -split '\r\n|\n|\r' |
                Where-Object { $_ -match '^\s*[^;#\s][^=]*=' }
        )
        if ($overrideLines.Count -eq 0) {
            throw (
                "Override section [$sectionName] has no assignments: " +
                $overrideFullPath
            )
        }
        if (-not $effectiveSections.Contains($sectionName)) {
            $effectiveSections[$sectionName] = [ordered]@{}
        }
        $sectionAssignments = $effectiveSections[$sectionName]
        foreach ($overrideLine in $overrideLines) {
            $parts = $overrideLine -split '=', 2
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()
            $family = Get-InputBindingFamily -Value $value
            $key = Get-InputAssignmentKey -Name $name -Family $family
            $sectionAssignments[$key] = [pscustomobject]@{
                Name = $name
                Value = $value
                Family = $family
            }
        }
    }
}

$overrideValues = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($sectionAssignments in $effectiveSections.Values) {
    foreach ($assignment in $sectionAssignments.Values) {
        $null = $overrideValues.Add($assignment.Value)
    }
}

$removals = [Collections.Generic.List[object]]::new()
foreach ($baseSection in [regex]::Matches($generatedText, $sectionPattern)) {
    $sectionName = $baseSection.Groups['name'].Value
    $bodyGroup = $baseSection.Groups['body']
    $targetAssignments = if ($effectiveSections.Contains($sectionName)) {
        $effectiveSections[$sectionName]
    }
    else { $null }
    foreach ($candidate in [regex]::Matches(
        $bodyGroup.Value,
        $assignmentPattern
    )) {
        $candidateName = $candidate.Groups['name'].Value.Trim()
        $candidateValue = $candidate.Groups['value'].Value.Trim()
        $candidateFamily = Get-InputBindingFamily -Value $candidateValue
        $candidateKey = Get-InputAssignmentKey `
            -Name $candidateName `
            -Family $candidateFamily
        $isOverrideTarget = (
            $null -ne $targetAssignments -and
            $targetAssignments.Contains($candidateKey)
        )
        if ($overrideValues.Contains($candidateValue) -and -not $isOverrideTarget) {
            $removals.Add([pscustomobject]@{
                Index = $bodyGroup.Index + $candidate.Index
                Length = $candidate.Length
            })
        }
    }
}
foreach ($removal in @($removals | Sort-Object Index -Descending)) {
    $generatedText = $generatedText.Remove($removal.Index, $removal.Length)
}

foreach ($sectionName in $effectiveSections.Keys) {
    $escapedSection = [regex]::Escape($sectionName)
    $baseSections = @([regex]::Matches(
        $generatedText,
        (
            "(?ms)^\[$escapedSection\][^\r\n]*(?:\r\n|\n|\r)" +
            '(?<body>.*?)' +
            '(?=^\[[^\r\n]+\][^\r\n]*(?:\r\n|\n|\r)|\z)'
        )
    ))
    if ($baseSections.Count -ne 1) {
        throw (
            "Expected exactly one [$sectionName] section; found " +
            "$($baseSections.Count)."
        )
    }

    $bodyGroup = $baseSections[0].Groups['body']
    $body = $bodyGroup.Value
    $newAssignments = [Collections.Generic.List[string]]::new()
    foreach ($assignment in $effectiveSections[$sectionName].Values) {
            $name = $assignment.Name
            $value = $assignment.Value
            $escapedName = [regex]::Escape($name)
            $overrideFamily = $assignment.Family
            $bindingPattern = (
                "(?im)^(?<indent>[ \t]*)$escapedName[ \t]*=" +
                '(?<value>[^\r\n]*)' +
                '(?<ending>\r\n|\n|\r|$)'
            )
            $bindingMatches = @(
                [regex]::Matches($body, $bindingPattern) |
                    Where-Object {
                        $candidateFamily = Get-InputBindingFamily `
                            -Value $_.Groups['value'].Value.Trim()
                        $null -eq $overrideFamily -or
                            $candidateFamily -ieq $overrideFamily
                    }
            )
            if ($bindingMatches.Count -eq 0) {
                $newAssignments.Add("$name = $value")
                continue
            }

            for (
                $matchIndex = $bindingMatches.Count - 1
                $matchIndex -ge 1
                $matchIndex--
            ) {
                $duplicate = $bindingMatches[$matchIndex]
                $body = $body.Remove($duplicate.Index, $duplicate.Length)
            }

            $first = $bindingMatches[0]
            $replacement = (
                $first.Groups['indent'].Value +
                "$name = $value" +
                $first.Groups['ending'].Value
            )
            $body = (
                $body.Substring(0, $first.Index) +
                $replacement +
                $body.Substring($first.Index + $first.Length)
            )
    }

    if ($newAssignments.Count -gt 0) {
        $body = [regex]::Replace(
            $body,
            '(?:[ \t]*(?:\r\n|\n|\r))+\z',
            ''
        )
        $body = (
            $body + $newline + $newline +
            ($newAssignments -join $newline) +
            $newline + $newline
        )
    }

    $generatedText = (
        $generatedText.Substring(0, $bodyGroup.Index) +
        $body +
        $generatedText.Substring($bodyGroup.Index + $bodyGroup.Length)
    )
}
$generatedBytes = [Text.Encoding]::Latin1.GetBytes($generatedText)

$changed = $true
if (Test-Path -LiteralPath $outputFullPath -PathType Leaf) {
    $changed = -not (Test-ByteArrayEqual `
        -Left ([IO.File]::ReadAllBytes($outputFullPath)) `
        -Right $generatedBytes)
}

if ($changed) {
    if (Test-Path -LiteralPath $outputFullPath -PathType Leaf) {
        $stream = [IO.File]::Open(
            $outputFullPath,
            [IO.FileMode]::Create,
            [IO.FileAccess]::Write,
            [IO.FileShare]::Read
        )
        try {
            $stream.Write($generatedBytes, 0, $generatedBytes.Length)
            $stream.Flush($true)
        }
        finally {
            $stream.Dispose()
        }
    }
    else {
        [IO.File]::WriteAllBytes($outputFullPath, $generatedBytes)
    }
}

$result = [pscustomobject]@{
    Changed   = $changed
    Template  = $templateFullPath
    Overrides = $overrideFullPaths
    Output    = $outputFullPath
}

if ($PassThru) {
    $result
}
else {
    $state = if ($changed) { 'updated' } else { 'already current' }
    Write-Host "$([IO.Path]::GetFileName($outputFullPath)): $state."
}
