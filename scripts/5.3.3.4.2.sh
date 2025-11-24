#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.4.2"
DESCRIPTION="Ensure pam_unix does not include remember"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES="/etc/pam.d/common-{password,auth,account,session,session-noninteractive}"
UNEXPECTED_ARGUMENT="remember=\d+"

# --- FUNGSI AUDIT REMEMBER ---
L_OUTPUT=$(grep -PHs -- '^\h*[^#\n\r]+\h+pam_unix\.so\h+([^#\n\r]+\h+)?remember=\d+\b' $TARGET_FILES 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Detected '$UNEXPECTED_ARGUMENT' argument on pam_unix.so line(s). This function should be handled by pam_pwhistory. Offending lines: ${L_OUTPUT//$'\n'/ | }")
else
    a_output+=(" - No instances of '$UNEXPECTED_ARGUMENT' found on pam_unix.so lines.")
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