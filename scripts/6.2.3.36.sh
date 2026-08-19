#!/usr/bin/env bash

CHECK_ID="6.2.3.36"
DESCRIPTION="Ensure the audit configuration is immutable"

{
RESULT="PASS" NOTES=""

# Mengekstrak flag '-e 2' dari file .rules
IMMUTABLE_FLAG=$(grep -Ph -- '^\h*-e\h+2\b' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)

# Membersihkan spasi untuk proses perbandingan (menghasilkan '-e 2' tanpa spasi ekstra)
IMMUTABLE_FLAG=$(echo "$IMMUTABLE_FLAG" | tr -s ' ' | xargs)

if [ "$IMMUTABLE_FLAG" = "-e 2" ]; then
    NOTES="PASS: Audit configuration is immutable (-e 2 flag found)."
else
    RESULT="FAIL"
    NOTES="FAIL: The '-e 2' flag is missing in /etc/audit/rules.d/*.rules."
fi

echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}