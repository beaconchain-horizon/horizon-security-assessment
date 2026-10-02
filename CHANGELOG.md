# Changelog

## [3.0.1] - 2026-10-02

### Added
- Unified Blockchain: License + TX + Audit on single chain
- Adaptive Batcher with parallel signing
- Block ECDSA P-256 signature on every block
- Air-Gap enforcement on outbound HTTP
- Fail-closed auth (no ADMIN_TOKEN = no start)
- Real Shamir Secret Sharing (GF(2^8))
- Dual Control enforcement on /tx path
- Signing Session one-time token enforcement
- Genesis block auto-creation on key unlock
- /chain/stats endpoint
- /chain/flush endpoint
- /tx/batch endpoint (up to 100K txs)

### Changed
- FIPS 186-4 -> FIPS 186-5
- HWID enforcement independent of signature
- Auto-create receiver account on transfer

### Fixed
- Block numbering race condition
- Duplicate route registration panic
- Ledger flush N+1 query problem

### Security
- Admin token bypass fixed
- JWT confusion / alg=none blocked

## [3.0.0] - 2026-09-27

### Added
- Initial security assessment package
- 192 attack vectors
- TPS benchmark
- Air-Gap demo
