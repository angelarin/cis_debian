#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.2.7"
DESCRIPTION="Ensure access to the su command is restricted"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
PAM_CONFIG="/etc/pam.d/su"
PAM_REGEX='^\h*auth\h+(?:required|requisite)\h+pam_wheel\.so\h+(?:[^#\n\r]+\h+)?((?!\2)(use_uid\b|group=\H+\b))\h+(?:[^#\n\r]+\h+)?((?!\1)(use_uid\b|group=\H+\b))(\h+.*)?$'

# 1. Cek konfigurasi PAM untuk pam_wheel.so
L_PAM_OUTPUT=$(grep -Pi -- "$PAM_REGEX" "$PAM_CONFIG" 2>/dev/null)

if [ -n "$L_PAM_OUTPUT" ]; then
    a_output+=(" - pam_wheel.so restriction found in $PAM_CONFIG.")
    a_output+=(" - Detected line: $L_PAM_OUTPUT")
    
    # Ekstrak nama grup yang digunakan
    GROUP_NAME=$(echo "$L_PAM_OUTPUT" | grep -oP 'group=\K\H+')

    if [ -n "$GROUP_NAME" ]; then
        a_output+=(" - Identified restricted group: $GROUP_NAME")
        
        # 2. Cek keanggotaan grup
        L_GROUP_ENTRY=$(grep "^$GROUP_NAME:" /etc/group)
        L_USERS=$(echo "$L_GROUP_ENTRY" | awk -F: '{print $4}')

        if [ -z "$L_USERS" ]; then
            a_output+=(" - Group '$GROUP_NAME' contains NO non-root users (PASS). Entry: $L_GROUP_ENTRY")
        else
            RESULT="FAIL"
            a_output2+=(" - Group '$GROUP_NAME' contains unauthorized users: $L_USERS")
        fi
    else
        # Jika group= tidak ditentukan, pam_wheel.so default menggunakan group 'wheel' atau 'root' tergantung distro.
        a_output+=(" - pam_wheel.so configured without explicit 'group=' tag. Default group assumed.")
    fi
else
    RESULT="FAIL"
    a_output2+=(" - $PAM_CONFIG does NOT restrict 'su' access using pam_wheel.so or required group method.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set/Info: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}