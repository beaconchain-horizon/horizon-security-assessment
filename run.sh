#!/bin/bash
cd "$(dirname "$0")"
echo "════ Horizon Core — Assessment ════"
echo ""
echo "[1/3] Basic Security (16 vectors)..."
[ -f ./attack.sh ] && ./attack.sh 2>&1 | tail -6
echo ""
echo "[2/3] Full Attack Suite (201 vectors)..."
[ -f ./attacks-192.sh ] && ./attacks-192.sh 2>&1 | tail -8
echo ""
echo "[3/3] Real TPS..."
[ -f ./tps-real.sh ] && ./tps-real.sh 2>&1 | tail -15
echo ""
echo "════ COMPLETE ════"
