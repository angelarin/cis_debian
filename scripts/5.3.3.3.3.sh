#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.3.3"
DESCRIPTION="Ensure pam_pwhistory includes use_authtok"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PAM_FILE="/etc/pam.d/common-password"
TARGET_ARGUMENT="use_authtok"

# Regex untuk mencari baris pam_pwhistory.so yang mengandung use_authtok
L_OUTPUT=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?use_authtok\b' "$PAM_FILE" 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    a_output+=(" - pam_pwhistory.so includes the '$TARGET_ARGUMENT' argument.")
    a_output+=(" - Detected line: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - pam_pwhistory.so does NOT include the '$TARGET_ARGUMENT' argument in $PAM_FILE.")
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