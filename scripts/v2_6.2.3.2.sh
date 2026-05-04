#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 6.1.2.11"
DESCRIPTION="Ensure rsyslog CA certificates are configured (Manual check automated)"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_rsyslog_ca_cert_chk()
{
    # 1. Pastikan rsyslog terinstal sebelum memindai
    if ! command -v rsyslogd >/dev/null 2>&1; then
        a_output2+=(" - rsyslog tidak terdeteksi (abaikan jika menggunakan syslog-ng atau journald murni)")
        return
    fi

    # 2. Cari definisi DefaultNetstreamDriverCAFile
    # Parameter ini menentukan Certificate Authority (CA) yang digunakan untuk memvalidasi server jarak jauh.
    l_search_res=$(grep -Psi -- 'DefaultNetstreamDriverCAFile' /etc/rsyslog.conf /etc/rsyslog.d/*.conf 2>/dev/null)

    if [ -n "$l_search_res" ]; then
        # Merapikan output jika ditemukan di beberapa baris
        l_formatted_res=$(echo "$l_search_res" | tr '\n' ';' | sed 's/;$//')
        a_output+=(" - Konfigurasi CA Certificate ditemukan: $l_formatted_res")
        a_output+=(" - [MANUAL REVIEW REQUIRED]: Pastikan sertifikat ini masih berlaku dan private key dijaga kerahasiaannya.")
    else
        a_output2+=(" - DefaultNetstreamDriverCAFile tidak ditemukan di /etc/rsyslog.conf atau /etc/rsyslog.d/*.conf")
    fi
}

# Jalankan prosedur pengecekan
f_rsyslog_ca_cert_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    # Jika konfigurasi ditemukan, status diset sebagai MANUAL/REVIEW sesuai sifat kontrol
    RESULT="REVIEW"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="REVIEW: ${a_output[*]}"
else
    # Jika tidak ditemukan sama sekali, statusnya FAIL karena komponen TLS belum lengkap (Level 2)
    RESULT="FAIL"
    NOTES+="FAIL: CA Certificate for rsyslog is missing | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}