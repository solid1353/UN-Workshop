# File one game's savestates from the selected user PCSX2 installation.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Game,

    [Parameter(Mandatory, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$SubPath,

    [Parameter(Position = 2)]
    [ValidateSet('stable', 'dev')]
    [string]$Target = 'dev',

    [switch]$Cleanup,

    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\paths.ps1')
. (Join-Path $PSScriptRoot 'iso_identity.ps1')
$paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
$catalog = Get-UnWorkshopCatalog -ProjectRoot $paths.Project
$canonicalGame = $null
$canonicalCategory = $null
foreach ($category in @('Sources', 'Builds')) {
    $section = $catalog.$category
    if ($null -eq $section) { continue }
    $definitions = $section
    foreach ($property in $definitions.PSObject.Properties) {
        $aliasesProperty = $property.Value.PSObject.Properties['aliases']
        $aliases = if ($null -eq $aliasesProperty) {
            @()
        }
        else {
            @($aliasesProperty.Value)
        }
        if (
            $property.Name -ieq $Game -or
            @($aliases | Where-Object { $_ -ieq $Game }).Count -gt 0
        ) {
            $canonicalGame = $property.Name
            $canonicalCategory = $category
            break
        }
    }
    if ($canonicalGame) { break }
}
if (-not $canonicalGame) { throw "Unknown game or alias '$Game'." }
$resolved = Resolve-UnWorkshopGame -Game $Game -ProjectRoot $paths.Project

$sourceDefinition = $catalog.Sources.PSObject.Properties[$canonicalGame]
if ($null -ne $sourceDefinition) {
    $serial = ([string]$sourceDefinition.Value.serial).ToUpperInvariant()
    $crc = ([string]$sourceDefinition.Value.crc).ToUpperInvariant()
}
else {
    if (-not (Test-Path -LiteralPath $resolved.iso -PathType Leaf)) {
        throw "Selected build ISO does not exist: $($resolved.iso)"
    }
    $identity = Get-Pcsx2IsoIdentity -Path $resolved.iso
    $serial = ([string]$identity.Serial).ToUpperInvariant()
    $crc = ([string]$identity.CRC).ToUpperInvariant()
}
$expectedStem = "$serial ($crc)"

$sourceInstallation = switch ($Target) {
    'stable' { $paths.Pcsx2Stable }
    'dev' { $paths.Pcsx2Dev }
}
$sourceRoot = Join-Path $sourceInstallation 'sstates'
$destinationRoot = if ($canonicalCategory -eq 'Builds') {
    if ([string]::IsNullOrWhiteSpace($paths.Project)) {
        throw 'A project root is required to file build savestates.'
    }
    Join-Path $paths.Project 'work\__sstates'
}
else {
    $paths.Savestates
}

if ([string]::IsNullOrWhiteSpace($SubPath)) {
    throw 'SubPath cannot be empty.'
}

if ([IO.Path]::IsPathRooted($SubPath)) {
    throw "SubPath must be relative, not an absolute path: $SubPath"
}

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Savestate source directory does not exist: $sourceRoot"
}

$trimChars = [char[]]@(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)

$destinationRootFull = [IO.Path]::GetFullPath($destinationRoot).TrimEnd($trimChars)
$destinationFull = [IO.Path]::GetFullPath(
    (Join-Path -Path $destinationRootFull -ChildPath $SubPath)
).TrimEnd($trimChars)

$rootPrefix = $destinationRootFull + [IO.Path]::DirectorySeparatorChar
$destinationPrefix = $destinationFull + [IO.Path]::DirectorySeparatorChar

if (-not $destinationPrefix.StartsWith(
    $rootPrefix,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw "SubPath escapes the savestate destination root: $SubPath"
}

if ($destinationFull.Equals(
    $destinationRootFull,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw 'Supply an actual subdirectory rather than the destination root itself.'
}

if (Test-Path -LiteralPath $destinationFull -PathType Leaf) {
    throw "Destination exists as a file: $destinationFull"
}

$stateFiles = @(
    Get-ChildItem `
        -LiteralPath $sourceRoot `
        -File `
        -ErrorAction Stop |
    Where-Object {
        $_.Extension -ieq '.p2s'
    } |
    Sort-Object -Property Name
)

if ($stateFiles.Count -eq 0) {
    Write-Warning "No .p2s savestates found in: $sourceRoot"
    return
}

$parsedStates = @(
    foreach ($file in $stateFiles) {
        $match = [regex]::Match(
            $file.Name,
            '^(?<stem>.+ \([0-9A-F]{8}\))\.(?<slot>\d+)\.p2s$',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if (-not $match.Success) {
            Write-Warning "Leaving unrecognized savestate filename untouched: $($file.Name)"
            continue
        }

        if (-not $match.Groups['stem'].Value.Equals(
            $expectedStem,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            continue
        }

        $slotText = $match.Groups['slot'].Value

        try {
            [long]$slot = $slotText
        }
        catch {
            Write-Warning "Leaving savestate with invalid slot untouched: $($file.Name)"
            continue
        }

        [pscustomobject]@{
            File             = $file
            Stem             = $match.Groups['stem'].Value
            Slot             = $slot
            OriginalSlotText = $slotText
            Width            = [Math]::Max(2, $slotText.Length)
        }
    }
)

if ($parsedStates.Count -eq 0) {
    Write-Warning "No savestates found for $canonicalGame ($expectedStem)."
    return
}

if (
    $Cleanup -and
    (Test-Path -LiteralPath $destinationFull -PathType Container) -and
    $PSCmdlet.ShouldProcess(
        $destinationFull,
        'Move existing target directory to Recycle Bin'
    )
) {
    Add-Type -AssemblyName Microsoft.VisualBasic
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
        $destinationFull,
        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
    )
}

if (-not (Test-Path -LiteralPath $destinationFull -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($destinationFull, 'Create destination directory')) {
        New-Item `
            -ItemType Directory `
            -Path $destinationFull `
            -Force `
            -ErrorAction Stop |
            Out-Null
    }
}

$reservedTargets = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)

$slotGroups = @(
    $parsedStates |
    Group-Object -Property Slot |
    Sort-Object {
        [long]$_.Name
    }
)

foreach ($slotGroup in $slotGroups) {
    [long]$candidateSlot = [long]$slotGroup.Name

    do {
        $plans = @(
            foreach ($state in $slotGroup.Group) {
                $slotFormat = 'D{0}' -f $state.Width
                $candidateSlotText = $candidateSlot.ToString(
                    $slotFormat,
                    [Globalization.CultureInfo]::InvariantCulture
                )
                $targetName = '{0}.{1}.p2s' -f (
                    $state.Stem,
                    $candidateSlotText
                )
                $targetPath = Join-Path `
                    -Path $destinationFull `
                    -ChildPath $targetName

                [pscustomobject]@{
                    State             = $state
                    CandidateSlot     = $candidateSlot
                    CandidateSlotText = $candidateSlotText
                    TargetName        = $targetName
                    TargetPath        = $targetPath
                }
            }
        )

        $hasConflict = $false

        foreach ($plan in $plans) {
            if (
                (Test-Path -LiteralPath $plan.TargetPath) -or
                $reservedTargets.Contains($plan.TargetPath)
            ) {
                $hasConflict = $true
                break
            }
        }

        if ($hasConflict) {
            if ($candidateSlot -gt ([long]::MaxValue - 10)) {
                throw "Could not allocate another slot for source slot $($slotGroup.Name)."
            }

            $candidateSlot += 10
        }
    }
    while ($hasConflict)

    foreach ($plan in $plans) {
        [void]$reservedTargets.Add($plan.TargetPath)
    }

    foreach ($plan in $plans) {
        $sourcePath = $plan.State.File.FullName

        if ($PSCmdlet.ShouldProcess(
            $plan.TargetPath,
            "Move '$sourcePath'"
        )) {
            Move-Item `
                -LiteralPath $sourcePath `
                -Destination $plan.TargetPath `
                -ErrorAction Stop

            [pscustomobject]@{
                Game               = $canonicalGame
                Target             = $Target
                Source             = $plan.State.File.Name
                Destination        = $plan.TargetName
                OriginalSlot       = $plan.State.OriginalSlotText
                NewSlot            = $plan.CandidateSlotText
                RenamedForConflict = (
                    $plan.CandidateSlot -ne $plan.State.Slot
                )
            }
        }
    }
}
