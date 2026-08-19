#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.2.1"
DESCRIPTION="Ensure updates, patches, and additional security software are installed"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_audit_updates_chk()
{
    # 1. Periksa apakah apt tersedia
    if ! command -v apt >/dev/null 2>&1; then
        a_output2+=(" - Perintah 'apt' tidak ditemukan. Pastikan sistem menggunakan manajemen paket berbasis Debian.")
        return
    fi

    # 2. Periksa paket yang dapat diperbarui (Simulasi Upgrade)
    # Menggunakan apt-get -s (simulate) agar tidak mengubah kondisi sistem
    l_upgrade_sim=$(apt-get -s upgrade 2>/dev/null | grep -P '^\d+ upgraded, \d+ newly installed')
    l_upgradable=$(echo "$l_upgrade_sim" | awk '{print $1}')

    if [ -n "$l_upgradable" ] && [ "$l_upgradable" -gt 0 ]; then
        a_output2+=(" - Ditemukan $l_upgradable paket yang memerlukan patch/update")
    else
        a_output+=(" - Semua paket perangkat lunak terpantau mutakhir")
    fi

    # 3. Periksa apakah sistem memerlukan reboot setelah pembaruan sebelumnya
    if [ -f /var/run/reboot-required ]; then
        l_reboot_reason=$(cat /var/run/reboot-required 2>/dev/null)
        a_output2+=(" - Sistem memerlukan reboot untuk menerapkan pembaruan: ${l_reboot_reason:-Reason unknown}")
    else
        a_output+=(" - Tidak ada permintaan reboot sistem yang tertunda")
    fi
}

# Jalankan prosedur pengecekan
f_audit_updates_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Updates or system reboot required | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV/Log
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}