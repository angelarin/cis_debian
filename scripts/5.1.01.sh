#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.1"
DESCRIPTION="Ensure permissions on /etc/ssh/sshd_config are configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
perm_mask='0177' # MASK 177: Tidak boleh ada izin group write/execute atau other read/write/execute
maxperm="$( printf '%o' $(( 0777 & ~$perm_mask)) )" # Max perms 600
EXPECTED_OWNER="root"
EXPECTED_GROUP="root"

f_sshd_files_chk()
{
local l_file="$1"
while IFS=: read -r l_mode l_user l_group; do
a_out2=()
l_mode_octal=$(printf '%o' "$l_mode")

# 1. Cek Izin (Mask 0177 berarti tidak ada izin untuk group/other)
if [ $(( $l_mode & $perm_mask )) -gt 0 ]; then
    a_out2+=("Mode: \"$l_mode_octal\" (mask fail)" "Should be mode: \"$maxperm\" or more restrictive")
fi

# 2. Cek Pemilik
if [ "$l_user" != "$EXPECTED_OWNER" ]; then
    a_out2+=("Owned by \"$l_user\"" "Should be owned by \"$EXPECTED_OWNER\"")
fi

# 3. Cek Grup
if [ "$l_group" != "$EXPECTED_GROUP" ]; then
    a_out2+=("Group owned by \"$l_group\"" "Should be group owned by \"$EXPECTED_GROUP\"")
fi

if [ "${#a_out2[@]}" -gt "0" ]; then
    a_output2+=(" - File: \"$l_file\": ${a_out2[*]}")
else
    a_output+=(" - File: \"$l_file\": Correct: mode ($l_mode_octal), owner ($l_user) and group owner ($l_group) configured")
fi
done < <(stat -Lc '%#a:%U:%G' "$l_file")
}

# 1. Cek /etc/ssh/sshd_config
if [ -e "/etc/ssh/sshd_config" ]; then
    f_sshd_files_chk "/etc/ssh/sshd_config"
else
    a_output2+=(" - Primary SSH configuration file /etc/ssh/sshd_config not found.")
fi

# 2. Cek file .conf di /etc/ssh/sshd_config.d/
if [ -d "/etc/ssh/sshd_config.d" ]; then
    while IFS= read -r -d $'\0' l_file; do
        [ -e "$l_file" ] && f_sshd_files_chk "$l_file"
    done < <(find /etc/ssh/sshd_config.d -type f -name '*.conf' -print0 2>/dev/null)
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}