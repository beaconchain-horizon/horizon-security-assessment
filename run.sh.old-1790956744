#!/bin/bash
cd "$(dirname "$0")"

echo "════════════════════════════════════════════════════════"
echo "  Horizon Core — Security Assessment"
echo "  Version 1.0 — September 2026"
echo "════════════════════════════════════════════════════════"
echo ""

taskkill //F //IM switch.exe 2>/dev/null || true
sleep 2

echo "[1/7] Generating ECDSA P-256 signing key..."
rm -f test-keys/private.pem test-keys/public.pem 2>/dev/null || true
./bin/sensortool genkey --out=test-keys
echo "      OK"
echo ""

CFG="$(pwd)/config/chain.json"
API="http://127.0.0.1:8080/api/v1"
TOK="X-Admin-Token: bench-0123456789abcdef0123456789ab"

echo "[2/7] Starting server (in-memory DB)..."
(SWITCH_DB=:memory: CHAIN_CONFIG="$CFG" ADMIN_TOKEN=bench-0123456789abcdef0123456789ab GIN_MODE=release ./bin/switch > /tmp/a.log 2>&1 &)
sleep 5
echo "      OK"
echo ""

echo "[3/7] Health check..."
curl -s $API/health
echo ""
echo ""

echo "[4/7] TPS Benchmark — 200,000 readings..."
./bin/tpsbench -url=$API/industrial/reading/batch -key=test-keys/private.pem -sensor=bench-001 -n=200000 -c=50 -bs=500
echo ""


echo "[5/8] Running real attack simulation suite..."
./attack.sh
echo ""

echo "[6/8] Dual Control & Session..."
curl -s -X POST $API/dual/request -H "$TOK" -H "Content-Type: application/json" -d '{"data":"test-tx","by":"admin1"}' | head -c 150
echo ""
curl -s -X POST $API/signing/session -H "$TOK" | head -c 150
echo ""
echo ""

echo "[7/8] Integrity check..."
curl -s $API/industrial/dashboard -H "$TOK" | head -c 250
echo ""
echo ""

echo "[8/8] Final Health check..."
curl -s $API/health
echo ""
echo ""

taskkill //F //IM switch.exe 2>/dev/null || true

echo "════════════════════════════════════════════════════════"
echo "  Security Assessment: COMPLETE"
echo "════════════════════════════════════════════════════════"
