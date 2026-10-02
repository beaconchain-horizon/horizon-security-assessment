# Horizon Core — Security Assessment Package

Version: 3.0.1
Date: October 2026

Reproducible security & performance evaluation for
Horizon Core private blockchain.

## What's New in v3.0.1

- Unified Blockchain: License + TX + Audit on single chain
- Adaptive Batcher: async batching (100K TX per request)
- Block ECDSA P-256 signing on every block
- Real Shamir Secret Sharing (GF(2^8))
- Air-Gap enforcement on outbound HTTP
- Fail-closed auth (no ADMIN_TOKEN = no start)
- Dual Control + Signing Session enforced on /tx
- FIPS 186-5 alignment (186-4 withdrawn Feb 2024)

## Quick Start

git clone https://github.com/beaconchain-horizon/horizon-security-assessment.git
cd horizon-security-assessment
./run.sh

Windows: Download ZIP -> run.bat

## What This Tests

Security:
- 16 attack vectors (SQLi, XSS, CMDi, SSRF, Replay, JWT)
- Block signature verification
- Dual Control flow
- Signing Session enforcement
- Air-Gap mode

Performance:
- TPS benchmark (up to 500K readings)
- Latency measurement
- Block creation rate

## Architecture

Unified Blockchain:

  Block 0: Genesis (owner ECDSA key)
  Block N: License issue / renew / revoke
  Block N: Transaction batch
  Block N: Audit events

Each block:
  - ECDSA P-256 signed
  - Merkle root of txs
  - Chain-linked (prev_hash)

## Docs

- SECURITY.md
- CHANGELOG.md
- EVIDENCE.md
- LICENSE
- LICENSE_FORMAT.md

## Contact

GitHub: @beaconchain-horizon
Email: gamma.mahdii@gmail.com
