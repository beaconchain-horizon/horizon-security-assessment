# Horizon v1.4 — Security Assessment & Live Demo

**Status**: v1.4 · secp256k1 · live-tested
**Repo**: [beaconchain-horizon/horizon-core](https://github.com/beaconchain-horizon/horizon-core)
**Pages**: https://beaconchain-horizon.github.io/horizon-security-assessment/

---

## Live pages

| Page | URL | Description |
|---|---|---|
| 🏠 Home | [index.html](https://beaconchain-horizon.github.io/horizon-security-assessment/) | Overview + all links |
| 🔑 **Offline Signer** | [offline-license.html](https://beaconchain-horizon.github.io/horizon-security-assessment/offline-license.html) | **v1.4 secp256k1 signing from USB** |
| 🎛️ Monitor | [monitor.html](https://beaconchain-horizon.github.io/horizon-security-assessment/monitor.html) | SOC dashboard |
| 🛍️ Store | [store.html](https://beaconchain-horizon.github.io/horizon-security-assessment/store.html) | Product catalog |
| 🛍️ Store v2 | [store-v2.html](https://beaconchain-horizon.github.io/horizon-security-assessment/store-v2.html) | Store (new) |
| 📊 Demo | [demo.html](https://beaconchain-horizon.github.io/horizon-security-assessment/demo.html) | Feature walkthrough |
| 🌐 WebApp | [webapp-real.html](https://beaconchain-horizon.github.io/horizon-security-assessment/webapp-real.html) | Live app demo |

> **Important**: the Offline Signer must be opened from `file://` (not GitHub Pages HTTPS)
> so the browser can POST to `http://localhost:8081/api/v1/license/check`.

---

## What's new in v1.4

- **Curve**: ECDSA on **secp256k1** (Bitcoin/Ethereum curve)
- **Signature**: 64-byte `R||S`, RFC 6979 deterministic
- **Trust root**: Horizon Authority holds the private key; Switch holds the public key only
- **USB signing**: private key never enters the browser — the page reads hex from a USB-mounted PEM
- **Switch**: Policy Enforcement Gateway at `POST /api/v1/license/check`
- **Offline verifier**: `cmd/licenseverify` validates licenses without any server
- **Merkle**: RFC 6962 inclusion proofs with tamper detection
- **CI**: tamper, HWID, expiry, crypto, protocol all tested on every push

## Quick start (local)

```bash
git clone https://github.com/beaconchain-horizon/horizon-core.git
cd horizon-core

# 1. Start Switch with public key auto-detected from USB
HORIZON_ISSUER_KEY_PATH="/d/mykey.txt" bash scripts/start-switch.sh

# 2. In the browser, open:
#    file:///C:/Users/<you>/Desktop/offline-license.html
#    → Load key from USB → Sign → Verify on Switch
#    → Green: valid=true verified=true
```

## Related repos

| Repo | Purpose |
|---|---|
| [horizon-core](https://github.com/beaconchain-horizon/horizon-core) | Main codebase (v1.4) |
| [horizon-security-assessment](https://github.com/beaconchain-horizon/horizon-security-assessment) | This repo — assessment + demo pages |
| [horizon-airgap-demo](https://github.com/beaconchain-horizon/horizon-airgap-demo) | Air-gap mode demo |
| [horizon-benchmark](https://github.com/beaconchain-horizon/horizon-benchmark) | TPS + latency benchmarks |

## Canonical docs (in horizon-core)

- [docs/CRYPTO-CONTRACT.md](https://github.com/beaconchain-horizon/horizon-core/blob/main/docs/CRYPTO-CONTRACT.md) — signature spec
- [docs/V14-DEMO.md](https://github.com/beaconchain-horizon/horizon-core/blob/main/docs/V14-DEMO.md) — live demo guide
- [docs/PRE-DEMO.md](https://github.com/beaconchain-horizon/horizon-core/blob/main/docs/PRE-DEMO.md) — pre-demo checklist
- [docs/V14-AUTHORITY-RUNBOOK.md](https://github.com/beaconchain-horizon/horizon-core/blob/main/docs/V14-AUTHORITY-RUNBOOK.md) — production runbook

## What this repo tests

- **Signature algorithm**: secp256k1 (not P-256)
- **Signature format**: 64-byte `R||S` (not DER)
- **Determinism**: RFC 6979 (no randomness)
- **Rejections**: malformed hex, wrong length, zero R/S, out-of-range R/S, high-S, P-256 keys, DER encoding
- **HWID binding**: license tied to a hardware ID
- **Expiry**: issued_at / expires_at boundaries
- **Tamper**: single-bit flips in signature or payload are rejected
- **Merkle inclusion**: RFC 6962 proofs verified and tamper-rejected

## Reproduce

```bash
cd horizon-core
bash scripts/smoke-test.sh
```

Must output `PASS: 12, FAIL: 0`.

## Legacy

This repo previously described a P-256 system (v3.0.x). All P-256 references
have been superseded by the secp256k1 v1.4 spec. See
[CRYPTO-CONTRACT.md](https://github.com/beaconchain-horizon/horizon-core/blob/main/docs/CRYPTO-CONTRACT.md).

---

**© 2026 Horizon Core**
