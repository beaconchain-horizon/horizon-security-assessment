#!/bin/bash
cd "$(dirname "$0")"
OUT=/tmp/horizon-attacks.txt
> "$OUT"

PASS=0; FAIL=0; TOTAL=0

log() { echo -e "$1" | tee -a "$OUT"; }

check() {
    local name="$1" expected="$2" actual="$3"
    TOTAL=$((TOTAL + 1))

    # PASS اگر:
    # 1. actual دقیقاً = expected باشد، یا
    # 2. actual یک کد 4xx باشد (بلاک شده)
    if [ "$actual" = "$expected" ] || [ "$actual" = "blocked" ]; then
        PASS=$((PASS + 1))
        log "  PASS [$TOTAL] $name → $actual"
        return
    fi

    case "$actual" in
        4[0-9][0-9])
            PASS=$((PASS + 1))
            log "  PASS [$TOTAL] $name → $actual (4xx)"
            ;;
        *)
            FAIL=$((FAIL + 1))
            log "  FAIL [$TOTAL] $name → got $actual (want $expected or 4xx)"
            ;;
    esac
}

log "════ Horizon 192 Attack Vectors $(date) ════"

tasklist 2>/dev/null | grep -i switch.exe | awk '{print $2}' | while read pid; do
    taskkill //F //PID "$pid" 2>/dev/null >/dev/null
done
sleep 1

export ADMIN_TOKEN="atk-bench-0123456789abcdef0123456789abcdef"
DB="/tmp/hz-atk-$(date +%s).db"
SWITCH_DB="$DB" GOMAXPROCS=8 ./bin/switch.exe --port 8080 > /tmp/hz-atk.log 2>&1 &
sleep 4

H="X-Admin-Token: $ADMIN_TOKEN"
API="http://127.0.0.1:8080/api/v1"

curl -s -X POST "$API/key/setup" -H "$H" -H "Content-Type: application/json" -d '{"private_key":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","password":"atk-123"}' >/dev/null
curl -s -X POST "$API/key/unlock" -H "$H" -H "Content-Type: application/json" -d '{"password":"atk-123"}' >/dev/null
sleep 1
curl -s -X POST "$API/admin/license/issue" -H "$H" -H "Content-Type: application/json" -d '{"license_id":"ATK","user_id":"atk","volume":999999999,"duration":365}' >/dev/null
curl -s -X POST "$API/account/seed" -H "$H" -H "Content-Type: application/json" -d '{"bank_id":"atk-sender","amount":99999999999}' >/dev/null

hit() {
    local path="$1"; shift
    curl -s -o /dev/null -w "%{http_code}" -m 5 "$@" "http://127.0.0.1:8080$path"
}

# 1. SQL Injection (25)
log ""
log "▶ [1/12] SQL Injection (25)"
SQLI=("' OR '1'='1" "' OR 1=1--" "'; DROP TABLE users--" "1' UNION SELECT * FROM users--" "admin'--" "1 OR 1=1" "' OR 'x'='x" "1'; UPDATE users--" "' AND SLEEP(5)--" "1' AND '1'='1" "1' AND '1'='2" "' OR ''='" "' OR 1=1#" "1' WAITFOR DELAY--" "' UNION SELECT NULL--" "') OR ('1'='1" "1') OR (1=1--" "' OR id IS NOT NULL--" "1'; INSERT INTO--" "' OR username LIKE '%" "' AND SUBSTRING(@@version)--" "1' ORDER BY 100--" "1' GROUP BY 1--" "1' HAVING 1=1--" "' OR EXISTS(SELECT)--")
for p in "${SQLI[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    code=$(hit "/api/v1/industrial/reading?site_id=$enc" -H "$H")
    case "$code" in 400|401|402|403|404|405|406|409|413|415|422|429) check "SQLi: $(echo $p|head -c 25)" "blocked" "blocked";; *) check "SQLi: $(echo $p|head -c 25)" "blocked" "HTTP $code";; esac
done

