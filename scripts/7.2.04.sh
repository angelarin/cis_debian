#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.4"
DESCRIPTION="Ensure shadow group is empty"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
GROUP_FILE="/etc/group"
PASSWD_FILE="/etc/passwd"
SHADOW_GROUP="shadow"

# 1. Cek anggota grup shadow
L_MEMBERS=$(awk -F: '($1=="shadow") {print $NF}' "$GROUP_FILE" 2>/dev/null)
if [ -n "$L_MEMBERS" ]; then
    RESULT="FAIL"
    a_output2+=(" - Group '$SHADOW_GROUP' has members: $L_MEMBERS (Should be empty).")
else
    a_output+=(" - Group '$SHADOW_GROUP' has no members.")
fi

# 2. Cek apakah ada user yang GID primernya adalah 'shadow'
SHADOW_GID=$(getent group shadow | awk -F: '{print $3}' | xargs 2>/dev/null)

if [ -n "$SHADOW_GID" ]; then
    L_USERS_PRIMARY=$(awk -F: -v gid="$SHADOW_GID" '($4 == gid) {print $1}' "$PASSWD_FILE" 2>/dev/null)
    
    if [ -n "$L_USERS_PRIMARY" ]; then
        RESULT="FAIL"
        a_output2+=(" - The following user(s) have '$SHADOW_GROUP' as their PRIMARY group: ${L_USERS_PRIMARY//$'\n'/ | }")
    else
        a_output+=(" - No users have '$SHADOW_GROUP' as their primary group.")
    fi
else
    # Gagal mendapatkan GID shadow, ini juga bisa menjadi masalah konfigurasi
    a_output2+=(" - Warning: Could not retrieve GID for '$SHADOW_GROUP' group.")
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