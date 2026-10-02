# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.x     | :white_check_mark: |
| < 3.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in Horizon Core, please report it responsibly.

**Please do NOT open a public GitHub issue for security vulnerabilities.**

### How to Report

Send an email to: **gamma.mahdii@gmail.com**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (optional)
- Your name/handle for credit (optional)

### What to Expect

| Timeframe | Action |
| --------- | ------ |
| 48 hours  | Acknowledgment |
| 7 days    | Initial assessment |
| 30 days   | Fix or mitigation plan |

## Security Model

- **Cryptography**: ECDSA P-256 (FIPS 186-5 standard)
- **Key Management**: Key rotation (90 days), Shamir Secret Sharing, Dual Control, Auto-Lock
- **Replay Protection**: Nonce + timestamp window (5 minutes)
- **Supply Chain**: Dependabot, govulncheck, gosec (weekly)
- **Isolation**: Air-Gap mode (fully offline)
- **Container**: Non-root user (UID 10001), healthcheck

## Independent Verification
