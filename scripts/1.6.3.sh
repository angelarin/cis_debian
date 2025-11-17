#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.6.3"
DESCRIPTION="Ensure remote login warning banner is configured properly"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/issue.net"

# Dapatkan ID OS untuk pengecualian
OS_ID=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | sed -e 's/"//g')
# Escape sequences yang dilarang
BANNED_SEQUENCES="(\\\v|\\\r|\\\m|\\\s|${OS_ID})"
# Perintah grep yang dicontohkan
L_OUTPUT_GREP=$(grep -E -i "$BANNED_SEQUENCES" "$TARGET_FILE" 2>/dev/null)

if [ -f "$TARGET_FILE" ]; then
    L_CONTENT=$(cat "$TARGET_FILE")
    a_output+=(" - Contents of $TARGET_FILE: ${L_CONTENT//[$'\n']/\n}")
else
    a_output2+=(" - $TARGET_FILE does not exist.")
fi

if [ -z "$L_OUTPUT_GREP" ]; then
    a_output+=(" - $TARGET_FILE does not contain banned escape sequences or OS ID.")
else
    RESULT="FAIL"
    a_output2+=(" - $TARGET_FILE contains banned escape sequences or OS ID. Offending output: $L_OUTPUT_GREP")
fi

# Audit kontent harus dilakukan manual, status diubah menjadi REVIEW
NOTES+="INFO: Content collected. | Action: REVIEW content against site policy. "

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "PASS" ] && [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: No banned sequences found. ${a_output[*]}"
    RESULT="PASS"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
    RESULT="FAIL"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}