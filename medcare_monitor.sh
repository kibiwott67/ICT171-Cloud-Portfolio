#!/bin/bash
# =============================================================================
# medcare_monitor.sh — MedCare Server Health Monitor
# ICT171 Assignment 3 — Allan Kibiwott — allankibiwott.net
#
# PURPOSE:
#   Monitors the MedCare web server and system resources, generates a
#   colour-coded ASCII health dashboard in the terminal, AND writes a
#   structured HTML report to /var/www/html/status.html so the output
#   is publicly verifiable at https://allankibiwott.net/status.html
#
# WHAT IT CHECKS:
#   1. Apache2 service status
#   2. HTTP response code from allankibiwott.net
#   3. HTTPS response code (SSL/TLS check)
#   4. PHP availability
#   5. CPU usage (%)
#   6. RAM usage (used / total)
#   7. Disk usage on /
#   8. System uptime
#
# STUDENT CONTRIBUTION:
#   - ASCII bar-chart visualisation (not in any lab)
#   - HTML report generation for public/verifiable output
#   - Colour-coded health grades (OK / WARN / FAIL)
#   - All checks combined into one tool specific to this project
#
# USAGE:
#   chmod +x medcare_monitor.sh
#   sudo ./medcare_monitor.sh          # run once
#   sudo crontab -e                    # add: */30 * * * * /home/azureuser/medcare_monitor.sh
# =============================================================================

set -euo pipefail

DOMAIN="allankibiwott.net"
LOG_FILE="/var/log/medcare_monitor.log"
HTML_REPORT="/var/www/html/status.html"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
DATE_SHORT=$(date "+%d %b %Y, %H:%M")

# ── COLOUR CODES ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "  ${GREEN}[  OK  ]${RESET} $1"; }
warn() { echo -e "  ${YELLOW}[ WARN ]${RESET} $1"; }
fail() { echo -e "  ${RED}[ FAIL ]${RESET} $1"; }

# ── ASCII BAR CHART ─────────────────────────────────────────────────────────
# Draws a bar out of block characters, proportional to a percentage value.
# $1 = label, $2 = percent (0-100), $3 = warn threshold, $4 = fail threshold
draw_bar() {
    local label="$1" pct="$2" warn_t="$3" fail_t="$4"
    local bar_width=30
    local filled=$(( pct * bar_width / 100 ))
    local empty=$(( bar_width - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty;  i++)); do bar+="░"; done

    local colour=$GREEN
    (( pct >= fail_t )) && colour=$RED || (( pct >= warn_t )) && colour=$YELLOW

    printf "  %-8s ${colour}[${bar}]${RESET} %3d%%\n" "$label" "$pct"
}

# ── GATHER METRICS ──────────────────────────────────────────────────────────
OVERALL_STATUS="OK"

# 1. Apache2 status
if systemctl is-active --quiet apache2; then
    APACHE_STATUS="OK"; APACHE_MSG="active (running)"
else
    APACHE_STATUS="FAIL"; APACHE_MSG="inactive / not running"; OVERALL_STATUS="FAIL"
fi

# 2. HTTP check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$DOMAIN" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "301" || "$HTTP_CODE" == "302" ]]; then
    HTTP_STATUS="OK"; HTTP_MSG="$HTTP_CODE"
else
    HTTP_STATUS="FAIL"; HTTP_MSG="$HTTP_CODE (unexpected)"; OVERALL_STATUS="FAIL"
fi

# 3. HTTPS check
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$DOMAIN" 2>/dev/null || echo "000")
if [[ "$HTTPS_CODE" == "200" ]]; then
    HTTPS_STATUS="OK"; HTTPS_MSG="$HTTPS_CODE"
elif [[ "$HTTPS_CODE" == "301" || "$HTTPS_CODE" == "302" ]]; then
    HTTPS_STATUS="WARN"; HTTPS_MSG="$HTTPS_CODE (redirect)"
    [[ "$OVERALL_STATUS" == "OK" ]] && OVERALL_STATUS="WARN"
else
    HTTPS_STATUS="FAIL"; HTTPS_MSG="$HTTPS_CODE"; OVERALL_STATUS="FAIL"
fi

# 4. PHP availability
if php -r 'echo "ok";' &>/dev/null; then
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    PHP_STATUS="OK"; PHP_MSG="PHP $PHP_VER available"
else
    PHP_STATUS="WARN"; PHP_MSG="PHP not found"; [[ "$OVERALL_STATUS" == "OK" ]] && OVERALL_STATUS="WARN"
