#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.2.5"
DESCRIPTION="Ensure password maximum sequential characters is configured (maxsequence <= 3 and != 0)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MAX_SEQUENCE=3
CONFIG_PATH="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"
PAM_FILE="/etc/pam.d/common-password"

# 1. Cek maxsequence di pwquality.conf* (maxsequence >= 1 dan <= 3)
L_CONF_PASS=$(grep -Psi -- '^\h*maxsequence\h*=\h*[1-'"$MAX_SEQUENCE"']\b' $CONFIG_PATH 2>/dev/null | tail -n 1)
L_CONF_FAIL=$(grep -Psi -- '^\h*maxsequence\h*=\h*(0|[4-9]|[1-9][0-9]+)\b' $CONFIG_PATH 2>/dev/null | tail -n 1)
L_FINAL_CONF=$(grep -Psi -- '^\h*maxsequence\h*=\h*([0-9]|[1-9][0-9]+)\b' $CONFIG_PATH 2>/dev/null | tail -n 1)

if [ -n "$L_CONF_PASS" ]; then
    a_output+=(" - pwquality.conf*: maxsequence set correctly (1 to $MAX_SEQUENCE). Final config line: $L_FINAL_CONF")
elif [ -n "$L_CONF_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - pwquality.conf*: maxsequence set too high (> $MAX_SEQUENCE) or disabled (0). Offending final config: $L_FINAL_CONF")
else
    a_output2+=(" - pwquality.conf*: maxsequence setting is MISSING or relies on system defaults.")
    RESULT="FAIL"
fi

# 2. Cek maxsequence di pam.d/common-password (mencari override maxsequence > 3 atau = 0)
L_PAM_FAIL=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?maxsequence\h*=\h*(0|[4-9]|[1-9][0-9]+)\b' "$PAM_FILE" 2>/dev/null)

if [ -n "$L_PAM_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $PAM_FILE: pam_pwquality.so argument overrides maxsequence to a non-compliant value. Offending line: $L_PAM_FAIL")
else
    a_output+=(" - $PAM_FILE: pam_pwquality.so argument does NOT override maxsequence to a non-compliant value.")
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