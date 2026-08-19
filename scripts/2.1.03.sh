#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.1.3"
DESCRIPTION="Ensure dhcp server services are not in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="isc-dhcp-server"
SERVICES=("isc-dhcp-server.service" "isc-dhcp-server6.service")

# 1. Cek Instalasi Paket
if dpkg-query -s "$PACKAGE" &> /dev/null; then
    a_output+=(" - Package '$PACKAGE' is installed (further checks required).")
    
    # 2. Cek status ENABLED
    L_ENABLED=$(systemctl is-enabled "${SERVICES[@]}" 2>/dev/null | grep 'enabled')
    if [ -n "$L_ENABLED" ]; then
        RESULT="FAIL"
        a_output2+=(" - Services ENABLED for boot: $L_ENABLED")
    else
        a_output+=(" - Services are NOT enabled.")
    fi

    # 3. Cek status ACTIVE
    L_ACTIVE=$(systemctl is-active "${SERVICES[@]}" 2>/dev/null | grep '^active')
    if [ -n "$L_ACTIVE" ]; then
        RESULT="FAIL"
        a_output2+=(" - Services are currently ACTIVE: $L_ACTIVE")
    else
        a_output+=(" - Services are NOT active.")
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
    if echo "${a_output[*]}" | grep -q "Package 'isc-dhcp-server' is installed"; then
        NOTES+=" | Note: Package required for dependency; manual review of policy needed."
    fi
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}