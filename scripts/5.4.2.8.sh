#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.8"
DESCRIPTION="Ensure accounts without a valid login shell are locked"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# 1. Bangun daftar shell yang valid
l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells 2>/dev/null | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

if [ "$l_valid_shells" = "^()$" ]; then
    a_output2+=(" - Could not determine valid shells from /etc/shells.")
    RESULT="FAIL"
else
    # 2. Cari akun non-root yang TIDAK memiliki shell valid
    while IFS= read -r l_user; do
        # 3. Cek status password: jika TIDAK 'L' (terkunci), maka ini adalah kegagalan
        L_PASSWD_STATUS=$(passwd -S "$l_user" 2>/dev/null | awk '$2 !~ /^L/ {print $2}')
        L_SHELL=$(grep "^$l_user:" /etc/passwd | awk -F: '{print $NF}')
        
        if [ -n "$L_PASSWD_STATUS" ]; then
            RESULT="FAIL"
            a_output2+=(" - Account: \"$l_user\" (Shell: $L_SHELL) does not have a valid login shell AND is NOT LOCKED (Status: $L_PASSWD_STATUS).")
        fi
    done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $NF !~ pat) {print $1}' /etc/passwd 2>/dev/null)
    
    if [ "${#a_output2[@]}" -eq 0 ]; then
        a_output+=(" - All non-root accounts without a valid login shell are locked.")
    fi
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