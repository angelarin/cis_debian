#!/usr/bin/env bash

{
    a_output=(); a_output2=(); a_parlist=(kernel.randomize_va_space=2)
    l_systemdsysctl="$(readlink -f /lib/systemd/systemd-sysctl)"

    f_kernel_parameter_chk() {
        # 1. Cek konfigurasi yang sedang berjalan
        l_running_parameter_value="$(sysctl -n "$l_parameter_name" | xargs)"
        if [ "$l_running_parameter_value" = "$l_parameter_value" ]; then
            a_output+=(" - \"$l_parameter_name\" sudah benar bernilai \"$l_running_parameter_value\" di runtime.")
        else
            a_output2+=(" - \"$l_parameter_name\" salah, bernilai \"$l_running_parameter_value\" (seharusnya $l_parameter_value).")
        fi

        # 2. Cek konfigurasi permanen di file
        l_file_val=$(sysctl -a --unfocused 2>/dev/null | grep "^$l_parameter_name" | awk -F= '{print $2}' | xargs)
        # Cara lebih sederhana untuk audit file:
        if grep -qps "^\s*$l_parameter_name\s*=\s*$l_parameter_value" /etc/sysctl.conf /etc/sysctl.d/*.conf; then
            a_output+=(" - \"$l_parameter_name\" sudah ditemukan di file konfigurasi.")
        else
            a_output2+=(" - \"$l_parameter_name\" tidak ditemukan dengan nilai benar di /etc/sysctl.conf atau /etc/sysctl.d/.")
        fi
    }

    while IFS="=" read -r l_parameter_name l_parameter_value; do
        f_kernel_parameter_chk
    done < <(printf '%s\n' "${a_parlist[@]}")

    if [ "${#a_output2[@]}" -eq 0 ]; then
        echo -e "\n- Audit Result: ** PASS **"
        printf '%s\n' "${a_output[@]}"
    else
        echo -e "\n- Audit Result: ** FAIL **"
        echo " Alasan kegagalan:"
        printf '%s\n' "${a_output2[@]}"
    fi
}