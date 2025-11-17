#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.7.2"
DESCRIPTION="Ensure nodev option set on /var/log/audit partition (Automated)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
TARGET="/var/log/audit"
OPTION="nodev"

# --- FUNGSI AUDIT MOUNT OPTION ---
L_OUTPUT=$(findmnt -kn $TARGET | grep -v "$OPTION")

if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("$TARGET mount options correctly include '$OPTION'.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("$TARGET is mounted WITHOUT the '$OPTION' option. Findmnt output: $L_OUTPUT")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}