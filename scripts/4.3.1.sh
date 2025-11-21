#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.1"
DESCRIPTION="Ensure nftables is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="nftables"

# --- FUNGSI AUDIT INSTALASI ---
if dpkg-query -s "$PACKAGE" &> /dev/null; then
    RESULT="PASS"
    a_output+=(" - Package '$PACKAGE' is installed.")
else
    RESULT="FAIL"
    a_output2+=(" - Package '$PACKAGE' is NOT installed.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}