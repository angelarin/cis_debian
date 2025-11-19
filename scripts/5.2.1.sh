#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.1"
DESCRIPTION="Ensure sudo is installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
PACKAGES=("sudo" "sudo-ldap")
INSTALLED_COUNT=0

# --- FUNGSI AUDIT INSTALASI ---
for pkg in "${PACKAGES[@]}"; do
    if dpkg-query -s "$pkg" &> /dev/null; then
        a_output+=(" - Package '$pkg' is installed.")
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$INSTALLED_COUNT" -gt 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=(" - Neither 'sudo' nor 'sudo-ldap' packages are installed.")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}