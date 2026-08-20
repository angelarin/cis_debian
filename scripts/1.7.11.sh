#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.7.11"
DESCRIPTION="Ensure Xwayland is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
# Debian biasanya menggunakan /etc/gdm3/custom.conf, namun kita cek sesuai prompt
# --- 0. CEK APAKAH GDM TERINSTALL ---
if ! dpkg-query -s gdm3 &>/dev/null && ! dpkg-query -s gdm &>/dev/null; then
    RESULT="PASS"
    NOTES="PASS: GDM is not installed on the system (Not Applicable)."
    echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
    exit 0
fi

l_conf_file="/etc/gdm3/custom.conf"
[ ! -f "$l_conf_file" ] && l_conf_file="/etc/gdm/custom.conf"

RESULT="" NOTES=""

f_xwayland_chk()
{
    if [ -f "$l_conf_file" ]; then
        # Mengambil blok [daemon] dan mencari pengaturan WaylandEnable
        # Sesuai audit: Harus ada 'WaylandEnable=false'
        l_wayland_status=$(sed -n '/\[daemon\]/,/\[/p' "$l_conf_file" | grep -Psi '^\h*WaylandEnable\h*=\h*false\b')

        if [ -n "$l_wayland_status" ]; then
            a_output+=(" - Wayland is disabled in \"$l_conf_file\": $l_wayland_status")
        else
            # Cek apakah baris tersebut ada tapi nilainya bukan false
            l_wrong_val=$(sed -n '/\[daemon\]/,/\[/p' "$l_conf_file" | grep -Psi '^\h*WaylandEnable\b')
            if [ -n "$l_wrong_val" ]; then
                a_output2+=(" - Wayland is not explicitly disabled: \"$l_wrong_val\"")
            else
                a_output2+=(" - WaylandEnable=false is not found in the [daemon] block of \"$l_conf_file\"")
            fi
        fi
    else
        # Jika GDM tidak terpasang, audit ini seringkali dianggap PASS 
        # karena risiko Xwayland hanya ada jika ada display manager yang mendukungnya.
        if ! dpkg-query -s gdm3 &>/dev/null; then
            a_output+=(" - GDM is not installed, Xwayland risk is not applicable")
        else
            a_output2+=(" - GDM is installed but configuration file \"$l_conf_file\" was not found")
        fi
    fi
}

# Jalankan pengecekan
f_xwayland_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Xwayland/Wayland configuration issues found | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}