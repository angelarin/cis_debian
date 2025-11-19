#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.1.18"
DESCRIPTION="Ensure web server services (apache2, nginx) are not in use"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGES=("apache2" "nginx")
SERVICES=("apache2.socket" "apache2.service" "nginx.service")
IS_INSTALLED=0

# 1. Cek Instalasi Paket
for pkg in "${PACKAGES[@]}"; do
    if dpkg-query -s "$pkg" &> /dev/null; then
        a_output+=(" - Package '$pkg' is installed.")
        IS_INSTALLED=1
    else
        a_output+=(" - Package '$pkg' is NOT installed.")
    fi
done

if [ "$IS_INSTALLED" -eq 1 ]; then
    # 2. Cek status ENABLED
    L_ENABLED=$(systemctl is-enabled "${SERVICES[@]}" 2>/dev/null | grep 'enabled')
    if [ -n "$L_ENABLED" ]; then
        RESULT="FAIL"
        a_output2+=(" - Services/sockets ENABLED for boot: $L_ENABLED")
    else
        a_output+=(" - Services/sockets are NOT enabled.")
    fi

    # 3. Cek status ACTIVE
    L_ACTIVE=$(systemctl is-active "${SERVICES[@]}" 2>/dev/null | grep '^active')
    if [ -n "$L_ACTIVE" ]; then
        RESULT="FAIL"
        a_output2+=(" - Services/sockets are currently ACTIVE: $L_ACTIVE")
    else
        a_output+=(" - Services/sockets are NOT active.")
    fi
else
    RESULT="PASS"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" != "FAIL" ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
    if [ "$IS_INSTALLED" -eq 1 ]; then
        NOTES+=" | Note: Package required for dependency; manual review of policy needed."
    fi
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}