#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.1.2"
DESCRIPTION="Ensure libpam-modules is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="libpam-modules"

# --- FUNGSI AUDIT VERSI PAM ---
L_OUTPUT=$(dpkg-query -s "$PACKAGE" 2>/dev/null | grep -P -- '^(Status|Version)\b')

if [ -z "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Package '$PACKAGE' is NOT installed.")
elif echo "$L_OUTPUT" | grep -q 'install ok installed'; then
    L_VERSION=$(echo "$L_OUTPUT" | grep 'Version:' | awk '{print $2}')
    RESULT="REVIEW" # Menilai versi harus manual terhadap kebijakan situs
    a_output+=(" - Package '$PACKAGE' is installed (Status: install ok installed).")
    a_output+=(" - Version detected: $L_VERSION. Needs manual review against required minimum version.")
else
    RESULT="FAIL"
    a_output2+=(" - Package '$PACKAGE' status is NOT 'install ok installed'. Output: $L_OUTPUT")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "REVIEW" ]; then
    NOTES+="REVIEW: ${a_output[*]}"
elif [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}