#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.3.3"
DESCRIPTION="Ensure default user umask is configured (umask 027 or more restrictive)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_UMASK="027"
CONFIG_FILES=("/etc/profile.d/*.sh" "/etc/profile" "/etc/bashrc" "/etc/bash.bashrc")
PAM_FILE="/etc/pam.d/postlogin"

# --- FUNGSI AUDIT UMASK ---
l_output="" l_output2=""

file_umask_chk()
{
    local l_file="$1"
    # Mencari umask 0[0-7][2-7]7 atau symbolic set yang setara (e.g., u=rwx,g=rx,o=)
    if [ -f "$l_file" ] && grep -Psiq -- '^\h*umask\h+(0?[0-7][2-7]7|u(=[rwx]{0,3}),g=([rx]{0,2}),o=)(\h*#.*)?$' "$l_file"; then
        l_output="$l_file" # Menandai file yang PASS
        return 0
    elif [ -f "$l_file" ] && grep -Psiq -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' "$l_file"; then
        l_output2="$l_output2\n - Umask is incorrectly set in \"$l_file\" (Less restrictive or non-standard)."
        return 1
    fi
    return 2 # Not set
}

# 1. Cek file konfigurasi shell
for l_file in "${CONFIG_FILES[@]}"; do
    if file_umask_chk "$l_file" == 0; then
        l_output="$l_file"
        break
    fi
done

# 2. Cek pam_umask di /etc/pam.d/postlogin
if [ -z "$l_output" ] && [ -f "$PAM_FILE" ]; then
    if grep -Psiq -- '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(0?[0-7][2-7]7)\b' "$PAM_FILE"; then
        l_output="$PAM_FILE (via pam_umask.so)"
    elif grep -Psiq '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b))' "$PAM_FILE"; then
        l_output2="$l_output2\n - Umask is incorrectly set in \"$PAM_FILE\" (Less restrictive or non-standard)."
    fi
fi

# --- Assess Final Result ---
if [ -n "$l_output" ] && [ -z "$l_output2" ]; then
    RESULT="PASS"
    a_output+=(" - Default user umask is correctly set (e.g., 027) in $l_output.")
elif [ -n "$l_output2" ]; then
    RESULT="FAIL"
    l_output2=$(echo -e "$l_output2" | sed 's/\\n/ | /g')
    a_output2+=(" - Umask is incorrectly configured (Less restrictive than 027). Offending locations: $l_output2")
else
    RESULT="FAIL"
    a_output2+=(" - Umask is NOT explicitly set in standard configuration files; relying on system default (check UID_MIN).")
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