#!/usr-bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.1.3"
DESCRIPTION="Ensure password failed attempts lockout includes root account"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
FAILLOCK_CONF="/etc/security/faillock.conf"
PAM_AUTH="/etc/pam.d/common-auth"
MIN_ROOT_UNLOCK=60

# 1. Cek apakah even_deny_root atau root_unlock_time ada di faillock.conf
L_CONF_ROOT=$(grep -Pi -- '^\h*(even_deny_root|root_unlock_time\h*=\h*\d+)\b' "$FAILLOCK_CONF" 2>/dev/null)

if [ -n "$L_CONF_ROOT" ]; then
    a_output+=(" - $FAILLOCK_CONF: Root lockout mechanism (even_deny_root or root_unlock_time) is enabled. Detected: $L_CONF_ROOT")

    # 2. Cek apakah root_unlock_time di faillock.conf terlalu rendah (1-59)
    L_CONF_ROOT_FAIL=$(grep -Pi -- '^\h*root_unlock_time\h*=\h*([1-9]|[1-5][0-9])\b' "$FAILLOCK_CONF" 2>/dev/null)
    if [ -n "$L_CONF_ROOT_FAIL" ]; then
        RESULT="FAIL"
        a_output2+=(" - $FAILLOCK_CONF: root_unlock_time set too low (< $MIN_ROOT_UNLOCK). Offending: $L_CONF_ROOT_FAIL")
    else
        a_output+=(" - $FAILLOCK_CONF: root_unlock_time, if set, is >= $MIN_ROOT_UNLOCK.")
    fi
else
    RESULT="FAIL"
    a_output2+=(" - $FAILLOCK_CONF: Root lockout mechanism (even_deny_root or root_unlock_time) is NOT enabled.")
fi

# 3. Cek apakah root_unlock_time di common-auth terlalu rendah (1-59)
L_PAM_ROOT_FAIL=$(grep -Pi -- '^\h*auth\h+([^#\n\r]+\h+)pam_faillock\.so\h+([^#\n\r]+\h+)?root_unlock_time\h*=\h*([1-9]|[1-5][0-9])\b' "$PAM_AUTH" 2>/dev/null)

if [ -n "$L_PAM_ROOT_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $PAM_AUTH: pam_faillock.so root_unlock_time argument set too low (< $MIN_ROOT_UNLOCK). Offending: $L_PAM_ROOT_FAIL")
else
    a_output+=(" - $PAM_AUTH: pam_faillock.so root_unlock_time argument, if set, is safe.")
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