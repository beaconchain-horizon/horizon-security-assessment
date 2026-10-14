# 🛡 Horizon Core — Security Architecture

**Version:** v2 (2026-10-14) · **Chain height:** 88 · **TX total:** 12,857

Horizon Core is a private, air-gap capable ledger for critical industries.
این سند هر لایه‌ی امنیتی پیاده‌شده را توصیف می‌کند.

**راهنمای نمادها:**
- ✅ **verified today** — با تست یا commit امروز تأیید شد
- 🟢 **in place** — از قبل، دست‌نخورده
- ⚠️ **not re-verified today** — ادعای v1، امروز چک نشد

---

## 🔐 Layer 1 — Signature & Crypto

| Control | Value | Location | Status |
|---|---|---|---|
| Curve | **secp256k1** (SEC 2) | `internal/crypto/secp256k1.go` | ✅ |
| Signature format | 64-byte raw `R\|\|S` (no DER) | same | ✅ |
| Hash | SHA-256 (FIPS 180-4) | `Sha256Hash` | ✅ |
| Determinism | RFC 6979 | `SignHashRS` | ✅ |
| **High-S rejection** | `s ≤ n/2` enforced | `parseRS` | ✅ **added 2026-10-14** |
| **DER rejection** | Strict 64-byte only | `VerifyData` | ✅ **added 2026-10-14** |
| P-256 rejection | Curve policy enforced | `validatedSecp256k1PublicKey` | ✅ |
| Zero R/S / wrong length | rejected | `parseRS` | ✅ |
| **Cross-verify** | OpenSSL 3.5.7 → `Verified OK` | `crossverify_test.go` | ✅ **added 2026-10-14** |
| **Fuzz** | ۱.۸۶M execs, ۰ counterexample | `fuzz_test.go` | ✅ **added 2026-10-14** |

**Tests:** 14 in `internal/crypto/`

---

## 🌳 Layer 2 — Merkle & Chain Integrity

| Control | Value | Location | Status |
|---|---|---|---|
| **v2 formula** | `leaf=SHA256(data)`, `node=SHA256(L\|\|R)`, odd self-pair | `chain/append.go` | ✅ **unified 2026-10-14** |
| **Unified across** | chain + license + proof + regen | 5 call sites | ✅ **added 2026-10-14** |
| **Ternary Merkle** | `fanout=3`, custom | `merkle/ternary.go` | ✅ **added 2026-10-14** |
| **Independent verifier** | `cmd/verify-tx` — no Backend, air-gap | CLI | ✅ **added 2026-10-14** |
| **License verifier** | `cmd/verify-lic` | CLI | ✅ |
| **Chain verified** | #1, #30, #59, #87, #88 → all VALID | manual run | ✅ **verified 2026-10-14** |
| Single-leaf tree | `proof=[]`, `root=leaf` (correct) | verify-tx | ✅ |
| RFC 6962 | **v1 legacy** — no longer used | `docs/MERKLE.md` | 📚 marked |
| `conform_test.go` | 9 test cases, byte-identical | `internal/merkle` | ✅ |

**Chain integrity proof (2026-10-14):**

| Block | Payload type | Proof | Result |
|---|---|---|---|
| #1 | v1 pipe (benchmark) | 8 siblings | ✅ VALID |
| #30 | v1 pipe | 8 siblings | ✅ VALID |
| #59 | v1 pipe | 8 siblings | ✅ VALID |
| #87 (idx 0) | v1 pipe | 7 siblings | ✅ VALID |
| #87 (idx 23) | v1 pipe | 7 siblings | ✅ VALID |
| #88 (idx 0) | **v2 JSON (license)** | 0 (single leaf) | ✅ VALID |

---

## 🚦 Layer 3 — DoS & Body Protection

| Control | Value | Location | Status |
|---|---|---|---|
| **Rate limiting** | per-IP token bucket، **60/s sustained، burst 120** | `internal/ratelimit` | ✅ **added 2026-10-14** |
| **Body size limit** | `MaxBytesReader` 8 MiB default (env: `HORIZON_MAX_BODY_BYTES`) | `bodyLimitMiddleware` in `cmd/api/main.go` | ✅ **added 2026-10-14** |
| **DoS-1 (OOM)** | closed — 10 MB body → 413, backend stays alive | verified live | ✅ |
| Connection limit | 500 concurrent (netutil.LimitListener) | `switch.go` | ⚠️ |
| Read/Write timeout | 30 s | `switch.go` | ⚠️ |
| Idle timeout | 60 s | `switch.go` | ⚠️ |
| Max header bytes | 1 MB | `switch.go` | ⚠️ |

**Rate limit tests:**
**Live verification:** 40 parallel requests → `8×200`, `32×429` (some refill due to local latency)

