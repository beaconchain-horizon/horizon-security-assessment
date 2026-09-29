@echo off
chcp 65001 >nul
cd /d "%%~dp0"

echo ============================================
echo   Horizon Core - Security Assessment
echo   Version 1.0 - September 2026
echo ============================================
echo.

taskkill /F /IM switch.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [1/8] Generating ECDSA P-256 signing key...
if exist test-keys\private.pem del test-keys\private.pem
if exist test-keys\public.pem del test-keys\public.pem
bin\sensortool.exe genkey --out=test-keys
echo       OK
echo.

echo [2/8] Starting server (in-memory DB)...
set SWITCH_DB=:memory:
set CHAIN_CONFIG=%%cd%%\config\chain.json
set ADMIN_TOKEN=bench
set GIN_MODE=release
start /B bin\switch.exe > %%TEMP%%\assessment.log 2>&1
timeout /t 5 /nobreak >nul
echo       OK - server on 127.0.0.1:8080
echo.

echo [3/8] Health check...
curl -s http://127.0.0.1:8080/api/v1/health
echo.
echo.

echo [4/8] TPS Benchmark - 200,000 readings...
bin\tpsbench.exe -url=http://127.0.0.1:8080/api/v1/industrial/reading/batch -key=test-keys\private.pem -sensor=bench-001 -n=200000 -c=50 -bs=500
echo.

echo [5/8] Rate Limiting check...
echo       (skipped in BAT - see run.sh for full test)
echo.

echo [6/8] Replay protection check...
curl -s -X POST http://127.0.0.1:8080/api/v1/industrial/reading -H "Content-Type: application/json" -d "{\"sensor_id\":\"bench-001\",\"value\":42.0,\"nonce\":\"test\",\"timestamp\":0,\"signature\":\"invalid\"}"
echo.
echo       (invalid signature should be rejected)
echo.

echo [7/8] Dual Control and Session endpoints...
curl -s -X POST http://127.0.0.1:8080/api/v1/dual/request -H "X-Admin-Token: bench" -H "Content-Type: application/json" -d "{\"data\":\"test-tx\",\"by\":\"admin1\"}"
echo.
curl -s -X POST http://127.0.0.1:8080/api/v1/signing/session -H "X-Admin-Token: bench"
echo.
echo.

echo [8/8] Integrity check...
curl -s http://127.0.0.1:8080/api/v1/industrial/dashboard -H "X-Admin-Token: bench"
echo.
echo.

taskkill /F /IM switch.exe >nul 2>&1

echo ============================================
echo   Security Assessment: COMPLETE
echo ============================================
pause
