#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.7"
DESCRIPTION="Ensure no duplicate user names exist"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PASSWD_FILE="/etc/passwd"

# --- FUNGSI AUDIT DUPLICATE USERS ---
L_OUTPUT=""
# Cari nama user duplikat (kolom 1)
while read -r l_count l_user; do
    if [ "$l_count" -gt 1 ]; then
        # Jika ada duplikat, tampilkan nama user (yang seharusnya unik)
        L_USERS=$(awk -F: -v n="$l_user" '($1 == n) { print $1 }' "$PASSWD_FILE" 2>/dev/null | xargs)
        L_OUTPUT="${L_OUTPUT} Duplicate User: \"$l_user\" (Violation Count: $l_count) | "
    fi
done < <(cut -f1 -d":" "$PASSWD_FILE" | sort -n | uniq -c 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - No duplicate user names found in $PASSWD_FILE.")
else
    RESULT="FAIL"
    L_OUTPUT="${L_OUTPUT% | }"
    a_output2+=(" - Detected duplicate user names. Violations: $L_OUTPUT")
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