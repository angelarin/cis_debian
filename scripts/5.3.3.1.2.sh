#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.1.2"
DESCRIPTION="Ensure password unlock time is configured (0 or >= 900 seconds)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MIN_UNLOCK_TIME=900
FAILLOCK_CONF="/etc/security/faillock.conf"
PAM_AUTH="/etc/pam.d/common-auth"

# 1. Cek unlock_time di /etc/security/faillock.conf (mencari 0 atau >= 900)
L_CONF_PASS=$(grep -Pi -- '^\h*unlock_time\h*=\h*(0|9[0-9][0-9]|[1-9][0-9]{3,})\b' "$FAILLOCK_CONF" 2>/dev/null)
L_CONF_FAIL=$(grep -Pi -- '^\h*unlock_time\h*=\h*([1-9]|[1-9][0-9]|[1-8][0-9][0-9])\b' "$FAILLOCK_CONF" 2>/dev/null)

if [ -n "$L_CONF_PASS" ]; then
    a_output+=(" - $FAILLOCK_CONF: Unlock time set correctly (0 or >= $MIN_UNLOCK_TIME). Detected: $L_CONF_PASS")
elif [ -n "$L_CONF_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $FAILLOCK_CONF: Unlock time set too low (between 1 and 899). Offending: $L_CONF_FAIL")
else
    RESULT="FAIL"
    a_output+=(" - $FAILLOCK_CONF: Unlock time setting not found. Assuming default or config elsewhere.")
fi

# 2. Cek unlock_time di common-auth (mencari 1-899)
L_PAM_FAIL=$(grep -Pi -- '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?unlock_time\h*=\h*([1-9]|[1-9][0-9]|[1-8][0-9][0-9])\b' "$PAM_AUTH" 2>/dev/null)

if [ -n "$L_PAM_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $PAM_AUTH: pam_faillock.so unlock_time argument set too low (1-899). Offending: $L_PAM_FAIL")
else
    a_output+=(" - $PAM_AUTH: pam_faillock.so unlock_time argument is safe (not set to 1-899).")
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