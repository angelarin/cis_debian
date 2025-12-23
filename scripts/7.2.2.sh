#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.2"
DESCRIPTION="Ensure /etc/shadow password fields are not empty"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SHADOW_FILE="/etc/shadow"

# --- FUNGSI AUDIT EMPTY PASSWORDS ---
# Mencari akun di /etc/shadow yang kolom $2-nya kosong (non-hashed)
L_OUTPUT=$(awk -F: '($2 == "" ) { print $1 " does not have a password "}' "$SHADOW_FILE" 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - All accounts in $SHADOW_FILE have a password field set (not empty).")
else
    RESULT="FAIL"
    a_output2+=(" - Detected user(s) with empty password fields in $SHADOW_FILE. Violations: ${L_OUTPUT//$'\n'/ | }")
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