#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.2"
DESCRIPTION="Ensure audit log files owner is configured (owner: root)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
EXPECTED_OWNER="root"

# --- FUNGSI AUDIT OWNER LOG FILES ---
if [ ! -e "$CONFIG_FILE" ]; then
    a_output2+=(" - File: \"$CONFIG_FILE\" not found. Verify auditd is installed.")
    RESULT="FAIL"
else
    # 1. Dapatkan direktori log
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' "$CONFIG_FILE" 2>/dev/null | xargs)")"
    
    if [ -d "$l_audit_log_directory" ]; then
        a_output+=(" - Audit log directory detected: $l_audit_log_directory.")
        
        # 2. Cari file yang TIDAK dimiliki oleh root
        l_files_fail=""
        while IFS= read -r -d $'\0' l_file; do
            l_owner=$(stat -Lc '%U' "$l_file")
            l_files_fail="$l_files_fail - File: \"$l_file\" is owned by user: \"$l_owner\" | "
        done < <(find "$l_audit_log_directory" -maxdepth 1 -type f ! -user "$EXPECTED_OWNER" -print0 2>/dev/null)

        if [ -z "$l_files_fail" ]; then
            a_output+=(" - All files in \"$l_audit_log_directory\" are owned by user: \"$EXPECTED_OWNER\".")
        else
            RESULT="FAIL"
            a_output2+=(" - Detected file(s) NOT owned by '$EXPECTED_OWNER'. Violations: ${l_files_fail// | / | }")
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