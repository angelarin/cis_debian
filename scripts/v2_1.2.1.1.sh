#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.2.1.1"
DESCRIPTION="Ensure the source.list and .source files use the Signed-By option"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

# Mendefinisikan file yang akan diperiksa
# /etc/apt/sources.list dan semua file .list atau .sources di /etc/apt/sources.list.d/
l_search_path="/etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources"

# Fungsi Audit
f_apt_signed_chk()
{
    # Menggunakan grep dengan flag -L (files-without-match) 
    # Jika file tidak mengandung pola 'Signed-By' pada baris aktif, maka akan muncul di output.
    # Sesuai panduan CIS: "Nothing should be returned" (artinya semua harus punya Signed-By)
    
    # Kita jalankan grep dan tangkap hasilnya ke dalam variabel
    # Menggunakan 2>/dev/null untuk menghindari error jika file .sources atau .list tidak ada
    l_bad_files=$(grep -PRLs -- '^([^#\n\r]+)?\bSigned-By\b' /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null)

    if [ -z "$l_bad_files" ]; then
        a_output+=("All apt source files are using the 'Signed-By' option")
    else
        # Jika ada file yang terdaftar (tidak punya Signed-By)
        while IFS= read -r l_file; do
            [ -n "$l_file" ] && a_output2+=("File missing Signed-By: $l_file")
        done <<< "$l_bad_files"
    fi
}

# Jalankan pengecekan
f_apt_signed_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Some APT sources do not use the Signed-By option. | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}