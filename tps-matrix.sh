API="http://127.0.0.1:8080/api/v1/industrial/reading/batch"
BENCH="./bin/tpsbench.exe"
KEY="test-keys/private.pem"

run_tps() {
    printf "  %-15s n=%-8s c=%-4s bs=%-5s  " "$4" "$1" "$2" "$3"
    $BENCH -url="$API" -key="$KEY" -sensor=bench-001 -n="$1" -c="$2" -bs="$3" 2>&1 | \
        grep ">>>" | tail -1 | \
        sed -E 's/.*\| OK=([0-9]+) ERR=([0-9]+) \| ★TPS=([0-9]+)/OK=\1 ERR=\2 ★TPS=\3/'
}

echo "════════════════════════════════════════════════════════"
echo "  HORIZON — TPS MATRIX"
echo "════════════════════════════════════════════════════════"

echo ""
echo "▶ [1] Concurrency (n=100k, bs=500)"
for c in 1 5 10 25 50 100 200; do run_tps 100000 "$c" 500 "c=$c"; done

echo ""
echo "▶ [2] Batch Size (n=200k, c=50)"
for bs in 10 50 100 250 500 1000 2000; do run_tps 200000 50 "$bs" "bs=$bs"; done

echo ""
echo "▶ [3] افزایشی"
run_tps 50000   10  100  "Small"
run_tps 100000  25  250  "Medium"
run_tps 200000  50  500  "Standard"
run_tps 500000  75  500  "Heavy"
run_tps 1000000 100 500  "Load"
run_tps 2000000 150 1000 "MAX"

echo ""
echo "▶ [4] فشار بحرانی"
run_tps 500000  200 1000 "HighConc"
run_tps 1000000 250 1000 "VeryHigh"
run_tps 500000  300 500  "Extreme"

echo ""
echo "════════════════════════════════════════════════════════"
