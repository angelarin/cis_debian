#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.1.3"
DESCRIPTION="Ensure ufw is not in use with iptables"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="FAIL" NOTES=""
PACKAGE="ufw"
SERVICE="ufw.service"
PASS_CRITERIA=0

# 1. Cek UFW tidak terinstal (Scenario 1)
if ! dpkg-query -s "$PACKAGE" &> /dev/null; then
    a_output+=(" - Scenario 1: Package '$PACKAGE' is NOT installed (PASS).")
    PASS_CRITERIA=1
else
    a_output+=(" - Package '$PACKAGE' IS installed (further checks required).")

    # 2. Cek UFW dinonaktifkan (Scenario 2)
    L_UFW_STATUS=$(ufw status 2>/dev/null | grep 'Status:')
    L_UFW_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null | grep '^enabled')
    L_UFW_ACTIVE=$(systemctl is-active "$SERVICE" 2>/dev/null | grep '^active')
    
    if echo "$L_UFW_STATUS" | grep -q 'inactive' && [ -z "$L_UFW_ENABLED" ] && [ -z "$L_UFW_ACTIVE" ]; then
        a_output+=(" - Scenario 2: UFW is installed but INACTIVE and NOT enabled/active.")
        PASS_CRITERIA=1
    else
        a_output2+=(" - UFW is installed and either ENABLED or ACTIVE (Status: $L_UFW_STATUS, Enabled: $L_UFW_ENABLED, Active: $L_UFW_ACTIVE).")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$PASS_CRITERIA" -eq 1 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}