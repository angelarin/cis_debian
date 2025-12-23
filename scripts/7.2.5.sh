#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.5"
DESCRIPTION="Ensure no duplicate UIDs exist"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PASSWD_FILE="/etc/passwd"

# --- FUNGSI AUDIT DUPLICATE UIDS ---
L_OUTPUT=""
# Cari UID duplikat (kolom 3)
while read -r l_count l_uid; do
    if [ "$l_count" -gt 1 ]; then
        # Jika ada duplikat, cari nama user yang terkait
        L_USERS=$(awk -F: -v n="$l_uid" '($3 == n) { print $1 }' "$PASSWD_FILE" | xargs)
        L_OUTPUT="${L_OUTPUT} Duplicate UID: \"$l_uid\" Users: \"$L_USERS\" | "
    fi
done < <(cut -f3 -d":" "$PASSWD_FILE" | sort -n | uniq -c 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - No duplicate UIDs found in $PASSWD_FILE.")
else
    RESULT="FAIL"
    # Hapus trailing separator
    L_OUTPUT="${L_OUTPUT% | }"
    a_output2+=(" - Detected duplicate UIDs. Violations: $L_OUTPUT")
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