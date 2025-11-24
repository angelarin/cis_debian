#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.3.1"
DESCRIPTION="Ensure nologin is not listed in /etc/shells"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/shells"
UNEXPECTED_SHELL="/nologin"

# --- FUNGSI AUDIT NOLOGIN ---
# Mencari baris yang mengandung /nologin dan tidak diawali dengan komentar (#)
L_OUTPUT=$(grep -Ps '^\h*([^#\n\r]+)?\/nologin\b' "$TARGET_FILE" 2>/dev/null)

if [ -n "$L_OUTPUT" ]; then
    RESULT="FAIL"
    a_output2+=(" - Detected '$UNEXPECTED_SHELL' listed as a valid shell in $TARGET_FILE. Offending lines: ${L_OUTPUT//$'\n'/ | }")
else
    a_output+=(" - $UNEXPECTED_SHELL is NOT listed as a valid shell in $TARGET_FILE.")
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