#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.4.1.1"
DESCRIPTION="Ensure iptables packages are installed"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PACKAGES=("iptables" "iptables-persistent")
INSTALL_FAIL=0

# --- FUNGSI AUDIT INSTALASI ---
for pkg in "${PACKAGES[@]}"; do
    if dpkg-query -s "$pkg" &> /dev/null; then
        a_output+=(" - Package '$pkg' is installed.")
    else
        a_output2+=(" - Package '$pkg' is NOT installed.")
        INSTALL_FAIL=1
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$INSTALL_FAIL" -eq 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}