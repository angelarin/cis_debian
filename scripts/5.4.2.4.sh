#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.4"
DESCRIPTION="Ensure root account access is controlled (Password set or locked)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_USER="root"
ALLOWED_STATUSES=("P" "L")

# --- FUNGSI AUDIT PASSWD STATUS ---
L_OUTPUT=$(passwd -S "$TARGET_USER" 2>/dev/null | awk '$2 ~ /^(P|L)/ {print $2}')
L_FULL_OUTPUT=$(passwd -S "$TARGET_USER" 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Root account status is neither 'P' (Password set) nor 'L' (Locked).")
    a_output2+=(" - Detected status: $(echo "$L_FULL_OUTPUT" | awk '{print $2}')")
elif [[ " ${ALLOWED_STATUSES[*]} " =~ " ${L_OUTPUT} " ]]; then
    a_output+=(" - Root account password status is compliant: $L_OUTPUT.")
    a_output+=(" - Full status: $L_FULL_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - Root account password status is non-compliant: $L_OUTPUT (Expected: P or L).")
    a_output+=(" - Full status: $L_FULL_OUTPUT")
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