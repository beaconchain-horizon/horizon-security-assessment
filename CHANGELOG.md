# Changelog

All notable changes to the Horizon Security Assessment package.

## [1.0.1] - 2026-10-01

### Security

- Removed leaked API key from public repository.
- config.local.js scrubbed from git history via git filter-branch.
- Added .gitignore entries: *.local.js, .env, *.key, *.pem.

### Added

- SECURITY.md - vulnerability disclosure policy.
- CHANGELOG.md - this file.

## [1.0.0] - 2026-09-27

### Added

- Initial public release of the security assessment package.
- 192 attack vectors across 12 categories:
  - SQL Injection (25)
  - XSS (20)
  - Command Injection (20)
  - Path Traversal (20)
  - SSRF (15)
  - Auth Bypass (25)
  - JWT Confusion (10)
  - Header Injection (15)
  - Null Byte / Unicode (15)
  - CRLF / Method / Protocol (15)
  - Replay / Signature (15)
  - Large Payload / Rate Limit (10)
- TPS benchmark (200,000 readings, c=50, bs=500).
- Air-Gap demo.
- EVIDENCE.md - raw test output evidence.
- run.sh (Linux/macOS) and run.bat (Windows) launchers.
- Precompiled binaries: switch, sensortool, tpsbench.

### Fixed

Six vulnerabilities discovered during internal assessment, all fixed before release:

| # | Vulnerability | Commit | Severity |
|---|---------------|--------|----------|
| 1 | SQL Injection in site_id | 342bb1d | High |
| 2 | XSS in site_id | 342bb1d | High |
| 3 | Command Injection | 342bb1d | High |
| 4 | SSRF in agent_url | 58e776e | High |
| 5 | Empty batch accepted | 58e776e | Medium |
| 6 | Empty sensor_id | b266276 | Medium |

### Verified

- 192/192 attack vectors blocked.
- TPS: ~15,000 on laptop (8 cores), 19,000-31,000 on dedicated server.
- Zero critical vulnerabilities.
- Air-Gap mode fully operational.