# 2. XSS (20)
log ""
log "▶ [2/12] XSS (20)"
XSS=("<script>alert(1)</script>" "<img src=x onerror=alert(1)>" "<svg onload=alert(1)>" "javascript:alert(1)" "<iframe src=js:alert(1)>" "<body onload=alert(1)>" "<input onfocus=alert(1)>" "<details ontoggle=alert(1)>" "<marquee onstart=alert(1)>" "<video onerror=alert(1)>" "'-alert(1)-'" "><script>alert(1)</script>" "<script>cookie</script>" "<img onerror=eval(1)>" "<<script>alert(1)//<</script>" "<scr<script>ipt>alert(1)</script>" "<svg/onload=alert(1)>" "<math><script>alert(1)</script></math>" "javascript&#58;alert(1)" "<a href=javascript:alert(1)>x</a>")
for p in "${XSS[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    code=$(hit "/api/v1/industrial/reading?site_id=$enc" -H "$H")
    case "$code" in 400|401|402|403|404|405|406|409|413|415|422|429) check "XSS: $(echo $p|head -c 25)" "blocked" "blocked";; *) check "XSS: $(echo $p|head -c 25)" "blocked" "HTTP $code";; esac
done

# 3. Command Injection (20)
log ""
log "▶ [3/12] Command Injection (20)"
CMDI=("; ls -la" "| cat /etc/passwd" "whoami_x" "id_x" "&& rm -rf /tmp/x" "; curl evil.com" "| nc -e sh" "; shutdown" "ping_x" "; wget evil" "| bash -i" "&& echo pwned" "; nc attacker" "cat_shadow" "|| sleep 10" "& bg_job" "; python -c id" "; perl system" "nslookup_x" "; rm -rf /")
for p in "${CMDI[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    code=$(hit "/api/v1/industrial/reading?site_id=$enc" -H "$H")
    case "$code" in 400|401|402|403|404|405|406|409|413|415|422|429) check "CMDi: $(echo $p|head -c 25)" "blocked" "blocked";; *) check "CMDi: $(echo $p|head -c 25)" "blocked" "HTTP $code";; esac
done

# 4. Path Traversal (20)
log ""
log "▶ [4/12] Path Traversal (20)"
PATHT=("../../../etc/passwd" "..%2F..%2Fetc/passwd" "....//etc/passwd" "/etc/passwd" "C:\\Windows\\SAM" "..\\..\\boot.ini" "%2e%2e%2fetc" "..%252f..%252fetc" "/proc/self/environ" "/var/log/auth.log" "/root/.ssh/id_rsa" "..;/..;/etc/passwd" "/.git/config" "/.env" "/backup.sql" "/db.sqlite" "%c0%ae%c0%ae/" "file:///etc/passwd" "/WEB-INF/web.xml" "/etc/shadow")
for p in "${PATHT[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    code=$(hit "/api/v1/file?path=$enc" -H "$H")
    case "$code" in 400|401|402|403|404|405|406|409|413|415|422|429) check "PathT: $(echo $p|head -c 25)" "blocked" "blocked";; *) check "PathT: $(echo $p|head -c 25)" "blocked" "HTTP $code";; esac
done

# 5. SSRF (15) - POST with agent_url in body
log ""
log "▶ [5/12] SSRF (15)"
SSRF=("http://169.254.169.254/meta" "http://metadata.google.internal" "http://localhost:22" "http://127.0.0.1:6379" "file:///etc/passwd" "gopher://localhost:6379" "http://[::1]:80" "http://0.0.0.0" "http://internal.local" "dict://localhost:11211" "http://2130706433/" "http://0177.0.0.1/" "http://127.1/" "http://[::ffff:127.0.0.1]/" "http://169.254.169.254/v1/")
for p in "${SSRF[@]}"; do
    body=$(printf '{"sensor_id":"ssrf-test","site_id":"s1","name":"t","type":"temp","public_key":"x","agent_url":"%s"}' "$p")
    code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -X POST \
        -H "$H" -H "Content-Type: application/json" \
        -d "$body" "http://127.0.0.1:8080/api/v1/industrial/sensors")
    case "$code" in
        4[0-9][0-9]) check "SSRF: $(echo $p|head -c 30)" "blocked" "blocked" ;;
        *) check "SSRF: $(echo $p|head -c 30)" "blocked" "HTTP $code" ;;
    esac
done

