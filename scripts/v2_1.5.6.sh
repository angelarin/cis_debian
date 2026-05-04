#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.5.6"
DESCRIPTION="Ensure prelink is not installed"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_package_chk()
{
    # Memeriksa status paket menggunakan dpkg-query
    # Jika perintah berhasil (exit code 0), berarti paket terpasang
    if dpkg-query -s prelink &>/dev/null; then
        a_output2+=(" - package \"prelink\" is installed")
    else
        a_output+=(" - package \"prelink\" is not installed")
    fi
}

# Jalankan pengecekan
f_package_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Software found that can interfere with binary integrity | Reason(s): ${a_output2[*]}"
    # Catatan tambahan jika ada informasi PASS yang relevan (biasanya kosong untuk audit paket)
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}