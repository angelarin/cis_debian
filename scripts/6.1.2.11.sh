#!/usr/bin/env bash

CHECK_ID="6.1.2.11"
DESCRIPTION="Ensure rsyslog CA certificates are configured"

{
RESULT="PASS" NOTES=""

# Mencari baris konfigurasi DefaultNetstreamDriverCAFile
OUTPUT=$(grep -hPsi -- 'DefaultNetstreamDriverCAFile' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)

if [ -n "$OUTPUT" ]; then
    NOTES="PASS: rsyslog CA certificate configuration found. NOTE: Please manually verify the certificate validity and permissions."
else
    RESULT="FAIL"
    NOTES="FAIL: rsyslog CA certificate (DefaultNetstreamDriverCAFile) configuration is missing."
fi

echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}