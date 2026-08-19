#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.6"
DESCRIPTION="Ensure sshd Ciphers are configured (no weak ciphers)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# Daftar weak ciphers yang dicek (case-insensitive)
WEAK_CIPHERS_REGEX='^ciphers\h+\"?([^#\n\r]+,)?((3des|blowfish|cast128|aes(128|192|256))-cbc|arcfour(128|256)?|rijndael-cbc@lysator\.liu\.se|chacha20-poly1305@openssh\.com)\b'

# Cek apakah konfigurasi ciphers mengandung weak ciphers
L_OUTPUT=$(sshd -T 2>/dev/null | grep -Pi -- "$WEAK_CIPHERS_REGEX")

# 1. Cek keberadaan weak ciphers
if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=(" - No explicitly configured weak ciphers (3des-cbc, *cbc, etc.) detected.")
else
    RESULT="FAIL"
    a_output2+=(" - Detected WEAK/DEPRECATED ciphers being explicitly configured: $L_OUTPUT")
    
    # Peringatan khusus untuk CVE-2023-48795 jika terdeteksi
    if echo "$L_OUTPUT" | grep -Piq "chacha20-poly1305@openssh\.com"; then
        a_output2+=(" - WARNING: chacha20-poly1305@openssh.com detected. Review CVE-2023-48795 and ensure system is patched.")
    fi
fi

# 2. Cek apakah ada konfigurasi Ciphers sama sekali (jika PASS)
if [ "$RESULT" = "PASS" ]; then
    L_ALL_CIPHERS=$(sshd -T 2>/dev/null | grep -Pi -- '^ciphers\h+')
    if [ -z "$L_ALL_CIPHERS" ]; then
        a_output+=(" - WARNING: 'Ciphers' directive is NOT explicitly set; system relies on OpenSSH defaults, which may include deprecated ciphers in older versions.")
        RESULT="REVIEW" # Set ke REVIEW karena bergantung pada versi OpenSSH
    else
        a_output+=(" - Ciphers directive is explicitly set and appears secure. Current setting: $L_ALL_CIPHERS")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    if [ "$RESULT" = "PASS" ]; then
        NOTES+="PASS: ${a_output[*]}"
    else
        NOTES+="REVIEW: ${a_output[*]}"
    fi
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
    RESULT="FAIL"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}