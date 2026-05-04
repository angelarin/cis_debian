#!/usr/bin/env bash

# Skrip ini mengaudit apakah parameter penting untuk pengunggahan log journald
# telah dikonfigurasi dalam file systemd/journal-upload.conf.

# --- Inisialisasi ---
a_output=()
a_output2=()
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_systemd_config_file="systemd/journal-upload.conf" # File konfigurasi target

# Daftar parameter yang harus diperiksa, dengan nilai regex yang diharapkan (^.+$ berarti harus diisi)
a_parameters=(
    "URL=^.+$"
    "ServerKeyFile=^.+$"
    "ServerCertificateFile=^.+$"
    "TrustedCertificateFile=^.+$"
)

# --- Fungsi Pemeriksaan Parameter ---
f_config_file_parameter_chk() {
    local l_used_parameter_setting=""
    
    # Dapatkan daftar file konfigurasi yang dianalisis systemd
    while IFS= read -r l_file; do
        l_file="$(tr -d '# ' <<< "$l_file")"
        # Cari baris parameter terakhir yang tidak dikomentari (yang aktif)
        l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
        [ -n "$l_used_parameter_setting" ] && break
    done < <($l_analyze_cmd cat-config "$l_systemd_config_file" | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    # Proses hasil pencarian
    if [ -n "$l_used_parameter_setting" ]; then
        # Jika ditemukan, proses baris yang ditemukan
        while IFS=: read -r l_file_name l_file_parameter; do
            while IFS="=" read -r l_file_parameter_name l_file_parameter_value; do
                # Periksa apakah nilai parameter cocok dengan regex yang diharapkan
                if grep -Pq -- "$l_parameter_value" <<< "$l_file_parameter_value"; then
                    # Jika cocok, tambahkan ke daftar LULUS (a_output)
                    a_output+=(" - Parameter: \"${l_file_parameter_name// /}\"" \
                               " set to: \"${l_file_parameter_value// /}\"" \
                               " in the file: \"$l_file_name\"")
                fi
            done <<< "$l_file_parameter"
        done <<< "$l_used_parameter_setting"
    else
        # Jika tidak ditemukan, tambahkan ke daftar GAGAL (a_output2)
        a_output2+=(" - Parameter: \"$l_parameter_name\" is not set in an included file" \
                    " *** Note: ***" " \"$l_parameter_name\" May be set in a file that's ignored by load procedure")
    fi
}

# --- Logika Utama ---
for l_input_parameter in "${a_parameters[@]}"; do
    # Pecah parameter (cth: "URL=^.+$") menjadi nama dan nilai regex
    while IFS="=" read -r l_parameter_name l_parameter_value; do 
        l_parameter_name="${l_parameter_name// /}";
        l_parameter_value="${l_parameter_value// /}"
        
        # Penanganan string untuk output yang lebih ramah pengguna (tidak digunakan dalam logika inti)
        l_value_out="${l_parameter_value//-/ through }";
        l_value_out="${l_value_out//|/ or }"
        l_value_out="$(tr -d '(){}' <<< "$l_value_out")"

        # Panggil fungsi pemeriksaan
        f_config_file_parameter_chk
    done <<< "$l_input_parameter"
done

# --- Hasil Audit ---
if [ "${#a_output2[@]}" -le 0 ]; then
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi
