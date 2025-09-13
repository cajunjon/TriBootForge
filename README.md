README.md

\# TriBootForge



\*\*TriBootForge\*\* is a PowerShell-based provisioning script that automates multi-OS disk partitioning and EFI boot setup for CentOS, Ubuntu, and Windows. Designed for lab and datacenter environments, it streamlines image deployment and boot configuration with robust error handling and modular logic.



---



\## 🚀 Features



\- Creates GPT partitions with customizable sizes

\- Restores CentOS and Ubuntu images using `dd`

\- Optionally expands Windows `.wim` using `wimlib-imagex`

\- Configures EFI boot entries via `efibootmgr`

\- Validates drive input (`nvme` or `sda`)

\- Logs execution to `C:\\temp\\partition-setup.log`

\- Checks for required utilities and installs if missing



---



\## 🛠 Requirements



\- Windows PowerShell (Admin)

\- `parted.exe`, `efibootmgr.exe`, `dd`, `wimlib-imagex`

\- OS image files:

&nbsp; - `centos4.img`

&nbsp; - `Ubuntu.img`

&nbsp; - `server.wim` (optional)

\- Drive identifier: `nvme` or `sda`



---



\## 📦 Usage



```powershell

.\\TriBootForge.ps1 nvme



