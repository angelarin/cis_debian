#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.2.1"
DESCRIPTION="Ensure password number of changed characters is configured (difok >= 2)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MIN_DIFOK=2
CONFIG_PATH="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"
PAM_FILE="/etc/pam.d/common-password"

# 1. Cek difok di pwquality.conf* (difok >= 2)
L_CONF_PASS=$(grep -Psi -- '^\h*difok\h*=\h*([2-9]|[1-9][0-9]+)\b' $CONFIG_PATH 2>/dev/null | tail -n 1)
L_CONF_FAIL=$(grep -Psi -- '^\h*difok\h*=\h*([0-1])\b' $CONFIG_PATH 2>/dev/null | tail -n 1)
L_FINAL_CONF=$(grep -Psi -- '^\h*difok\h*=\h*([0-9]|[1-9][0-9]+)\b' $CONFIG_PATH 2>/dev/null | tail -n 1)

if [ -n "$L_CONF_PASS" ]; then
    a_output+=(" - pwquality.conf*: difok set correctly (>= $MIN_DIFOK). Final config line: $L_FINAL_CONF")
elif [ -n "$L_CONF_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - pwquality.conf*: difok set too low (< $MIN_DIFOK). Offending final config: $L_FINAL_CONF")
else
    a_output2+=(" - pwquality.conf*: difok setting is MISSING or relies on system defaults (which may be < $MIN_DIFOK).")
    RESULT="FAIL"
fi

# 2. Cek difok di pam.d/common-password (mencari override difok < 2)
L_PAM_FAIL=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?difok\h*=\h*([0-1])\b' "$PAM_FILE" 2>/dev/null)

if [ -n "$L_PAM_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $PAM_FILE: pam_pwquality.so argument overrides difok to value < $MIN_DIFOK. Offending line: $L_PAM_FAIL")
else
    a_output+=(" - $PAM_FILE: pam_pwquality.so argument does NOT override difok to a low value.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES+="INFO: Value must be verified against site policy. "

if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}