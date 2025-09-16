# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2025-09-16
## Code Quality Improvements
## Replaced Write-Host with:
Write-Verbose for dry-run and completion messages.
Write-Output for general output.
Write-Information for status and error messages.
This improves compatibility with non-interactive hosts and aligns with PowerShell best practices.
## Function Naming Updates
## Renamed functions to use approved PowerShell verbs:
Locate-Image → Find-Image
Is-HybridISO → Test-HybridISO
Validate-ISO → Test-ISOValidity
These changes improve script readability and compliance with PowerShell standards.
## Encoding Fix
Script now uses Unicode BOM encoding to ensure compatibility with editors and environments that require BOM for non-ASCII characters.


## [1.3.1] - 2025-09-16
### Added
### Enhancements
Dynamic Partition Sizing:
Replaced static partition sizes (except EFI) with dynamic calculations based on total drive size.
EFI partition remains fixed at 300MB.
Remaining space is distributed using the following ratios:
NTFS: 16.67%
LVM: 41.67%
FAT32: 16.67%
EXT3: 41.67%
## Logic Improvements
Added logic to:
Detect total drive size in MB.
Subtract EFI size and apply ratios to remaining space.
Log calculated partition sizes for transparency.
## Preserved Functionality
ISO validation, dry-run execution, logging, and EFI boot entry setup remain unchanged.
Image restoration and Windows WIM application logic preserved.
---

## [1.3.0] - 2025-09-15
### Added
- Modularized script into reusable functions (`Assert-Admin`, `Init-Logger`, `Validate-Drive`, etc.)
- Dry-run mode for safe execution preview
- ISO hybrid validation logic before raw-write operations
- Logging enhancements with timestamped entries
- EFI boot entry creation for CentOS, Ubuntu, and Windows
- Image path auto-discovery using `Get-ChildItem`

### Changed
- Replaced inline logic with structured function calls for maintainability
- Updated Ubuntu boot entry to use `grubx64.efi` instead of `vmlinuz.efi`
- Improved error handling and exit conditions

### Fixed
- Missing quote in Ubuntu ISO filename
- Partition flag assignments for LVM and FAT32 partitions

---

## [1.2.0] - 2025-08-30
### Added
- Initial support for multi-OS provisioning (CentOS, Ubuntu, Windows)
- Partition layout creation using `parted.exe`
- Raw image restoration using `dd`
- Windows WIM application via `wimlib-imagex`
- Basic EFI boot configuration

---

## [1.1.0] - 2025-08-15
### Added
- Initial script scaffold with parameter parsing and logging

- Drive validation and admin privilege check

