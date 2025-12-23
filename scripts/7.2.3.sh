#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.3"
DESCRIPTION="Ensure all groups in /etc/passwd exist in /etc/group"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PASSWD_FILE="/etc/passwd"
GROUP_FILE="/etc/group"

# 1. Kumpulkan semua GID unik dari /etc/passwd
a_passwd_group_gid=("$(awk -F: '{print $4}' "$PASSWD_FILE" | sort -u 2>/dev/null)")
# 2. Kumpulkan semua GID unik dari /etc/group
a_group_gid=("$(awk -F: '{print $3}' "$GROUP_FILE" | sort -u 2>/dev/null)")

# 3. Hitung perbedaan GID yang ada di /etc/passwd TAPI TIDAK ada di /etc/group
# comm -23: Mencetak baris yang hanya ada di File1. File1 = a_passwd_group_gid.
L_GID_DIFF=$(comm -23 <(printf '%s\n' "${a_passwd_group_gid[@]}" | sort -u) <(printf '%s\n' "${a_group_gid[@]}" | sort -u))

if [ -n "$L_GID_DIFF" ]; then
    RESULT="FAIL"
    L_VIOLATIONS=""
    while IFS= read -r l_gid; do
        # Cari user mana yang memiliki GID yang tidak ada ini
        L_USERS=$(awk -F: -v gid="$l_gid" '($4 == gid) {print " - User: \"" $1 "\" has GID: \"" $4 "\" which does not exist in /etc/group" }' "$PASSWD_FILE")
        L_VIOLATIONS+="${L_USERS//$'\n'/ | }"
    done < <(echo "$L_GID_DIFF")
    
    a_output2+=(" - Detected user(s) with primary GID that does not exist in /etc/group. Violations: ${L_VIOLATIONS}")
else
    a_output+=(" - All primary GIDs in $PASSWD_FILE exist in $GROUP_FILE.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}