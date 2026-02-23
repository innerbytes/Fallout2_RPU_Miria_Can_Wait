#Requires -Version 7.0

<#
.SYNOPSIS
    Builds the mcmiria.int script from mcmiria.ssl using the sslc compiler.
.DESCRIPTION
    Downloads compile.exe and parser.dll from the sslc GitHub release,
    then compiles scripts_src/modoc/mcmiria.ssl into mcmiria.int.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sslcTag = '2026-02-07-11-20-26'
$baseUrl = "https://github.com/sfall-team/sslc/releases/download/$sslcTag"
$repoRoot = $PSScriptRoot

# --- Step 1: Download compile.exe and parser.dll to a temp folder ---

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "sslc-$sslcTag"

if (-not (Test-Path $tempDir)) {
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    catch {
        Write-Error "Failed to create temp directory '$tempDir': $_"
        exit 1
    }
}

$files = @('compile.exe', 'parser.dll')

foreach ($file in $files) {
    $url = "$baseUrl/$file"
    $dest = Join-Path $tempDir $file

    if (Test-Path $dest) {
        Write-Host "Already downloaded: $dest"
        continue
    }

    Write-Host "Downloading $url ..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download '$url'. Check your internet connection and that the release exists.`n$_"
        exit 1
    }

    if (-not (Test-Path $dest)) {
        Write-Error "Download appeared to succeed but '$dest' was not found on disk."
        exit 1
    }

    Write-Host "Saved: $dest"
}

$compilePath = Join-Path $tempDir 'compile.exe'

# --- Step 2: Change to scripts_src/modoc ---

$modocDir = Join-Path $repoRoot 'scripts_src' 'modoc'

if (-not (Test-Path $modocDir)) {
    Write-Error "Source directory not found: '$modocDir'. Make sure you are running this script from the repository root."
    exit 1
}

Push-Location $modocDir
Write-Host "Working directory: $modocDir"

try {
    # --- Step 3: Compile mcmiria.ssl ---

    $sslFile = 'mcmiria.ssl'
    $intFile = 'mcmiria.int'

    if (-not (Test-Path $sslFile)) {
        Write-Error "Source file '$sslFile' not found in '$modocDir'."
        exit 1
    }

    # Remove stale output if present
    if (Test-Path $intFile) {
        Remove-Item $intFile -Force
    }

    Write-Host "Compiling $sslFile ..."
    & $compilePath -p -l -O2 -s -q -n $sslFile -o $intFile

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation failed with exit code $LASTEXITCODE."
        exit 1
    }

    # --- Step 4: Verify output ---

    if (-not (Test-Path $intFile)) {
        Write-Error "Compilation appeared to succeed (exit code 0) but '$intFile' was not created in '$modocDir'."
        exit 1
    }

    $fullIntPath = (Resolve-Path $intFile).Path
    Write-Host "Build successful: $fullIntPath"
}
finally {
    Pop-Location
}
