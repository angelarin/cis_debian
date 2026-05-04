#!/usr/bin/env bash

{
    # --- 1. Inisialisasi Variabel ---
    a_output2=()
    l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
    l_include='\$IncludeConfig' 
    a_config_files=("/etc/rsyslog.conf")

    # --- 2. Pencarian File Konfigurasi yang Disertakan ($IncludeConfig) ---
    while IFS= read -r l_file; do
        l_file_cleaned="$(tr -d '# ' <<< "$l_file")"
        if [ -f "$l_file_cleaned" ]; then
            l_conf_loc="$(awk '$1~/^\s*'"$l_include"'\b/ {print $2}' "$l_file_cleaned" | tail -n 1)"
            [ -n "$l_conf_loc" ] && break
        fi
    done < <($l_analyze_cmd cat-config "${a_config_files[@]}" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    # Menentukan direktori dan ekstensi file yang di-include
    if [ -d "$l_conf_loc" ]; then
        l_dir="$l_conf_loc" 
        l_ext="*"
    elif grep -Psq '\/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
        l_dir="$(dirname "$l_conf_loc")" 
        l_ext="$(basename "$l_conf_loc")"
    fi

    # Menambahkan file-file dari direktori include ke daftar audit
    while IFS= read -r -d $'\0' l_file_name; do
        if [ -f "$(readlink -f "$l_file_name")" ]; then
            a_config_files+=("$(readlink -f "$l_file_name")")
        fi
    done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

    # --- 3. Proses Audit Pengecekan Modul imtcp ---
    for l_logfile in "${a_config_files[@]}"; do
        # Cek format advanced (modul load)
        l_fail="$(grep -Psi -- '^\h*module\(load=\"?imtcp\"?\)' "$l_logfile")"
        [ -n "$l_fail" ] && a_output2+=("- Advanced format entry to accept incoming logs: \"$l_fail\"" "found in: \"$l_logfile\"")
        
        # Cek format advanced (input tcp)
        l_fail="$(grep -Psi -- '^\h*input\(type=\"?imtcp\"?\b' "$l_logfile")"
        [ -n "$l_fail" ] && a_output2+=("- Advanced format entry to accept incoming logs: \"$l_fail\"" "found in: \"$l_logfile\"")
        
        # Cek format lama/obsolete (input tcp) - Menjaga logika duplikat sesuai skrip asal
        l_fail="$(grep -Psi -- '^\h*\$InputTCPServerRun\b' "$l_logfile")"
        [ -n "$l_fail" ] && a_output2+=("- Obsolete format entry to accept incoming logs: \"$l_fail\"" "found in: \"$l_logfile\"")
    done

    # --- 4. Pelaporan Hasil ---
    if [ "${#a_output2[@]}" -le "0" ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" " - No entries to accept incoming logs found"
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    fi
}