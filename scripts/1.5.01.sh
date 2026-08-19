#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.5.1"
DESCRIPTION="Ensure fs.protected_hardlinks is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() a_files=()
l_parameter_name="fs.protected_hardlinks"
l_grep="${l_parameter_name//./(\\.|\\/)}"
RESULT="" NOTES=""

f_sysctl_chk()
{
    # 1. Audit Running Configuration
    l_running_val=$(sysctl -n "$l_parameter_name" 2>/dev/null)
    if [ "$l_running_val" = "1" ]; then
        a_output+=(" - Running config: \"$l_parameter_name\" is set to \"1\"")
    else
        a_output2+=(" - Running config: \"$l_parameter_name\" is set to \"${l_running_val:-NOT SET}\" (expected 1)")
    fi

    # 2. Audit Configuration Files
    l_systemdsysctl="$(readlink -e /lib/systemd/systemd-sysctl || readlink -e /usr/lib/systemd/systemd-sysctl)"
    
    # Cek file UFW jika ada
    l_ufw_file="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
    if [ -f "$(readlink -e "$l_ufw_file")" ]; then
        a_files+=("$(readlink -e "$l_ufw_file")")
    fi
    
    # Tambahkan sysctl.conf utama
    [ -f "/etc/sysctl.conf" ] && a_files+=("/etc/sysctl.conf")

    # Cari semua file .conf yang dibaca oleh systemd-sysctl (prioritas berdasarkan tac)
    while IFS= read -r l_fname; do
        l_file="$(readlink -e "${l_fname//# /}")"
        if [ -n "$l_file" ] && ! grep -Psiq -- '(^|\h+)'"$l_file"'\b' <<< "${a_files[*]}"; then
            a_files+=("$l_file")
        fi
    done < <("$l_systemdsysctl" --cat-config | tac | grep -Psio -- '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    l_found_correct_file="n"
    # Loop untuk memeriksa setiap file
    for l_file in "${a_files[@]}"; do
        l_opt="$(grep -Psoi '^\h*'"$l_grep"'\h*=\h*\H+\b' "$l_file" | tail -n 1)"
        l_option_value="$(cut -d= -f2 <<< "$l_opt" | xargs)"
        
        if [ -n "$l_option_value" ]; then
            if [ "$l_option_value" = "1" ]; then
                a_output+=(" - Config file: \"$l_parameter_name = $l_option_value\" in \"$l_file\"")
                l_found_correct_file="y"
                # Berhenti setelah menemukan konfigurasi prioritas tertinggi
                break
            else
                a_output2+=(" - Config file: \"$l_parameter_name = $l_option_value\" in \"$l_file\" (expected 1)")
                l_found_correct_file="error"
                break
            fi
        fi
    done

    if [ "$l_found_correct_file" = "n" ]; then
        a_output2+=(" - Config file: \"$l_parameter_name\" is not explicitly set in any sysctl configuration file")
    fi
}

# Jalankan pengecekan
f_sysctl_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Sysctl hardlink protection issues found | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}