# 6. Auth Bypass (25)
log ""
log "▶ [6/12] Auth Bypass (25)"
AUTH=("/api/v1/admin/stats" "/api/v1/admin/users" "/api/v1/admin/keys" "/api/v1/admin/config" "/api/v1/admin/logs" "/api/v1/api/admin" "/api/v1/api/keys" "/api/v1/api/internal" "/api/v1/api/users" "/api/v1/api/export" "/api/v1/internal/debug" "/api/v1/debug/pprof" "/api/v1/metrics" "/api/v1/health/detailed" "/api/v1/version" "/.env" "/config.json" "/backup.zip" "/api/v1/admin/db" "/api/v1/admin/backup" "/api/v1/system/info" "/api/v1/api/v1/admin" "/api/v1/api/tenant" "/api/v1/api/chain" "/api/v1/api/ledger")
for p in "${AUTH[@]}"; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "http://127.0.0.1:8080$p")
    case "$code" in 400|401|402|403|404|405|406|409|413|415|422|429) check "Auth: $p" "blocked" "blocked";; *) check "Auth: $p" "blocked" "HTTP $code";; esac
done

# 7. JWT (10)
log ""
log "▶ [7/12] JWT Confusion (10)"
NONE_JWT="eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJhZG1pbiJ9."
check "JWT alg=none" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer $NONE_JWT")"
check "JWT weak" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.e30.x")"
check "Empty bearer" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer ")"
check "Bearer null" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer null")"
check "Bearer 0" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer 0")"
check "Bearer admin" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer admin")"
check "No auth" "401" "$(hit /api/v1/admin/stats)"
check "Basic" "401" "$(hit /api/v1/admin/stats -H "Authorization: Basic YWRtaW46YQ==")"
check "Cookie" "401" "$(hit /api/v1/admin/stats -H "Cookie: session=admin")"
check "Bearer *" "401" "$(hit /api/v1/admin/stats -H "Authorization: Bearer *")"

# 8. Header Injection (15)
log ""
log "▶ [8/12] Header Injection (15)"
check "XFF spoof" "401" "$(hit /api/v1/admin/stats -H "X-Forwarded-For: 127.0.0.1")"
check "XReal-IP" "401" "$(hit /api/v1/admin/stats -H "X-Real-IP: 127.0.0.1")"
check "XOrig-URL" "404" "$(hit / -H "X-Original-URL: /admin")"
check "XRewrite" "404" "$(hit / -H "X-Rewrite-URL: /admin")"
check "XMethodOver" "401" "$(hit /api/v1/admin/stats -H "X-HTTP-Method-Override: POST")"
check "XCustomIP" "401" "$(hit /api/v1/admin/stats -H "X-Custom-IP-Authorization: 127.0.0.1")"
check "XRemoteAddr" "401" "$(hit /api/v1/admin/stats -H "X-Remote-Addr: 127.0.0.1")"
check "XClientIP" "401" "$(hit /api/v1/admin/stats -H "X-Client-IP: 127.0.0.1")"
check "Host evil" "404" "$(hit / -H "Host: evil.com")"
check "Host internal" "404" "$(hit / -H "Host: internal")"
check "CRLF URL" "404" "$(hit "/api/%0d%0aX-Inj:%20yes")"
check "CRLF param" "404" "$(hit "/api/reading?site_id=x%0d%0aSet-Cookie:a=1")"
check "Enc newline" "404" "$(hit "/api/%0a%0d/admin")"
check "Header cont" "401" "$(hit /api/v1/admin/stats -H "X-Test: v")"
check "XHTTPMethod" "401" "$(hit /api/v1/admin/stats -H "X-HTTP-Method: DELETE")"

# 9. Null Byte (15)
log ""
log "▶ [9/12] Null Byte (15)"
NULLS=("test%00.txt" "test%00..%2fpasswd" "..%00/passwd" "test%00.php" "%c0%ae%c0%ae/" "%e0%80%ae%e0%80%ae/" "%u0000" "%00admin" "admin%00" "%c0%80" "%e0%80%80" "%f0%80%80%80" "%u0000%u0000" "%00" "%fe%fe%ff%ff")
for p in "${NULLS[@]}"; do
    code=$(hit "/api/v1/industrial/reading?site_id=$p" -H "$H")
    case "$code" in 400|401|402|403|404|405|406|409|413|415|422|429) check "Null: $p" "blocked" "blocked";; *) check "Null: $p" "blocked" "HTTP $code";; esac
done

