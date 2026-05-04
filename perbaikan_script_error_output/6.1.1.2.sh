#!/usr/bin/env bash

# Skrip ini mengaudit konfigurasi izin file log journald sesuai standar CIS.
# Skrip asli memiliki blok pembungkus '{...}' yang tidak diperlukan.

# Inisialisasi array untuk output
a_output=()
a_output2=()

# Konfigurasi file systemd dan perintah analyze
l_systemd_config_file="/etc/tmpfiles.d/systemd.conf"
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"

# --- Fungsi Pemeriksaan File ---
f_file_chk() {
    # Menghitung izin maksimum yang diizinkan (0777 dikurangi mask yang melanggar)
    l_maxperm="$(printf '%o' $((0777 & ~$l_perm_mask)))"

    # Periksa izin:
    # 1. Jika mode saat ini TIDAK memiliki bit mask yang melanggar (lebih aman/restrictive),
    # ATAU 
    # 2. Jika itu direktori DAN mode-nya adalah 2750 atau 2755 (sticky bit yang diizinkan)
    if [ $((l_mode & l_perm_mask)) -le 0 ] || [[ "$l_type" = "Directory" && "$l_mode" =~ 275(0|5) ]]; then
        # PASS: Izin sudah cukup ketat
        a_out+=(" - $l_type \"$l_logfile\" access is:" \
                " mode: \"$l_mode\", owned by: \"$l_user\", and group owned by: \"$l_group\"")
    else
        # REVIEW: Izin terlalu permisif
        a_out2+=(" - $l_type \"$l_logfile\" access is:" \
                 " mode: \"$l_mode\", owned by: \"$l_user\", and group owned by: \"$l_group\"" \
                 " should be mode: \"$l_maxperm\" or more restrictive")
    fi
}

# --- Logika Utama Skrip ---

# Dapatkan daftar file konfigurasi yang dianalisis systemd
while IFS= read -r l_file; do
    l_file="$(tr -d '# ' <<< "$l_file")"
    a_out=()
    a_out2=()

    # Ekstrak logfile, mode, user, dan group dari konfigurasi tmpfiles
    l_logfile_perms_line="$(awk '($1~/^(f|d)$/ && $2~/\/\S+/ && $3~/[0-9]{3,}/){print $2 ":" $3 ":" $4 ":" $5}' "$l_file")"
    
    # Iterasi melalui setiap entri file/direktori yang terdeteksi
    while IFS=: read -r l_logfile l_mode l_user l_group; do
        l_mode=$((8#$l_mode)) # Konversi mode dari string oktal ke integer desimal
        
        # 1. Tentukan jenis entitas (File atau Directory) dan mask default
        if [ -d "$l_logfile" ]; then
            l_perm_mask="0027"    # Maksimum diizinkan: 750 (d_mask 027 = r/w/x for owner, r/x for group, nothing for others)
            l_type="Directory"
            
            # Khusus /run atau /var/lib/systemd, izin lebih ketat (0755 atau 2755)
            grep -Psq '^(\/run|\/var\/lib\/systemd)\b' <<< "$l_logfile" && l_perm_mask="0022" # Maksimum diizinkan: 755
        else
            l_perm_mask="0137"    # Maksimum diizinkan: 640 (f_mask 137 = r/w for owner, r for group, nothing for others)
            l_type="File"
        fi

        # Terapkan ulang mask yang lebih ketat untuk /run atau /var/lib/systemd (berlaku juga untuk file di dalamnya)
        grep -Psq '^(\/run|\/var\/lib\/systemd)\b' <<< "$l_logfile" && l_perm_mask="0022"
        
        # Jalankan pemeriksaan
        f_file_chk
    done <<< "$l_logfile_perms_line"

    # Kumpulkan output untuk file konfigurasi saat ini
    [ "${#a_out[@]}" -gt "0" ] && a_output+=(" - File: \"$l_file\" sets:" "${a_out[@]}")
    [ "${#a_out2[@]}" -gt "0" ] && a_output2+=(" - File: \"$l_file\" sets:" "${a_out2[@]}")
done < <($l_analyze_cmd cat-config "$l_systemd_config_file" | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

# --- Hasil Audit ---

if [ "${#a_output2[@]}" -le 0 ]; then
    # Jika tidak ada pelanggaran
    printf '%s\n' "" "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
else
    # Jika ada pelanggaran, tampilkan sebagai REVIEW
    printf '%s\n' "" "- Audit Result:" " ** REVIEW **" \
    " - Review file access to ensure they are set IAW site policy:" "${a_output2[@]}"
    
    # Tampilkan konfigurasi yang benar (jika ada)
    [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "- Correctly set:" "${a_output[@]}" ""
fi