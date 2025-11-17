#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.4.1"
DESCRIPTION="Ensure bootloader password is set"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
GRUB_CONFIG="/boot/grub/grub.cfg"
USERNAME_PATTERN="<username>" # Placeholder for expected username

# --- FUNGSI AUDIT BOOTLOADER PASSWORD ---
if [ ! -f "$GRUB_CONFIG" ]; then
    a_output2+=(" - GRUB configuration file ($GRUB_CONFIG) not found.")
else
    # 1. Cek 'set superusers'
    L_SUPERUSERS=$(grep "^set superusers" "$GRUB_CONFIG")
    if echo "$L_SUPERUSERS" | grep -q 'superusers="[^"]\+"'; then
        a_output+=(" - 'set superusers' is configured.")
        a_output+=(" - Output: $L_SUPERUSERS")
    else
        a_output2+=(" - 'set superusers' is missing or not configured correctly.")
    fi

    # 2. Cek 'password_pbkdf2'
    L_PASSWORD=$(awk -F. '/^\s*password/ {print $1"."$2"."$3}' "$GRUB_CONFIG")
    if echo "$L_PASSWORD" | grep -q 'password_pbkdf2'; then
        a_output+=(" - password_pbkdf2 is configured.")
        a_output+=(" - Output: $L_PASSWORD")
    else
        a_output2+=(" - password_pbkdf2 is missing.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ] && [ "${#a_output[@]}" -ge 2 ]; then # Harus ada set superusers DAN password
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO (Partial success): ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}