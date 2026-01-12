#!/usr/bin/env bash

# --- ID dan Deskripsi ---
CHECK_ID="7.1.10"
DESCRIPTION="Ensure permissions on /etc/security/opasswd and opasswd.old are configured (mode <= 600 owner:root:root)"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=(" /etc/security/opasswd" "/etc/security/opasswd.old")
EXPECTED_MODE=0600
EXPECTED_UID=0
EXPECTED_GID=0

# --- FUNGSI AUDIT ---
for TARGET_FILE in "${TARGET_FILES[@]}"; do
    # Membersihkan spasi jika ada di awal/akhir nama file
    TARGET_FILE=$(echo "$TARGET_FILE" | xargs)
    
    if [ -e "$TARGET_FILE" ]; then
        L_ACCESS_OCTAL=$(stat -c '%a' "$TARGET_FILE")
        L_UID=$(stat -c '%u' "$TARGET_FILE")
        L_GID=$(stat -c '%g' "$TARGET_FILE")
        L_STAT=$(stat -Lc 'Access: (%#a/%A) Uid: ( %u/ %U) Gid: ( %g/ %G)' "$TARGET_FILE")

        a_output+=(" - $TARGET_FILE: $L_STAT")

        # 1. Cek kepemilikan (UID & GID)
        if [ "$L_UID" -eq "$EXPECTED_UID" ] && [ "$L_GID" -eq "$EXPECTED_GID" ]; then
            a_output+=(" - $TARGET_FILE: Uid/Gid correctly set to root:root.")
        else
            a_output2+=(" - $TARGET_FILE: Uid ($L_UID) and/or Gid ($L_GID) are not root:root.")
            RESULT="FAIL"
        fi

        # 2. Cek izin (600 atau lebih ketat)
        # $((0$VAR)) memastikan Bash memperlakukan nilai sebagai Oktal
        if [ "$((0$L_ACCESS_OCTAL))" -le "$((EXPECTED_MODE))" ]; then
            a_output+=(" - $TARGET_FILE: Access ($L_ACCESS_OCTAL) is correct.")
        else
            a_output2+=(" - $TARGET_FILE: Access ($L_ACCESS_OCTAL) is less restrictive than 0600.")
            RESULT="FAIL"
        fi
    else
        a_output+=(" - $TARGET_FILE does not exist (Acceptable).")
    fi
done

# --- LOGIKA OUTPUT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
