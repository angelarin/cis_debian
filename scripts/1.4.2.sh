#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.4.2"
DESCRIPTION="Ensure access to bootloader config is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
GRUB_CONFIG="/boot/grub/grub.cfg"
EXPECTED_MODE=0600

# --- FUNGSI AUDIT FILE PERMISSIONS ---
if [ ! -f "$GRUB_CONFIG" ]; then
    a_output2+=(" - GRUB configuration file ($GRUB_CONFIG) not found.")
else
    # Ambil stat data
    L_STAT=$(stat -Lc 'Access: (%#a) Uid: ( %u) Gid: ( %g)' "$GRUB_CONFIG")
    L_ACCESS=$(stat -c '%a' "$GRUB_CONFIG")
    L_UID=$(stat -c '%u' "$GRUB_CONFIG")
    L_GID=$(stat -c '%g' "$GRUB_CONFIG")

    a_output+=(" - Current status: $L_STAT")

    # 1. Cek kepemilikan (UID & GID)
    if [ "$L_UID" -eq 0 ] && [ "$L_GID" -eq 0 ]; then
        a_output+=(" - Uid (0) and Gid (0) are correctly set to root.")
    else
        a_output2+=(" - Uid ($L_UID) and/or Gid ($L_GID) are not set to 0 (root).")
    fi

    # 2. Cek izin (0600 atau lebih ketat)
    # Cek apakah izin kurang dari atau sama dengan 0600 (lebih ketat atau sama)
    if [ "$(printf "%o" "$L_ACCESS")" -le "$EXPECTED_MODE" ]; then
        a_output+=(" - Access ($L_ACCESS) is set to $EXPECTED_MODE or more restrictive.")
    else
        a_output2+=(" - Access ($L_ACCESS) is less restrictive than $EXPECTED_MODE.")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
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