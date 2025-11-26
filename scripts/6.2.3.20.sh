#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.20"
DESCRIPTION="Ensure the audit configuration is immutable"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
EXPECTED_RULE="-e 2"

# 1. Cek konfigurasi On Disk (aturan terakhir)
L_OUTPUT_DISK=$(grep -Ph -- '^\h*-e\h+2\b' /etc/audit/rules.d/*.rules 2>/dev/null | tail -1)

if [ "$L_OUTPUT_DISK" = "$EXPECTED_RULE" ]; then
    a_output+=(" - Disk: Immutable rule ($EXPECTED_RULE) found as the last rule in rules.d.")
else
    RESULT="FAIL"
    a_output2+=(" - Disk: Immutable rule ($EXPECTED_RULE) is MISSING or is not the last rule.")
fi

# 2. Cek konfigurasi Loaded (aturan terakhir)
L_OUTPUT_LOADED=$(auditctl -l 2>/dev/null | grep -Ph -- '^\h*-e\h+2\b' | tail -1)

if [ "$L_OUTPUT_LOADED" = "$EXPECTED_RULE" ]; then
    a_output+=(" - Loaded: Immutable rule ($EXPECTED_RULE) found in the running configuration.")
else
    RESULT="FAIL"
    a_output2+=(" - Loaded: Immutable rule ($EXPECTED_RULE) is MISSING from the running configuration.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Immutable configuration rule failed. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}