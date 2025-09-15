# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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