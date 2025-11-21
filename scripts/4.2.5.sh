#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.2.5"
DESCRIPTION="Ensure ufw outbound connections are configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="MANUAL" NOTES=""

# --- FUNGSI AUDIT MANUAL ---
L_OUTPUT=$(ufw status numbered 2>/dev/null)

if [ $? -eq 0 ]; then
    a_output+=(" - UFW is active. Review the numbered rules below to ensure all outbound connections match site policy.")
    a_output+=(" - UFW Rules (ufw status numbered):\n$L_OUTPUT\n")
else
    a_output2+=(" - UFW appears inactive or 'ufw status numbered' command failed. Check installation (4.2.1) and status (4.2.3).")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "MANUAL" ]; then
    NOTES+="MANUAL: Review required. Check UFW rules for outbound connections (To Any, To Anywhere, or specific To addresses). Output: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}