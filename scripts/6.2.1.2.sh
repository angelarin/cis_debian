#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.1.2"
DESCRIPTION="Ensure auditd service is enabled and active"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICE="auditd"
EXPECTED_ENABLED="enabled"
EXPECTED_ACTIVE="active"

# 1. Cek status ENABLED
L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null | grep '^enabled')
if [ "$L_ENABLED" = "$EXPECTED_ENABLED" ]; then
    a_output+=(" - Service is ENABLED for boot (Status: $L_ENABLED).")
else
    RESULT="FAIL"
    a_output2+=(" - Service ENABLED status is non-compliant (Status: $L_ENABLED, Expected: $EXPECTED_ENABLED).")
fi

# 2. Cek status ACTIVE
L_ACTIVE=$(systemctl is-active "$SERVICE" 2>/dev/null | grep '^active')
if [ "$L_ACTIVE" = "$EXPECTED_ACTIVE" ]; then
    a_output+=(" - Service is currently ACTIVE (Status: $L_ACTIVE).")
else
    RESULT="FAIL"
    a_output2+=(" - Service ACTIVE status is non-compliant (Status: $L_ACTIVE, Expected: $EXPECTED_ACTIVE).")
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