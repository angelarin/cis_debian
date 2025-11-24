#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.1.1"
DESCRIPTION="Ensure password expiration is configured (PASS_MAX_DAYS <= 365)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
LOGIN_DEFS="/etc/login.defs"
SHADOW_FILE="/etc/shadow"
MAX_DAYS=365
MIN_DAYS=1

# 1. Cek PASS_MAX_DAYS di /etc/login.defs
L_LOGIN_DEFS_OUTPUT=$(grep -Pi -- '^\h*PASS_MAX_DAYS\h+\d+\b' "$LOGIN_DEFS" 2>/dev/null | tail -n 1)
L_DEFS_VALUE=$(echo "$L_LOGIN_DEFS_OUTPUT" | awk '{print $2}')

if [ -z "$L_DEFS_VALUE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $LOGIN_DEFS: PASS_MAX_DAYS setting is MISSING.")
else
    a_output+=(" - $LOGIN_DEFS: PASS_MAX_DAYS detected: $L_DEFS_VALUE.")
    
    if [ "$L_DEFS_VALUE" -gt "$MAX_DAYS" ]; then
        RESULT="FAIL"
        a_output2+=(" - $LOGIN_DEFS: PASS_MAX_DAYS ($L_DEFS_VALUE) is greater than the recommended maximum of $MAX_DAYS.")
    fi
    if [ "$L_DEFS_VALUE" -lt "$MIN_DAYS" ]; then
        RESULT="FAIL"
        a_output2+=(" - $LOGIN_DEFS: PASS_MAX_DAYS ($L_DEFS_VALUE) is less than the required minimum of $MIN_DAYS.")
    fi
fi

# 2. Cek PASS_MAX_DAYS di /etc/shadow (kolom 5: max days)
# Cari pengguna dengan password yang di-hash (kolom 2 dimulai dengan $) yang melanggar batas
L_SHADOW_VIOLATION=$(awk -F: '($2~/^\$.+\$/) {if($5 > 365 || $5 < 1)print "User: " $1 " PASS_MAX_DAYS: " $5}' "$SHADOW_FILE" 2>/dev/null)

if [ -n "$L_SHADOW_VIOLATION" ]; then
    RESULT="FAIL"
    a_output2+=(" - $SHADOW_FILE: Found users with non-compliant PASS_MAX_DAYS (outside 1-$MAX_DAYS range). Violations: ${L_SHADOW_VIOLATION//$'\n'/ | }")
else
    a_output+=(" - $SHADOW_FILE: All users with passwords have compliant PASS_MAX_DAYS (1-$MAX_DAYS).")
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