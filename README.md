# Horizon Core — Security Assessment

**Independent security & performance evaluation package.**

This package allows banks, exchanges, and auditors to independently verify Horizon Core's security and performance claims.

---

## Quick Start

### Linux / macOS

git clone https://github.com/beaconchain-horizon/horizon-security-assessment.git
cd horizon-security-assessment
./run.sh

### Windows

1. Download ZIP
2. Extract
3. Double-click `run.bat`

---

## What This Tests

| # | Test | What It Proves |
|---|------|----------------|
| 1 | Health Check | Server is online |
| 2 | TPS Benchmark | 200,000 transactions signed & verified |
| 3 | Rate Limiting | 50 req/s limit enforced |
| 4 | Replay Protection | Invalid signatures rejected |
| 5 | Dual Control | Two-person approval system |
| 6 | Signing Session | One-time tokens with 5-min TTL |
| 7 | Integrity Check | Zero tampering (tamper_count=0) |
| 8 | Auto-Lock | Key auto-locks after inactivity |

---

## Verified Results (Reference Run)

| Metric | Value |
|--------|-------|
| **Peak TPS** | 20,000 – 31,000 |
| **Errors** | 0 |
| **Tampering** | 0 |
| **ECDSA Sign Time** | < 1 ms |
| **Latency** | ~6 ms |

**Note:** TPS depends on your CPU. On Intel i7-1185G7: 20K–31K.

---

## Security Layers Tested

### Layer 1 — DoS Protection
- Rate Limiting (50 req/s, capacity 100)
- Connection Limit (500 concurrent)
- Read/Write Timeout (30 s)
- Idle Timeout (60 s)
- Max Header Bytes (1 MB)

### Layer 2 — Replay & Intrusion
- Nonce (unique per reading)
- Timestamp window (−300 s to +120 s)
- SSRF Protection (39/40 vectors blocked)
- Input Validation
- CORS Whitelist

### Layer 3 — Key Protection
- ECDSA P-256 (FIPS 186-4)
- Key Rotation (90 days)
- Auto-Lock (30 min inactivity)
- Manual Lock endpoint
- Dual Control (two-person approval)
- Signing Session (one-time tokens)
- Audit Trail (every signature logged)

### Layer 4 — Supply Chain
- Dependabot (Go, Docker, Actions)
- govulncheck + gosec
- Zero known vulnerabilities

### Layer 5 — Air-Gap
- Full offline operation
- In-memory DB (`:memory:`)
- Zero outbound in isolated mode

---

## Files

- `bin/` — compiled binaries (switch, sensortool, tpsbench)
- `config/chain.json` — chain configuration
- `run.sh` — Linux/macOS launcher
- `run.bat` — Windows launcher
- `EVIDENCE.md` — reference run logs
- `LICENSE` — MIT

---

## No Source Code

This package contains **only compiled binaries**. The source code is private and available under NDA for qualified partners.

---

## Contact

- **GitHub:** https://github.com/beaconchain-horizon
- **Benchmark:** https://github.com/beaconchain-horizon/horizon-benchmark
- **Air-Gap Demo:** https://github.com/beaconchain-horizon/horizon-airgap-demo

---

**© 2026 Horizon Core — MIT License**
