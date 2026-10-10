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

    $workshopManifest = [IO.Path]::GetFullPath((
        Join-Path $PSScriptRoot '..\..\paths.json'
    ))
    $candidate = Get-Item -LiteralPath (Get-Location).Path
    while ($null -ne $candidate) {
        $manifestPath = Join-Path $candidate.FullName 'paths.json'
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            try {
                $manifest = Get-Content -Raw -LiteralPath $manifestPath |
                    ConvertFrom-Json
            }
            catch {
                $manifest = $null
            }
            if ($null -ne $manifest) {
                $imports = $manifest.PSObject.Properties['imports']
                if ($null -ne $imports) {
                    $workshop = $imports.Value.PSObject.Properties['workshop']
                    if ($null -ne $workshop -and
                        -not [string]::IsNullOrWhiteSpace([string]$workshop.Value)) {
                        $importPath = [IO.Path]::GetFullPath((
                            Join-Path $candidate.FullName ([string]$workshop.Value)
                        ))
                        if ([string]::Equals(
                            $importPath,
                            $workshopManifest,
                            [StringComparison]::OrdinalIgnoreCase
                        )) {
                            return $candidate.FullName
                        }
                    }
                }
            }
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
        Annotations = $effectiveRoots.annotations
        Tools = $effectiveRoots.tools
        Work = if ($effectiveRoots.Contains('work')) {
            $effectiveRoots.work
        } else { $null }
        GhidraMcpWork = if ($effectiveRoots.Contains('ghidra_mcp_work')) {
            $effectiveRoots.ghidra_mcp_work
        } else { $null }
        Build = if ($effectiveRoots.Contains('build')) {
            $effectiveRoots.build
        } else { $null }
        Scripts = $effectiveRoots.scripts
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

function Get-UnWorkshopTaskContext {
    # The acting task's folder, an immediate child of a project's work root, and
    # that project's paths.
    if ([string]::IsNullOrWhiteSpace($env:UN_TASK_WORK_ROOT)) {
        throw 'UN_TASK_WORK_ROOT must name the current chat work directory.'
    }
    $taskRoot = [IO.Path]::GetFullPath($env:UN_TASK_WORK_ROOT)
    $workRoot = [IO.Path]::GetDirectoryName($taskRoot)
    $projectRoot = [IO.Path]::GetDirectoryName($workRoot)
    $paths = Get-UnWorkshopPaths -ProjectRoot $projectRoot
    if ($null -eq $paths.Work -or
        -not [IO.Path]::Equals($workRoot, [IO.Path]::GetFullPath($paths.Work)) -or
        [string]::IsNullOrWhiteSpace([IO.Path]::GetFileName($taskRoot))) {
        throw 'UN_TASK_WORK_ROOT must name an immediate child of work/.'
    }
    [pscustomobject]@{
        Root = $taskRoot
        Paths = $paths
    }
}

function Get-UnWorkshopCatalog {
    [CmdletBinding()]
    param()

    $paths = Get-UnWorkshopPaths -NoProject
    $shared = Get-Content -Raw -LiteralPath $paths.SourceCatalog | ConvertFrom-Json
    [pscustomobject][ordered]@{
        Sources = $shared.sources
    }
}

function Get-UnWorkshopAvailableGameNames {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $arguments = @('-B', $paths.ResolveGame, '--available-sources')
    if ($paths.Project) {
        $arguments += @('--project-root', $paths.Project)
    }
    $output = & python @arguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Game resolver failed to list available sources.'
    }
    @(($output -join "`n") | ConvertFrom-Json)
}

function Get-UnWorkshopResolvedPropertyNames {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $arguments = @('-B', $paths.ResolveGame, '--properties')
    if ($paths.Project) {
        $arguments += @('--project-root', $paths.Project)
    }
    $output = & python @arguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Game resolver failed to list its properties.'
    }
    @(($output -join "`n") | ConvertFrom-Json)
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
