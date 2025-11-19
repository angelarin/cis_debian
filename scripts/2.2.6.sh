#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.2.6"
DESCRIPTION="Ensure ftp client is not installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT INSTALASI ---
# Menggunakan dpkg-query -l dan grep karena mencakup beberapa nama paket
if dpkg-query -l | grep -E 'ftp|tnftp' &> /dev/null; then
    RESULT="FAIL"
    L_PACKAGES=$(dpkg-query -l | grep -E 'ftp|tnftp' | awk '{print $2}')
    a_output2+=(" - One or more FTP client packages are currently installed: $L_PACKAGES")
else
    RESULT="PASS"
    a_output+=(" - No FTP client packages detected.")
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