#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.1.3"
DESCRIPTION="Ensure password expiration warning days is configured (PASS_WARN_AGE >= 7)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
LOGIN_DEFS="/etc/login.defs"
SHADOW_FILE="/etc/shadow"
MIN_WARN_AGE=7

# 1. Cek PASS_WARN_AGE di /etc/login.defs
L_LOGIN_DEFS_OUTPUT=$(grep -Pi -- '^\h*PASS_WARN_AGE\h+\d+\b' "$LOGIN_DEFS" 2>/dev/null | tail -n 1)
L_DEFS_VALUE=$(echo "$L_LOGIN_DEFS_OUTPUT" | awk '{print $2}')

if [ -z "$L_DEFS_VALUE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $LOGIN_DEFS: PASS_WARN_AGE setting is MISSING.")
else
    a_output+=(" - $LOGIN_DEFS: PASS_WARN_AGE detected: $L_DEFS_VALUE.")
    
    if [ "$L_DEFS_VALUE" -lt "$MIN_WARN_AGE" ]; then
        RESULT="FAIL"
        a_output2+=(" - $LOGIN_DEFS: PASS_WARN_AGE ($L_DEFS_VALUE) is less than the required minimum of $MIN_WARN_AGE.")
    fi
fi

# 2. Cek PASS_WARN_AGE di /etc/shadow (kolom 6: warn age)
# Cari pengguna dengan password yang di-hash (kolom 2 dimulai dengan $) yang melanggar batas
L_SHADOW_VIOLATION=$(awk -F: '($2~/^\$.+\$/) {if($6 < 7)print "User: " $1 " PASS_WARN_AGE: " $6}' "$SHADOW_FILE" 2>/dev/null)

if [ -n "$L_SHADOW_VIOLATION" ]; then
    RESULT="FAIL"
    a_output2+=(" - $SHADOW_FILE: Found users with PASS_WARN_AGE < $MIN_WARN_AGE. Violations: ${L_SHADOW_VIOLATION//$'\n'/ | }")
else
    a_output+=(" - $SHADOW_FILE: All users with passwords have PASS_WARN_AGE >= $MIN_WARN_AGE.")
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