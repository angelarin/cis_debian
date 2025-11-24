#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.1.2"
DESCRIPTION="Ensure minimum password days is configured (PASS_MIN_DAYS > 0)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
LOGIN_DEFS="/etc/login.defs"
SHADOW_FILE="/etc/shadow"
MIN_DAYS=1

# 1. Cek PASS_MIN_DAYS di /etc/login.defs
L_LOGIN_DEFS_OUTPUT=$(grep -Pi -- '^\h*PASS_MIN_DAYS\h+\d+\b' "$LOGIN_DEFS" 2>/dev/null | tail -n 1)
L_DEFS_VALUE=$(echo "$L_LOGIN_DEFS_OUTPUT" | awk '{print $2}')

if [ -z "$L_DEFS_VALUE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $LOGIN_DEFS: PASS_MIN_DAYS setting is MISSING.")
elif [ "$L_DEFS_VALUE" -ge "$MIN_DAYS" ]; then
    a_output+=(" - $LOGIN_DEFS: PASS_MIN_DAYS detected: $L_DEFS_VALUE (is >= $MIN_DAYS).")
else
    RESULT="FAIL"
    a_output2+=(" - $LOGIN_DEFS: PASS_MIN_DAYS ($L_DEFS_VALUE) is set to 0 (disabled).")
fi

# 2. Cek PASS_MIN_DAYS di /etc/shadow (kolom 4: min days)
# Cari pengguna dengan password yang di-hash (kolom 2 dimulai dengan $) yang melanggar batas
L_SHADOW_VIOLATION=$(awk -F: '($2~/^\$.+\$/) {if($4 < 1)print "User: " $1 " PASS_MIN_DAYS: " $4}' "$SHADOW_FILE" 2>/dev/null)

if [ -n "$L_SHADOW_VIOLATION" ]; then
    RESULT="FAIL"
    a_output2+=(" - $SHADOW_FILE: Found users with PASS_MIN_DAYS < 1 (disabled). Violations: ${L_SHADOW_VIOLATION//$'\n'/ | }")
else
    a_output+=(" - $SHADOW_FILE: All users with passwords have PASS_MIN_DAYS >= $MIN_DAYS.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
else
    NOTES+="REVIEW: $LOGIN_DEFS value detected: $L_DEFS_VALUE. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the PASS_MIN_DAYS value against local site policy."
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}