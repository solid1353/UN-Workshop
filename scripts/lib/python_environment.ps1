Set-StrictMode -Version Latest

# The pinned Python. Workshop's packages.json pins the official CPython
# package, which is downloaded, verified and unpacked once into Workshop's
# cache root. A repository whose own packages.json pins packages gets a virtual
# environment of them, created from that interpreter in its own cache root and
# recreated whenever either pin file changes.
function Get-UnPython {
    [CmdletBinding()]
    param([string]$Repository)

    $workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $runtime = Get-UnPythonRuntime -Workshop $workshop
    if (-not $Repository -or [IO.Path]::GetFullPath($Repository) -eq $workshop) {
        return $runtime
    }

    $pinsPath = Join-Path $Repository 'packages.json'
    $pins = Get-Content -Raw -LiteralPath $pinsPath | ConvertFrom-Json
    $environment = Join-Path (Get-UnCacheRoot -Repository $Repository) 'python'
    $python = Join-Path $environment 'Scripts\python.exe'
    $stampPath = Join-Path $environment 'packages.sha256'
    $expected = (Get-FileHash -LiteralPath $pinsPath -Algorithm SHA256).Hash +
        (Get-FileHash -LiteralPath (Join-Path $workshop 'packages.json') -Algorithm SHA256).Hash
    if (Test-UnStamp -Target $python -StampPath $stampPath -Expected $expected) {
        return $python
    }
    # Parallel runs wait for one creation instead of racing it.
    $mutex = [Threading.Mutex]::new($false, 'Local\un-python-environment')
    [void]$mutex.WaitOne()
    try {
        if (Test-UnStamp -Target $python -StampPath $stampPath -Expected $expected) {
            return $python
        }
        Write-Host "[python] Creating the pinned Python environment in $environment..."
        if (Test-Path -LiteralPath $environment) {
            Remove-Item -LiteralPath $environment -Recurse -Force
        }
        & $runtime -m venv $environment *>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not create the pinned Python environment.'
        }
        $requirements = Join-Path $environment 'requirements.txt'
        [IO.File]::WriteAllLines($requirements, [string[]]@($pins.requirements))
        & $python -B -m pip install --disable-pip-version-check --require-hashes `
            --only-binary=:all: --requirement $requirements *>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not install the pinned Python packages.'
        }
        [IO.File]::WriteAllText($stampPath, $expected)
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
    return $python
}

# A repository's cache root, read straight from its paths.json: the path
# loaders themselves run on this Python.
function Get-UnCacheRoot {
    param([Parameter(Mandatory = $true)][string]$Repository)

    $manifest = Get-Content -Raw -LiteralPath (Join-Path $Repository 'paths.json') | ConvertFrom-Json
    $cacheRoot = [string]$manifest.roots.cache
    if ($cacheRoot -cnotmatch '^[A-Za-z0-9._-]+$') {
        throw "$Repository's paths.json cache root must be one plain repository folder; found '$cacheRoot'."
    }
    return Join-Path $Repository $cacheRoot
}

function Test-UnStamp {
    param([string]$Target, [string]$StampPath, [string]$Expected)

    return (Test-Path -LiteralPath $Target -PathType Leaf) -and
        (Test-Path -LiteralPath $StampPath -PathType Leaf) -and
        ((Get-Content -Raw -LiteralPath $StampPath).Trim() -ceq $Expected)
}

# The pinned interpreter: the official CPython package from its pinned URL,
# refused unless its SHA-256 matches, unpacked once under Workshop's cache root.
function Get-UnPythonRuntime {
    param([Parameter(Mandatory = $true)][string]$Workshop)

    $pin = (Get-Content -Raw -LiteralPath (Join-Path $Workshop 'packages.json') | ConvertFrom-Json).python
    $cache = Get-UnCacheRoot -Repository $Workshop
    $runtime = Join-Path $cache 'python_runtime'
    $python = Join-Path $runtime 'tools\python.exe'
    $stampPath = Join-Path $runtime 'package.sha256'
    $expected = ([string]$pin.sha256).ToUpperInvariant()
    if (Test-UnStamp -Target $python -StampPath $stampPath -Expected $expected) {
        return $python
    }
    $mutex = [Threading.Mutex]::new($false, 'Local\un-python-runtime')
    [void]$mutex.WaitOne()
    try {
        if (Test-UnStamp -Target $python -StampPath $stampPath -Expected $expected) {
            return $python
        }
        Write-Host "[python] Downloading Python $($pin.version) from $($pin.package)..."
        New-Item -ItemType Directory -Path $cache -Force | Out-Null
        $download = Join-Path $cache 'python_runtime.download'
        try {
            Invoke-WebRequest -Uri ([string]$pin.package) -OutFile $download -UseBasicParsing
            $actual = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash
            if ($actual -cne $expected) {
                throw "The downloaded Python package's SHA-256 $actual does not match the pinned $expected."
            }
            if (Test-Path -LiteralPath $runtime) {
                Remove-Item -LiteralPath $runtime -Recurse -Force
            }
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [IO.Compression.ZipFile]::ExtractToDirectory($download, $runtime)
        }
        finally {
            Remove-Item -LiteralPath $download -Force -ErrorAction SilentlyContinue
        }
        $found = & $python -c 'import platform; print(platform.python_version())'
        if ($LASTEXITCODE -ne 0 -or [string]$found -cne [string]$pin.version) {
            throw "The pinned Python package reports version '$found', not $($pin.version)."
        }
        [IO.File]::WriteAllText($stampPath, $expected)
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
    return $python
}
