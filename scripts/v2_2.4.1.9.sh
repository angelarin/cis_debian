#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.4.1.7"
DESCRIPTION="Ensure access to /etc/cron.yearly is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_dir="/etc/cron.yearly"
RESULT="" NOTES=""

f_cron_yearly_access_chk()
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

        # 3. Verifikasi Permission (Harus 700)
        # Sesuai CIS: Tidak boleh ada izin untuk group maupun others
        if [ "$l_mode" -eq 700 ]; then
            a_output+=(" - Directory \"$l_dir\" permissions are $l_mode (700)")
        else
            a_output2+=(" - Directory \"$l_dir\" permissions are $l_mode (should be 700)")
        fi
    else
        # Jika direktori tidak ada, cek apakah cron terpasang
        if dpkg-query -s cron &>/dev/null; then
            a_output2+=(" - Cron is installed but directory \"$l_dir\" is missing")
        else
            a_output+=(" - Cron is not installed and directory \"$l_dir\" does not exist (Not Applicable)")
        fi
    fi
}

# Jalankan pengecekan
f_cron_yearly_access_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Access configuration issues found for $l_dir | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}