#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.4"
DESCRIPTION="Ensure a nftables table exists"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI AUDIT NFTABLES TABLE ---
L_OUTPUT=$(nft list tables 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    L_COUNT=$(echo "$L_OUTPUT" | grep -c 'table')
    RESULT="PASS"
    a_output+=(" - $L_COUNT nftables table(s) found.")
    a_output+=(" - Detected tables: ${L_OUTPUT//$'\n'/ | }")
else
    RESULT="FAIL"
    a_output2+=(" - No nftables tables found. nftables may not be configured or running.")
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