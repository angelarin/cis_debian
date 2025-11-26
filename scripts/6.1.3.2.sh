#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.2"
DESCRIPTION="Ensure rsyslog service is enabled and active"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICE="rsyslog.service"

# 1. Cek status ENABLED
L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null)
if [ "$L_ENABLED" = "enabled" ]; then
    a_output+=(" - Service is ENABLED for boot (Status: $L_ENABLED).")
else
    RESULT="FAIL"
    a_output2+=(" - Service ENABLED status is non-compliant (Status: $L_ENABLED, Expected: enabled).")
fi

# 2. Cek status ACTIVE
L_ACTIVE=$(systemctl is-active "$SERVICE" 2>/dev/null)
if [ "$L_ACTIVE" = "active" ]; then
    a_output+=(" - Service is currently ACTIVE (Status: $L_ACTIVE).")
else
    RESULT="FAIL"
    a_output2+=(" - Service ACTIVE status is non-compliant (Status: $L_ACTIVE, Expected: active).")
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