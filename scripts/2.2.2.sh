#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.2.2"
DESCRIPTION="Ensure rsh client is not installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="rsh-client"

# --- FUNGSI AUDIT INSTALASI ---
if dpkg-query -s "$PACKAGE" &> /dev/null; then
    RESULT="FAIL"
    a_output2+=(" - Package '$PACKAGE' is currently installed.")
else
    RESULT="PASS"
    a_output+=(" - Package '$PACKAGE' is NOT installed.")
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