#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.8"
DESCRIPTION="Ensure permissions on /etc/gshadow- are configured (mode <= 640, owner:root, group:root|shadow)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/gshadow-"
EXPECTED_MODE=0640
EXPECTED_UID=0
EXPECTED_GROUPS=("root" "shadow")

# --- FUNGSI AUDIT FILE PERMISSIONS ---
if [ ! -f "$TARGET_FILE" ]; then
    a_output2+=(" - $TARGET_FILE is missing.")
    RESULT="FAIL"
else
    L_ACCESS_OCTAL=$(stat -c '%a' "$TARGET_FILE")
    L_UID=$(stat -c '%u' "$TARGET_FILE")
    L_GROUP=$(stat -c '%G' "$TARGET_FILE")
    L_STAT=$(stat -Lc 'Access: (%#a/%A) Uid: ( %u/ %U) Gid: ( %g/ %G)' "$TARGET_FILE")

    a_output+=(" - Current status: $L_STAT")
    
    # 1. Cek kepemilikan (UID)
    if [ "$L_UID" -eq "$EXPECTED_UID" ]; then
        a_output+=(" - Uid (0) is correctly set to root.")
    else
        a_output2+=(" - Uid ($L_UID) is not set to root.")
        RESULT="FAIL"
    fi

    # 2. Cek grup pemilik (GID)
    local group_match=0
    for g in "${EXPECTED_GROUPS[@]}"; do
        if [ "$L_GROUP" = "$g" ]; then
            group_match=1
            break
        fi
    done
    if [ "$group_match" -eq 1 ]; then
        a_output+=(" - Group ($L_GROUP) is correctly set to root or shadow.")
    else
        a_output2+=(" - Group ($L_GROUP) is not set to root or shadow.")
        RESULT="FAIL"
    fi

    # 3. Cek izin (640 atau lebih ketat)
    if [ "$(printf "%o" "$L_ACCESS_OCTAL")" -le "$EXPECTED_MODE" ]; then
        a_output+=(" - Access ($L_ACCESS_OCTAL) is set to $EXPECTED_MODE or more restrictive.")
    else
        a_output2+=(" - Access ($L_ACCESS_OCTAL) is less restrictive than $EXPECTED_MODE.")
        RESULT="FAIL"
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