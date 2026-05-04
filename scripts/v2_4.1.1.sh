#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 4.1.1"
DESCRIPTION="Ensure ufw is installed"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_ufw_install_chk()
{
    # Memeriksa status instalasi paket menggunakan dpkg-query
    if dpkg-query -s ufw &>/dev/null; then
        l_status=$(dpkg-query -W -f='${Status}' ufw)
        if [[ "$l_status" == "install ok installed" ]]; then
            a_output+=(" - Paket 'ufw' terdeteksi dan terinstal dengan benar")
        else
            a_output2+=(" - Paket 'ufw' terdeteksi namun dalam status: $l_status")
        fi
    else
        a_output2+=(" - Paket 'ufw' tidak ditemukan/tidak terinstal di sistem")
    fi
}

# Jalankan prosedur pengecekan
f_ufw_install_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Uncomplicated Firewall (UFW) is not installed | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}