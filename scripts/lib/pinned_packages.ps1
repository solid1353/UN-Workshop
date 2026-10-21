Set-StrictMode -Version Latest

# Pinned packages. Workshop's packages.json pins each package by URL and
# SHA-256. A package is downloaded, verified and unpacked once into Workshop's
# cache root, and unpacked again whenever its pin changes.

# The pinned Python. A repository whose own packages.json pins packages gets a
# virtual environment of them, created from that interpreter in its own cache
# root and recreated whenever those pins or the interpreter's pin change.
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
        ([string](Get-Content -Raw -LiteralPath (Join-Path $workshop 'packages.json') |
            ConvertFrom-Json).python.sha256).ToUpperInvariant()
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

# The pinned EE compiler's bin folder: ps2dev's GCC for the R5900 with the
# EABI stack kept 16-byte aligned, as the PS2's native compilers keep it.
function Get-UnEeToolchain {
    [CmdletBinding()]
    param()

    $workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $python = Get-UnPythonRuntime -Workshop $workshop
    $root = Install-UnPinnedPackage -Workshop $workshop -Name 'ee_toolchain' `
        -Executable 'ps2dev\ee\bin\mips64r5900el-ps2-elf-gcc.exe' `
        -Expand {
            param([string]$Archive, [string]$Target)
            & $python -I -c 'import sys, tarfile; tarfile.open(sys.argv[1]).extractall(sys.argv[2], filter="data")' `
                $Archive $Target
            if ($LASTEXITCODE -ne 0) {
                throw 'Could not unpack the pinned EE toolchain.'
            }
        }.GetNewClosure()
    return Join-Path $root 'ps2dev\ee\bin'
}

# The pinned ffmpeg's bin folder: gyan.dev's essentials build, which decodes
# the PSP games' ATRAC3plus audio.
function Get-UnFfmpeg {
    [CmdletBinding()]
    param()

    $workshop = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
    $version = [string](Get-Content -Raw -LiteralPath (Join-Path $workshop 'packages.json') |
        ConvertFrom-Json).ffmpeg.version
    $folder = "ffmpeg-$version-essentials_build"
    $root = Install-UnPinnedPackage -Workshop $workshop -Name 'ffmpeg' `
        -Executable "$folder\bin\ffmpeg.exe" `
        -Expand {
            param([string]$Archive, [string]$Target)
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Target)
        }.GetNewClosure()
    return Join-Path $root "$folder\bin"
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

# The pinned interpreter: the official CPython package, unpacked under
# Workshop's cache root.
function Get-UnPythonRuntime {
    param([Parameter(Mandatory = $true)][string]$Workshop)

    $version = [string](Get-Content -Raw -LiteralPath (Join-Path $Workshop 'packages.json') |
        ConvertFrom-Json).python.version
    $runtime = Install-UnPinnedPackage -Workshop $Workshop -Name 'python' `
        -Folder 'python_runtime' -Executable 'tools\python.exe' `
        -Expand {
            param([string]$Archive, [string]$Target)
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Target)
            $found = & (Join-Path $Target 'tools\python.exe') -c 'import platform; print(platform.python_version())'
            if ($LASTEXITCODE -ne 0 -or [string]$found -cne $version) {
                throw "The pinned Python package reports version '$found', not $version."
            }
        }.GetNewClosure()
    return Join-Path $runtime 'tools\python.exe'
}

# One packages.json pin, unpacked into its own folder under Workshop's cache
# root: downloaded from its pinned URL, refused unless its SHA-256 matches, and
# unpacked by the caller's Expand block. Returns the folder.
function Install-UnPinnedPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Workshop,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Folder = $Name,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][scriptblock]$Expand
    )

    $pin = (Get-Content -Raw -LiteralPath (Join-Path $Workshop 'packages.json') | ConvertFrom-Json).$Name
    $cache = Get-UnCacheRoot -Repository $Workshop
    $target = Join-Path $cache $Folder
    $stampPath = Join-Path $target 'package.sha256'
    $expected = ([string]$pin.sha256).ToUpperInvariant()
    if (Test-UnStamp -Target (Join-Path $target $Executable) -StampPath $stampPath -Expected $expected) {
        return $target
    }
    $mutex = [Threading.Mutex]::new($false, "Local\un-package-$Name")
    [void]$mutex.WaitOne()
    try {
        if (Test-UnStamp -Target (Join-Path $target $Executable) -StampPath $stampPath -Expected $expected) {
            return $target
        }
        Write-Host "[$Name] Downloading $($pin.version) from $($pin.package)..."
        New-Item -ItemType Directory -Path $cache -Force | Out-Null
        $download = Join-Path $cache "$Folder.download"
        try {
            Invoke-WebRequest -Uri ([string]$pin.package) -OutFile $download -UseBasicParsing
            $actual = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash
            if ($actual -cne $expected) {
                throw "The downloaded $Name package's SHA-256 $actual does not match the pinned $expected."
            }
            if (Test-Path -LiteralPath $target) {
                Remove-Item -LiteralPath $target -Recurse -Force
            }
            & $Expand $download $target | Out-Host
            if (-not (Test-Path -LiteralPath (Join-Path $target $Executable) -PathType Leaf)) {
                throw "The pinned $Name package has no $Executable."
            }
        }
        finally {
            Remove-Item -LiteralPath $download -Force -ErrorAction SilentlyContinue
        }
        [IO.File]::WriteAllText($stampPath, $expected)
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
    return $target
}
