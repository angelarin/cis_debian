#!/usr/bin/env bash

# Fungsi utama untuk menjalankan pemeriksaan konfigurasi
{
    # Inisialisasi array untuk output
    a_output=()
    a_output2=()

    # Tentukan path dan file konfigurasi
    l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
    l_systemd_config_file="systemd/journald.conf"
    
    # Daftar parameter yang akan diperiksa
    a_parameters=("ForwardToSyslog=yes")

    # Definisi fungsi untuk memeriksa parameter dalam file konfigurasi
    f_config_file_parameter_chk()
    {
        local l_used_parameter_setting=""
        local l_file_name l_file_parameter l_file_parameter_name l_file_parameter_value

        # Cari setting parameter yang berlaku (menggunakan systemd-analyze dan membaca dari bawah ke atas)
        while IFS= read -r l_file; do
            # Hapus '#' dan spasi dari nama file (jika ada)
            l_file="$(tr -d '# ' <<< "$l_file")" 
            
            # Cari baris setting parameter terakhir di file yang berlaku
            l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
            
            [ -n "$l_used_parameter_setting" ] && break # Keluar jika ditemukan setting yang berlaku
        done < <($l_analyze_cmd cat-config "$l_systemd_config_file" | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

        if [ -n "$l_used_parameter_setting" ]; then
            # Proses setting yang ditemukan
            while IFS=: read -r l_file_name l_file_parameter; do
                while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                    # Hapus spasi untuk perbandingan
                    l_file_parameter_name="${l_file_parameter_name// /}"
                    l_file_parameter_value="${l_file_parameter_value// /}"

                    if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                        # Setting benar
                        a_output+=(" - Parameter: \"$l_file_parameter_name\" correctly set to: \"$l_file_parameter_value\" in the file: \"$l_file_name\"")
                    else
                        # Setting salah
                        a_output2+=(" - Parameter: \"$l_file_parameter_name\" incorrectly set to: \"$l_file_parameter_value\" in the file: \"$l_file_name\". Should be set to: \"$l_value_out\"")
                    fi
                done <<< "$l_file_parameter"
            done <<< "$l_used_parameter_setting"
        else
            # Parameter tidak ditemukan di file yang dimuat
            a_output2+=(" - Parameter: \"$l_parameter_name\" is not set in an included file." "*** Note: \"$l_parameter_name\" May be set in a file that's ignored by load procedure ***")
        fi
    } # <-- **INI ADALAH LOKASI TUTUP FUNGSI YANG BENAR**

    # --- Bagian Utama ---

    # Loop melalui semua parameter yang harus diperiksa
    for l_input_parameter in "${a_parameters[@]}"; do
        # Pisahkan nama parameter dan nilai yang diharapkan
        while IFS="=" read -r l_parameter_name l_parameter_value; do
            l_parameter_name="${l_parameter_name// /}"
            l_parameter_value="${l_parameter_value// /}"
            
            # Format nilai output yang mudah dibaca untuk pesan kesalahan
            l_value_out="${l_parameter_value//-/ through }"
            l_value_out="${l_value_out//|/ or }"
            l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

            # Panggil fungsi pemeriksaan
            f_config_file_parameter_chk
        done <<< "$l_input_parameter"
    done

    # Output Hasil Audit
    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}
