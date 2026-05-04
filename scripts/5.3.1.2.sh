#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.1.2"
DESCRIPTION="Ensure latest version of libpam-modules is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
l_pkg="libpam-modules"

# 1. Verifikasi apakah paket terinstal
if dpkg-query -s "$l_pkg" 2>/dev/null | grep -q 'install ok installed'; then
    l_version=$(dpkg-query -W -f='${Version}' "$l_pkg")
    a_output+=(" - Paket '$l_pkg' terinstal (Versi: $l_version)")

    # 2. Verifikasi ketersediaan update (Kriteria: Latest Version)
    # Perintah ini mengecek apakah paket muncul dalam daftar yang bisa ditingkatkan
    l_upgradable=$(apt list --upgradable 2>/dev/null | grep -P "^$l_pkg\b")

    if [ -z "$l_upgradable" ]; then
        RESULT="PASS"
        a_output+=(" - Paket '$l_pkg' adalah versi terbaru (tidak ada pembaruan tersedia di repositori)")
    else
        RESULT="FAIL"
        l_next_version=$(echo "$l_upgradable" | awk '{print $2}')
        a_output2+=(" - Pembaruan tersedia untuk '$l_pkg'. Versi saat ini: $l_version, Versi tersedia: $l_next_version")
    fi
else
    RESULT="FAIL"
    a_output2+=(" - Paket '$l_pkg' TIDAK ditemukan atau tidak terinstal dengan benar")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "PASS" ]; then
    NOTES="PASS: ${a_output[*]}"
else
    NOTES="FAIL: Masalah pada paket $l_pkg | Alasan: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt "0" ] && NOTES+=" | Info tambahan: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV/Log
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}