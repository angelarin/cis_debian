#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.2.3"
DESCRIPTION="Ensure iptables outbound and established connections are configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="MANUAL" NOTES=""

# --- FUNGSI AUDIT MANUAL ---
L_OUTPUT=$(iptables -L -v -n 2>/dev/null)

if [ $? -eq 0 ]; then
    a_output+=(" - iptables is configured. Review the full ruleset below to ensure all new outbound and established connections match site policy.")
    a_output+=(" - Full iptables Ruleset:\n$L_OUTPUT\n")
    
    # Deteksi aturan established/related
    L_ESTABLISHED=$(echo "$L_OUTPUT" | grep 'state ESTABLISHED,RELATED')
    [ -n "$L_ESTABLISHED" ] && a_output+=(" - Established/Related rules detected: ${L_ESTABLISHED//$'\n'/ | }")
else
    a_output2+=(" - Could not retrieve iptables ruleset. iptables may not be active or configured.")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "MANUAL" ]; then
    NOTES+="MANUAL: Review required. Check full iptables ruleset against site policy. ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}