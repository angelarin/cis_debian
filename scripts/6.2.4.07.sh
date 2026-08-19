#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.7"
DESCRIPTION="Ensure audit configuration files group owner is configured (group: root)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
EXPECTED_GROUP="root"

# --- FUNGSI AUDIT GROUP OWNER CONFIG FILES ---
# Mencari file .conf dan .rules di /etc/audit/ yang TIDAK dimiliki oleh grup root
L_OUTPUT=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \) ! -group "$EXPECTED_GROUP" 2>/dev/null)

if [ -z "$L_OUTPUT" ]; then
    a_output+=(" - All audit configuration files are owned by group '$EXPECTED_GROUP'.")
else
    RESULT="FAIL"
    # Menampilkan file yang melanggar dan grupnya
    L_VIOLATIONS=$(while IFS= read -r l_file; do echo -n "File: $l_file (Group: $(stat -Lc '%G' "$l_file")) | "; done <<< "$L_OUTPUT")
    a_output2+=(" - Detected file(s) NOT owned by group '$EXPECTED_GROUP'. Violations: $L_VIOLATIONS")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}