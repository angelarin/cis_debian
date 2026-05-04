#!/usr/bin/env bash

# Fungsi utama untuk menjalankan pemeriksaan konfigurasi
{
    # Inisialisasi array untuk output
    a_output=()
    a_output2=()
    
    # Perintah dan variabel konfigurasi
    l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
    l_include='\$IncludeConfig'
    a_config_files=("/etc/rsyslog.conf")
    l_parameter_name='\$FileCreateMode'
    
    # Definisi fungsi untuk memeriksa parameter mode file
    f_parameter_chk()
    {
        # l_perm_mask adalah bit yang TIDAK boleh disetel (misalnya, 0137 = 001 011 111)
        l_perm_mask="0137"
        
        # Hitung mode maksimum yang diizinkan (0777 dikurangi mask yang tidak diizinkan)
        # Mode yang disarankan adalah 0640
        l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )"

        # Ekstrak mode dari setting yang ditemukan (kolom kedua)
        l_mode="$(awk '{print $2}' <<< "$l_used_parameter_setting" | xargs)"

        # Periksa apakah ada bit yang tidak diizinkan disetel (mode AND mask > 0)
        if [ $(( $l_mode & $l_perm_mask )) -gt 0 ]; then
            # Parameter GAGAL
            a_output2+=(" - Parameter: \"${l_parameter_name//\\/}\" is incorrectly set to mode: \"$l_mode\"" "in the file: \"$l_file\"" "Should be mode: \"$l_maxperm\" or more restrictive")
        else
            # Parameter LULUS
            a_output+=(" - Parameter: \"${l_parameter_name//\\/}\" is correctly set to mode: \"$l_mode\"" "in the file: \"$l_file\"" "Should be mode: \"$l_maxperm\" or more restrictive")
        fi
    }

    # --- Bagian 1: Temukan Direktori Konfigurasi yang Disertakan ($IncludeConfig) ---

    l_conf_loc=""
    # Cari baris $IncludeConfig terakhir yang berlaku di file konfigurasi
    while IFS= read -r l_file; do
        # Hapus komentar dan spasi di depan file, lalu cari lokasi $IncludeConfig
        l_conf_loc="$(awk '$1~/^\s*'"$l_include"'$/ {print $2}' "$(tr -d '# ' <<< "$l_file")" | tail -n 1)"
        [ -n "$l_conf_loc" ] && break
    done < <($l_analyze_cmd cat-config "${a_config_files[*]}" | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    # Tentukan direktori dan ekstensi yang akan dicari
    l_dir=""
    l_ext=""
    if [ -d "$l_conf_loc" ]; then
        l_dir="$l_conf_loc"
        l_ext="*"
    elif grep -Psq '\/\*\.([^#/\n\r]+)?\h*$' <<< "$l_conf_loc" || [ -f "$(readlink -f "$l_conf_loc")" ]; then
        l_dir="$(dirname "$l_conf_loc")"
        l_ext="$(basename "$l_conf_loc")"
    fi

    # Tambahkan file konfigurasi yang disertakan ke daftar pemeriksaan
    if [ -n "$l_dir" ]; then
        while read -r -d $'\0' l_file_name; do
            # Tambahkan file yang valid ke a_config_files
            [ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
        done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)
    fi

    # --- Bagian 2: Cari Parameter yang Diterapkan ($FileCreateMode) ---

    l_used_parameter_setting=""
    # Cari setting parameter terakhir yang berlaku
    while IFS= read -r l_file; do
        # Hapus komentar dan spasi di depan file
        l_file="$(tr -d '# ' <<< "$l_file")"
        
        # Cari baris setting parameter terakhir di file yang berlaku
        l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file" | tail -n 1)"
        
        [ -n "$l_used_parameter_setting" ] && break # Keluar jika ditemukan setting yang berlaku
    done < <($l_analyze_cmd cat-config "${a_config_files[@]}" | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

    # --- Bagian 3: Evaluasi dan Output Hasil ---

    if [ -n "$l_used_parameter_setting" ]; then
        f_parameter_chk # Panggil fungsi pemeriksaan jika setting ditemukan
    else
        # Parameter tidak ditemukan
        a_output2+=(" - Parameter: \"${l_parameter_name//\\/}\" is not set in a configuration file." "*** Note: \"${l_parameter_name//\\/}\" May be set in a file that's ignored by load procedure ***")
    fi

    # Output Hasil Audit
    if [ "${#a_output2[@]}" -le 0 ]; then
        printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '%s\n' "" "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}"
        [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
    fi
}
