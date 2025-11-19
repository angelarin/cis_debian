#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.4.1.1"
DESCRIPTION="Ensure cron daemon is enabled and active"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICE_PATTERN="^crond?\.service"

# 1. Cek status ENABLED
L_ENABLED=$(systemctl list-unit-files 2>/dev/null | awk '$1~/'"$SERVICE_PATTERN"'/{print $2}')

if [ "$L_ENABLED" = "enabled" ]; then
    a_output+=(" - Cron service is ENABLED for boot (Status: $L_ENABLED).")
else
    a_output2+=(" - Cron service is NOT enabled (Status: $L_ENABLED).")
    RESULT="FAIL"
fi

# 2. Cek status ACTIVE
L_ACTIVE=$(systemctl list-units 2>/dev/null | awk '$1~/'"$SERVICE_PATTERN"'/{print $3}')
L_SUB=$(systemctl list-units 2>/dev/null | awk '$1~/'"$SERVICE_PATTERN"'/{print $4}')

if [ "$L_ACTIVE" = "active" ]; then
    a_output+=(" - Cron service is currently ACTIVE (Status: $L_ACTIVE/$L_SUB).")
else
    a_output2+=(" - Cron service is NOT active (Status: $L_ACTIVE/$L_SUB).")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}