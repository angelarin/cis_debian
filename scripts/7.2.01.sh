#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.1"
DESCRIPTION="Ensure accounts in /etc/passwd use shadowed passwords"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PASSWD_FILE="/etc/passwd"

# --- FUNGSI AUDIT SHADOWED PASSWORDS ---
# Mencari akun di /etc/passwd yang kolom $2-nya BUKAN 'x'
L_OUTPUT=$(awk -F: '($2 != "x" ) { print "User: \"" $1 "\" is not set to shadowed passwords "}' "$PASSWD_FILE" 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - All accounts in $PASSWD_FILE correctly use shadowed passwords ('x').")
else
    RESULT="FAIL"
    a_output2+=(" - Detected user(s) with unshadowed passwords in $PASSWD_FILE. Violations: ${L_OUTPUT//$'\n'/ | }")
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