#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.6.6"
DESCRIPTION="Ensure access to /etc/issue.net is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/issue.net"
EXPECTED_MODE=0644

# --- FUNGSI AUDIT FILE PERMISSIONS ---
if [ ! -f "$TARGET_FILE" ]; then
    RESULT="FAIL"
    a_output2+=(" - $TARGET_FILE is missing.")
else
    # Ambil stat data
    L_ACCESS_OCTAL=$(stat -c '%a' "$TARGET_FILE")
    L_UID=$(stat -c '%u' "$TARGET_FILE")
    L_GID=$(stat -c '%g' "$TARGET_FILE")
    L_STAT=$(stat -Lc 'Access: (%#a/%A) Uid: ( %u/ %U) Gid: ( %g/ %G)' "$TARGET_FILE")

    a_output+=(" - Current status: $L_STAT")

    # 1. Cek kepemilikan (UID & GID)
    if [ "$L_UID" -eq 0 ] && [ "$L_GID" -eq 0 ]; then
        a_output+=(" - Uid (0) and Gid (0) are correctly set to root.")
    else
        a_output2+=(" - Uid ($L_UID) and/or Gid ($L_GID) are not set to 0 (root).")
    fi

    # 2. Cek izin (0644 atau lebih ketat)
    if [ "$L_ACCESS_OCTAL" -le "$EXPECTED_MODE" ]; then
        a_output+=(" - Access ($L_ACCESS_OCTAL) is set to $EXPECTED_MODE or more restrictive.")
    else
        a_output2+=(" - Access ($L_ACCESS_OCTAL) is less restrictive than $EXPECTED_MODE.")
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