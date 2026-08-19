#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 2.1.16"
DESCRIPTION="Ensure telnet-server services are not in use"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_telnet_chk()
{
    # 1. Cek apakah paket telnetd atau telnetd-ssl terpasang
    l_pkg_installed=$(dpkg-query -l | awk '{print $2}' | grep -Pi -- '^telnetd|^telnetd-ssl')

    if [ -z "$l_pkg_installed" ]; then
        a_output+=(" - Telnet server packages (telnetd/telnetd-ssl) are not installed")
    else
        # 2. Jika paket terpasang (mungkin sebagai dependensi), cek status servisnya
        l_service="inetutils-inetd.service"
        l_enabled=$(systemctl is-enabled "$l_service" 2>/dev/null)
        l_active=$(systemctl is-active "$l_service" 2>/dev/null)

        if [[ "$l_enabled" != "enabled" ]] && [[ "$l_active" != "active" ]]; then
            a_output+=(" - Telnet packages found but service \"$l_service\" is disabled and inactive")
        else
            [ "$l_enabled" == "enabled" ] && a_output2+=(" - Telnet service \"$l_service\" is enabled")
            [ "$l_active" == "active" ] && a_output2+=(" - Telnet service \"$l_service\" is active")
        fi
    fi
}

# Jalankan pengecekan
f_telnet_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Insecure Telnet server is active or enabled | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}