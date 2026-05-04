#!/usr/bin/env bash

{
    # --- 1. Mengumpulkan GID dari /etc/passwd dan /etc/group ---
    # Menggunakan mapfile untuk memastikan setiap baris menjadi elemen array yang terpisah
    mapfile -t a_passwd_group_gid < <(awk -F: '{print $4}' /etc/passwd | sort -u)
    mapfile -t a_group_gid < <(awk -F: '{print $3}' /etc/group | sort -u)

    # --- 2. Mencari Selisih (GID di passwd yang tidak ada di group) ---
    mapfile -t a_passwd_group_diff < <(printf '%s\n' "${a_group_gid[@]}" "${a_passwd_group_gid[@]}" | sort | uniq -u)

    # --- 3. Melakukan Audit ---
    # Mencari irisan antara GID yang digunakan user dan GID yang hilang dari /etc/group
    l_violations=$(printf '%s\n' "${a_passwd_group_gid[@]}" "${a_passwd_group_diff[@]}" | sort | uniq -D | uniq)

    if [ -n "$l_violations" ]; then
        echo -e "\n- Audit Result:\n ** FAIL **"
        while IFS= read -r l_gid; do
            if [ -n "$l_gid" ]; then
                awk -F: '($4 == '"$l_gid"') {print " - User: \"" $1 "\" has GID: \""$4 "\" which does not exist in /etc/group" }' /etc/passwd
            fi
        done <<< "$l_violations"
    else
        echo -e "\n- Audit Result:\n ** PASS **\n - All GIDs in /etc/passwd exist in /etc/group"
    fi

    # Membersihkan variabel
    unset a_passwd_group_gid a_group_gid a_passwd_group_diff l_violations
}