fi

# 5. CPU usage (1-second sample)
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%id,' 2>/dev/null || echo "0")
CPU_USED=$(echo "100 - ${CPU_IDLE%.*}" | bc 2>/dev/null || echo "0")
CPU_USED=$(( CPU_USED < 0 ? 0 : CPU_USED > 100 ? 100 : CPU_USED ))

# 6. RAM usage
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
RAM_USED=$(free -m  | awk '/^Mem:/{print $3}')
RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))

# 7. Disk usage
DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')

# 8. Uptime
UPTIME_STR=$(uptime -p | sed 's/up //')

# ── TERMINAL DASHBOARD ──────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║         MedCare Server Health Monitor               ║"
echo "  ║         allankibiwott.net — ICT171 Assignment 3     ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}Timestamp:${RESET} $TIMESTAMP"
echo -e "  ${BOLD}Uptime:   ${RESET} $UPTIME_STR"
echo ""

echo -e "${BOLD}  ── Service Checks ─────────────────────────────────────${RESET}"
[[ "$APACHE_STATUS" == "OK"   ]] && ok   "Apache2      $APACHE_MSG" || fail "Apache2      $APACHE_MSG"
[[ "$HTTP_STATUS"   == "OK"   ]] && ok   "HTTP         http://$DOMAIN → $HTTP_MSG"
[[ "$HTTP_STATUS"   == "FAIL" ]] && fail "HTTP         http://$DOMAIN → $HTTP_MSG"
[[ "$HTTPS_STATUS"  == "OK"   ]] && ok   "HTTPS        https://$DOMAIN → $HTTPS_MSG"
[[ "$HTTPS_STATUS"  == "WARN" ]] && warn "HTTPS        https://$DOMAIN → $HTTPS_MSG"
[[ "$HTTPS_STATUS"  == "FAIL" ]] && fail "HTTPS        https://$DOMAIN → $HTTPS_MSG"
[[ "$PHP_STATUS"    == "OK"   ]] && ok   "PHP          $PHP_MSG" || warn "PHP          $PHP_MSG"

echo ""
echo -e "${BOLD}  ── Resource Usage ─────────────────────────────────────${RESET}"
draw_bar "CPU"  "$CPU_USED"  70 90
draw_bar "RAM"  "$RAM_PCT"   75 90
draw_bar "Disk" "$DISK_PCT"  80 95
echo -e "  RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB   Disk: ${DISK_USED} / ${DISK_TOTAL}"

echo ""
# Overall grade
if [[ "$OVERALL_STATUS" == "OK" ]]; then
    echo -e "  ${GREEN}${BOLD}Overall Status: ✔  ALL SYSTEMS HEALTHY${RESET}"
elif [[ "$OVERALL_STATUS" == "WARN" ]]; then
    echo -e "  ${YELLOW}${BOLD}Overall Status: ⚠  WARNINGS DETECTED${RESET}"
else
    echo -e "  ${RED}${BOLD}Overall Status: ✘  FAILURES DETECTED${RESET}"
fi
echo ""

# ── LOG ENTRY ───────────────────────────────────────────────────────────────
LOG_LINE="[$TIMESTAMP] $OVERALL_STATUS | Apache=$APACHE_STATUS | HTTP=$HTTP_STATUS($HTTP_CODE) | HTTPS=$HTTPS_STATUS($HTTPS_CODE) | PHP=$PHP_STATUS | CPU=${CPU_USED}% | RAM=${RAM_PCT}% | Disk=${DISK_PCT}%"
echo "$LOG_LINE" >> "$LOG_FILE"
echo -e "  Logged to: ${CYAN}$LOG_FILE${RESET}"

# ── HTML REPORT (verifiable output at /status.html) ─────────────────────────
html_badge() {
    local status="$1" text="$2"
    local colour
    case "$status" in
        OK)   colour="#22c55e" ;;
        WARN) colour="#f59e0b" ;;
        FAIL) colour="#ef4444" ;;
        *)    colour="#6b7280" ;;
    esac
    echo "<span style='background:${colour};color:#fff;padding:3px 12px;border-radius:20px;font-weight:700;font-size:0.85em;'>${text}</span>"
}

