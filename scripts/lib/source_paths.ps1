Set-StrictMode -Version Latest
$script:UnWorkshopSourceRoots = @{}

function Get-UnWorkshopSourceRoots {
    param([Parameter(Mandatory)][object]$Paths)

    $key = [IO.Path]::GetFullPath($Paths.Source)
    if ($script:UnWorkshopSourceRoots.ContainsKey($key)) {
        return $script:UnWorkshopSourceRoots[$key]
    }
    $catalog = Get-UnWorkshopCatalog
    $roots = @(foreach ($source in $catalog.Sources.PSObject.Properties) {
        [pscustomobject]@{
            Name = "source_$($source.Name.ToLowerInvariant())"
            Game = $source.Name
            Path = [IO.Path]::GetFullPath((Join-Path $Paths.Source ($source.Name + '.iso.files')))
        }
    })
    $script:UnWorkshopSourceRoots[$key] = $roots
    return $roots
}

function Resolve-UnWorkshopSourceAlias {
    param(
        [Parameter(Mandatory)][string]$Alias,
        [Parameter(Mandatory)][object]$Paths
    )

    $match = [regex]::Match($Alias, '^@(?<root>source_[^/\\]+)[/\\](?<child>.+)$')
    if (-not $match.Success) { throw "Invalid source alias: $Alias" }
    $root = Get-UnWorkshopSourceRoots -Paths $Paths |
        Where-Object Name -eq $match.Groups['root'].Value |
        Select-Object -First 1
    if ($null -eq $root) { throw "Unknown source alias: $Alias" }
    $child = $match.Groups['child'].Value
    if ([IO.Path]::IsPathRooted($child)) { throw "Invalid source alias: $Alias" }
    $resolved = [IO.Path]::GetFullPath((Join-Path $root.Path $child))
    $prefix = $root.Path.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Source alias escapes its root: $Alias"
    }
    return $resolved
}

function ConvertTo-UnWorkshopConfiguredPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object]$Paths
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $roots = @(
        Get-UnWorkshopSourceRoots -Paths $Paths |
            Select-Object Name, Path
    )
    if ($null -ne $Paths.Work) {
        $roots += [pscustomobject]@{ Name = 'work'; Path = $Paths.Work }
    }
    $roots += [pscustomobject]@{ Name = 'source'; Path = $Paths.Source }
    $roots += [pscustomobject]@{ Name = 'disassembly'; Path = $Paths.Disassembly }
    foreach ($root in $roots | Sort-Object { $_.Path.Length } -Descending) {
        $rootPath = [IO.Path]::GetFullPath([string]$root.Path)
        if ([IO.Path]::Equals($fullPath, $rootPath)) { return "@$($root.Name)" }
        $prefix = $rootPath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if ($fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            $relative = $fullPath.Substring($prefix.Length).Replace('\', '/')
            return "@$($root.Name)/$relative"
        }
    }
    throw "Path is outside configured Workshop roots: $Path"
}
