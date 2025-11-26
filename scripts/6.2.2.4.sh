#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.2.4"
DESCRIPTION="Ensure system warns when audit logs are low on space"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
SL_ACTION="space_left_action"
ASL_ACTION="admin_space_left_action"
VALID_SL_ACTIONS=("email" "exec" "single" "halt")
VALID_ASL_ACTIONS=("single" "halt")

# 1. Cek space_left_action (harus email, exec, single, atau halt)
L_SL_OUTPUT=$(grep -P -- '^\h*space_left_action\h*=\h*(email|exec|single|halt)\b' "$CONFIG_FILE" 2>/dev/null | tail -n 1)
L_SL_VALUE=$(echo "$L_SL_OUTPUT" | awk '{print $NF}' | xargs)

if [[ " ${VALID_SL_ACTIONS[*]} " =~ " ${L_SL_VALUE} " ]]; then
    a_output+=(" - $SL_ACTION is correctly set to $L_SL_VALUE.")
else
    RESULT="FAIL"
    a_output2+=(" - $SL_ACTION is set to $L_SL_VALUE (Expected: email, exec, single, or halt).")
    [ -n "$L_SL_OUTPUT" ] && a_output+=(" - Detected line: $L_SL_OUTPUT")
fi

# 2. Cek admin_space_left_action (harus single atau halt)
L_ASL_OUTPUT=$(grep -P -- '^\h*admin_space_left_action\h*=\h*(single|halt)\b' "$CONFIG_FILE" 2>/dev/null | tail -n 1)
L_ASL_VALUE=$(echo "$L_ASL_OUTPUT" | awk '{print $NF}' | xargs)

if [[ " ${VALID_ASL_ACTIONS[*]} " =~ " ${L_ASL_VALUE} " ]]; then
    a_output+=(" - $ASL_ACTION is correctly set to $L_ASL_VALUE (single or halt).")
else
    RESULT="FAIL"
    a_output2+=(" - $ASL_ACTION is set to $L_ASL_VALUE (Expected: single or halt).")
    [ -n "$L_ASL_OUTPUT" ] && a_output+=(" - Detected line: $L_ASL_OUTPUT")
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