#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.5.7"
DESCRIPTION="Ensure Automatic Error Reporting is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_apport_chk()
{
    # 1. Periksa apakah paket apport terpasang
    if dpkg-query -s apport &>/dev/null; then
        
        # 2. Jika terpasang, periksa apakah 'enabled' di /etc/default/apport bukan 0
        if grep -Psiq -- '^\h*enabled\h*=\h*[^0]\b' /etc/default/apport 2>/dev/null; then
            a_output2+=(" - Apport is enabled in /etc/default/apport")
        else
            a_output+=(" - Apport is disabled in /etc/default/apport")
        fi

        # 3. Periksa apakah layanan apport sedang aktif
        if systemctl is-active apport.service 2>/dev/null | grep -q '^active'; then
            a_output2+=(" - Apport service is active")
        else
            a_output+=(" - Apport service is not active")
        fi
    else
        # Jika paket tidak terpasang, otomatis memenuhi kriteria keamanan
        a_output+=(" - Apport package is not installed")
    fi
}

# Jalankan pengecekan
f_apport_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Automatic Error Reporting (Apport) is enabled/active | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}