#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.3"
DESCRIPTION="Ensure permissions on SSH public host key files are configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
l_pmask="0133" # Mask 133: Tidak boleh ada group/other write/execute
l_maxperm="0644"
EXPECTED_OWNER="root"
EXPECTED_GROUP="root"

f_file_chk()
{
local l_file="$1"
while IFS=: read -r l_file_mode l_file_owner l_file_group; do
a_out2=()
l_file_mode_octal=$(printf '%o' "$l_file_mode")

# 1. Cek Izin
if [ $(( $l_file_mode & $l_pmask )) -gt 0 ]; then
a_out2+=("Mode: \"$l_file_mode_octal\" (mask fail)" "Should be mode: \"$l_maxperm\" or more restrictive")
fi

# 2. Cek Pemilik
if [ "$l_file_owner" != "$EXPECTED_OWNER" ]; then
a_out2+=("Owned by: \"$l_file_owner\"" "Should be owned by: \"$EXPECTED_OWNER\"")
fi

# 3. Cek Grup
if [ "$l_file_group" != "$EXPECTED_GROUP" ]; then
a_out2+=("Owned by group \"$l_file_group\"" "Should be group owned by group: \"$EXPECTED_GROUP\"")
fi

if [ "${#a_out2[@]}" -gt "0" ]; then
a_output2+=(" - File: \"$l_file\": ${a_out2[*]}")
else
a_output+=(" - File: \"$l_file\": Correct: mode: \"$l_file_mode_octal\", owner: \"$l_file_owner\" and group owner: \"$l_file_group\" configured")
fi
done < <(stat -Lc '%#a:%U:%G' "$l_file")
}

# Cari SSH public keys
while IFS= read -r -d $'\0' l_file; do
if ssh-keygen -lf &>/dev/null "$l_file"; then
    file "$l_file" | grep -Piq -- '\bopenssh\h+([^#\n\r]+\h+)?public\h+key\b' && f_file_chk "$l_file"
fi
done < <(find -L /etc/ssh -xdev -type f -print0 2>/dev/null)

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -le 0 ] && a_output+=(" - No openSSH public keys found in /etc/ssh.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}