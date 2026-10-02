#!/bin/bash
cd "$(dirname "$0")"
OUT=/tmp/horizon-tps.txt
> "$OUT"

echo "════ Horizon TPS Benchmark $(date) ════" | tee -a "$OUT"
echo "CPU: $(nproc 2>/dev/null) cores" | tee -a "$OUT"

tasklist 2>/dev/null | grep -i switch.exe | awk '{print $2}' | while read pid; do
    taskkill //F //PID "$pid" 2>/dev/null >/dev/null
done
sleep 1

export ADMIN_TOKEN="tps-bench-0123456789abcdef0123456789abcdef"
DB="/tmp/hz-tps-$(date +%s).db"

SWITCH_DB="$DB" GOMAXPROCS=8 ./bin/switch.exe --port 8080 > /tmp/hz-tps.log 2>&1 &
sleep 4

H="X-Admin-Token: $ADMIN_TOKEN"
API="http://127.0.0.1:8080/api/v1"

curl -s -X POST "$API/key/setup" -H "$H" -H "Content-Type: application/json" \
    -d '{"private_key":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","password":"bench-123"}' >/dev/null
curl -s -X POST "$API/key/unlock" -H "$H" -H "Content-Type: application/json" \
    -d '{"password":"bench-123"}' >/dev/null
sleep 1

curl -s -X POST "$API/admin/license/issue" -H "$H" -H "Content-Type: application/json" \
    -d '{"license_id":"TPS","user_id":"bench","volume":999999999,"duration":365}' >/dev/null
curl -s -X POST "$API/account/seed" -H "$H" -H "Content-Type: application/json" \
    -d '{"bank_id":"bench-sender","amount":99999999999}' >/dev/null

run_tps() {
    local label="$1" count="$2"
    echo "" | tee -a "$OUT"
    echo "── $label (n=$count) ──" | tee -a "$OUT"

    TOK=$(curl -s -X POST "$API/signing/session" -H "$H" | grep -oP '"session_token":"\K[^"]+')
    P="/tmp/p-$$.json"
    {
        printf '{"session_token":"%s","txs":[' "$TOK"
        seq 1 "$count" | awk 'BEGIN{f=1}{if(!f)printf ",";f=0;printf "{\"from\":\"bench-sender\",\"to\":\"r-%d\",\"amount\":1}",$1}'
        printf ']}'
    } > "$P"

    START=$(date +%s%N)
    RESP=$(curl -s -X POST "$API/tx/batch" -H "$H" -H "Content-Type: application/json" --data-binary @"$P")
    DUR=$(( ($(date +%s%N) - START) / 1000000 ))
    TPS=$((count * 1000 / (DUR > 0 ? DUR : 1)))

    echo "  Duration: ${DUR}ms" | tee -a "$OUT"
    echo "  TPS:      $TPS" | tee -a "$OUT"
    echo "  Response: $RESP" | tee -a "$OUT"
    rm -f "$P"
}

run_tps "Warmup 10K" 10000
sleep 1
run_tps "Standard 50K" 50000
sleep 1
run_tps "High 100K" 100000
sleep 1
run_tps "Stress 100K" 100000

echo "" | tee -a "$OUT"
echo "── Chain Stats ──" | tee -a "$OUT"
sleep 3
curl -s "$API/chain/stats" -H "$H" | tee -a "$OUT"
echo "" | tee -a "$OUT"

echo "Blocks created: $(grep -c 'Block #' /tmp/hz-tps.log)" | tee -a "$OUT"

tasklist 2>/dev/null | grep -i switch.exe | awk '{print $2}' | while read pid; do
    taskkill //F //PID "$pid" 2>/dev/null >/dev/null
done

cp "$OUT" ~/Desktop/horizon-security-assessment/TPS_EVIDENCE.txt
echo ""
echo "Saved: TPS_EVIDENCE.txt"
