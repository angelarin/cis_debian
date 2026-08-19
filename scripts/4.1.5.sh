#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="4.1.5"
DESCRIPTION="Ensure ufw routed default is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_ufw_default_routed_chk()
{
    # 1. Pastikan UFW terinstal agar perintah status bisa dijalankan
    if ! command -v ufw >/dev/null 2>&1; then
        a_output2+=(" - ufw command not found (prasyarat UFW tidak terpenuhi)")
        return
    fi

    # 2. Ambil baris default policy dari ufw status verbose
    # Format output biasanya: Default: deny (incoming), allow (outgoing), disabled (routed)
    l_ufw_status=$(ufw status verbose 2>/dev/null)
    
    # Ekstrak kata sebelum "(routed)" dari baris yang diawali dengan "Default:"
    l_default_routed=$(echo "$l_ufw_status" | grep "^Default:" | grep -o '[a-z]* (routed)' | awk '{print $1}')

    if [[ -z "$l_default_routed" ]]; then
        a_output2+=(" - Default routed policy not found (kemungkinan UFW dalam status inactive)")
    elif [[ "$l_default_routed" =~ ^(deny|reject|disabled)$ ]]; then
        a_output+=(" - Default routed policy is correctly set to: $l_default_routed")
    else
        a_output2+=(" - Default routed policy is set to: $l_default_routed (expected: disabled or deny)")
    fi
}

# Jalankan prosedur pengecekan
f_ufw_default_routed_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: UFW default routed policy is not restrictive | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}