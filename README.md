# ublocks
![Update uBlock Filters](https://github.com/pkok1099/ublocks/actions/workflows/update-filters.yml/badge.svg)

This repository automatically merges and categorizes filters from high-authority sources such as **uBlock Origin** and **AdGuard** into optimized, deduplicated lists.

> [!CAUTION]
> **Do not use these filters directly.** These lists are specifically formatted and merged for a dedicated application. Using them in standard ad-blockers may lead to performance issues or unexpected behavior.

## 🚀 Features
- **Automated**: Synced daily at 03:00 UTC via GitHub Actions.
- **Categorized**: Rules are split into specific files (Blocking, Allow, Cosmetic, Metadata).
- **Deduplicated**: Duplicate entries are removed for maximum efficiency.
- **Optimized**: Sorted and normalized for better performance.

## 📁 Filter Lists
Subscribe to these filters using the following *raw* links:

| Filter | Description | Raw Link |
| :--- | :--- | :--- |
| **Bulk Merged** | All rules combined | [Link](https://raw.githubusercontent.com/pkok1099/ublocks/main/ublock-merged.txt) |
| **Network Blocking** | Network request blocking | [Link](https://raw.githubusercontent.com/pkok1099/ublocks/main/filter-block.txt) |
| **Exception Rules** | Whitelist / Allowlist rules | [Link](https://raw.githubusercontent.com/pkok1099/ublocks/main/filter-allow.txt) |
| **Cosmetic Rules** | Element hiding / Visual filters | [Link](https://raw.githubusercontent.com/pkok1099/ublocks/main/filter-cosmetic.txt) |
| **Metadata** | Filter headers and metadata | [Link](https://raw.githubusercontent.com/pkok1099/ublocks/main/filter-metadata.txt) |

## 🛰️ Fetched Sources
The following official repositories are used as data sources for this project:

| Source Name | Category | Official Repository URL |
| :--- | :--- | :--- |
| **uBlock Assets** | Core Filters | [uBlockOrigin/uAssets](https://github.com/uBlockOrigin/uAssets) |
| **AdGuard Base** | Ads & Tracking | [AdguardTeam/AdguardFilters](https://github.com/AdguardTeam/AdguardFilters) |
| **AdGuard Spyware** | Privacy & Analytics | [AdguardTeam/AdguardFilters](https://github.com/AdguardTeam/AdguardFilters) |
| **AdGuard Popups** | Overlays & Popups | [AdguardTeam/AdguardFilters](https://github.com/AdguardTeam/AdguardFilters) |
| **AdGuard Cookies** | GDPR & Consent | [AdguardTeam/AdguardFilters](https://github.com/AdguardTeam/AdguardFilters) |

## ⚙️ Automation Details
The `merge-ublock-filters.sh` script handles the core logic:
1. **Fetch**: Uses GitHub API to scan for the latest `.txt` filter files from source repos.
2. **Download**: Executes high-speed parallel downloads with automated retry logic.
3. **Process**: Normalizes line endings and classifies rules using a high-performance AWK script.
4. **Clean**: Strips comments and removes duplicate lines to keep the final output lightweight.
5. **Verify**: Integrity checks prevent empty or corrupted files from being pushed to the repository.

---
*Automatically maintained by [Filter Bot](.github/workflows/update-filters.yml).*
