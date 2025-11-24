#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.3.3.4.3"
DESCRIPTION="Ensure pam_unix includes a strong password hashing algorithm (sha512 or yescrypt)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PAM_FILE="/etc/pam.d/common-password"
STRONG_HASH_REGEX='(sha512|yescrypt)'

# --- FUNGSI AUDIT STRONG HASH ---
L_OUTPUT=$(grep -PH -- '^\h*password\h+([^#\n\r]+)\h+pam_unix\.so\h+([^#\n\r]+\h+)?(sha512|yescrypt)\b' "$PAM_FILE" 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    a_output+=(" - pam_unix.so includes a strong hashing algorithm ($STRONG_HASH_REGEX).")
    a_output+=(" - Detected line: $L_OUTPUT")
else
    RESULT="FAIL"
    a_output2+=(" - pam_unix.so line in $PAM_FILE does NOT explicitly include sha512 or yescrypt.")
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