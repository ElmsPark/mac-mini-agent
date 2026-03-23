#!/usr/bin/env bash
# pm-smoke.sh -- Thorough HTTP smoke test for PageMotor sites.
#
# Usage:
#   bash pm-smoke.sh                          # Test all sites
#   bash pm-smoke.sh https://buildtheweb.site # Test a single site
#
# Checks per site:
# 1. HTTP status code (must be 200)
# 2. Response body size (must be > 1000 bytes, catches blank pages)
# 3. PHP error scan (fatal error, parse error, warning, 500 Internal)
# 4. HTML structure (html, head, body tags present)
# 5. PageMotor marker (confirms it's actually serving PageMotor output)
# 6. Response time (flags anything over 5 seconds)
#
# Exit code: 0 if all sites pass, 1 if any site fails.

set -euo pipefail

ALL_SITES=(
  "https://buildtheweb.site"
  "https://helenmillar.com"
  "https://birdsofbannowbay.com"
  "https://epemail.elmspark.com"
  "https://epbookings.elmspark.com"
  "https://epgdpr.elmspark.com"
  "https://epnewsletter.elmspark.com"
  "https://demo.elmspark.com"
  "https://oej.elmspark.com"
  "https://k9.elmspark.com"
  "https://miraclebibleway.com"
  "https://nosampling.com"
  "https://everytanisdamage.com"
  "https://dev2.elmspark.com"
  "https://cc-dev20260302.buildtheweb.site"
)

# If a single URL is passed, test only that site
if [ -n "${1:-}" ]; then
  ALL_SITES=("$1")
fi

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=${#ALL_SITES[@]}

echo "PageMotor Smoke Test"
echo "===================="
echo "Testing $TOTAL site(s)..."
echo ""

for URL in "${ALL_SITES[@]}"; do
  SITE_NAME=$(echo "$URL" | sed 's|https://||')
  ISSUES=""
  TMPFILE=$(mktemp /tmp/pm-smoke-XXXXXX.html)

  # Fetch the page, capturing status code, size, and time
  HTTP_CODE=$(curl -s -o "$TMPFILE" -w "%{http_code}" --max-time 15 "$URL" 2>/dev/null || echo "000")
  BODY_SIZE=$(wc -c < "$TMPFILE" | tr -d ' ')
  TIME_TOTAL=$(curl -s -o /dev/null -w "%{time_total}" --max-time 15 "$URL" 2>/dev/null || echo "0")

  # Check 1: HTTP status
  if [ "$HTTP_CODE" != "200" ]; then
    ISSUES="$ISSUES  FAIL: HTTP $HTTP_CODE (expected 200)\n"
  fi

  # Check 2: Response size
  if [ "$BODY_SIZE" -lt 1000 ]; then
    ISSUES="$ISSUES  FAIL: Body is $BODY_SIZE bytes (< 1000, likely blank page)\n"
  fi

  # Check 3: PHP errors
  PHP_ERRORS=$(grep -ci "fatal error\|parse error\|Warning:.*on line\|500 Internal Server Error" "$TMPFILE" 2>/dev/null) || PHP_ERRORS=0
  if [ "$PHP_ERRORS" -gt 0 ]; then
    # Grab the first error line for context
    FIRST_ERROR=$(grep -i "fatal error\|parse error\|Warning:.*on line\|500 Internal" "$TMPFILE" | head -1 | cut -c1-120)
    ISSUES="$ISSUES  FAIL: $PHP_ERRORS PHP error(s) found. First: $FIRST_ERROR\n"
  fi

  # Check 4: HTML structure
  HAS_HTML=$(grep -ci "<html" "$TMPFILE" 2>/dev/null) || HAS_HTML=0
  HAS_HEAD=$(grep -ci "<head" "$TMPFILE" 2>/dev/null) || HAS_HEAD=0
  HAS_BODY=$(grep -ci "<body" "$TMPFILE" 2>/dev/null) || HAS_BODY=0
  HAS_CLOSE=$(grep -ci "</html>" "$TMPFILE" 2>/dev/null) || HAS_CLOSE=0
  if [ "$HAS_HTML" -eq 0 ] || [ "$HAS_HEAD" -eq 0 ] || [ "$HAS_BODY" -eq 0 ] || [ "$HAS_CLOSE" -eq 0 ]; then
    ISSUES="$ISSUES  FAIL: Incomplete HTML structure (html=$HAS_HTML head=$HAS_HEAD body=$HAS_BODY close=$HAS_CLOSE)\n"
  fi

  # Check 5: PageMotor marker
  PM_MARKER=$(grep -ci "pagemotor\|pm-content\|pm-block" "$TMPFILE" 2>/dev/null) || PM_MARKER=0
  if [ "$PM_MARKER" -eq 0 ]; then
    ISSUES="$ISSUES  WARN: No PageMotor markers found in output\n"
  fi

  # Check 6: Response time
  TIME_MS=$(echo "$TIME_TOTAL" | awk '{printf "%.0f", $1 * 1000}')
  if [ "$TIME_MS" -gt 5000 ]; then
    ISSUES="$ISSUES  WARN: Slow response (${TIME_MS}ms > 5000ms)\n"
  fi

  # Report -- distinguish between hard FAILs and soft WARNs
  HAS_FAILS=$(echo -e "$ISSUES" | grep -c "FAIL:" 2>/dev/null) || HAS_FAILS=0
  HAS_WARNS=$(echo -e "$ISSUES" | grep -c "WARN:" 2>/dev/null) || HAS_WARNS=0

  if [ "$HAS_FAILS" -gt 0 ]; then
    echo "FAIL  $SITE_NAME  (HTTP $HTTP_CODE, ${BODY_SIZE}B, ${TIME_MS}ms)"
    echo -e "$ISSUES"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  elif [ "$HAS_WARNS" -gt 0 ]; then
    echo "WARN  $SITE_NAME  (HTTP $HTTP_CODE, ${BODY_SIZE}B, ${TIME_MS}ms)"
    echo -e "$ISSUES"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "PASS  $SITE_NAME  (HTTP $HTTP_CODE, ${BODY_SIZE}B, ${TIME_MS}ms)"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi

  rm -f "$TMPFILE"
done

echo ""
echo "===================="
echo "Results: $PASS_COUNT/$TOTAL passed, $FAIL_COUNT/$TOTAL failed"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
