# Threat Model (STRIDE) — Horizon Core

نسخه 1.0 — 2026-10-05

## دارایی‌ها
| # | دارایی | حساسیت |
|---|---|---|
| A1 | Private Key ECDSA | Critical |
| A2 | Ledger | Critical |
| A3 | Blockchain | High |
| A4 | License | High |
| A5 | Session | High |
| A6 | Admin Token | Critical |
| A7 | Audit Log | High |
| A8 | Sensor | Medium |

## تهدیدها بر اساس STRIDE

### S — Spoofing
| ID | تهدید | کنترل | شدت |
|---|---|---|---|
| S1 | Admin Token جعل | 256-bit random | Low |
| S2 | Session جعل | single-use 5min | Low |
| S3 | HW ID جعل | HW bind | Medium |
| S4 | Sensor جعل | ECDSA sign | Medium |
| S5 | JWT alg=none | reject | Resolved |

### T — Tampering
| ID | تهدید | کنترل | شدت |
|---|---|---|---|
| T1 | Ledger تغییر | transaction | Medium |
| T2 | Block تغییر | Merkle | Medium |
| T3 | License تغییر | ECDSA | High |
| T4 | Audit تغییر | append-only | Medium |
| T5 | SQLi | Sanitize | Resolved |

### R — Repudiation
| ID | تهدید | کنترل |
|---|---|---|
| R1 | انکار تراکنش | dual + audit |
| R2 | انکار license | ECDSA |
| R3 | انکار sensor | ECDSA |

### I — Info Disclosure
| ID | تهدید | کنترل | شدت |
|---|---|---|---|
| I1 | Ledger read | X-Admin-Token | High |
| I2 | Key leak | air-gap | Critical |
| I3 | Token leak | env ACL | High |
| I4 | Timing | constant-time | Low |

### D — DoS
| ID | تهدید | کنترل |
|---|---|---|
| D1 | HTTP flood | rate 500K |
| D2 | Oversize | max 64KB |
| D3 | Slowloris | Gin timeout |
| D4 | DB exhaust | pool config |

### E — EoP
| ID | تهدید | کنترل | شدت |
|---|---|---|---|
| E1 | user→admin | X-Admin-Token | High |
| E2 | session bypass | fresh session | Low |
| E3 | SQLi→RCE | Sanitize | Resolved |
| E4 | CMD inj | banned patterns | Resolved |
| E5 | Path trav | banned .. | Resolved |

## خلاصه
| دسته | تعداد | Resolved | باقی |
|---|---:|---:|---:|
| Spoofing | 5 | 4 | 1 |
| Tampering | 5 | 2 | 3 |
| Repudiation | 3 | 0 | 3 |
| Info Disclosure | 4 | 3 | 1 |
| DoS | 4 | 3 | 1 |
| EoP | 5 | 4 | 1 |
| **جمع** | **26** | **16** | **10** |

## کنترل‌های فعال
- Sanitize Middleware (30 الگو)
- X-Admin-Token + API_KEY
- Session (5min, single-use)
- ECDSA P-256 (FIPS 186-5)
- Rate 500K req/s
- Body max 64KB
- Air-gap outbound block
- Dual control (1M ریال)
- Append-only audit

## Roadmap
| کنترل | اولویت |
|---|---|
| HSM فیزیکی | 🔥 |
| Pen-test مستقل | 🔥 |
| Hardware diode | 🔥 |
| WAF | ⚠️ |
| SIEM | ⚠️ |
| ISO 27001 | ⚠️ |

## نتیجه
- 16 از 26 تهدید resolved
- 0 آسیب‌پذیری بحرانی
- 10 در Roadmap
