#Requires -Version 7.0

<#
.SYNOPSIS
    Installs the "Miria Can Wait" patch into a Fallout 2 + RPU game folder.
.DESCRIPTION
    Prompts the user to select their Fallout 2 game folder (with RPU already installed),
    validates the selection, then copies the compiled script and dialog files.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

$repoRoot = $PSScriptRoot

# ---------------------------------------------------------------------------
# Hidden topmost form used as the owner for all dialogs so they stay in front.
# ---------------------------------------------------------------------------
$script:ownerForm = New-Object System.Windows.Forms.Form
$script:ownerForm.TopMost = $true
$script:ownerForm.ShowInTaskbar = $false
$script:ownerForm.StartPosition = 'Manual'
$script:ownerForm.Location = New-Object System.Drawing.Point(-9999, -9999)
$script:ownerForm.Size = New-Object System.Drawing.Size(1, 1)
$script:ownerForm.Show()
$script:ownerForm.Hide()

# ---------------------------------------------------------------------------
# Helper: Show a folder-picker dialog. Returns the selected path or $null.
# ---------------------------------------------------------------------------
function Select-Fallout2Folder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Please select Fallout 2 game folder (with RPU already installed)'
    $dialog.ShowNewFolderButton = $false
    $dialog.RootFolder = [System.Environment+SpecialFolder]::MyComputer

    if ($dialog.ShowDialog($script:ownerForm) -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

# ---------------------------------------------------------------------------
# Step 0: Keep asking until a valid folder is chosen or user cancels.
# ---------------------------------------------------------------------------
$gameDir = $null

while ($true) {
    $selected = Select-Fallout2Folder

    if (-not $selected) {
        Write-Host ''
        Write-Host 'Folder selection was cancelled. No changes have been made.' -ForegroundColor Yellow
        Write-Host 'To install the patch, re-run this script and select your Fallout 2 game folder.'
        exit 1
    }

    # Validate the chosen folder.
    $problems = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path (Join-Path $selected 'fallout2.exe'))) {
        $problems.Add("'fallout2.exe' was not found in the selected folder.")
    }
    if (-not (Test-Path (Join-Path $selected 'ddraw.ini'))) {
        $problems.Add("'ddraw.ini' was not found — sfall does not appear to be installed.")
    }
    if (-not (Test-Path (Join-Path $selected 'mods' 'rpu.ini'))) {
        $problems.Add("'mods\rpu.ini' was not found — RPU does not appear to be installed.")
    }

    if ($problems.Count -eq 0) {
        $gameDir = $selected
        break
    }

    # Build a message box explaining the problems.
    $msg = "The selected folder does not look like a valid Fallout 2 + RPU installation:`n`n"
    foreach ($p in $problems) {
        $msg += "  - $p`n"
    }
    $msg += "`nPlease select the correct folder."

    [System.Windows.Forms.MessageBox]::Show(
        $script:ownerForm,
        $msg,
        'Invalid Folder',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

Write-Host "Game folder: $gameDir"
$script:ownerForm.Dispose()

# ---------------------------------------------------------------------------
# Step 1: Copy compiled script (mcmiria.int)
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '--- Step 1: Copying mcmiria.int ---'

$srcInt = Join-Path $repoRoot 'scripts_src' 'modoc' 'mcmiria.int'
if (-not (Test-Path $srcInt)) {
    Write-Error "Source file not found: '$srcInt'. Did you run build.ps1 first?"
    exit 1
}

$dstScriptsDir = Join-Path $gameDir 'data' 'scripts'
if (-not (Test-Path $dstScriptsDir)) {
    New-Item -ItemType Directory -Path $dstScriptsDir -Force | Out-Null
    Write-Host "Created directory: $dstScriptsDir"
}

$dstInt = Join-Path $dstScriptsDir 'mcmiria.int'
Copy-Item -Path $srcInt -Destination $dstInt -Force
Write-Host "Copied: $dstInt"

# ---------------------------------------------------------------------------
# Step 2: Copy dialog files for every language
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '--- Step 2: Copying dialog files ---'

$srcTextDir = Join-Path $repoRoot 'data' 'text'

if (-not (Test-Path $srcTextDir)) {
    Write-Error "Source text directory not found: '$srcTextDir'."
    exit 1
}

$langDirs = Get-ChildItem -Path $srcTextDir -Directory |
Where-Object { $_.Name -ne 'po' }

foreach ($lang in $langDirs) {
    $langName = $lang.Name

    # --- dialog/mcmiria.msg ---
    $srcMsg = Join-Path $lang.FullName 'dialog' 'mcmiria.msg'

    if (Test-Path $srcMsg) {
        $dstDialogDir = Join-Path $gameDir 'data' 'text' $langName 'dialog'
        if (-not (Test-Path $dstDialogDir)) {
            New-Item -ItemType Directory -Path $dstDialogDir -Force | Out-Null
            Write-Host "Created directory: $dstDialogDir"
        }

        $dstMsg = Join-Path $dstDialogDir 'mcmiria.msg'
        Copy-Item -Path $srcMsg -Destination $dstMsg -Force
        Write-Host "Copied ($langName): $dstMsg"
    }
    else {
        Write-Host "Info: No dialog/mcmiria.msg for '$langName' — skipping." -ForegroundColor DarkGray
    }

    # --- dialog_female/mcmiria.msg (if exists) ---
    $srcMsgFemale = Join-Path $lang.FullName 'dialog_female' 'mcmiria.msg'

    if (Test-Path $srcMsgFemale) {
        $dstDialogFemaleDir = Join-Path $gameDir 'data' 'text' $langName 'dialog_female'
        if (-not (Test-Path $dstDialogFemaleDir)) {
            New-Item -ItemType Directory -Path $dstDialogFemaleDir -Force | Out-Null
            Write-Host "Created directory: $dstDialogFemaleDir"
        }

        $dstMsgFemale = Join-Path $dstDialogFemaleDir 'mcmiria.msg'
        Copy-Item -Path $srcMsgFemale -Destination $dstMsgFemale -Force
        Write-Host "Copied ($langName female): $dstMsgFemale"
    }
}

# ---------------------------------------------------------------------------
# Done — Verification & final messages
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Files copied successfully.' -ForegroundColor Green

# --- Verify ddraw.ini UseFileSystemOverride setting ---
$ddrawIni = Join-Path $gameDir 'ddraw.ini'
$ddrawWarning = $false
$ddrawContent = Get-Content $ddrawIni -Raw

# Match UseFileSystemOverride under [Misc] section
if ($ddrawContent -match '(?ms)^\[Misc\].*?(?=^\[|\z)') {
    $miscSection = $Matches[0]
    if ($miscSection -match '(?m)^\s*UseFileSystemOverride\s*=\s*(\d+)') {
        if ($Matches[1] -ne '1') {
            $ddrawWarning = $true
            Write-Host "WARNING: ddraw.ini [Misc] UseFileSystemOverride=$($Matches[1]) — it must be set to 1 for the patch to work." -ForegroundColor Red
        }
        else {
            Write-Host "Verified: ddraw.ini [Misc] UseFileSystemOverride=1 (OK)"
        }
    }
    else {
        $ddrawWarning = $true
        Write-Host "WARNING: ddraw.ini [Misc] section exists but UseFileSystemOverride is not defined. It must be set to 1." -ForegroundColor Red
    }
}
else {
    $ddrawWarning = $true
    Write-Host "WARNING: ddraw.ini does not contain a [Misc] section. UseFileSystemOverride=1 must be present under [Misc]." -ForegroundColor Red
}

if ($ddrawWarning) {
    [System.Windows.Forms.MessageBox]::Show(
        "Your ddraw.ini file needs attention!`n`nOpen:`n$ddrawIni`n`nand make sure the following setting exists under the [Misc] section:`n`nUseFileSystemOverride=1`n`nWithout this, the game will not load the patched scripts.",
        'ddraw.ini — Action Required',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

# --- Final success message ---
$rpuIni = Join-Path $gameDir 'mods' 'rpu.ini'
$successMsg = "Miria Can Wait patch installed successfully!`n`nTo enable the Miria waiting feature, edit:`n$rpuIni`n`nand add the following line at the end:`n`nmiria_can_wait=1"

Write-Host ''
Write-Host '---------------------------------------------------------------' -ForegroundColor Cyan
Write-Host 'INSTALLATION COMPLETE' -ForegroundColor Green
Write-Host ''
Write-Host "To enable the Miria waiting feature, edit:" -ForegroundColor Yellow
Write-Host "  $rpuIni" -ForegroundColor Yellow
Write-Host ''
Write-Host "and add the following line at the end:" -ForegroundColor Yellow
Write-Host "  miria_can_wait=1" -ForegroundColor Yellow
Write-Host '---------------------------------------------------------------' -ForegroundColor Cyan

[System.Windows.Forms.MessageBox]::Show(
    $successMsg,
    'Installation Complete',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null