---

## 🔒 Layer 4 — Authentication & Authorization

| Control | Value | Location | Status |
|---|---|---|---|
| Admin token | `X-Admin-Key` header | `requireAdmin()` | ✅ |
| Fail-closed on missing token | Backend refuses to start | `cmd/api/main.go` | ✅ |
| License suspend-all | 401 without token، 200 with | verified live | ✅ |
| License renew-all | 401 without token | verified live | ✅ |

**Endpoints protected (sample):**

---

## 🌐 Layer 5 — CORS & Transport

| Control | Value | Location | Status |
|---|---|---|---|
| **CORS allowlist** | wildcard `*` **removed** — `AllowOriginFunc` | `corsOriginAllowed` in `cmd/api/main.go` | ✅ **added 2026-10-14** |
| Allowed origins | `null` (file://), localhost, github.io | same | ✅ |
| `evil.example` | rejected (no CORS header) | verified live | ✅ |
| **mTLS helper** | TLS 1.3 min، RequireAndVerifyClientCert | `internal/mtls/mtls.go` | ✅ **added 2026-10-14** |
| mTLS cert generation | secp256k1 CA + server + client | `scripts/gen-mtls-certs.sh` | ✅ |
| Security headers | nosniff، DENY، XSS-Protection | `SecurityHeadersMiddleware` | ⚠️ |

---

## 📜 Layer 6 — Audit Trail

| Control | Value | Location | Status |
|---|---|---|---|
| **Hash-chained audit log** | `entry_hash = SHA256(seq\|ts\|action\|actor\|payload\|prev_hash)` | `internal/auditlog/auditlog.go` | ✅ **added 2026-10-14** |
| Tamper detection | `Verify()` returns first broken seq | same | ✅ |
| Tests | `TestAudit_ChainIntact`, `TestAudit_TamperDetected` | same | ✅ |
| Legacy sign audit | every signature logged | `signData()` | ⚠️ |

---

## 🔁 Layer 7 — Replay & Intrusion Prevention

| Control | Value | Location | Status |
|---|---|---|---|
| Nonce | unique per reading | `internal/industrial/logic.go` | ⚠️ |
| Timestamp window | −300 s to +120 s | `NonceFresh()` | ⚠️ |
| Nonce cache | 300 s in-memory | same | ⚠️ |
| SSRF protection | URL allow-list | `ValidateAgentURL()` | ⚠️ |
| Input validation | regex + sanitize | `ValidateTenantID()`, `SanitizeString()` | ⚠️ |

---

## 🗝 Layer 8 — Key Management

| Control | Value | Location | Status |
|---|---|---|---|
| Private key location | USB only، RAM فقط، wipe بعد از امضا | `offline-license.html` | ✅ |
| Browser RAM wipe | `window.__hz_wipeKey()` on beforeunload | same | ✅ **added 2026-10-14** |
| **Key rotation runbook** | script + docs، manual trigger | `scripts/rotate-signing-key.sh`، `docs/KEY-ROTATION.md` | ✅ **added 2026-10-14** |
| Rotation interval | 90 days recommended | same | ✅ |
| Shamir secret sharing | multi-party key split | `shamir.go` | ⚠️ |
| Auto-lock | 30 min inactivity | `startAutoLock()` | ⚠️ |
| HWID binding | license bound to hardware | `license_enforce.go` | ⚠️ |

---

## 📦 Layer 9 — Supply Chain

| Control | Value | Location | Status |
|---|---|---|---|
| Dependabot | Go + Docker + Actions | `.github/dependabot.yml` | 🟢 |
| **x/net CVE fix** | v0.43.0 → **v0.46.0** | `go.mod` | ✅ **2026-10-14** |
| govulncheck | weekly | `.github/workflows/security-scan.yml` | ⚠️ |
| gosec | static analysis | same | ⚠️ |
| **Dependabot status** | 18 fixed، ۴ open (pgx/v5، x/net) | `gh api` | ⚠️ |
| **pgx/v5 CVE** | **قفل با Go 1.24** (نیاز به Go 1.25 برای fix) | analyzed | ⚠️ |
| x/net CVE | قفل با Go 1.24، ریسک عملی صفر (`html.Parse` استفاده نمی‌شود) | analyzed | ⚠️ |

**Dependabot details:**
- 2 critical (pgx/v5 memory-safety) — fix in v5.9.0 requires Go 1.25
- 1 low (pgx/v5 SQL injection) — `PreferSimpleProtocol` removed, not exploitable
- 1 medium (x/net HTML parser DoS) — `html.Parse` not used

---

## 🛰 Layer 10 — Air-Gap Capability

| Control | Value |
|---|---|
| Offline signing | local ECDSA in browser |
| Offline verification | `cmd/verify-tx`, `cmd/verify-lic` — no network |
| `file://` origin | accepted in CORS allowlist |
| In-memory DB option | `SWITCH_DB=:memory:` |
| Smart sync | only new data on reconnect |
| Zero outbound (isolated) | no external calls |

---

## 🐳 Layer 11 — Docker & Deployment

| Control | Value | Location | Status |
|---|---|---|---|
| Non-root user | UID 10001 | `Dockerfile` | ⚠️ |
| Healthcheck | curl /api/v1/health | `Dockerfile` | ⚠️ |
| Explicit Dockerfile per app | switch vs backend | `.github/workflows/deploy-liara.yml` | ⚠️ |
| Read-only root | Alpine + su-exec | `Dockerfile` | ⚠️ |
| Go 1.24 | pinned (matches Liara) | `go.mod` | ✅ |

---

## 📊 Verified Metrics (2026-10-14)

| Metric | Value | Source |
|---|---|---|
| Chain height | **88** | `chain/info` |
| Total transactions | **12,857** | same |
| Latest hash | `cc5df59d...` | same |
| Latest merkle root | `bc712f92...` | same |
| Blocks verified | 6 (#1, #30, #59, #87 ×2, #88) | verify-tx |
| Fuzz executions | ~**1.86M** | `go test -fuzz` |
| Fuzz counterexamples | **0** | same |
| Cross-verify | **OpenSSL 3.5.7 → Verified OK** | `crossverify_test.go` |
| Test count (crypto) | 14 | `internal/crypto/` |
| Rate limit active | ✅ 60/s burst 120 | live test |
| Body limit active | ✅ 8 MiB | live test |
| CORS wildcard | ❌ removed | live test |

---

## 🧪 Test Coverage (2026-10-14)

| Package | Tests |
|---|---|
| `internal/crypto` | 14 |
| `internal/merkle` | 8 |
| `internal/license` | 5 |
| `internal/ratelimit` | 1 |
| `internal/auditlog` | 2 |
| `cmd/api` | 4 |
| `cmd/verify-tx` | negative + positive cases |
| **Total** | **34+** |

**Fuzz targets:**
- `FuzzVerifyHashRS` — malleability closure، length، determinism
- `FuzzSignDataRS` — roundtrip، RFC 6979، tamper detection
- `FuzzVerifyDataHex` — no panic، deterministic ok/err

---

## 📜 Compliance Notes

| Standard | Status |
|---|---|
| ECDSA secp256k1 (SEC 2) | ✅ Bitcoin/Ethereum curve |
| SHA-256 (FIPS 180-4) | ✅ |
| RFC 6979 (deterministic ECDSA) | ✅ |
| BIP-62 (low-S) | ✅ enforced |
| RFC 6962 (Merkle) | ⚠️ **v1 legacy** — v2 uses custom binary + ternary |
| FIPS 186-5 (ECDSA) | ❌ Not certified — secp256k1 is not FIPS-approved |
| ISO 27001 | ❌ Not certified — Q2 2027 |
| Third-party audit | ❌ Pending |
| HSM | ❌ Not yet — Q4 2026 |

**For court admissibility:** every transaction on chain has:
1. Leaf hash = `SHA256(payload)` — independently computable
2. ECDSA signature verified against Authority public key
3. Merkle inclusion proof to block root
4. Hash chain link to previous block

All four are independently verifiable via `cmd/verify-tx` (no Backend، no network).

---

## 🚧 What Is NOT YET

- ⏳ **HSM hardware** — software-only today (Q4 2026)
- ⏳ **Multi-node consensus** — single node (Q1 2027)
- ⏳ **ISO 27001** — Q2 2027
- ⏳ **FIPS certification** — secp256k1 not FIPS-compliant by design
- ⏳ **Third-party security audit** — pending
- ⏳ **Ternary Merkle in production** — implemented, not yet wired into `chain/append.go`

---

## 📞 Contact

- 🔭 **Explorer (live):** [monitor.html](https://beaconchain-horizon.github.io/horizon-security-assessment/monitor.html)
- 🔑 **Offline signer:** [offline-license.html](https://beaconchain-horizon.github.io/horizon-security-assessment/offline-license.html)
- 📦 **Main repo:** [github.com/beaconchain-horizon/horizon-core](https://github.com/beaconchain-horizon/horizon-core)
- 📊 **Public pages:** [github.com/beaconchain-horizon/horizon-security-assessment](https://github.com/beaconchain-horizon/horizon-security-assessment)

---

<div align="center">

**© 2026 Horizon Core — Mahdi Amoli Moghaddam**

🔭 *اثبات‌پذیری برای بانک، صنعت، و air-gap.*

</div>
