#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.1"
DESCRIPTION="Ensure root is the only UID 0 account"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PASSWD_FILE="/etc/passwd"
EXPECTED_USER="root"

# --- FUNGSI AUDIT UID 0 ---
L_OUTPUT=$(awk -F: '($3 == 0) { print $1 }' "$PASSWD_FILE" 2>/dev/null)
L_COUNT=$(echo "$L_OUTPUT" | wc -l)
L_NON_ROOT_USERS=$(echo "$L_OUTPUT" | grep -v "^$EXPECTED_USER$" | tr '\n' ' ')

if [ "$L_COUNT" -eq 1 ] && [ "$L_OUTPUT" = "$EXPECTED_USER" ]; then
    a_output+=(" - Only user '$EXPECTED_USER' has UID 0 (PASS).")
else
    RESULT="FAIL"
    a_output2+=(" - Multiple accounts or non-root accounts found with UID 0.")
    a_output2+=(" - Detected UID 0 users: $L_OUTPUT")
    [ -n "$L_NON_ROOT_USERS" ] && a_output2+=(" - Non-root users with UID 0: $L_NON_ROOT_USERS")
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