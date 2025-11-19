#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.7"
DESCRIPTION="Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI AUDIT CLIENT ALIVE SETTINGS ---
L_OUTPUT=$(sshd -T 2>/dev/null | grep -Pi -- '(clientaliveinterval|clientalivecountmax)')

if [ -z "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - ClientAliveInterval and ClientAliveCountMax are NOT set globally.")
else
    # 1. Cek ClientAliveInterval
    L_INTERVAL_LINE=$(echo "$L_OUTPUT" | grep -Pi 'clientaliveinterval')
    L_INTERVAL_VAL=$(echo "$L_INTERVAL_LINE" | awk '{print $2}')
    
    if [ -n "$L_INTERVAL_VAL" ] && [ "$L_INTERVAL_VAL" -gt 0 ]; then
        a_output+=(" - ClientAliveInterval is set and > 0 (Value: $L_INTERVAL_VAL)")
    else
        RESULT="FAIL"
        a_output2+=(" - ClientAliveInterval is missing or set to zero (Value: $L_INTERVAL_VAL).")
    fi

    # 2. Cek ClientAliveCountMax
    L_COUNT_LINE=$(echo "$L_OUTPUT" | grep -Pi 'clientalivecountmax')
    L_COUNT_VAL=$(echo "$L_COUNT_LINE" | awk '{print $2}')

    if [ -n "$L_COUNT_VAL" ] && [ "$L_COUNT_VAL" -gt 0 ]; then
        a_output+=(" - ClientAliveCountMax is set and > 0 (Value: $L_COUNT_VAL)")
    else
        RESULT="FAIL"
        a_output2+=(" - ClientAliveCountMax is missing or set to zero (Value: $L_COUNT_VAL).")
    fi

    a_output+=(" - Detected settings: $L_OUTPUT")
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