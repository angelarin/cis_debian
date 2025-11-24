#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.2.2"
DESCRIPTION="Ensure minimum password length is configured (minlen >= 14)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
MIN_LENGTH=14
CONFIG_PATH="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"
PAM_FILES="/etc/pam.d/system-auth /etc/pam.d/common-password"

# 1. Cek minlen di pwquality.conf* (minlen >= 14)
L_CONF_PASS=$(grep -Psi -- '^\h*minlen\h*=\h*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' $CONFIG_PATH 2>/dev/null | tail -n 1)
L_CONF_FAIL=$(grep -Psi -- '^\h*minlen\h*=\h*([0-9]|1[0-3])\b' $CONFIG_PATH 2>/dev/null | tail -n 1)
L_FINAL_CONF=$(grep -Psi -- '^\h*minlen\h*=\h*([0-9]|[1-9][0-9]+)\b' $CONFIG_PATH 2>/dev/null | tail -n 1)

if [ -n "$L_CONF_PASS" ]; then
    a_output+=(" - pwquality.conf*: minlen set correctly (>= $MIN_LENGTH). Final config line: $L_FINAL_CONF")
elif [ -n "$L_CONF_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - pwquality.conf*: minlen set too low (< $MIN_LENGTH). Offending final config: $L_FINAL_CONF")
else
    a_output2+=(" - pwquality.conf*: minlen setting is MISSING or relies on system defaults (which may be < $MIN_LENGTH).")
    RESULT="FAIL"
fi

# 2. Cek minlen di pam.d/* (mencari override minlen < 14)
L_PAM_FAIL=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?minlen\h*=\h*([0-9]|1[0-3])\b' $PAM_FILES 2>/dev/null)

if [ -n "$L_PAM_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - pam.d/*: pam_pwquality.so argument overrides minlen to value < $MIN_LENGTH. Offending lines: ${L_PAM_FAIL//$'\n'/ | }")
else
    a_output+=(" - pam.d/*: pam_pwquality.so argument does NOT override minlen to a low value.")
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