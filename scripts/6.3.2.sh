#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.3.2"
DESCRIPTION="Ensure filesystem integrity is regularly checked (dailyaidecheck)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TIMER_SERVICE="dailyaidecheck"
TIMER_UNIT="${TIMER_SERVICE}.timer"
SERVICE_UNIT="${TIMER_SERVICE}.service"

# 1. Cek status ENABLED timer dan service
L_UNIT_FILES=$(systemctl list-unit-files 2>/dev/null | awk '$1~/^'"$TIMER_SERVICE"'\.(timer|service)$/{print $1 "\t" $2}')

L_TIMER_ENABLED=$(echo "$L_UNIT_FILES" | grep "$TIMER_UNIT" | awk '{print $2}')
L_SERVICE_ENABLED=$(echo "$L_UNIT_FILES" | grep "$SERVICE_UNIT" | awk '{print $2}')

if [ "$L_TIMER_ENABLED" = "enabled" ]; then
    a_output+=(" - $TIMER_UNIT is ENABLED.")
else
    RESULT="FAIL"
    a_output2+=(" - $TIMER_UNIT is NOT enabled (Status: $L_TIMER_ENABLED).")
fi

if [ "$L_SERVICE_ENABLED" = "static" ] || [ "$L_SERVICE_ENABLED" = "enabled" ]; then
    a_output+=(" - $SERVICE_UNIT status is compliant (Status: $L_SERVICE_ENABLED).")
else
    RESULT="FAIL"
    a_output2+=(" - $SERVICE_UNIT status is non-compliant (Status: $L_SERVICE_ENABLED).")
fi

# 2. Cek status ACTIVE timer
L_TIMER_ACTIVE=$(systemctl is-active "$TIMER_UNIT" 2>/dev/null)
if [ "$L_TIMER_ACTIVE" = "active" ]; then
    a_output+=(" - $TIMER_UNIT is currently ACTIVE.")
else
    RESULT="FAIL"
    a_output2+=(" - $TIMER_UNIT is NOT active (Status: $L_TIMER_ACTIVE).")
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