#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.6"
DESCRIPTION="Ensure no duplicate GIDs exist"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
GROUP_FILE="/etc/group"

# --- FUNGSI AUDIT DUPLICATE GIDS ---
L_OUTPUT=""
# Cari GID duplikat (kolom 3)
while read -r l_count l_gid; do
    if [ "$l_count" -gt 1 ]; then
        # Jika ada duplikat, cari nama grup yang terkait
        L_GROUPS=$(awk -F: -v n="$l_gid" '($3 == n) { print $1 }' "$GROUP_FILE" 2>/dev/null | xargs)
        L_OUTPUT="${L_OUTPUT} Duplicate GID: \"$l_gid\" Groups: \"$L_GROUPS\" | "
    fi
done < <(cut -f3 -d":" "$GROUP_FILE" | sort -n | uniq -c 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - No duplicate GIDs found in $GROUP_FILE.")
else
    RESULT="FAIL"
    L_OUTPUT="${L_OUTPUT% | }"
    a_output2+=(" - Detected duplicate GIDs. Violations: $L_OUTPUT")
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