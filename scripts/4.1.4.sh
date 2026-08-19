#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 4.1.4"
DESCRIPTION="Ensure ufw outgoing default is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_ufw_default_outgoing_chk()
{
    # 1. Pastikan UFW terinstal agar perintah status bisa dijalankan
    if ! command -v ufw >/dev/null 2>&1; then
        a_output2+=(" - ufw command not found (prasyarat kontrol 4.1.1 tidak terpenuhi)")
        return
    fi

    # 2. Ambil baris default policy dari ufw status verbose
    # Output tipikal: Default: deny (incoming), allow (outgoing), disabled (routed)
    # Kita mengambil kolom ke-2 setelah pemisah koma
    l_ufw_status=$(ufw status verbose 2>/dev/null)
    l_default_out=$(echo "$l_ufw_status" | awk -F',' '$1~/Default/ {print $2}' | xargs)

    if [[ "$l_default_out" =~ ^(deny|reject) ]]; then
        a_output+=(" - Default outgoing policy is correctly set to: $l_default_out")
    else
        a_output2+=(" - Default outgoing policy is set to: ${l_default_out:-unknown} (expected: deny or reject)")
    fi
}

# Jalankan prosedur pengecekan
f_ufw_default_outgoing_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: UFW default outgoing policy is not restrictive (Level 2 requirement) | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Info: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}