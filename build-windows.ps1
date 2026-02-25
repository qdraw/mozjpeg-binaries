$ErrorActionPreference = "Stop"

# -------- Configuration --------
$MozJpegVersion = "4.1.1"
$Root = Resolve-Path "."
$BuildDir = Join-Path $Root "build"
$OutDir = Join-Path $Root "out"
$VcpkgDir = Join-Path $Root "vcpkg"

New-Item -ItemType Directory -Force -Path $BuildDir, $OutDir | Out-Null

# -------- Clone vcpkg --------
if (-not (Test-Path $VcpkgDir)) {
    Write-Host "Cloning vcpkg..."
    git clone https://github.com/microsoft/vcpkg.git $VcpkgDir
}

# -------- Bootstrap vcpkg --------
Write-Host "Bootstrapping vcpkg..."
& "$VcpkgDir\bootstrap-vcpkg.bat"

# -------- Detect architecture --------
$Triplet = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    "arm64-windows-static"
} else {
    "x64-windows-static"
}

# -------- Install dependencies (static) --------
Write-Host "Installing dependencies ($Triplet)..."
& "$VcpkgDir\vcpkg.exe" install `
    "libpng:$Triplet" `
    "zlib:$Triplet"

# -------- Download mozjpeg --------
$Tarball = Join-Path $Root "mozjpeg.tar.gz"
if (-not (Test-Path $Tarball)) {
    Write-Host "Downloading mozjpeg..."
    Invoke-WebRequest `
        -Uri "https://github.com/mozilla/mozjpeg/archive/refs/tags/v$MozJpegVersion.tar.gz" `
        -OutFile $Tarball
}

# -------- Extract --------
Write-Host "Extracting source..."
tar -xzf $Tarball -C $BuildDir --strip-components=1

Push-Location $BuildDir

# -------- Map vcpkg installed bin/include for triplet --------
$VcpkgTripletBin = Join-Path $VcpkgDir "installed/$Triplet/bin"
$VcpkgTripletLib = Join-Path $VcpkgDir "installed/$Triplet/lib"
$VcpkgTripletInclude = Join-Path $VcpkgDir "installed/$Triplet/include"
if (Test-Path $VcpkgTripletBin) { $env:PATH = "$VcpkgTripletBin;$env:PATH" }
if (Test-Path $VcpkgTripletLib) { $env:PATH = "$VcpkgTripletLib;$env:PATH" }
$env:VCPKG_ROOT = $VcpkgDir

Write-Host "Using vcpkg triplet: $Triplet"
Write-Host "Vcpkg bin: $VcpkgTripletBin"
Write-Host "Vcpkg lib: $VcpkgTripletLib"
Write-Host "Vcpkg include: $VcpkgTripletInclude"

# -------- Map CMake from vcpkg (dynamic, version-agnostic) --------
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Host "CMake not found on PATH, locating vcpkg CMake..."

    $CMakeRoot = Join-Path $VcpkgDir 'downloads\tools'
    if (-not (Test-Path $CMakeRoot)) {
        throw "vcpkg tools directory not found: $CMakeRoot"
    }

    $CMakeBin = Get-ChildItem $CMakeRoot -Directory |
        Where-Object { $_.Name -like 'cmake-*' } |
        ForEach-Object {
            Get-ChildItem $_.FullName -Directory |
            Where-Object { $_.Name -like 'cmake-*windows*' } |
            ForEach-Object {
                Join-Path $_.FullName 'bin'
            }
        } |
        Where-Object { Test-Path (Join-Path $_ 'cmake.exe') } |
        Sort-Object |
        Select-Object -Last 1

    if (-not $CMakeBin) {
        throw "cmake.exe not found in vcpkg downloads/tools"
    }

    Write-Host "Using CMake from vcpkg: $CMakeBin"
    $env:PATH = "$CMakeBin;$env:PATH"
}

# -------- CMake configure --------
$Toolchain = Join-Path $VcpkgDir "scripts/buildsystems/vcpkg.cmake"

Write-Host "Configuring CMake..."
cmake `
  -G "Visual Studio 17 2022" `
  -A x64 `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_TOOLCHAIN_FILE="$Toolchain" `
  -DBUILD_SHARED_LIBS=OFF `
  -DENABLE_SHARED=OFF `
  -DWITH_TURBOJPEG=ON `
  -DPNG_SHARED=OFF `
  -DPNG_SUPPORTED=NO `
  -DZLIB_USE_STATIC_LIBS=ON `
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded `
  .

# -------- Build --------
Write-Host "Building..."
cmake --build . --config Release

# -------- Copy output --------
$Exe = Get-ChildItem -Recurse -Filter cjpeg-static.exe | Select-Object -First 1
if (-not $Exe) {
    Pop-Location
    throw "cjpeg-static.exe not found"
}

Copy-Item $Exe.FullName (Join-Path $OutDir "cjpeg-static.exe") -Force
Copy-Item $Exe.FullName (Join-Path $OutDir "mozjpeg.exe") -Force

Pop-Location

Write-Host "mozjpeg build complete"
Write-Host "Output: $(Join-Path $OutDir "cjpeg-static.exe")"
Write-Host "Output: $(Join-Path $OutDir "mozjpeg.exe")"
