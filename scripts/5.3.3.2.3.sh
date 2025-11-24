#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.2.3"
DESCRIPTION="Ensure password complexity is configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
CONFIG_PATH="/etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf"
PAM_FILE="/etc/pam.d/common-password"

# 1. Kumpulkan semua pengaturan kompleksitas dari pwquality.conf*
L_CONF_SETTINGS=$(grep -Psi -- '^\h*(minclass|[dulo]credit)\b' $CONFIG_PATH 2>/dev/null)
L_CREDIT_VIOLATION=0

if [ -n "$L_CONF_SETTINGS" ]; then
    a_output+=(" - pwquality.conf* complexity settings detected: ${L_CONF_SETTINGS//$'\n'/ | }")
    
    # Cek bahwa [dulo]credit tidak diatur ke nilai positif (yang berarti karakter tersebut harus diulang)
    # Target: Mencari credit > 0. Negatif (wajib) atau 0 (opsional) adalah OK.
    for credit_type in dcredit ucredit lcredit ocredit; do
        L_POSITIVE_CREDIT=$(echo "$L_CONF_SETTINGS" | grep -Pi -- "^\h*$credit_type\h*=\h*[1-9]\b" | tail -n 1)
        if [ -n "$L_POSITIVE_CREDIT" ]; then
            a_output2+=(" - WARNING: '$credit_type' is set to a POSITIVE value, forcing repetition of that character class. Review required: $L_POSITIVE_CREDIT")
            L_CREDIT_VIOLATION=1
        fi
    done
else
    a_output2+=(" - No complexity settings (minclass, dcredit, etc.) found in pwquality.conf*.")
    RESULT="FAIL"
fi

# 2. Cek override di pam.d/common-password
L_PAM_OVERRIDE=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?(minclass=\d*|[dulo]credit=-?\d*)\b' "$PAM_FILE" 2>/dev/null)

if [ -n "$L_PAM_OVERRIDE" ]; then
    a_output2+=(" - WARNING: Complexity settings are being OVERRIDDEN in $PAM_FILE. Recommended settings should be in pwquality.conf*. Offending line: $L_PAM_OVERRIDE")
    # Jika ada override, audit tidak bisa PASS/FAIL secara otomatis
    [ "$RESULT" != "FAIL" ] && RESULT="REVIEW" 
else
    a_output+=(" - No complexity settings override found in $PAM_FILE.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Critical complexity settings missing or incorrectly configured. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
else
    NOTES+="INFO: Complexity settings collected. ${a_output[*]}"
    [ "${#a_output2[@]}" -gt 0 ] && NOTES+=" | WARNINGS: ${a_output2[*]}"
    NOTES+=" | Action: REVIEW the minclass/[dulo]credit values against local site policy."
    RESULT="REVIEW"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}