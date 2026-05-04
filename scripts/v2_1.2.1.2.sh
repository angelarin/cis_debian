#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.2.1.2"
DESCRIPTION="Ensure weak dependencies are configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
RESULT="" NOTES=""

f_apt_dependencies_chk()
{
    # Mengambil konfigurasi apt untuk Install-Recommends dan Install-Suggests
    l_recommends="$(apt-config dump | grep 'APT::Install-Recommends')"
    l_suggests="$(apt-config dump | grep 'APT::Install-Suggests')"

    # 1. Periksa APT::Install-Recommends
    if [ -n "$l_recommends" ]; then
        if grep -q 'APT::Install-Recommends "0";' <<< "$l_recommends"; then
            a_output+=(" - APT::Install-Recommends is set to 0")
        else
            a_output2+=(" - APT::Install-Recommends is not 0 (found: $l_recommends)")
        fi
    else
        a_output2+=(" - APT::Install-Recommends is not configured (defaults to 1/Enabled)")
    fi

    # 2. Periksa APT::Install-Suggests
    if [ -n "$l_suggests" ]; then
        if grep -q 'APT::Install-Suggests "0";' <<< "$l_suggests"; then
            a_output+=(" - APT::Install-Suggests is set to 0")
        else
            a_output2+=(" - APT::Install-Suggests is not 0 (found: $l_suggests)")
        fi
    else
        a_output2+=(" - APT::Install-Suggests is not configured (defaults to 1/Enabled)")
    fi
}

# Jalankan pengecekan
f_apt_dependencies_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Weak dependencies are not properly disabled | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}