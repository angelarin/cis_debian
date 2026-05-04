#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.1.3"
DESCRIPTION="Ensure ufw incoming default is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_ufw_default_incoming_chk()
{
    # 1. Pastikan UFW terinstal agar perintah status bisa dijalankan
    if ! command -v ufw >/dev/null 2>&1; then
        a_output2+=(" - ufw command not found (prasyarat kontrol 4.1.1 tidak terpenuhi)")
        return
    fi

    # 2. Ambil baris default policy dari ufw status verbose
    # Format output biasanya: Default: deny (incoming), allow (outgoing), disabled (routed)
    l_ufw_status=$(ufw status verbose 2>/dev/null)
    l_default_in=$(echo "$l_ufw_status" | awk -F',' '$1~/Default/ {print $1}' | awk '{print $2}')

    if [[ "$l_default_in" =~ ^(deny|reject)$ ]]; then
        a_output+=(" - Default incoming policy is correctly set to: $l_default_in")
    else
        a_output2+=(" - Default incoming policy is set to: ${l_default_in:-unknown} (expected: deny or reject)")
    fi
}

# Jalankan prosedur pengecekan
f_ufw_default_incoming_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: UFW default incoming policy is not restrictive | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}