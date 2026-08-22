Set-StrictMode -Version Latest

function Find-UnWorkshopProjectRoot {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        return [IO.Path]::GetFullPath($ProjectRoot)
    }
    $configured = Get-Variable `
        -Name UNWorkshopProjectRoot `
        -Scope Global `
        -ValueOnly `
        -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace([string]$configured)) {
        return [IO.Path]::GetFullPath([string]$configured)
    }

    $candidate = Get-Item -LiteralPath (Get-Location).Path
    while ($null -ne $candidate) {
        if (
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'paths.json') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'game.json') -PathType Leaf)
        ) {
            return $candidate.FullName
        }
        $candidate = $candidate.Parent
    }
    return $null
}

function Get-UnWorkshopPaths {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [switch]$NoProject
    )

    $workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $manifestPath = Join-Path $workshop 'paths.json'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $roots = [ordered]@{ repository = $workshop }
    $pending = [Collections.Generic.List[string]]::new()
    foreach ($name in $manifest.roots.PSObject.Properties.Name) {
        $pending.Add($name)
    }
    while ($pending.Count -gt 0) {
        $progress = $false
        foreach ($name in @($pending)) {
            $raw = [string]$manifest.roots.$name
            $base = $workshop
            $child = $raw
            if ($raw.StartsWith('@')) {
                $match = [regex]::Match(
                    $raw,
                    '^@(?<root>[^/\\]+)(?:[/\\](?<child>.*))?$'
                )
                if (-not $match.Success) {
                    throw "Invalid Workshop root alias: $raw"
                }
                $parent = $match.Groups['root'].Value
                if (-not $roots.Contains($parent)) { continue }
                $base = [string]$roots[$parent]
                $child = $match.Groups['child'].Value
            }
            elseif ([IO.Path]::IsPathRooted($raw)) {
                throw "Workshop root '$name' must be relative: $raw"
            }
            $value = [IO.Path]::GetFullPath((Join-Path $base $child))
            if ($raw.StartsWith('@')) {
                $prefix = $base.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
                if (-not [IO.Path]::Equals($value, $base) -and
                    -not $value.StartsWith(
                        $prefix,
                        [StringComparison]::OrdinalIgnoreCase
                    )) {
                    throw "Workshop root '$name' escapes its parent: $raw"
                }
            }
            $roots[$name] = $value
            [void]$pending.Remove($name)
            $progress = $true
        }
        if (-not $progress) {
            throw "Workshop root aliases contain a dependency cycle: $($pending -join ', ')"
        }
    }
    $files = [ordered]@{}
    foreach ($property in $manifest.files.PSObject.Properties) {
        $raw = [string]$property.Value
        if ($raw.StartsWith('@')) {
            $match = [regex]::Match(
                $raw,
                '^@(?<root>[^/\\]+)[/\\](?<child>.+)$'
            )
            if (-not $match.Success -or -not $roots.Contains($match.Groups['root'].Value)) {
                throw "Invalid Workshop file alias: $raw"
            }
            $base = [string]$roots[$match.Groups['root'].Value]
            $child = $match.Groups['child'].Value
        }
        else {
            $base = $workshop
            $child = $raw
        }
        $files[$property.Name] = [IO.Path]::GetFullPath((Join-Path `
            $base `
            $child
        ))
    }
    $project = if ($NoProject) {
        $null
    }
    else {
        Find-UnWorkshopProjectRoot -ProjectRoot $ProjectRoot
    }
    $effectiveRoots = [ordered]@{}
    foreach ($name in $roots.Keys) {
        $effectiveRoots[$name] = $roots[$name]
    }
    $effectiveFiles = [ordered]@{}
    foreach ($name in $files.Keys) {
        $effectiveFiles[$name] = $files[$name]
    }
    if ($project) {
        $projectManifestPath = Join-Path $project 'paths.json'
        $projectManifest = Get-Content -Raw -LiteralPath $projectManifestPath |
            ConvertFrom-Json
        $localRootNames = @($projectManifest.roots.PSObject.Properties.Name)
        if ($localRootNames.Count -eq 0) {
            throw 'Project path manifest has no roots.'
        }
        $effectiveRoots.workshop = $roots.repository
        $effectiveRoots.repository = $project
        $pending = [Collections.Generic.List[string]]::new()
        foreach ($name in $localRootNames) {
            $pending.Add($name)
        }
        while ($pending.Count -gt 0) {
            $progress = $false
            foreach ($name in @($pending)) {
                $raw = [string]$projectManifest.roots.$name
                $base = $project
                $child = $raw
                if ($raw.StartsWith('@')) {
                    $match = [regex]::Match(
                        $raw,
                        '^@(?<root>[^/\\]+)(?:[/\\](?<child>.*))?$'
                    )
                    if (-not $match.Success) {
                        throw "Invalid project root alias: $raw"
                    }
                    $parent = $match.Groups['root'].Value
                    if ($pending.Contains($parent)) { continue }
                    if (-not $effectiveRoots.Contains($parent)) {
                        throw "Unknown project root alias: $raw"
                    }
                    $base = [string]$effectiveRoots[$parent]
                    $child = $match.Groups['child'].Value
                }
                elseif ([IO.Path]::IsPathRooted($raw)) {
                    throw "Project root '$name' must be relative: $raw"
                }
                $value = [IO.Path]::GetFullPath((Join-Path $base $child))
                if ($raw.StartsWith('@')) {
                    $prefix = $base.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
                    if (-not [IO.Path]::Equals($value, $base) -and
                        -not $value.StartsWith(
                            $prefix,
                            [StringComparison]::OrdinalIgnoreCase
                        )) {
                        throw "Project root '$name' escapes its parent: $raw"
                    }
                }
                $effectiveRoots[$name] = $value
                [void]$pending.Remove($name)
                $progress = $true
            }
            if (-not $progress) {
                throw "Project root aliases contain a dependency cycle: $($pending -join ', ')"
            }
        }
        if (-not [IO.Path]::Equals([string]$effectiveRoots.repository, $project)) {
            throw "The project 'repository' root must contain paths.json."
        }
        foreach ($property in $projectManifest.files.PSObject.Properties) {
            $raw = [string]$property.Value
            if ($raw.StartsWith('@')) {
                $match = [regex]::Match(
                    $raw,
                    '^@(?<root>[^/\\]+)[/\\](?<child>.+)$'
                )
                if (-not $match.Success -or
                    -not $effectiveRoots.Contains($match.Groups['root'].Value)) {
                    throw "Invalid project file alias: $raw"
                }
                $base = [string]$effectiveRoots[$match.Groups['root'].Value]
                $child = $match.Groups['child'].Value
            }
            else {
                $base = $project
                $child = $raw
            }
            $effectiveFiles[$property.Name] = [IO.Path]::GetFullPath((Join-Path `
                $base `
                $child
            ))
        }
    }
    [pscustomobject][ordered]@{
        Workshop = $roots.repository
        Project = $project
        Source = $effectiveRoots.source
        Disassembly = $effectiveRoots.disassembly
        Tools = $effectiveRoots.tools
        Work = $effectiveRoots.work
        Build = if ($effectiveRoots.Contains('build')) {
            $effectiveRoots.build
        } else { $null }
        Scripts = $effectiveRoots.scripts
        Savestates = $effectiveRoots.savestates
        SourceCatalog = $effectiveFiles.source_catalog
        ProjectSettings = if ($project) {
            $effectiveFiles.project_settings
        } else { $null }
        Pcsx2Dev = $effectiveRoots.pcsx2_dev
        Pcsx2Fork = $effectiveRoots.pcsx2_fork
        Pcsx2Files = $effectiveRoots.pcsx2_files
        InputProfiles = $effectiveRoots.pcsx2_input_profiles
        InputRecordings = $effectiveRoots.pcsx2_input_recordings
        MemoryCards = $effectiveRoots.pcsx2_memory_cards
        ResolveGame = $effectiveFiles.game_resolver
        Roots = [pscustomobject]$effectiveRoots
        Files = [pscustomobject]$effectiveFiles
    }
}

