#!/usr/bin/env bash

{
    a_output=() 
    a_output2=() 
    l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
    # Di Debian, file ini biasanya diakses tanpa prefix 'systemd/' oleh systemd-analyze
    l_systemd_config_file="journal-upload.conf"
    
    a_parameters=(
        "URL=^.+$" 
        "ServerKeyFile=^.+$" 
        "ServerCertificateFile=^.+$" 
        "TrustedCertificateFile=^.+$"
    )

    f_config_file_parameter_chk() {
        l_used_parameter_setting=""
        # Mengambil daftar file konfigurasi yang dibaca oleh systemd
        while IFS= read -r l_file; do
            l_file="$(tr -d '# ' <<< "$l_file")"
            if [ -f "$l_file" ]; then
                l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
                [ -n "$l_used_parameter_setting" ] && break
            fi
        done < <($l_analyze_cmd cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

        if [ -n "$l_used_parameter_setting" ]; then
            l_file_name="${l_used_parameter_setting%%:*}"
            l_file_parameter="${l_used_parameter_setting#*:}"
            l_file_parameter_value="${l_file_parameter#*=}"
            
            if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                a_output+=(" - Parameter: \"${l_parameter_name}\" set to: \"${l_file_parameter_value// /}\" in: \"$l_file_name\"")
            fi
        else
            a_output2+=(" - Parameter: \"$l_parameter_name\" is not explicitly set in journal-upload configuration")
        fi
    }

    for l_input_parameter in "${a_parameters[@]}"; do
        l_parameter_name="${l_input_parameter%%=*}"
        l_parameter_value="${l_input_parameter#*=}"
        f_config_file_parameter_chk
    done

    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}