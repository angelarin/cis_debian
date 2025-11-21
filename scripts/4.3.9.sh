#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.3.9"
DESCRIPTION="Ensure nftables service is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
SERVICE="nftables.service"

# 1. Cek status ENABLED
L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null)
if [ "$L_ENABLED" = "enabled" ]; then
    a_output+=(" - Service '$SERVICE' is ENABLED for boot.")
else
    RESULT="FAIL"
    a_output2+=(" - Service '$SERVICE' is NOT enabled (Status: $L_ENABLED).")
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