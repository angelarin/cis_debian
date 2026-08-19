#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.4.4"
DESCRIPTION="Ensure the audit log file directory mode is configured (mode <= 0750)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
CONFIG_FILE="/etc/audit/auditd.conf"
l_perm_mask="0027" # Mask 0027 = Group Write, Other Read/Write/Execute
l_maxperm="$(printf '%o' $(( 0777 & ~$l_perm_mask )) )" # 0750

# --- FUNGSI AUDIT MODE LOG DIRECTORY ---
if [ ! -e "$CONFIG_FILE" ]; then
    a_output2+=(" - File: \"$CONFIG_FILE\" not found. Verify auditd is installed.")
    RESULT="FAIL"
else
    # 1. Dapatkan direktori log
    l_audit_log_directory="$(dirname "$(awk -F= '/^\s*log_file\s*/{print $2}' "$CONFIG_FILE" 2>/dev/null | xargs)")"
    
    if [ -d "$l_audit_log_directory" ]; then
        l_directory_mode="$(stat -Lc '%#a' "$l_audit_log_directory")"
        a_output+=(" - Directory detected: $l_audit_log_directory. Current mode: $l_directory_mode.")

        # 2. Cek apakah mode saat ini lebih longgar dari 0750
        if [ $(( l_directory_mode & l_perm_mask )) -gt 0 ]; then
            RESULT="FAIL"
            a_output2+=(" - Directory: \"$l_audit_log_directory\" is mode: \"$l_directory_mode\" (should be mode: \"$l_maxperm\" (0750) or more restrictive)")
        else
            a_output+=(" - Directory mode is compliant (<= 0750).")
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