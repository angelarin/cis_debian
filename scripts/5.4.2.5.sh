#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.5"
DESCRIPTION="Ensure root path integrity"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_output2=""
l_pmask="0022"
l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )" # Max perms 755
EXPECTED_OWNER="root"

# Dapatkan PATH root
l_root_path="$(sudo -Hiu root env 2>/dev/null | grep '^PATH' | cut -d= -f2)"

if [ -z "$l_root_path" ]; then
    a_output2+=(" - WARNING: Could not determine root's PATH variable.")
    RESULT="FAIL" # Anggap gagal jika PATH tidak dapat ditemukan
else
    a_output+=(" - Root PATH: $l_root_path")
    unset a_path_loc && IFS=":" read -ra a_path_loc <<< "$l_root_path"

    # 1. Cek empty directory (::)
    grep -q "::" <<< "$l_root_path" && l_output2="$l_output2 | root's path contains a empty directory (::)"

    # 2. Cek trailing (:)
    grep -Pq ":\h*$" <<< "$l_root_path" && l_output2="$l_output2 | root's path contains a trailing (:)"

    # 3. Cek current working directory (.)
    grep -Pq '(\h+|:)\.(:|\h*$)' <<< "$l_root_path" && l_output2="$l_output2 | root's path contains current working directory (.)"

    # 4. Cek setiap lokasi di PATH
    for l_path in "${a_path_loc[@]}"; do
        if [ -d "$l_path" ]; then
            # Cek kepemilikan dan izin
            while read -r l_fmode l_fown; do
                if [ "$l_fown" != "$EXPECTED_OWNER" ]; then
                    l_output2="$l_output2 | Directory: \"$l_path\" is owned by: \"$l_fown\" should be owned by \"$EXPECTED_OWNER\""
                fi
                
                # Cek izin: mode harus lebih ketat atau sama dengan 755 (mask 0022)
                # $l_fmode & $l_pmask harus 0. Jika > 0, berarti ada izin write untuk group/other.
                if [ $(( $l_fmode & $l_pmask )) -gt 0 ]; then
                    l_output2="$l_output2 | Directory: \"$l_path\" is mode: \"$l_fmode\" and should be mode: \"$l_maxperm\" or more restrictive"
                fi
            done <<< "$(stat -Lc '%#a %U' "$l_path")"
        elif [ -n "$l_path" ]; then # Hanya laporkan jika path bukan string kosong
            l_output2="$l_output2 | \"$l_path\" is not a directory"
        fi
    done
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ -n "$l_output2" ]; then
    RESULT="FAIL"
    # Menghapus '| ' awal jika ada
    l_output2="${l_output2# \| }"
    NOTES+="FAIL: * Reasons for audit failure * : $l_output2"
else
    NOTES+="PASS: Root's path is correctly configured."
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}