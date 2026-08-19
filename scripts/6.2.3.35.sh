#!/usr/bin/env bash

CHECK_ID="6.2.3.35"
DESCRIPTION="Ensure the audit configuration is loaded regardless of errors"

{
RESULT="PASS" NOTES=""

# Mengekstrak flag '-c' dari file .rules
CONF_FLAG=$(grep -Ph -- '^\h*-c\b' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)

# Membersihkan spasi pada hasil ekstraksi
CONF_FLAG=$(echo "$CONF_FLAG" | xargs)

if [ "$CONF_FLAG" = "-c" ]; then
    NOTES="PASS: Audit configuration is set to load regardless of errors (-c flag found)."
else
    RESULT="FAIL"
    NOTES="FAIL: The '-c' flag is missing in /etc/audit/rules.d/*.rules."
fi

echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}