#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 6.1.2.9"
DESCRIPTION="Ensure rsyslog-gnutls is installed"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_rsyslog_gnutls_chk()
{
    # Memeriksa apakah paket rsyslog-gnutls terinstal
    # Sesuai deskripsi CIS, ini diperlukan untuk dukungan enkripsi TLS pada rsyslog
    if dpkg-query -s rsyslog-gnutls &>/dev/null; then
        l_status=$(dpkg-query -W -f='${Status}' rsyslog-gnutls)
        if [[ "$l_status" == "install ok installed" ]]; then
            a_output+=(" - Paket 'rsyslog-gnutls' terdeteksi dan terinstal")
        else
            a_output2+=(" - Paket 'rsyslog-gnutls' terdeteksi namun statusnya: $l_status")
        fi
    else
        a_output2+=(" - Paket 'rsyslog-gnutls' tidak ditemukan/tidak terinstal")
    fi
}

# Jalankan prosedur pengecekan
f_rsyslog_gnutls_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: rsyslog-gnutls is missing (Required for Level 2) | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}