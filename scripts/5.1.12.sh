#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.12"
DESCRIPTION="Ensure sshd KexAlgorithms is configured (no weak algorithms)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# Daftar weak algorithms yang dicek (case-insensitive)
WEAK_KEX_REGEX='kexalgorithms\h+([^#\n\r]+,)?(diffie-hellman-group1-sha1|diffie-hellman-group14-sha1|diffie-hellman-group-exchange-sha1)\b'
WEAK_ALGORITHMS="diffie-hellman-group1-sha1, diffie-hellman-group14-sha1, diffie-hellman-group-exchange-sha1"

# Cek apakah konfigurasi KexAlgorithms mengandung weak algorithms
L_OUTPUT=$(sshd -T 2>/dev/null | grep -Pi -- "$WEAK_KEX_REGEX")
L_ALL_KEX=$(sshd -T 2>/dev/null | grep -Pi -- '^kexalgorithms\h+')

# 1. Cek keberadaan weak algorithms
if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=(" - No explicitly configured weak Key Exchange Algorithms detected.")
else
    RESULT="FAIL"
    a_output2+=(" - Detected WEAK/DEPRECATED Key Exchange Algorithms being explicitly configured: $L_OUTPUT")
    a_output2+=(" - The following algorithms should be removed: $WEAK_ALGORITHMS")
fi

# 2. Cek apakah ada konfigurasi KexAlgorithms sama sekali (jika PASS)
if [ -n "$L_ALL_KEX" ]; then
    a_output+=(" - KexAlgorithms directive is explicitly set. Current setting: $L_ALL_KEX")
else
    a_output+=(" - KexAlgorithms directive is NOT explicitly set; system relies on OpenSSH defaults.")
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