#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.1.1"
DESCRIPTION="Ensure password failed attempts lockout is configured (deny <= 5)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MAX_DENY=5
FAILLOCK_CONF="/etc/security/faillock.conf"
PAM_AUTH="/etc/pam.d/common-auth"

# 1. Cek deny di /etc/security/faillock.conf (deny <= 5)
L_CONF_PASS=$(grep -Pi -- '^\h*deny\h*=\h*[1-'"$MAX_DENY"']\b' "$FAILLOCK_CONF" 2>/dev/null)
L_CONF_FAIL=$(grep -Pi -- '^\h*deny\h*=\h*([6-9]|[1-9][0-9]+)\b' "$FAILLOCK_CONF" 2>/dev/null)

if [ -n "$L_CONF_PASS" ]; then
    a_output+=(" - $FAILLOCK_CONF: Deny limit set correctly (<= $MAX_DENY). Detected: $L_CONF_PASS")
elif [ -n "$L_CONF_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $FAILLOCK_CONF: Deny limit set > $MAX_DENY. Offending: $L_CONF_FAIL")
else
    a_output+=(" - $FAILLOCK_CONF: Deny setting not found. Assuming default or config elsewhere.")
fi

# 2. Cek deny di common-auth (mencari deny > 5)
L_PAM_FAIL=$(grep -Pi -- '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?deny\h*=\h*(0|[6-9]|[1-9][0-9]+)\b' "$PAM_AUTH" 2>/dev/null)

if [ -n "$L_PAM_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $PAM_AUTH: pam_faillock.so deny argument set too high (> $MAX_DENY or 0). Offending: $L_PAM_FAIL")
else
    a_output+=(" - $PAM_AUTH: pam_faillock.so deny argument is safe (not set to > $MAX_DENY or 0).")
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