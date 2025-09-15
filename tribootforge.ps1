<#
.SYNOPSIS
    TriBootForge – Automates multi-OS partitioning and boot setup for CentOS, Ubuntu, and Windows.

.DESCRIPTION
    Creates GPT partitions, restores OS images, configures EFI boot entries, and logs execution.
    Designed for use in lab or datacenter provisioning workflows.

.AUTHOR
    Cajunjon

.VERSION
    1.2.0

.NOTES
    Requires administrator privileges and presence of parted.exe, efibootmgr.exe, dd, and wimlib-imagex.
    Supports 'nvme' or 'sda' as target drive identifiers.

.EXAMPLE
    .\TriBootForge.ps1 nvme
#>

# Set strict error handling
$ErrorActionPreference = "Stop"
$debug = $false

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run as administrator"
    exit
}

# Initialize logging
$LOG_FILE = "C:\temp\partition-setup.log"
$sw = New-Object System.IO.StreamWriter($LOG_FILE, $true)
$sw.WriteLine("Started TriBootForge script")
$sw.Flush()

# Define image filenames
$centos_version = "CentOS-Stream-Image-GNOME-Live.x86_64-9-202507151507.iso"
$win_version = "SERVER_EVAL_x64FRE_en-us.wim"
$Ubuntu_version = "ubuntu-24.04.3-desktop-amd64.iso"  # Fixed missing quote

# Locate image paths
$Ubuntu_img_path = Get-ChildItem -Path C:\ -Filter $Ubuntu_version -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 | Split-Path -Parent
$centos_img_path = Get-ChildItem -Path C:\ -Filter $centos_version -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 | Split-Path -Parent

# Define partition sizes
$efi_size = "300MB"
$ntfs_size = "100GB"
$lvm_size = "250GB"
$fat32_size = "100GB"
$ext3_size = "250GB"

# Ensure required utilities are present
if (!(Test-Path (Join-Path $env:SystemRoot "System32\parted.exe"))) { Write-Host "Installing parted..."; Install-Package -Name parted -Force }
if (!(Test-Path (Join-Path $env:SystemRoot "System32\efibootmgr.exe"))) { Write-Host "Installing efibootmgr..."; Install-Package -Name efibootmgr -Force }

# Validate drive argument
if ($args[0] -ne "nvme" -and $args[0] -ne "sda") {
    Write-Host "Invalid drive option. Use 'nvme' or 'sda'."
    exit 1
}

$DRIVE = "disk" + $args[0]

# Confirm drive exists
if (-not (Get-Disk | Where-Object { $_.UniqueId -eq $DRIVE })) {
    Write-Host "$DRIVE not found."
    exit 1
}

# Calculate remaining space
$DRIVE_SIZE = (Get-Disk -UniqueId $DRIVE).Size
$remaining_size = (($DRIVE_SIZE / 1GB) - 300 - 100 - 250 - 100 - 250) * 1GB

# Partition creation
$parted = Join-Path $env:SystemRoot "System32\parted.exe"
& $parted -a opt "\\.\$DRIVE" mklabel gpt || { Write-Host "Partition table creation failed."; exit 1 }

# Create and flag partitions
& $parted -a opt "\\.\$DRIVE" mkpart efi fat32 0% $efi_size
& $parted "\\.\$DRIVE" set 1 esp on
& $parted -a opt "\\.\$DRIVE" mkpart ntfs $efi_size $ntfs_size
& $parted "\\.\$DRIVE" set 2 msftdata on
& $parted -a opt "\\.\$DRIVE" mkpart lvm $ntfs_size $((ntfs_size + lvm_size))
& $parted "\\.\$DRIVE" set 3 lvm on
& $parted -a opt "\\.\$DRIVE" mkpart fat32 $((ntfs_size + lvm_size)) $((ntfs_size + lvm_size + fat32_size))
& $parted "\\.\$DRIVE" set 4 msftdata on
& $parted -a opt "\\.\$DRIVE" mkpart ext3 $((ntfs_size + lvm_size + fat32_size)) $((ntfs_size + lvm_size + fat32_size + ext3_size))
& $parted "\\.\$DRIVE" set 5 lvm on
& $parted -a opt "\\.\$DRIVE" mkpart fat32 $((ntfs_size + lvm_size + fat32_size + ext3_size)) $((ntfs_size + lvm_size + fat32_size + ext3_size + remaining_size))
& $parted "\\.\$DRIVE" set 6 msftdata on

# Restore CentOS and Ubuntu images
dd if="$centos_img_path\$centos_version" of="${DRIVE}3" bs=1M conv=fsync
dd if="$Ubuntu_img_path\$Ubuntu_version" of="${DRIVE}5" bs=1M conv=fsync

# EFI folder setup
$efi_path = "C:\boot\efi"
if (-not (Test-Path $efi_path)) { New-Item -Path $efi_path -ItemType Directory | Out-Null }
$driveLetter = $efi_path.Substring(0,1)
mountvol "$driveLetter:" /s

$boot_path = Join-Path $efi_path "EFI\BOOT"
if (-not (Test-Path $boot_path)) { New-Item -Path $boot_path -ItemType Directory | Out-Null }
Copy-Item -Path "$env:SystemRoot\System32\Boot\winload.efi" -Destination (Join-Path $boot_path "BOOTX64.EFI") -Force

# Apply Windows image (if debug mode enabled)
if ($debug) {
    $win_path = "C:\Images"  # Placeholder path
    if (-not (Test-Path $win_path)) {
        Write-Host "Windows WIM file not found."
        exit 1
    }
    & wimlib-imagex apply "$win_path\$win_version" 1 "${DRIVE}2"
}

# Configure EFI boot entries
$efiBootDrive = $DRIVE + "p1"
$winBootDrive = $DRIVE + "p2"
$UbuntuBootDrive = $DRIVE + "p5"
$efiContentBootDrive = $DRIVE + "p6"

efibootmgr -c -d "$efiBootDrive" -L "EFI Boot" -l "\EFI\BOOT\BOOTX64.EFI"
efibootmgr -c -d "$winBootDrive" -L "Windows Boot" -l "\WINDOWS\SYSTEM32\WINLOAD.EFI"
efibootmgr -c -d "$UbuntuBootDrive" -L "Ubuntu Boot" -l "\EFI\Ubuntu\vmlinuz.efi"
efibootmgr -c -d "$efiContentBootDrive" -L "EFI Content Boot" -l "\EFI\CONTENT\BOOTX64.EFI"

# Unmount volumes
mountvol "$driveLetter:" /d
mountvol /mnt/ntfs /d
mountvol /mnt/lvm /d
mountvol /mnt/winsrv /d
mountvol /mnt/Ubuntu /d
mountvol /mnt/efi_content /d

Write-Host "TriBootForge executed successfully."
