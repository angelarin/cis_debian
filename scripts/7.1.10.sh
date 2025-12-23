#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.10"
DESCRIPTION="Ensure permissions on /etc/security/opasswd are configured (mode <= 600 owner:root:root)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=("/etc/security/opasswd" "/etc/security/opasswd.old")
EXPECTED_MODE=0600
EXPECTED_UID=0
EXPECTED_GID=0

# --- FUNGSI AUDIT FILE PERMISSIONS ---
for TARGET_FILE in "${TARGET_FILES[@]}"; do
    if [ -e "$TARGET_FILE" ]; then
        L_ACCESS_OCTAL=$(stat -c '%a' "$TARGET_FILE")
        L_UID=$(stat -c '%u' "$TARGET_FILE")
        L_GID=$(stat -c '%g' "$TARGET_FILE")
        L_STAT=$(stat -Lc 'Access: (%#a/%A) Uid: ( %u/ %U) Gid: ( %g/ %G)' "$TARGET_FILE")

        a_output+=(" - Status for $TARGET_FILE: $L_STAT")

        # 1. Cek kepemilikan (UID & GID)
        if [ "$L_UID" -eq "$EXPECTED_UID" ] && [ "$L_GID" -eq "$EXPECTED_GID" ]; then
            a_output+=(" - $TARGET_FILE: Uid (0) and Gid (0) are correctly set to root.")
        else
            a_output2+=(" - $TARGET_FILE: Uid ($L_UID) and/or Gid ($L_GID) are not set to root:root.")
            RESULT="FAIL"
        fi

        # 2. Cek izin (600 atau lebih ketat)
        if [ "$(printf "%o" "$L_ACCESS_OCTAL")" -le "$EXPECTED_MODE" ]; then
            a_output+=(" - $TARGET_FILE: Access ($L_ACCESS_OCTAL) is set to $EXPECTED_MODE or more restrictive.")
        else
            a_output2+=(" - $TARGET_FILE: Access ($L_ACCESS_OCTAL) is less restrictive than $EXPECTED_MODE.")
            RESULT="FAIL"
        fi
    else
        a_output+=(" - $TARGET_FILE does not exist. (Acceptable if feature is not used or backup is deleted)")
    fi
done

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