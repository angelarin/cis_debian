#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.2"
DESCRIPTION="Ensure root is the only GID 0 account (primary GID)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PASSWD_FILE="/etc/passwd"
EXPECTED_USER="root"
EXCLUDED_USERS="sync|shutdown|halt|operator"

# --- FUNGSI AUDIT PRIMARY GID 0 ---
# Mencari user dengan GID 0, mengecualikan user yang disebutkan dalam Note.
L_OUTPUT=$(awk -F: '($1 !~ /^(sync|shutdown|halt|operator)/ && $4=="0") {print $1}' "$PASSWD_FILE" 2>/dev/null)
L_COUNT=$(echo "$L_OUTPUT" | wc -l)

if [ "$L_COUNT" -eq 1 ] && [ "$L_OUTPUT" = "$EXPECTED_USER" ]; then
    a_output+=(" - Only user '$EXPECTED_USER' has primary GID 0 (after excluding system users).")
else
    RESULT="FAIL"
    a_output2+=(" - Multiple accounts or non-root accounts found with primary GID 0.")
    a_output2+=(" - Detected primary GID 0 users: $L_OUTPUT")
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