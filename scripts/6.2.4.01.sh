#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.1"
DESCRIPTION="Ensure audit log files mode is configured (mode <= 0640)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
l_perm_mask="0137" # Mask 0137 = Group/Other Write/Execute, Other Read
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )" # 0640

# --- FUNGSI AUDIT MODE LOG FILES ---
if [ ! -e "$CONFIG_FILE" ]; then
    a_output2+=(" - File: \"$CONFIG_FILE\" not found. Verify auditd is installed.")
    RESULT="FAIL"
else
    # 1. Dapatkan direktori log dari auditd.conf
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' "$CONFIG_FILE" 2>/dev/null | xargs)")"
    
    if [ -d "$l_audit_log_directory" ]; then
        a_output+=(" - Audit log directory detected: $l_audit_log_directory.")
        
        # 2. Cari file yang melanggar mode (perm /0137)
        a_files=()
        while IFS= read -r -d $'\0' l_file; do
            [ -e "$l_file" ] && a_files+=("$l_file")
        done < <(find "$l_audit_log_directory" -maxdepth 1 -type f -perm /"$l_perm_mask" -print0 2>/dev/null)

        if (( "${#a_files[@]}" > 0 )); then
            RESULT="FAIL"
            for l_file in "${a_files[@]}"; do
                l_file_mode="$(stat -Lc '%#a' "$l_file")"
                # Periksa apakah mode saat ini lebih longgar dari 0640
                if [ $(( l_file_mode & l_perm_mask )) -gt 0 ]; then
                    a_output2+=(" - File: \"$l_file\" is mode: \"$l_file_mode\" (should be mode: \"$l_maxperm\" or more restrictive)")
                fi
            done
        else
            a_output+=(" - All files in \"$l_audit_log_directory\" are mode: \"$l_maxperm\" or more restrictive.")
        fi
    else
        RESULT="FAIL"
        a_output2+=(" - Log file directory '$l_audit_log_directory' not found or not set in \"$CONFIG_FILE\".")
    fi
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}