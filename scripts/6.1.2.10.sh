#!/usr/bin/env bash

CHECK_ID="6.1.2.10"
DESCRIPTION="Ensure rsyslog forwarding uses gtls"

{
RESULT="PASS" NOTES=""

# Menggunakan 2>/dev/null agar tidak error jika folder /etc/rsyslog.d/ kosong
# Opsi -h digunakan untuk menyembunyikan nama file pada output grep (opsional)
OUTPUT=$(grep -hPsi -- '^\h*StreamDriver="gtls"' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)

if [ -n "$OUTPUT" ]; then
    NOTES="PASS: rsyslog forwarding uses gtls (StreamDriver=\"gtls\" configuration found)."
else
    RESULT="FAIL"
    NOTES="FAIL: rsyslog forwarding is not configured to use gtls (StreamDriver=\"gtls\" not found)."
fi

echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}