#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="v2 1.5.3"
DESCRIPTION="Ensure kernel.yama.ptrace_scope is configured"
# -----------------------------------------------------

{
a_output=() a_output2=()
l_parameter_name="kernel.yama.ptrace_scope"
l_grep="${l_parameter_name//./\\.}"
RESULT="" NOTES=""

# 1. Audit Running Configuration
l_running_val=$(sysctl -n "$l_parameter_name" 2>/dev/null)
if [[ "$l_running_val" =~ ^[1-3]$ ]]; then
    a_output+=(" - Running config: \"$l_parameter_name\" is set to \"$l_running_val\"")
else
    a_output2+=(" - Running config: \"$l_parameter_name\" is set to \"${l_running_val:-NOT SET}\" (expected 1, 2, or 3)")
fi

# 2. Audit Configuration Files (Persistence)
f_sysctl_file_chk()
{
    l_systemdsysctl="$(readlink -e /lib/systemd/systemd-sysctl || readlink -e /usr/lib/systemd/systemd-sysctl)"
    l_found_in_file=""

    # Cek file UFW jika ada
    l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw | xargs)"
    
    # Gabungkan file UFW dan output dari systemd-sysctl --cat-config
    # Gunakan 'tac' agar file dengan prioritas tertinggi (paling bawah) diperiksa lebih dulu
    while IFS= read -r l_file_line; do
        l_file="${l_file_line//# /}"
        if [ -f "$l_file" ]; then
            l_opt="$(grep -Psoi '^\h*'"$l_grep"'\h*=\h*\H+\b' "$l_file" | tail -n 1)"
            l_option_value="$(cut -d= -f2 <<< "$l_opt" | xargs)"

            if [ -n "$l_option_value" ]; then
                if [[ "$l_option_value" =~ ^[1-3]$ ]]; then
                    a_output+=(" - Config file: \"$l_parameter_name\" is set to \"$l_option_value\" in \"$l_file\"")
                    l_found_in_file="pass"
                else
                    a_output2+=(" - Config file: \"$l_parameter_name\" is set to \"$l_option_value\" in \"$l_file\" (expected 1, 2, or 3)")
                    l_found_in_file="fail"
                fi
                # Berhenti karena kita sudah menemukan setting dengan prioritas tertinggi
                break
            fi
        fi
    done < <({ [ -f "$l_ufwscf" ] && echo "# $l_ufwscf"; "$l_systemdsysctl" --cat-config; } | tac | grep -Psoi '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    if [ -z "$l_found_in_file" ]; then
        a_output2+=(" - Config file: \"$l_parameter_name\" not found in any sysctl configuration files")
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
    NOTES+="FAIL: Ptrace scope configuration issues found | Reason(s): ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# Bersihkan karakter newline dan spasi berlebih untuk output CSV
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}