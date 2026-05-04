#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 6.1.2.10"
DESCRIPTION="Ensure rsyslog forwarding uses gtls"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_rsyslog_gtls_forwarding_chk()
{
    # 1. Pastikan rsyslog terinstal sebelum melakukan audit file konfigurasi
    if ! command -v rsyslogd >/dev/null 2>&1; then
        # Jika rsyslog tidak digunakan, kontrol ini mungkin tidak applicable, 
        # namun rsyslog-gnutls (6.1.2.9) adalah prasyarat Level 2.
        a_output2+=(" - rsyslog tidak terdeteksi di sistem")
        return
    fi

    # 2. Cari definisi StreamDriver="gtls" di file konfigurasi utama dan direktori .d/
    # Parameter ini wajib ada jika sistem melakukan forwarding secara aman.
    l_search_res=$(grep -Psi -- '^\h*StreamDriver=\"gtls\"' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)

    if [ -n "$l_search_res" ]; then
        # Menghapus spasi berlebih dan mengganti newline dengan semicolon untuk kejelasan notes
        l_formatted_res=$(echo "$l_search_res" | tr '\n' ';' | sed 's/;$//')
        a_output+=(" - Konfigurasi gtls ditemukan: $l_formatted_res")
    else
        a_output2+=(" - StreamDriver=\"gtls\" tidak ditemukan di /etc/rsyslog.conf atau /etc/rsyslog.d/*.conf")
    fi
}

# Jalankan prosedur pengecekan
f_rsyslog_gtls_forwarding_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    # Karena ini Level 2, kegagalan berarti kebijakan enkripsi log belum diterapkan
    RESULT="FAIL"
    NOTES+="FAIL: rsyslog forwarding is not using gtls | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}