#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.2.1.4"
DESCRIPTION="Ensure access to /etc/apt/trusted.gpg.d directory is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_dir="/etc/apt/trusted.gpg.d"
RESULT="" NOTES=""

f_dir_access_chk()
{
    if [ -d "$l_dir" ]; then
        # Mengambil mode (oktal), UID, GID, nama user, dan nama group
        read l_mode l_uid l_gid l_user l_group < <(stat -Lc '%a %u %g %U %G' "$l_dir")

        # 1. Verifikasi User (Root)
        if [ "$l_uid" -eq 0 ]; then
            a_output+=(" - Directory \"$l_dir\" is owned by user: $l_user")
        else
            a_output2+=(" - Directory \"$l_dir\" is owned by user: $l_user (should be root)")
        fi

        # 2. Verifikasi Group (Root)
        if [ "$l_gid" -eq 0 ]; then
            a_output+=(" - Directory \"$l_dir\" is group-owned by group: $l_group")
        else
            a_output2+=(" - Directory \"$l_dir\" is group-owned by group: $l_group (should be root)")
        fi

        # 3. Verifikasi Permission (0755 atau lebih ketat)
        # Penjelasan: Mask 022 (----w--w-) tidak boleh ada yang menyala.
        # Jika hasil AND antara mode dan 022 adalah 0, berarti group/others tidak bisa menulis.
        if [ "$((l_mode & 022))" -eq 0 ]; then
            a_output+=(" - Directory \"$l_dir\" permissions are $l_mode (0755 or more restrictive)")
        else
            a_output2+=(" - Directory \"$l_dir\" permissions are $l_mode (too permissive, must not be group/others writable)")
        fi
    else
        a_output2+=(" - Directory \"$l_dir\" does not exist on the system")
    fi
}

# Jalankan pengecekan
f_dir_access_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Directory access issues found | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}