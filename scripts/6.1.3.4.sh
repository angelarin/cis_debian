#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.3.4"
DESCRIPTION="Ensure rsyslog log file creation mode is configured ($FileCreateMode <= 0640)"
# -----------------------------------------------------

{
a_output=() a_output2=() l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"
l_include='\$IncludeConfig' a_config_files=("/etc/rsyslog.conf")
l_parameter_name='\$FileCreateMode'
RESULT="PASS" NOTES=""

f_parameter_chk()
{
l_perm_mask="0137"; l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )"
l_mode="$(awk '{print $2}' <<< "$l_used_parameter_setting" | xargs)"
l_mode_octal=$((8#$l_mode)) # Konversi ke desimal untuk perbandingan

if [ $(( $l_mode_octal & $l_perm_mask )) -gt 0 ]; then
a_output2+=(" - Parameter: \"${l_parameter_name//\\/}\" is incorrectly set to mode: \"$l_mode\"" \
" in the file: \"$l_file\"" " Should be mode: \"$l_maxperm\" (0640) or more restrictive")
else
a_output+=(" - Parameter: \"${l_parameter_name//\\/}\" is correctly set to mode: \"$l_mode\"" \
" in the file: \"$l_file\"" " Should be mode: \"$l_maxperm\" (0640) or more restrictive")
fi
}

# --- LOGIKA PENENTUAN FILE KONFIGURASI RSYSLOG ---

l_dir="/etc/rsyslog.d"
l_ext="*.conf"

# Dapatkan file konfigurasi yang dipertimbangkan
while read -r -d $'\0' l_file_name; do
[ -f "$(readlink -f "$l_file_name")" ] && a_config_files+=("$(readlink -f "$l_file_name")")
done < <(find -L "$l_dir" -type f -name "$l_ext" -print0 2>/dev/null)

# Cari $FileCreateMode dengan preseden terbalik
l_used_parameter_setting=""
for l_file in "${a_config_files[@]}"; do
    l_file_raw="$(tr -d '# ' <<< "$l_file")"
    l_used_parameter_setting="$(grep -PHs -- '^\h*'"$l_parameter_name"'\b' "$l_file_raw" | tail -n 1)"
    if [ -n "$l_used_parameter_setting" ]; then
        l_file="$l_file_raw"
        break
    fi
done

if [ -n "$l_used_parameter_setting" ]; then
    f_parameter_chk
else
    # Jika tidak disetel, rsyslog menggunakan default kernel umask, yang biasanya 0022/0002.
    # Default ini menghasilkan 0755/0775, yang TIDAK 0640.
    a_output2+=(" - Parameter: \"${l_parameter_name//\\/}\" is not explicitly set in a configuration file.")
    a_output2+=(" - WARNING: Relying on default system umask may result in less restrictive permissions (e.g., 0664 or 0775).")
    RESULT="FAIL"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}