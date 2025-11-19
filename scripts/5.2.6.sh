#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.6"
DESCRIPTION="Ensure sudo authentication timeout is configured correctly (<= 15 minutes)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MAX_TIMEOUT=15 # Minutes
MAX_TIMEOUT_SEC=900 # Seconds

# 1. Cek konfigurasi timestamp_timeout di sudoers*
L_CONFIGURED_TIMEOUT=$(grep -roP "timestamp_timeout=\K-?[0-9]*" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sort -n | tail -n 1)

if [ -n "$L_CONFIGURED_TIMEOUT" ]; then
    L_VALUE=$L_CONFIGURED_TIMEOUT
    a_output+=(" - Configured timestamp_timeout value found: $L_VALUE minutes.")
    
    if [ "$L_VALUE" -eq -1 ]; then
        RESULT="FAIL"
        a_output2+=(" - timestamp_timeout is set to -1 (disabled/infinite timeout).")
    elif [ "$L_VALUE" -gt "$MAX_TIMEOUT" ]; then
        RESULT="FAIL"
        a_output2+=(" - timestamp_timeout is set to $L_VALUE minutes (Greater than $MAX_TIMEOUT minutes).")
    else
        a_output+=(" - timestamp_timeout is set to $L_VALUE minutes (<= $MAX_TIMEOUT minutes).")
    fi
else
    # 2. Jika tidak dikonfigurasi, cek default system sudo -V
    L_DEFAULT_TIMEOUT_RAW=$(sudo -V 2>/dev/null | grep "Authentication timestamp timeout:")
    L_DEFAULT_TIMEOUT_SEC=$(echo "$L_DEFAULT_TIMEOUT_RAW" | grep -oP '\d+' | head -n 1) # Biasanya 900
    
    if [ "$L_DEFAULT_TIMEOUT_SEC" -le "$MAX_TIMEOUT_SEC" ]; then
        a_output+=(" - timestamp_timeout is NOT explicitly set. Default timeout is $L_DEFAULT_TIMEOUT_SEC seconds (<= $MAX_TIMEOUT_SEC seconds).")
    else
        RESULT="FAIL"
        a_output2+=(" - timestamp_timeout is NOT explicitly set. Default timeout ($L_DEFAULT_TIMEOUT_SEC s) is greater than $MAX_TIMEOUT_SEC seconds.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set/Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}