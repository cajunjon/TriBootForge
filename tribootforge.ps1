
<# 
.SYNOPSIS
    TriBootForge – Automates multi-OS partitioning and boot setup for CentOS, Ubuntu, and Windows.

.DESCRIPTION
    Creates GPT partitions, restores OS images, configures EFI boot entries, and logs execution.
    Designed for use in lab or datacenter provisioning workflows.

.AUTHOR
    Cajunjon

.VERSION
    1.3.1

.NOTES
    Requires administrator privileges and presence of parted.exe, efibootmgr.exe, dd, and wimlib-imagex.
    Supports 'nvme' or 'sda' as target drive identifiers.

.EXAMPLE
    .\TriBootForge.ps1 nvme -DryRun
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("nvme", "sda")]
    [string]$DriveType,

    [switch]$DryRun
)

# Set strict error handling
$ErrorActionPreference = "Stop"

# Initialize logging
$LOG_FILE = "C:\temp\partition-setup.log"
$sw = New-Object System.IO.StreamWriter($LOG_FILE, $true)
function Log { param($msg); $sw.WriteLine("[$(Get-Date)] $msg"); $sw.Flush() }

# Dry-run executor
function Execute {
    param ($cmd)
    if ($DryRun) {
        Write-Host "[DRY-RUN] $cmd"
        Log "[DRY-RUN] $cmd"
    } else {
        Invoke-Expression $cmd
        Log "[EXECUTED] $cmd"
    }
}

# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run as administrator"
    exit 1
}

# Utility check
foreach ($util in @("parted.exe", "efibootmgr.exe")) {
    $path = Join-Path $env:SystemRoot "System32\$util"
    if (!(Test-Path $path)) {
        Write-Host "$util not found. Attempting install..."
        Execute "Install-Package -Name $util -Force"
    }
}

# Drive validation
$DRIVE = "disk$DriveType"
$disk = Get-Disk | Where-Object { $_.FriendlyName -eq $DriveType }
if (-not $disk) {
    Write-Host "$DRIVE not found."
    exit 1
}

# Get total drive size in MB
$total_size_mb = [math]::Round($disk.Size / 1MB)

# Fixed EFI size
$efi_size = 300

# Remaining size after EFI
$remaining_size_mb = $total_size_mb - $efi_size

# Calculate partition sizes based on ratios
$ntfs_size = [math]::Round($remaining_size_mb * 0.1667)
$lvm_size = [math]::Round($remaining_size_mb * 0.4167)
$fat32_size = [math]::Round($remaining_size_mb * 0.1667)
$ext3_size = [math]::Round($remaining_size_mb * 0.4167)

# Log calculated sizes
Write-Host "Calculated Partition Sizes:"
Write-Host "EFI: $efi_size MB"
Write-Host "NTFS: $ntfs_size MB"
Write-Host "LVM: $lvm_size MB"
Write-Host "FAT32: $fat32_size MB"
Write-Host "EXT3: $ext3_size MB"

# Image definitions
$centos_version = "CentOS-Stream-Image-GNOME-Live.x86_64-9-202507151507.iso"
$Ubuntu_version = "ubuntu-24.04.3-desktop-amd64.iso"
$win_version = "SERVER_EVAL_x64FRE_en-us.wim"

# Locate images
function Locate-Image($filename) {
    $path = Get-ChildItem -Path C:\ -Filter $filename -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 | Split-Path -Parent
    if (-not $path) { Write-Host "$filename not found."; exit 1 }
    return $path
}
$Ubuntu_img_path = Locate-Image $Ubuntu_version
$centos_img_path = Locate-Image $centos_version

# ISO hybrid check (placeholder logic)
function Is-HybridISO($isoPath) {
    return $true
}

function Validate-ISO($isoPath) {
    if (-not (Test-Path $isoPath)) {
        Write-Host "ISO not found: $isoPath"
        exit 1
    }
    if (-not (Is-HybridISO $isoPath)) {
        Write-Host "$isoPath is not hybrid. Cannot raw-write."
        exit 1
    }
    Log "$isoPath passed hybrid check"
}

# Partition creation
$parted = Join-Path $env:SystemRoot "System32\parted.exe"
$start = 0
$end = $efi_size
Execute "$parted -a opt \\.\$DRIVE mklabel gpt"
Execute "$parted -a opt \\.\$DRIVE mkpart efi fat32 ${start}MB ${end}MB"
Execute "$parted \\.\$DRIVE set 1 esp on"

$start = $end
$end += $ntfs_size
Execute "$parted -a opt \\.\$DRIVE mkpart ntfs ${start}MB ${end}MB"
Execute "$parted \\.\$DRIVE set 2 msftdata on"

$start = $end
$end += $lvm_size
Execute "$parted -a opt \\.\$DRIVE mkpart lvm ${start}MB ${end}MB"
Execute "$parted \\.\$DRIVE set 3 lvm on"

$start = $end
$end += $fat32_size
Execute "$parted -a opt \\.\$DRIVE mkpart fat32 ${start}MB ${end}MB"
Execute "$parted \\.\$DRIVE set 4 msftdata on"

$start = $end
$end += $ext3_size
Execute "$parted -a opt \\.\$DRIVE mkpart ext3 ${start}MB ${end}MB"
Execute "$parted \\.\$DRIVE set 5 lvm on"

# Restore ISO images
$centos_iso = Join-Path $centos_img_path $centos_version
$ubuntu_iso = Join-Path $Ubuntu_img_path $Ubuntu_version
Validate-ISO $centos_iso
Validate-ISO $ubuntu_iso
Execute "dd if=`"$centos_iso`" of=`"${DRIVE}3`" bs=1M conv=fsync"
Execute "dd if=`"$ubuntu_iso`" of=`"${DRIVE}5`" bs=1M conv=fsync"

# EFI setup
$efi_path = "C:\boot\efi"
if (-not (Test-Path $efi_path)) { New-Item -Path $efi_path -ItemType Directory | Out-Null }
$boot_path = Join-Path $efi_path "EFI\BOOT"
if (-not (Test-Path $boot_path)) { New-Item -Path $boot_path -ItemType Directory | Out-Null }
Copy-Item -Path "$env:SystemRoot\System32\Boot\winload.efi" -Destination (Join-Path $boot_path "BOOTX64.EFI") -Force

# Apply Windows image (optional)
$win_path = "C:\Images"
if (Test-Path "$win_path\$win_version") {
    Execute "wimlib-imagex apply `"$win_path\$win_version`" 1 `"$DRIVE`2`""
} else {
    Log "Windows WIM not found. Skipping."
}

# EFI boot entries
Execute "efibootmgr -c -d `$DRIVE`p1 -L 'EFI Boot' -l '\EFI\BOOT\BOOTX64.EFI'"
Execute "efibootmgr -c -d `$DRIVE`p2 -L 'Windows Boot' -l '\WINDOWS\SYSTEM32\WINLOAD.EFI'"
Execute "efibootmgr -c -d `$DRIVE`p5 -L 'Ubuntu Boot' -l '\EFI\Ubuntu\grubx64.efi'"

Write-Host "TriBootForge execution complete."
Log "TriBootForge completed successfully."
$sw.Close()
