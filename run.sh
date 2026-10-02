#!/bin/bash
cd "$(dirname "$0")"
echo "════ Horizon Core — Assessment ════"
echo ""
echo "[1/3] Full Attack Suite (201 vectors)..."
./attacks-192.sh 2>&1 | tail -8
echo ""
echo "[2/3] Real TPS..."
./tps-real.sh 2>&1 | tail -12
echo ""
echo "════ COMPLETE ════"
