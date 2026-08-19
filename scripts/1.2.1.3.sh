#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.1.3"
DESCRIPTION="Ensure access to gpg key files are configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_gpg_access_chk()
{
    # 1. Verifikasi file .gpg di /usr/share/keyrings/ dan /etc/apt/trusted.gpg.d/
    # Mencari file yang: Bukan milik root, atau bukan group root, atau punya izin tulis group/others atau execute (perm /133)
    while IFS= read -r -d $'\0' l_file; do
        if [ -n "$l_file" ]; then
            l_out=$(stat -Lc 'File: %n Mode: (%#a) User: (%U) Group: (%G)' "$l_file")
            a_output2+=("Incorrect GPG key access: $l_out")
        fi
    done < <(find -L /usr/share/keyrings/ /etc/apt/trusted.gpg.d/ -mount -xdev -type f \( ! -user root -o ! -group root -o -perm /133 \) -name '*gpg' -print0 2>/dev/null)

    # 2. Verifikasi file .list atau .sources yang mengandung 'Signed-By' di /etc/apt/sources.list.d/
    while IFS= read -r -d $'\0' l_file; do
        if [ -n "$l_file" ]; then
            # Hanya periksa jika baris Signed-By aktif (tidak dikomentari)
            if grep -Psq -- '^([^#\n\r]+)?\bSigned-By\b' "$l_file"; then
                l_out=$(stat -Lc 'File: %n Mode: (%#a) User: (%U) Group: (%G)' "$l_file")
                a_output2+=("Incorrect Signed-By file access: $l_out")
            fi
        fi
    done < <(find -L /etc/apt/sources.list.d/ -mount -xdev -type f \( ! -user root -o ! -group root -o -perm /133 \) \( -name '*.list' -o -name '*.sources' \) -print0 2>/dev/null)

    if [ "${#a_output2[@]}" -eq 0 ]; then
        a_output+=("All GPG keys and Signed-By source files have correct permissions and ownership")
    fi
}

# Jalankan pengecekan
f_gpg_access_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: GPG key or source file access issues found. | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}