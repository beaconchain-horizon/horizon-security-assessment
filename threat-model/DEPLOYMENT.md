# Deployment Architecture

## محیط‌های استقرار
| محیط | کاربرد | امنیت |
|---|---|---|
| Dev | توسعه | Low |
| Staging | تست | Medium |
| Production (بانک) | عملیات | High |
| Air-gap (صنعت) | حیاتی | Critical |

## Production (بانک)
Client → LB (Nginx) → App Cluster (3-5 node) → PostgreSQL Cluster → HSM

## Air-Gap (صنعت)
L0 Sensor → L1 PLC → L2 SCADA → L3 Historian → [Diode] → L3.5 switch → L5 Chain

## Ports
| Port | Service |
|---|---|
| 8080 | switch API |
| 5432 | PostgreSQL |
| 22 | SSH |

## Backup
- DB: روزانه + ساعتی
- Blockchain: روزانه
- Encryption: AES-256

## DR
- RTO: < 1 hour
- RPO: < 15 min
