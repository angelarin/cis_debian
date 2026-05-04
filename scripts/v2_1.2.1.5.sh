#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.1.5"
DESCRIPTION="Ensure access to /etc/apt/auth.conf.d directory is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_dir="/etc/apt/auth.conf.d"
RESULT="" NOTES=""

f_dir_access_chk()
{
    if [ -d "$l_dir" ]; then
        # Mengambil mode (oktal), UID, GID, nama user, dan nama group
        read l_mode l_uid l_gid l_user l_group < <(stat -Lc '%a %u %g %U %G' "$l_dir")

        # 1. Verifikasi Kepemilikan User (Root)
        if [ "$l_uid" -eq 0 ]; then
            a_output+=(" - Directory \"$l_dir\" is owned by user: $l_user")
        else
            a_output2+=(" - Directory \"$l_dir\" is owned by user: $l_user (should be root)")
        fi

        # 2. Verifikasi Kepemilikan Group (Root)
        if [ "$l_gid" -eq 0 ]; then
            a_output+=(" - Directory \"$l_dir\" is group-owned by group: $l_group")
        else
            a_output2+=(" - Directory \"$l_dir\" is group-owned by group: $l_group (should be root)")
        fi

        # 3. Verifikasi Permission (0755 atau lebih ketat)
        # Sesuai CIS, group dan others tidak boleh memiliki akses tulis (write).
        # Menggunakan bitwise AND dengan mask 022 (----w--w-)
        if [ "$((l_mode & 022))" -eq 0 ]; then
            a_output+=(" - Directory \"$l_dir\" permissions are $l_mode (0755 or more restrictive)")
        else
            a_output2+=(" - Directory \"$l_dir\" permissions are $l_mode (too permissive, group/others must not have write access)")
        fi
    else
        # Jika direktori tidak ada, ini bisa dianggap PASS karena tidak ada risiko bocornya kredensial
        a_output+=(" - Directory \"$l_dir\" does not exist (No private auth configuration found)")
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
    NOTES+="FAIL: Directory access issues found on $l_dir | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}