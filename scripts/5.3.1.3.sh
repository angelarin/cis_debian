#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.1.3"
DESCRIPTION="Ensure latest version of libpam-pwquality is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
l_pkg="libpam-pwquality"

# 1. Verifikasi instalasi paket
if dpkg-query -s "$l_pkg" 2>/dev/null | grep -q 'install ok installed'; then
    l_version=$(dpkg-query -W -f='${Version}' "$l_pkg")
    a_output+=(" - Paket '$l_pkg' terdeteksi (Versi: $l_version)")

    # 2. Verifikasi apakah versi terbaru (Latest Version check)
    # Perintah ini mengecek apakah paket muncul di daftar 'apt list --upgradable'
    l_upgradable=$(apt list --upgradable 2>/dev/null | grep -P "^$l_pkg\b")

    if [ -z "$l_upgradable" ]; then
        RESULT="PASS"
        a_output+=(" - Paket '$l_pkg' sudah merupakan versi terbaru (tidak ada pembaruan tersedia)")
    else
        RESULT="FAIL"
        l_next_version=$(echo "$l_upgradable" | awk '{print $2}')
        a_output2+=(" - Pembaruan tersedia untuk '$l_pkg'. Versi tersedia: $l_next_version (Kriteria 'latest version' tidak terpenuhi)")
    fi
else
    RESULT="FAIL"
    a_output2+=(" - Paket '$l_pkg' TIDAK ditemukan atau tidak terinstal di sistem")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "PASS" ]; then
    NOTES="PASS: ${a_output[*]}"
else
    NOTES="FAIL: Masalah pada $l_pkg | Alasan kegagalan: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt "0" ] && NOTES+=" | INFO: ${a_output[*]}"
fi

# Merapikan output untuk format CSV/Piped
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}