#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.2.7"
DESCRIPTION="Ensure password quality checking is enforced (enforcing != 0)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_PATH="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"
PAM_FILE="/etc/pam.d/common-password"

# 1. Cek enforcing=0 di pwquality.conf* (Tidak boleh ada)
L_CONF_FAIL=$(grep -PHsi -- '^\h*enforcing\h*=\h*0\b' $CONFIG_PATH 2>/dev/null | tail -n 1)

if [ -n "$L_CONF_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - pwquality.conf*: enforcing is set to 0 (disabled). Offending final config: $L_CONF_FAIL")
else
    a_output+=(" - pwquality.conf*: enforcing is NOT explicitly disabled (0).")
fi

# 2. Cek enforcing=0 di pam.d/common-password (Tidak boleh ada)
L_PAM_FAIL=$(grep -PHsi -- '^\h*password\h+[^#\n\r]+\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?enforcing=0\b' "$PAM_FILE" 2>/dev/null)

if [ -n "$L_PAM_FAIL" ]; then
    RESULT="FAIL"
    a_output2+=(" - $PAM_FILE: pam_pwquality.so argument sets enforcing=0 (disabled). Offending line: $L_PAM_FAIL")
else
    a_output+=(" - $PAM_FILE: pam_pwquality.so argument does NOT disable enforcing.")
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