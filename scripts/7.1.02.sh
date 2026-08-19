#!/usr/bin/env bash

# --- ID dan Deskripsi ---
CHECK_ID="7.1.2"
DESCRIPTION="Ensure permissions on /etc/passwd- are configured (mode <= 644 owner:root:root)"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/passwd-"
EXPECTED_MODE=0644
EXPECTED_UID=0
EXPECTED_GID=0

# --- FUNGSI AUDIT ---
if [ ! -f "$TARGET_FILE" ]; then
    # File ini opsional di beberapa distro, tapi CIS Debian mewajibkannya jika ada
    a_output2+=(" - $TARGET_FILE is missing.")
    RESULT="FAIL"
else
    L_ACCESS_OCTAL=$(stat -c '%a' "$TARGET_FILE")
    L_UID=$(stat -c '%u' "$TARGET_FILE")
    L_GID=$(stat -c '%g' "$TARGET_FILE")
    L_STAT=$(stat -Lc 'Access: (%#a/%A) Uid: ( %u/ %U) Gid: ( %g/ %G)' "$TARGET_FILE")

    a_output+=(" - Current status: $L_STAT")

    # 1. Cek kepemilikan (UID & GID)
    if [ "$L_UID" -eq "$EXPECTED_UID" ] && [ "$L_GID" -eq "$EXPECTED_GID" ]; then
        a_output+=(" - Uid (0) and Gid (0) are correctly set to root.")
    else
        a_output2+=(" - Uid ($L_UID) and/or Gid ($L_GID) are not set to root:root.")
        RESULT="FAIL"
    fi

    # 2. Cek izin (644 atau lebih ketat)
    # Penjelasan: $((0$L_ACCESS_OCTAL)) memaksa Bash membaca input sebagai octal
    if [ "$((0$L_ACCESS_OCTAL))" -le "$((EXPECTED_MODE))" ]; then
        a_output+=(" - Access ($L_ACCESS_OCTAL) is correct (<= 644).")
    else
        a_output2+=(" - Access ($L_ACCESS_OCTAL) is less restrictive than 644.")
        RESULT="FAIL"
    fi
fi

# --- LOGIKA OUTPUT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

# Membersihkan spasi ganda atau karakter aneh
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
