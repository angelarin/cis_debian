#!/usr/bin/env bash
{
# 1. Buat pola regex shell yang valid, menghindari nologin
# Escape slash dan gabungkan dengan pipe
l_valid_shells=$(grep -v '/usr/sbin/nologin' /etc/shells | sed 's/\//\\\//g' | tr '\n' '|' | sed 's/|$/ /')
l_valid_shells="^(${l_valid_shells%|})$"

# --- Mulai Loop Audit ---
while IFS= read -r l_user; do
    # Pastikan l_user bersih dari whitespace
    CLEAN_USER=$(echo "$l_user" | tr -d ' \t\r\n') 

    if [ -n "$CLEAN_USER" ]; then
        # Audit: Cek status kata sandi. Jika TIDAK 'L' (Locked), cetak sebagai kegagalan.
        # Catatan: Perintah ini hanya untuk AUDIT (mencetak).
        sudo passwd -S "$CLEAN_USER" | awk '
            $2 !~ /^L/ { 
                print "Account: \"" $1 "\" does not have a valid login shell and is NOT LOCKED" 
            }' 2>/dev/null
    fi
# Tambahkan tr -d '\r' untuk memastikan input ke loop bersih
done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $(NF) !~ pat) {print $1}' /etc/passwd | tr -d '\r')
}



