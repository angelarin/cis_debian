#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.2.8"
DESCRIPTION="Ensure password quality is enforced for the root user"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SETTING="enforce_for_root"
CONFIG_PATH="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"

# 1. Cek enforce_for_root di pwquality.conf*
L_OUTPUT=$(grep -Psi -- "^\h*$SETTING\b" $CONFIG_PATH 2>/dev/null | tail -n 1)

if [ -n "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=(" - $SETTING is enabled. Final config line: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $SETTING is NOT explicitly enabled in pwquality configuration files.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}