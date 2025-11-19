#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.2.4"
DESCRIPTION="Ensure pam_pwhistory module is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="FAIL" NOTES=""
TARGET_MODULE="pam_pwhistory\.so"
TARGET_FILE="/etc/pam.d/common-password"

# --- FUNGSI AUDIT PAM PWHISTORY ---
L_OUTPUT=$(grep -P -- "\b$TARGET_MODULE\b" "$TARGET_FILE" 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=(" - $TARGET_MODULE is enabled in $TARGET_FILE.")
    a_output+=(" - Detected line: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - $TARGET_MODULE is NOT enabled in $TARGET_FILE.")
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