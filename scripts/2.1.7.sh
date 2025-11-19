#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.1.7"
DESCRIPTION="Ensure slapd LDAP server service is not in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="slapd"
SERVICE="slapd.service"

# 1. Cek Instalasi Paket
if dpkg-query -s "$PACKAGE" &> /dev/null; then
    a_output+=(" - Package '$PACKAGE' is installed (further checks required).")
    
    # 2. Cek status ENABLED
    L_ENABLED=$(systemctl is-enabled "$SERVICE" 2>/dev/null | grep 'enabled')
    if [ -n "$L_ENABLED" ]; then
        RESULT="FAIL"
        a_output2+=(" - Service '$SERVICE' is ENABLED for boot.")
    else
        a_output+=(" - Service '$SERVICE' is NOT enabled.")
    fi

    # 3. Cek status ACTIVE
    L_ACTIVE=$(systemctl is-active "$SERVICE" 2>/dev/null | grep '^active')
    if [ -n "$L_ACTIVE" ]; then
        RESULT="FAIL"
        a_output2+=(" - Service '$SERVICE' is currently ACTIVE.")
    else
        a_output+=(" - Service '$SERVICE' is NOT active.")
    fi
else
    RESULT="PASS"
    a_output+=(" - Package '$PACKAGE' is NOT installed.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" != "FAIL" ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO (Correctly set): ${a_output[*]}"
    if echo "${a_output[*]}" | grep -q "Package '$PACKAGE' is installed"; then
        NOTES+=" | Note: Package required for dependency; manual review of policy needed."
    fi
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}