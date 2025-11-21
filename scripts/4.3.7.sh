#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.7"
DESCRIPTION="Ensure nftables outbound and established connections are configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="MANUAL" NOTES=""

# 1. Cek aturan Established Incoming
L_ESTABLISHED_IN=$(nft list ruleset 2>/dev/null | awk '/hook input/,/}/' | grep -E 'ip protocol (tcp|udp) ct state')
a_output+=(" - INPUT Chain Established/Related rules detected: ${L_ESTABLISHED_IN//$'\n'/ | }")

# 2. Cek aturan Outbound New/Established
L_OUTBOUND_OUTPUT=$(nft list ruleset 2>/dev/null | awk '/hook output/,/}/' | grep -E 'ip protocol (tcp|udp) ct state')
a_output+=(" - OUTPUT Chain New/Established/Related rules detected: ${L_OUTBOUND_OUTPUT//$'\n'/ | }")

if [ -z "$L_ESTABLISHED_IN" ] || [ -z "$L_OUTBOUND_OUTPUT" ]; then
    a_output2+=(" - WARNING: Established/Outbound connection rules may be missing or insufficient.")
    RESULT="REVIEW"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "MANUAL" ]; then
    NOTES+="MANUAL: Rules detected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the detected rules against site policy to ensure only necessary connections are allowed."
elif [ "$RESULT" == "REVIEW" ]; then
    NOTES+="REVIEW: Critical rules may be missing. ${a_output2[*]} | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}