#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.2.1.6"
DESCRIPTION="Ensure access to files in the /etc/apt/auth.conf.d/ directory is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_dir="/etc/apt/auth.conf.d"
RESULT="" NOTES=""

f_auth_conf_chk()
{
    # Cek apakah direktori ada dan tidak kosong
    if [ -d "$l_dir" ] && [ -n "$(ls -A "$l_dir" 2>/dev/null)" ]; then
        
        # Mencari file yang melanggar aturan:
        # 1. Bukan milik user root (! -user root)
        # 2. Bukan milik group root (! -group root)
        # 3. Izin lebih longgar dari 0640 (-perm /137)
        #    (137 mask: u+x, g+wx, o+rwx adalah pelanggaran)
        
        while IFS= read -r -d $'\0' l_file; do
            if [ -n "$l_file" ]; then
                l_out=$(stat -Lc 'File: %n Access: (%a/%A) Uid: (%u/%U) Gid: (%g/%G)' "$l_file")
                a_output2+=("Incorrect access: $l_out")
            fi
        done < <(find "$l_dir" -type f -name "*.conf" -mount -xdev \( ! -user root -o ! -group root -o -perm /137 \) -print0 2>/dev/null)

        if [ "${#a_output2[@]}" -eq 0 ]; then
            a_output+=("All files in $l_dir have correct permissions and ownership")
        fi
    else
        # Jika direktori kosong atau tidak ada, ini dianggap PASS karena tidak ada secret yang terekspos
        a_output+=("Directory $l_dir is empty or does not exist (No credentials found)")
    fi
}

# Jalankan pengecekan
f_auth_conf_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Sensitive APT auth files have insecure permissions | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}