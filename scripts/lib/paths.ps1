Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'pinned_packages.ps1')

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

# Workshop's paths.py resolves every manifest; one result serves every caller
# within the same command line.
function Invoke-UnWorkshopPathLoader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,
        [switch]$Workshop,
        [switch]$Local,
        [switch]$NoGames
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Path manifest not found: $ManifestPath"
    }
    $manifest = (Get-Item -LiteralPath $ManifestPath).FullName
    $cacheKey = "$($MyInvocation.HistoryId)|$manifest|$Workshop|$Local|$NoGames"
    $cache = Get-Variable -Name UnWorkshopPathCache -Scope Global -ValueOnly `
        -ErrorAction SilentlyContinue
    if ($cache -isnot [hashtable]) {
        $cache = @{}
        Set-Variable -Name UnWorkshopPathCache -Scope Global -Value $cache
    }
    if ($cache.ContainsKey($cacheKey)) {
        return $cache[$cacheKey]
    }

    $arguments = @('-B', (Join-Path $PSScriptRoot 'paths.py'), $manifest)
    if ($Workshop) { $arguments += '--workshop' }
    if ($Local) { $arguments += '--local' }
    if ($NoGames) { $arguments += '--no-games' }
    $output = @(& (Get-UnPython) @arguments 2>&1)
    $lines = [string[]]@($output | ForEach-Object { [string]$_ })
    if ($LASTEXITCODE -ne 0) {
        throw "Paths could not be resolved: $($lines -join "`n")"
    }
    $loaded = ($lines -join "`n") | ConvertFrom-Json
    $cache[$cacheKey] = $loaded
    return $loaded
}

# A project's paths with each root as a property, plus its files, settings and
# games.
function Resolve-UnWorkshopManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,
        [switch]$Local
    )

    $loaded = Invoke-UnWorkshopPathLoader `
        -ManifestPath $ManifestPath `
        -Local:$Local
    $resolved = [ordered]@{ ManifestPath = [string]$loaded.manifest }
    foreach ($root in $loaded.roots.PSObject.Properties) {
        $resolved[$root.Name] = [string]$root.Value
    }
    if ($null -ne $loaded.settings) {
        $resolved['settings'] = $loaded.settings
    }
    $resolved['files'] = $loaded.files
    $entries = [ordered]@{}
    $aliases = [ordered]@{}
    foreach ($game in $loaded.games.PSObject.Properties) {
        foreach ($alias in @($game.Value.aliases)) {
            $aliases[[string]$alias] = $game.Name
        }
        $aliases[$game.Name] = $game.Name
        $entries[$game.Name] = [pscustomobject]@{
            Name = $game.Name
            Config = $game.Value.config
        }
    }
    $resolved['games'] = [pscustomobject]@{
        Entries = [pscustomobject]$entries
        Aliases = [pscustomobject]$aliases
        Names = @($entries.Keys)
    }
    [pscustomobject]$resolved
}

function Get-UnWorkshopPaths {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [switch]$NoProject
    )

    $workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $project = if ($NoProject) {
        $null
    }
    else {
        Find-UnWorkshopProjectRoot -ProjectRoot $ProjectRoot
    }
    $loaded = if ($project) {
        Invoke-UnWorkshopPathLoader `
            -ManifestPath (Join-Path $project 'paths.json') `
            -NoGames
    }
    else {
        Invoke-UnWorkshopPathLoader `
            -ManifestPath (Join-Path $workshop 'paths.json') `
            -Workshop
    }
    $roots = $loaded.roots
    $files = $loaded.files
    $optional = {
        param($Table, [string]$Name)
        $property = $Table.PSObject.Properties[$Name]
        if ($null -ne $property) { [string]$property.Value } else { $null }
    }
    [pscustomobject][ordered]@{
        Workshop = $workshop
        Project = $project
        Source = & $optional $roots 'source'
        Disassembly = & $optional $roots 'disassembly'
        Annotations = & $optional $roots 'annotations'
        Tools = & $optional $roots 'tools'
        Work = & $optional $roots 'work'
        GhidraMcpWork = & $optional $roots 'ghidra_mcp_work'
        Build = & $optional $roots 'build'
        Scripts = & $optional $roots 'scripts'
        SourceCatalog = & $optional $files 'source_catalog'
        ProjectSettings = if ($project) {
            & $optional $files 'project_settings'
        } else { $null }
        Pcsx2Dev = & $optional $roots 'pcsx2_dev'
        Pcsx2Fork = & $optional $roots 'pcsx2_fork'
        Pcsx2Files = & $optional $roots 'pcsx2_files'
        InputProfiles = & $optional $roots 'pcsx2_input_profiles'
        InputRecordings = & $optional $roots 'pcsx2_input_recordings'
        MemoryCards = & $optional $roots 'pcsx2_memory_cards'
        ResolveGame = & $optional $files 'game_resolver'
        Roots = $roots
        Files = $files
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

function Get-UnWorkshopResolvedPropertyNames {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $arguments = @('-B', $paths.ResolveGame, '--properties')
    if ($paths.Project) {
        $arguments += @('--project-root', $paths.Project)
    }
    $output = & (Get-UnPython) @arguments
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
    $output = & (Get-UnPython) @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Game resolver failed for '$Game'."
    }
    ($output -join "`n") | ConvertFrom-Json
}
