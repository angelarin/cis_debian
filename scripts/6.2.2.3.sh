#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.2.3"
DESCRIPTION="Ensure system is disabled when audit logs are full"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
DISK_FULL_ACTION="disk_full_action"
DISK_ERROR_ACTION="disk_error_action"
VALID_FULL_ACTIONS=("halt" "single")
VALID_ERROR_ACTIONS=("syslog" "single" "halt")

# 1. Cek disk_full_action (harus halt atau single)
L_FULL_OUTPUT=$(grep -Pi -- '^\h*disk_full_action\h*=\h*(halt|single)\b' "$CONFIG_FILE" 2>/dev/null | tail -n 1)
L_FULL_VALUE=$(echo "$L_FULL_OUTPUT" | awk '{print $NF}' | xargs)

if [[ " ${VALID_FULL_ACTIONS[*]} " =~ " ${L_FULL_VALUE} " ]]; then
    a_output+=(" - $DISK_FULL_ACTION is correctly set to $L_FULL_VALUE (halt or single).")
else
    RESULT="FAIL"
    a_output2+=(" - $DISK_FULL_ACTION is set to $L_FULL_VALUE (Expected: halt or single).")
    [ -n "$L_FULL_OUTPUT" ] && a_output+=(" - Detected line: $L_FULL_OUTPUT")
fi

# 2. Cek disk_error_action (harus syslog, single, atau halt)
L_ERROR_OUTPUT=$(grep -Pi -- '^\h*disk_error_action\h*=\h*(syslog|single|halt)\b' "$CONFIG_FILE" 2>/dev/null | tail -n 1)
L_ERROR_VALUE=$(echo "$L_ERROR_OUTPUT" | awk '{print $NF}' | xargs)

if [[ " ${VALID_ERROR_ACTIONS[*]} " =~ " ${L_ERROR_VALUE} " ]]; then
    a_output+=(" - $DISK_ERROR_ACTION is correctly set to $L_ERROR_VALUE (syslog, single, or halt).")
else
    RESULT="FAIL"
    a_output2+=(" - $DISK_ERROR_ACTION is set to $L_ERROR_VALUE (Expected: syslog, single, or halt).")
    [ -n "$L_ERROR_OUTPUT" ] && a_output+=(" - Detected line: $L_ERROR_OUTPUT")
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