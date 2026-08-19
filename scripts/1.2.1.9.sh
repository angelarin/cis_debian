#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.1.9"
DESCRIPTION="Ensure access to files in /etc/apt/sources.list.d are configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_dir="/etc/apt/sources.list.d"
RESULT="" NOTES=""

f_files_access_chk()
{
    # Cek apakah direktori ada dan tidak kosong
    if [ -d "$l_dir" ] && [ -n "$(ls -A "$l_dir" 2>/dev/null)" ]; then
        
        # Mencari file yang melanggar aturan:
        # 1. Bukan milik user root (! -user root)
        # 2. Bukan milik group root (! -group root)
        # 3. Izin lebih longgar dari 0644 (-perm /133)
        #    (Mask 133 mendeteksi: u+x, g+wx, o+wx sebagai pelanggaran)
        
        while IFS= read -r -d $'\0' l_file; do
            if [ -n "$l_file" ]; then
                l_out=$(stat -Lc 'File: %n Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$l_file")
                a_output2+=("Incorrect file access: $l_out")
            fi
        done < <(find "$l_dir" -type f -mount -xdev \( ! -user root -o ! -group root -o -perm /133 \) -print0 2>/dev/null)

        if [ "${#a_output2[@]}" -eq 0 ]; then
            a_output+=("All files in $l_dir have correct permissions (0644 or more restrictive) and ownership")
        fi
    else
        # Jika direktori kosong, secara teknis tidak ada file yang melanggar
        a_output+=("Directory $l_dir is empty (No additional source files to check)")
    fi
}

# Jalankan pengecekan
f_files_access_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Some files in $l_dir have insecure permissions or ownership | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}