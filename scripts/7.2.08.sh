#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.8"
DESCRIPTION="Ensure no duplicate group names exist"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
GROUP_FILE="/etc/group"

# --- FUNGSI AUDIT DUPLICATE GROUPS ---
L_OUTPUT=""
# Cari nama grup duplikat (kolom 1)
while read -r l_count l_group; do
    if [ "$l_count" -gt 1 ]; then
        # Jika ada duplikat, tampilkan nama grup (yang seharusnya unik)
        L_GROUPS=$(awk -F: -v n="$l_group" '($1 == n) { print $1 }' "$GROUP_FILE" 2>/dev/null | xargs)
        L_OUTPUT="${L_OUTPUT} Duplicate Group: \"$l_group\" (Violation Count: $l_count) | "
    fi
done < <(cut -f1 -d":" "$GROUP_FILE" | sort -n | uniq -c 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - No duplicate group names found in $GROUP_FILE.")
else
    RESULT="FAIL"
    L_OUTPUT="${L_OUTPUT% | }"
    a_output2+=(" - Detected duplicate group names. Violations: $L_OUTPUT")
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