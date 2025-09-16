# TriBootForge

**TriBootForge** is a PowerShell-based provisioning script that automates multi-OS disk partitioning and EFI boot setup for CentOS, Ubuntu, and Windows. Designed for lab and datacenter environments, it streamlines image deployment and boot configuration with robust error handling and modular logic.

---

## 🚀 Features

- Creates GPT partitions with **dynamic sizing** based on total drive capacity
- Restores CentOS and Ubuntu images using `dd`
- Optionally expands Windows `.wim` using `wimlib-imagex`
- Configures EFI boot entries via `efibootmgr`
- Validates drive input (`nvme` or `sda`)
- Logs execution to `C:\temp\partition-setup.log`
- Checks for required utilities and installs if missing
- Uses PowerShell-approved verbs for all functions
- Improved logging using `Write-Verbose`, `Write-Output`, and `Write-Information`

---

## 🛠 Requirements

- Windows PowerShell (Admin)
- `parted.exe`, `efibootmgr.exe`, `dd`, `wimlib-imagex`
- OS image files:
  - `CentOS-Stream-Image-GNOME-Live.x86_64-9-202507151507.iso`
  - `ubuntu-24.04.3-desktop-amd64.iso`
  - `SERVER_EVAL_x64FRE_en-us.wim` (optional)
- Drive identifier: `nvme` or `sda`

---

## 📦 Usage

```powershell
.\TriBootForge.ps1 -DriveType nvme [-DryRun] [-Verbose]
