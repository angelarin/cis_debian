#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.1.2"
DESCRIPTION="Ensure journald log file access is configured (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
l_systemd_config_file="/etc/tmpfiles.d/systemd.conf"
l_analyze_cmd="$(readlink -f /bin/systemd-analyze)"

f_file_chk()
{
local l_logfile="$1" l_mode="$2" l_user="$3" l_group="$4"
local l_perm_mask="0027" l_type="File"
local l_maxperm=""
local l_check_status="PASS"

# Tentukan mask izin yang diharapkan berdasarkan path
if grep -Psq '^(\/run|\/var\/lib\/systemd)\b' <<< "$l_logfile"; then
    # Directories /run/ and /var/lib/systemd/ are mode 0755 or more restrictive (mask 0022)
    l_perm_mask="0022"
    l_type="Directory/File"
elif [ -d "$l_logfile" ]; then
    # All other configured directories are mode 2755, 0750, or more restrictive (mask 0027)
    l_perm_mask="0027"
    l_type="Directory"
else
    # Logfiles should be mode 0640 or more restrictive (mask 0137)
    l_perm_mask="0137"
    l_type="File"
fi

l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )"
l_mode_octal=$(stat -c '%a' "$l_logfile" 2>/dev/null) # Get current mode from system

# Pemeriksaan Izin: Membandingkan mode yang dikonfigurasi dengan mask yang diharapkan
if [ $(( $l_mode & $l_perm_mask )) -gt 0 ]; then
    a_out2+=(" - $l_type \"$l_logfile\" configured mode ($l_mode) is NOT restrictive enough (mask violation). Should be mode: \"$l_maxperm\" or more restrictive")
    l_check_status="FAIL"
elif [[ "$l_type" = "Directory" && "$l_mode" =~ 275(0|5) ]]; then
    a_out+=(" - $l_type \"$l_logfile\" access is: mode: \"$l_mode\", owned by: \"$l_user\", and group owned by: \"$l_group\" (PASS: Sticky bit set)")
else
    a_out+=(" - $l_type \"$l_logfile\" access is: mode: \"$l_mode\", owned by: \"$l_user\", and group owned by: \"$l_group\"")
fi
}

# Dapatkan semua file konfigurasi yang dipertimbangkan oleh systemd-analyze
while IFS= read -r l_file; do
    l_file="$(tr -d '# ' <<< "$l_file")" a_out=() a_out2=()
    
    # Ambil baris yang menentukan file/dir (kolom 1: f/d, kolom 2: path, kolom 3: mode, kolom 4: user, kolom 5: group)
    l_logfile_perms_line="$(awk '($1~/^(f|d)$/ && $2~/\/\S+/ && $3~/[0-9]{3,}/){print $2 ":" $3 ":" $4 ":" $5}' "$l_file" 2>/dev/null)"
    
    # Proses setiap entri file/dir yang dikonfigurasi
    while IFS=: read -r l_logfile l_mode l_user l_group; do
        if [ -n "$l_logfile" ] && [ -e "$l_logfile" ]; then
            f_file_chk "$l_logfile" "$l_mode" "$l_user" "$l_group"
        fi
    done <<< "$l_logfile_perms_line"
    
    [ "${#a_out[@]}" -gt "0" ] && a_output+=(" - File: \"$l_file\" sets:" "${a_out[@]}")
    [ "${#a_out2[@]}" -gt "0" ] && a_output2+=(" - File: \"$l_file\" sets:" "${a_out2[@]}")
done < <("$l_analyze_cmd" cat-config "$l_systemd_config_file" 2>/dev/null | tac | grep -Pio '^\h*#\h*\/[^#\n\r\h]+\.conf\b')

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="REVIEW: No permission violations detected in configured tmpfiles.d files. ${a_output[*]}"
else
    NOTES+="REVIEW: File permission violations detected. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO (Correctly set): ${a_output[*]}"
fi
NOTES+=" | Action: Review configured file access against local site policy."
RESULT="REVIEW"

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}