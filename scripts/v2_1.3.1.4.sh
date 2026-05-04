#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.3.1.4"
DESCRIPTION="Ensure apparmor_restrict_unprivileged_unconfined is enabled"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_parameter_name="kernel.apparmor_restrict_unprivileged_unconfined"
l_grep="${l_parameter_name//./\\.}"
RESULT="" NOTES=""

# 1. Audit Running Configuration
l_running_val=$(sysctl -n "$l_parameter_name" 2>/dev/null)
if [ "$l_running_val" = "1" ]; then
    a_output+=(" - Running config: \"$l_parameter_name\" is set to \"1\"")
else
    a_output2+=(" - Running config: \"$l_parameter_name\" is set to \"${l_running_val:-NOT SET}\" (expected 1)")
fi

# 2. Audit Config Files (systemd-sysctl)
f_sysctl_file_chk()
{
    l_systemdsysctl="$(readlink -e /lib/systemd/systemd-sysctl || readlink -e /usr/lib/systemd/systemd-sysctl)"
    l_found_in_file=""
    
    # Mencari nilai di file konfigurasi (menggunakan logic dari CIS)
    while IFS= read -r l_file; do
        l_file="${l_file//# /}"
        l_opt="$(grep -Psoi '^\h*'"$l_grep"'\h*=\h*\H+\b' "$l_file" | tail -n 1)"
        l_option_value="$(cut -d= -f2 <<< "$l_opt" | xargs)"
        
        if [ -n "$l_option_value" ]; then
            if [ "$l_option_value" = "1" ]; then
                a_output+=(" - Config file: \"$l_parameter_name\" is set to \"1\" in \"$l_file\"")
                l_found_in_file="y"
            else
                a_output2+=(" - Config file: \"$l_parameter_name\" is set to \"$l_option_value\" in \"$l_file\" (expected 1)")
                l_found_in_file="error"
            fi
            # Berhenti setelah menemukan konfigurasi prioritas tertinggi
            break
        fi
    done < <("$l_systemdsysctl" --cat-config | tac | grep -Psoi '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    if [ -z "$l_found_in_file" ]; then
        a_output2+=(" - Config file: \"$l_parameter_name\" is not found in sysctl configuration")
    fi
}

# Jalankan pengecekan file
f_sysctl_file_chk

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Sysctl configuration issues found | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}