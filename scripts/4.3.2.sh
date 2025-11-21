#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.2"
DESCRIPTION="Ensure ufw is uninstalled or disabled with nftables"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="FAIL" NOTES=""
PACKAGE="ufw"
SERVICE="ufw.service"
PASS_CRITERIA=0

# 1. Cek UFW tidak terinstal
if ! dpkg-query -s "$PACKAGE" &> /dev/null; then
    a_output+=(" - Scenario 1: Package '$PACKAGE' is NOT installed.")
    PASS_CRITERIA=1
else
    a_output+=(" - Package '$PACKAGE' IS installed.")
fi

# 2. Cek UFW dinonaktifkan (hanya jika terinstal)
if [ "$PASS_CRITERIA" -eq 0 ]; then
    L_UFW_STATUS=$(ufw status 2>/dev/null | grep 'Status:')
    L_UFW_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null)
    
    if echo "$L_UFW_STATUS" | grep -q 'inactive' && [ "$L_UFW_ENABLED" = "masked" ]; then
        a_output+=(" - Scenario 2: UFW is installed but INACTIVE and service is MASKED.")
        PASS_CRITERIA=1
    else
        a_output2+=(" - UFW is installed but not fully disabled (Status: $L_UFW_STATUS, Service Status: $L_UFW_ENABLED).")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$PASS_CRITERIA" -eq 1 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: UFW is installed and either active or not masked. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}