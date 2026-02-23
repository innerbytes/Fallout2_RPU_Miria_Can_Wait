#Requires -Version 7.0

<#
.SYNOPSIS
    Packs the "Miria Can Wait" patch into a distributable miria.zip file.
.DESCRIPTION
    Collects install.ps1, the compiled mcmiria.int, all language dialog files,
    and a generated readme.txt into miria.zip with preserved folder structure.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$zipName = 'miria.zip'
$zipPath = Join-Path $repoRoot $zipName

# ---------------------------------------------------------------------------
# Verify that mcmiria.int exists (must run build.ps1 first)
# ---------------------------------------------------------------------------
$intFile = Join-Path $repoRoot 'scripts_src' 'modoc' 'mcmiria.int'
if (-not (Test-Path $intFile)) {
    Write-Error "mcmiria.int not found at '$intFile'. Run build.ps1 first to compile the script."
    exit 1
}

# ---------------------------------------------------------------------------
# Create a temporary staging directory
# ---------------------------------------------------------------------------
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "miria-pack-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
Write-Host "Staging directory: $stagingDir"

try {
    # All files go under a miria_can_wait subfolder inside the staging dir
    $innerDir = Join-Path $stagingDir 'miria_can_wait'
    New-Item -ItemType Directory -Path $innerDir -Force | Out-Null

    # -------------------------------------------------------------------
    # 1. install.ps1
    # -------------------------------------------------------------------
    $srcInstall = Join-Path $repoRoot 'install.ps1'
    if (-not (Test-Path $srcInstall)) {
        Write-Error "install.ps1 not found in '$repoRoot'."
        exit 1
    }
    Copy-Item -Path $srcInstall -Destination $innerDir
    Write-Host 'Added: install.ps1'

    # -------------------------------------------------------------------
    # 2. scripts_src/modoc/mcmiria.int
    # -------------------------------------------------------------------
    $dstIntDir = Join-Path $innerDir 'scripts_src' 'modoc'
    New-Item -ItemType Directory -Path $dstIntDir -Force | Out-Null
    Copy-Item -Path $intFile -Destination $dstIntDir
    Write-Host 'Added: scripts_src/modoc/mcmiria.int'

    # -------------------------------------------------------------------
    # 3. data/text/<lang>/dialog/mcmiria.msg  (+ dialog_female where present)
    # -------------------------------------------------------------------
    $srcTextDir = Join-Path $repoRoot 'data' 'text'
    $langDirs = Get-ChildItem -Path $srcTextDir -Directory |
    Where-Object { $_.Name -ne 'po' }

    foreach ($lang in $langDirs) {
        $langName = $lang.Name

        # dialog/mcmiria.msg
        $srcMsg = Join-Path $lang.FullName 'dialog' 'mcmiria.msg'
        if (Test-Path $srcMsg) {
            $dstDir = Join-Path $innerDir 'data' 'text' $langName 'dialog'
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Copy-Item -Path $srcMsg -Destination $dstDir
            Write-Host "Added: data/text/$langName/dialog/mcmiria.msg"
        }

        # dialog_female/mcmiria.msg (if exists)
        $srcMsgF = Join-Path $lang.FullName 'dialog_female' 'mcmiria.msg'
        if (Test-Path $srcMsgF) {
            $dstDirF = Join-Path $innerDir 'data' 'text' $langName 'dialog_female'
            New-Item -ItemType Directory -Path $dstDirF -Force | Out-Null
            Copy-Item -Path $srcMsgF -Destination $dstDirF
            Write-Host "Added: data/text/$langName/dialog_female/mcmiria.msg"
        }
    }

    # -------------------------------------------------------------------
    # 4. Generate readme.txt
    # -------------------------------------------------------------------
    $readmeContent = @"
================================================================================
  Miria Can Wait  —  Fallout 2 RPU Patch
================================================================================

This patch modifies Miria's script so that she can be told to wait,
just like other party members in Fallout 2 with the Restoration Project (RPU).

REQUIREMENTS
------------
  - Fallout 2 with the Restoration Project Update (RPU) already installed.
    Tested with RPU v2.4.34.

    RPU installation instructions:
    https://github.com/BGforgeNet/Fallout2_Restoration_Project?tab=readme-ov-file#installation

    RPU v2.4.34 release:
    https://github.com/BGforgeNet/Fallout2_Restoration_Project/releases/tag/v2.4.34

  - PowerShell 7 (or later).

    If you do not have PowerShell 7 installed, download it from:
    https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows

    The easiest option is the MSI installer — look for "PowerShell-7.x.x-win-x64.msi".

INSTALLATION
------------
  1. Open PowerShell 7 (look for "pwsh" or "PowerShell 7" in your Start menu).

  2. Extract the zip and navigate to the miria_can_wait folder. For example:
       cd "C:\path\to\miria_can_wait"

  3. Run the installer:
       .\install.ps1

  4. A folder selection dialog will appear — select your Fallout 2 game folder
     (the one that contains fallout2.exe).

  5. The script will copy the necessary files and show you any remaining steps.

  6. After installation, open mods\rpu.ini in your Fallout 2 game folder
     and add the following line at the end:
       miria_can_wait=1

NOTE: Windows PowerShell 5.1 (the blue one built into Windows) might not work.
      You specifically need PowerShell 7+, which runs as "pwsh.exe".
================================================================================
"@

    $readmePath = Join-Path $innerDir 'readme.txt'
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host 'Added: readme.txt'

    # -------------------------------------------------------------------
    # 5. Create the zip
    # -------------------------------------------------------------------
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
        Write-Host "Removed existing $zipName"
    }

    Compress-Archive -Path $innerDir -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host ''
    Write-Host "Package created: $zipPath" -ForegroundColor Green

    # Show contents summary
    $zipInfo = Get-Item $zipPath
    Write-Host "Size: $([math]::Round($zipInfo.Length / 1KB, 1)) KB"
}
finally {
    # Clean up staging directory
    if (Test-Path $stagingDir) {
        Remove-Item $stagingDir -Recurse -Force
    }
}
