#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.2.1.1"
DESCRIPTION="Ensure systemd-journal-remote is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGE="systemd-journal-remote"

# --- FUNGSI AUDIT INSTALASI ---
if dpkg-query -s "$PACKAGE" &> /dev/null; then
    RESULT="PASS"
    a_output+=(" - Package '$PACKAGE' is installed.")
else
    RESULT="FAIL"
    a_output2+=(" - Package '$PACKAGE' is NOT installed.")
    a_output2+=(" - NOTE: Installation is only required if this system acts as a remote log server or if log upload dependencies exist.")
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