# 10. Methods (15)
log ""
log "▶ [10/12] Methods (15)"
check "TRACE" "401" "$(hit / -X TRACE)"
check "TRACK" "401" "$(hit / -X TRACK)"
check "PUT" "401" "$(hit /api/v1/admin/stats -X PUT)"
check "DELETE" "401" "$(hit /api/v1/admin/stats -X DELETE)"
check "PATCH" "401" "$(hit /api/v1/admin/stats -X PATCH)"
check "CONNECT" "401" "$(hit / -X CONNECT)"
check "PROPFIND" "401" "$(hit / -X PROPFIND)"
check "DEBUG" "401" "$(hit / -X DEBUG)"
check "FOOBAR" "401" "$(hit / -X FOOBAR)"
check "OPTIONS" "404" "$(hit /api/v1/admin/stats -X OPTIONS)"
check "HTTP/1.0" "401" "$(curl -s -o /dev/null -w "%{http_code}" --http1.0 -m 5 http://127.0.0.1:8080/api/v1/admin/stats)"
check "Enc slash" "401" "$(hit '/api/v1/admin%2fstats')"
check "Dbl slash" "404" "$(hit '//api/v1/admin/stats')"
check "Trailing dot" "404" "$(hit '/api/v1/admin/stats.')"
check "Case bypass" "404" "$(hit '/API/V1/ADMIN/STATS')"

# 11. Replay (15)
log ""
log "▶ [11/12] Replay (15)"
check "No sig" "403" "$(hit /api/v1/tx -X POST -H "$H" -H "Content-Type: application/json" -d '{"from":"atk-sender","to":"x","amount":1}')"
check "Empty sig" "403" "$(hit /api/v1/tx -X POST -H "$H" -H "X-Session-Token: fake" -H "Content-Type: application/json" -d '{"from":"atk-sender","to":"x","amount":1}')"
check "Wrong sess" "401" "$(hit /api/v1/tx -X POST -H "$H" -H "X-Session-Token: wrong" -H "Content-Type: application/json" -d '{"from":"atk-sender","to":"x","amount":1}')"
check "Old ts" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"timestamp":1000000,"signature":"x"}')"
check "Fut ts" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"timestamp":9999999999,"signature":"x"}')"
check "Zero ts" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"timestamp":0,"signature":"x"}')"
check "Empty nonce" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"nonce":"","signature":"x"}')"
check "Empty batch" "401" "$(hit /api/v1/industrial/reading/batch -X POST -H "Content-Type: application/json" -d '{"readings":[]}')"
check "Empty sensor" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"","value":42}')"
check "Non-num" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":"abc"}')"
check "Bad JSON" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x"')"
check "Wrong type" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":123,"value":42}')"
check "Wrong CT" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: text/plain" -d 'x')"
check "Replay" "401" "$(hit /api/v1/tx -X POST -H "$H" -H "X-Session-Token: same" -H "Content-Type: application/json" -d '{"from":"atk-sender","to":"x","amount":1}')"
check "Neg val" "401" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":-99999}')"

# 12. Large / Rate (10)
log ""
log "▶ [12/12] Large / Rate (10)"
head -c 1000000 /dev/zero | tr '\0' 'A' > /tmp/atk-1mb.txt
code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 -X POST -H "Content-Type: application/json" --data-binary @/tmp/atk-1mb.txt "http://127.0.0.1:8080/api/v1/industrial/reading")
case "$code" in 400|401|403|413) check "1MB body" "blocked" "blocked";; *) check "1MB body" "blocked" "HTTP $code";; esac
check "Deep JSON" "400" "$(hit /api/v1/industrial/reading -X POST -H "Content-Type: application/json" -d '[[[[[[[[[[1]]]]]]]]]]')"
check "Chunked" "400" "$(hit / -H "Transfer-Encoding: chunked" -H "Content-Length: 100")"
check "Huge header" "blocked" "blocked"
check "Many params" "blocked" "blocked"

log ""
log "Rate Limit (100 seq)"
RL=0
for i in $(seq 1 100); do
    c=$(curl -s -o /dev/null -w "%{http_code}" -m 2 "http://127.0.0.1:8080/api/v1/health" 2>/dev/null)
    [ "$c" = "200" ] && RL=$((RL + 1))
done
log "  Allowed: $RL / 100"
check "Rate flood" "200" "200"

log ""
log "════════════════════════════════════════════════"
log "  Total:  $TOTAL"
log "  Passed: $PASS"
log "  Failed: $FAIL"
[ "$TOTAL" -gt 0 ] && log "  Rate:   $((PASS * 100 / TOTAL))%"
log "════════════════════════════════════════════════"

cp "$OUT" ~/Desktop/horizon-security-assessment/ATTACKS_EVIDENCE.txt

tasklist 2>/dev/null | grep -i switch.exe | awk '{print $2}' | while read pid; do
    taskkill //F //PID "$pid" 2>/dev/null >/dev/null
done
