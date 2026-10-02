# Horizon Core — Benchmark Results

Date: 2026-10-02
Environment: Windows 10, 8-core CPU, GOMAXPROCS=8

## Measured TPS (Batch /tx/batch)

| Test | TX count | Duration | TPS |
|------|----------|----------|-----|
| Warmup | 10,000 | 156ms | 64,102 |
| Standard | 50,000 | 279ms | 179,211 |
| High Load | 100,000 | 416ms | **240,384** |
| Stress | 500,000 | - | rejected (limit 100K) |

**Peak measured: 240,384 TPS** at 100,000 TX per batch request.

## Verified End-to-End

- Batch 100K: HTTP 201, processed=100000, failed=0
- Chain blocks created: 41
- No panics, no data loss in accepted window

## Important Limitation

Batcher flush is INCOMPLETE under extreme load:
- Submitted: 160,000 (cumulative across tests)
- Flushed to chain: 16,273
- Ratio: ~10%

The peak 240,384 TPS measures **ledger ingestion + block creation rate**,
NOT sustained end-to-end throughput for a complete workload.

Root cause: async batcher contention — multiple Flush goroutines compete
for chainMutex. Full design fix (batcher v2) deferred.

## What It DOES Prove

- Ledger handles 100K TX in <500ms
- Block creation + ECDSA signing works
- No crashes at 240K TPS ingestion
- Chain remains valid

## Historical Reference

| Date | Type | TPS |
|------|------|-----|
| 2026-09 | Industrial reading (tpsbench) | 32,849 |
| 2026-10 | Banking batch (peak) | 240,384 |
| 2026-10 | Banking batch (sustained) | ~10,000 |

## Reproduce

./tps-real.sh

Evidence: TPS_EVIDENCE.txt
