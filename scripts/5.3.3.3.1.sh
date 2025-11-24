#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.3.1"
DESCRIPTION="Ensure password history remember is configured (remember >= 24)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PAM_FILE="/etc/pam.d/common-password"
MIN_REMEMBER=24

# Regex untuk menemukan baris pam_pwhistory.so dengan argumen remember=<N>
# Mencari remember=[0-23] sebagai kegagalan
L_OUTPUT=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?remember=\d+\b' "$PAM_FILE" 2>/dev/null)
L_VALUE=$(echo "$L_OUTPUT" | grep -oP 'remember=\K\d+' | tail -n 1)

if [ -z "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - pam_pwhistory.so is used but the 'remember' argument is MISSING in $PAM_FILE.")
elif [ "$L_VALUE" -ge "$MIN_REMEMBER" ]; then
    a_output+=(" - pam_pwhistory.so 'remember' is set to $L_VALUE, which is >= $MIN_REMEMBER.")
    a_output+=(" - Detected line: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - pam_pwhistory.so 'remember' is set to $L_VALUE, which is less than the required minimum of $MIN_REMEMBER.")
    a_output+=(" - Detected line: $L_OUTPUT")
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