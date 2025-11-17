#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.1"
DESCRIPTION="Ensure AppArmor and apparmor-utils are installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# --- FUNGSI AUDIT INSTALASI ---
PACKAGES=("apparmor" "apparmor-utils")

for pkg in "${PACKAGES[@]}"; do
    if dpkg-query -s "$pkg" &> /dev/null; then
        a_output+=(" - Package '$pkg' is installed.")
    else
        a_output2+=(" - Package '$pkg' is NOT installed.")
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}