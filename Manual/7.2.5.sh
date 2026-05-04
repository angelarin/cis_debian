#!/usr/bin/env bash

{
    # --- 1. Menghitung Frekuensi Kemunculan UID ---
    # Mengambil kolom ke-3 (UID), mengurutkan, dan menghitung jumlah kemunculannya
    while read -r l_count l_uid; do
        
        # --- 2. Jika Ditemukan UID dengan Jumlah > 1 ---
        if [ "$l_count" -gt 1 ]; then
            # Mencari semua nama pengguna yang memiliki UID tersebut
            l_user_list="$(awk -F: '($3 == n) { print $1 }' n=$l_uid /etc/passwd | xargs)"
            
            echo -e "Duplicate UID: \"$l_uid\" Users: \"$l_user_list\""
        fi

    done < <(cut -f3 -d":" /etc/passwd | sort -n | uniq -c)
}