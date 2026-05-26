#!/bin/bash
# healthcheck.sh — ICT171 Assignment 3
# Checks if allankibiwott.net is reachable on HTTP and HTTPS,
# logs a timestamped result to /var/log/site_health.log

DOMAIN="allankibiwott.net"
LOGFILE="/var/log/site_health.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Check HTTP (port 80)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN)

# Check HTTPS (port 443)
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ]; then
  HTTP_STATUS="OK ($HTTP_CODE)"
else
  HTTP_STATUS="FAIL ($HTTP_CODE)"
fi

if [ "$HTTPS_CODE" -eq 200 ]; then
  HTTPS_STATUS="OK ($HTTPS_CODE)"
else
  HTTPS_STATUS="FAIL ($HTTPS_CODE)"
fi

echo "$TIMESTAMP | HTTP: $HTTP_STATUS | HTTPS: $HTTPS_STATUS" >> $LOGFILE
echo "[$TIMESTAMP] HTTP=$HTTP_STATUS  HTTPS=$HTTPS_STATUS"
