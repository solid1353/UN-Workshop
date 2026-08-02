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
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'product.json') -PathType Leaf)
        ) {
            return $candidate.FullName
        }
        $candidate = $candidate.Parent
    }
    return $null
}

function Get-UnWorkshopPaths {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    $workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $manifestPath = Join-Path $workshop 'paths.json'
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ([int]$manifest.schema_version -ne 1) {
        throw "Unsupported Workshop path schema: $($manifest.schema_version)"
    }
    $roots = [ordered]@{}
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
        $match = [regex]::Match(
            $raw,
            '^@(?<root>[^/\\]+)[/\\](?<child>.+)$'
        )
        if (-not $match.Success -or -not $roots.Contains($match.Groups['root'].Value)) {
            throw "Invalid Workshop file alias: $raw"
        }
        $files[$property.Name] = [IO.Path]::GetFullPath((Join-Path `
            ([string]$roots[$match.Groups['root'].Value]) `
            $match.Groups['child'].Value
        ))
    }
    $project = Find-UnWorkshopProjectRoot -ProjectRoot $ProjectRoot
    [pscustomobject][ordered]@{
        Workshop = $roots.repository
        Project = $project
        Source = $roots.source
        Analysis = $roots.analysis
        Tools = $roots.tools
        Savestates = $roots.savestates
        SourceCatalog = $files.game_catalog
        ProjectCatalog = if ($project) {
            Join-Path $project 'product.json'
        } else { $null }
        Pcsx2Stable = $roots.pcsx2_stable
        Pcsx2Dev = $roots.pcsx2_dev
        Pcsx2Clean = $roots.pcsx2_clean
        Pcsx2Files = $roots.pcsx2_files
        Bios = $roots.pcsx2_bios
        Cheats = $roots.pcsx2_cheats
        GameSettings = $roots.pcsx2_game_settings
        InputProfiles = $roots.pcsx2_input_profiles
        InputRecordings = $roots.pcsx2_input_recordings
        MemoryCards = $roots.pcsx2_memory_cards
        ResolveGame = $files.game_resolver
        Roots = [pscustomobject]$roots
        Files = [pscustomobject]$files
    }
}

function Get-UnWorkshopCatalog {
    [CmdletBinding()]
    param([string]$ProjectRoot)

    $paths = Get-UnWorkshopPaths -ProjectRoot $ProjectRoot
    $shared = Get-Content -Raw -LiteralPath $paths.SourceCatalog | ConvertFrom-Json
    if ([int]$shared.schema_version -ne 1) {
        throw "Unsupported Workshop game catalog schema: $($shared.schema_version)"
    }
    $result = [ordered]@{
        Sources = $shared.sources
        Title = $null
        Serial = $null
        Builds = $null
    }
    if ($paths.ProjectCatalog) {
        $project = Get-Content -Raw -LiteralPath $paths.ProjectCatalog | ConvertFrom-Json
        if ([int]$project.schema_version -ne 1) {
            throw "Unsupported project game catalog schema: $($project.schema_version)"
        }
        $result.Title = $project.title
        $result.Serial = $project.serial
        $result.Builds = $project.builds
    }
    [pscustomobject]$result
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