cat > "$HTML_REPORT" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta http-equiv="refresh" content="60">
  <title>MedCare Server Status — allankibiwott.net</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Inter',sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;padding:40px 20px}
    .container{max-width:800px;margin:0 auto}
    h1{font-size:1.9rem;color:#60a5fa;margin-bottom:4px}
    .subtitle{color:#94a3b8;margin-bottom:40px}
    .card{background:#1e293b;border-radius:12px;padding:24px;margin-bottom:20px;border:1px solid #334155}
    .card h2{font-size:1rem;text-transform:uppercase;letter-spacing:.08em;color:#94a3b8;margin-bottom:16px}
    .row{display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid #334155}
    .row:last-child{border-bottom:none}
    .label{color:#94a3b8;font-size:.9rem}
    .bar-wrap{background:#0f172a;border-radius:6px;height:10px;width:200px;overflow:hidden}
    .bar-fill{height:100%;border-radius:6px}
    .ok{background:#22c55e}.warn{background:#f59e0b}.fail{background:#ef4444}
    .overall{text-align:center;padding:24px;font-size:1.3rem;font-weight:700;border-radius:12px}
    .overall.ok{background:#14532d;color:#86efac}.overall.warn{background:#78350f;color:#fde68a}.overall.fail{background:#7f1d1d;color:#fca5a5}
    a{color:#60a5fa;text-decoration:none}.footer{text-align:center;color:#475569;font-size:.8rem;margin-top:30px}
  </style>
</head>
<body>
<div class="container">
  <h1>❤ MedCare Server Status</h1>
  <p class="subtitle">allankibiwott.net &nbsp;|&nbsp; Last updated: $DATE_SHORT &nbsp;|&nbsp; Auto-refreshes every 60s</p>

  <div class="card">
    <h2>Service Checks</h2>
    <div class="row"><span class="label">Apache2 Web Server</span>$(html_badge "$APACHE_STATUS" "$APACHE_MSG")</div>
    <div class="row"><span class="label">HTTP (port 80)</span>$(html_badge "$HTTP_STATUS" "$HTTP_CODE")</div>
    <div class="row"><span class="label">HTTPS / SSL (port 443)</span>$(html_badge "$HTTPS_STATUS" "$HTTPS_CODE")</div>
    <div class="row"><span class="label">PHP</span>$(html_badge "$PHP_STATUS" "$PHP_MSG")</div>
  </div>

  <div class="card">
    <h2>Resource Usage</h2>
    <div class="row">
      <span class="label">CPU Usage</span>
      <div class="bar-wrap"><div class="bar-fill $(( CPU_USED >= 90 )) && echo fail || (( CPU_USED >= 70 )) && echo warn || echo ok" style="width:${CPU_USED}%"></div></div>
      <span>${CPU_USED}%</span>
    </div>
    <div class="row">
      <span class="label">RAM Usage</span>
      <div class="bar-wrap"><div class="bar-fill $(( RAM_PCT >= 90 )) && echo fail || (( RAM_PCT >= 75 )) && echo warn || echo ok" style="width:${RAM_PCT}%"></div></div>
      <span>${RAM_USED}MB / ${RAM_TOTAL}MB</span>
    </div>
    <div class="row">
      <span class="label">Disk Usage (/)</span>
      <div class="bar-wrap"><div class="bar-fill $(( DISK_PCT >= 95 )) && echo fail || (( DISK_PCT >= 80 )) && echo warn || echo ok" style="width:${DISK_PCT}%"></div></div>
      <span>${DISK_USED} / ${DISK_TOTAL}</span>
    </div>
    <div class="row"><span class="label">Server Uptime</span><span>$UPTIME_STR</span></div>
  </div>

  <div class="overall $(echo "$OVERALL_STATUS" | tr '[:upper:]' '[:lower:]')">
    $([ "$OVERALL_STATUS" = "OK" ] && echo "✔ All Systems Healthy" || echo "⚠ $OVERALL_STATUS Detected")
  </div>

  <div class="footer">
    <p>Generated by medcare_monitor.sh &nbsp;|&nbsp; ICT171 Assignment 3 &nbsp;|&nbsp; Allan Kibiwott</p>
    <p><a href="/">← Back to MedCare</a> &nbsp;|&nbsp; <a href="/status.html">Refresh Status</a></p>
  </div>
</div>
</body>
</html>
HTML

echo -e "  HTML report: ${CYAN}https://$DOMAIN/status.html${RESET}"
echo ""
