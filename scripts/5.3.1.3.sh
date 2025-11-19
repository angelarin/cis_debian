#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.1.3"
DESCRIPTION="Ensure libpam-pwquality is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="libpam-pwquality"

# --- FUNGSI AUDIT INSTALASI ---
L_OUTPUT=$(dpkg-query -s "$PACKAGE" 2>/dev/null | grep -P -- '^(Status|Version)\b')

if echo "$L_OUTPUT" | grep -q 'install ok installed'; then
    L_VERSION=$(echo "$L_OUTPUT" | grep 'Version:' | awk '{print $2}')
    RESULT="PASS"
    a_output+=(" - Package '$PACKAGE' is installed and active.")
    a_output+=(" - Version detected: $L_VERSION.")
else
    RESULT="FAIL"
    a_output2+=(" - Package '$PACKAGE' is NOT installed or not active.")
    [ -n "$L_OUTPUT" ] && a_output2+=(" - Status output: $L_OUTPUT")
    a_output2+=(" - Remediation: apt install $PACKAGE")
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