function Get-UnWorkshopCatalog {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $shared = Get-Content -Raw -LiteralPath $paths.SourceCatalog | ConvertFrom-Json
    $result = [ordered]@{
        Sources = $shared.sources
        Title = $null
        Serial = $null
        Builds = $null
    }
    if ($paths.ProjectSettings) {
        $project = Get-Content -Raw -LiteralPath $paths.ProjectSettings | ConvertFrom-Json
        $result.Title = $project.title
        $result.Serial = $project.serial
        $result.Builds = $project.builds
    }
    [pscustomobject]$result
}

function Resolve-UnWorkshopRecordingName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Root,
        [switch]$CreateParent
    )

    if ([string]::IsNullOrWhiteSpace($Name) -or [IO.Path]::IsPathRooted($Name)) {
        throw 'Input recording must be a relative path.'
    }
    if (-not $Name.EndsWith('.p2m2', [StringComparison]::OrdinalIgnoreCase)) {
        $Name = "$Name.p2m2"
    }
    $recordingRoot = [IO.Path]::GetFullPath($Root)
    $recordingPrefix = $recordingRoot.TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    ) + [IO.Path]::DirectorySeparatorChar
    $recordingPath = [IO.Path]::GetFullPath((Join-Path $recordingRoot $Name))
    if (-not $recordingPath.StartsWith(
        $recordingPrefix,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Input recording must be inside $recordingRoot."
    }
    if ($CreateParent) {
        [void](New-Item -ItemType Directory -Path (
            [IO.Path]::GetDirectoryName($recordingPath)
        ) -Force)
    }
    return [IO.Path]::GetRelativePath($recordingRoot, $recordingPath)
}

function Resolve-UnWorkshopGame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Game,
        [string]$ProjectRoot
    )

    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $arguments = @('-B', $paths.ResolveGame, $Game)
    if ($paths.Project) {
        $arguments += @('--project-root', $paths.Project)
    }
    $output = & python @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Game resolver failed for '$Game'."
    }
    ($output -join "`n") | ConvertFrom-Json
}
