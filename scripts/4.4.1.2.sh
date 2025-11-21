#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.1.2"
DESCRIPTION="Ensure nftables is not in use with iptables"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PACKAGE="nftables"
SERVICE="nftables.service"

# 1. Cek Instalasi Paket
if dpkg-query -s "$PACKAGE" &> /dev/null; then
    a_output+=(" - Package '$PACKAGE' IS installed (further checks required).")
    
    # 2. Cek status ENABLED
    L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null | grep '^enabled')
    if [ -n "$L_ENABLED" ]; then
        RESULT="FAIL"
        a_output2+=(" - Service '$SERVICE' is ENABLED for boot (Conflict).")
    else
        a_output+=(" - Service '$SERVICE' is NOT enabled.")
    fi

    # 3. Cek status ACTIVE
    L_ACTIVE=$(systemctl is-active "$SERVICE" 2>/dev/null | grep '^active')
    if [ -n "$L_ACTIVE" ]; then
        RESULT="FAIL"
        a_output2+=(" - Service '$SERVICE' is currently ACTIVE (Conflict).")
    else
        a_output+=(" - Service '$SERVICE' is NOT active.")
    fi
else
    a_output+=(" - Package '$PACKAGE' is NOT installed (PASS).")
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