#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.3"
DESCRIPTION="Ensure audit log files group owner is configured (group: root or adm)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
ALLOWED_GROUPS=("root" "adm")

# --- FUNGSI AUDIT GROUP LOG FILES ---
if [ ! -e "$CONFIG_FILE" ]; then
    a_output2+=(" - File: \"$CONFIG_FILE\" not found. Verify auditd is installed.")
    RESULT="FAIL"
else
    # 1. Cek parameter log_group di auditd.conf (Tidak boleh ada selain root/adm)
    L_GROUP_PARAM_FAIL=$(grep -Piws -- '^\h*log_group\h*=\h*\H+\b' "$CONFIG_FILE" 2>/dev/null | grep -Pvi -- '(root|adm)' | tail -n 1)
    
    if [ -n "$L_GROUP_PARAM_FAIL" ]; then
        RESULT="FAIL"
        a_output2+=(" - log_group parameter is set to an unauthorized group. Offending line: $L_GROUP_PARAM_FAIL")
    else
        L_GROUP_PARAM=$(grep -Piws -- '^\h*log_group\h*=\h*\H+\b' "$CONFIG_FILE" 2>/dev/null | awk -F= '{print $2}' | xargs)
        [ -n "$L_GROUP_PARAM" ] && a_output+=(" - log_group parameter set to: $L_GROUP_PARAM.")
    fi

    # 2. Dapatkan direktori log
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' "$CONFIG_FILE" 2>/dev/null | xargs)")"
    
    if [ -d "$l_audit_log_directory" ]; then
        # 3. Cari file yang TIDAK dimiliki oleh grup yang diizinkan (root atau adm)
        l_files_fail=""
        # Gunakan find untuk mencari file yang bukan milik grup root DAN bukan milik grup adm
        while IFS= read -r l_file; do
             l_group=$(stat -Lc '%G' "$l_file")
             l_files_fail="$l_files_fail - File: \"$l_file\" is owned by group: \"$l_group\" | "
        done < <(find -L "$l_audit_log_directory" -not -path "$l_audit_log_directory"/lost+found -type f \( ! -group root -a ! -group adm \) -print 2>/dev/null)

        if [ -z "$l_files_fail" ]; then
            a_output+=(" - All audit log files are owned by group: root or adm.")
        else
            RESULT="FAIL"
            a_output2+=(" - Detected file(s) NOT owned by 'root' or 'adm' group. Violations: ${l_files_fail// | / | }")
        fi
    else
        RESULT="FAIL"
        a_output2+=(" - Log file directory '$l_audit_log_directory' not found or not set.")
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