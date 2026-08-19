#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.4"
DESCRIPTION="Ensure sshd access is configured (Allow/Deny Users/Groups)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""

# Perintah untuk memeriksa konfigurasi Allow/Deny global
L_OUTPUT=$(sshd -T 2>/dev/null | grep -Pi -- '^\h*(allow|deny)(users|groups)\h+\H+')

# --- FUNGSI AUDIT AKSES SSHD ---
if [ -n "$L_OUTPUT" ]; then
    RESULT="REVIEW" # Manual karena harus dicek terhadap site policy
    
    # Pisahkan output yang terdeteksi
    while IFS= read -r line; do
        a_output+=(" - Detected: $line")
    done <<< "$L_OUTPUT"
    
    a_output+=(" - Configuration found. Need manual review against site policy.")
else
    RESULT="FAIL"
    a_output2+=(" - No explicit sshd access control directives (AllowUsers/Groups, DenyUsers/Groups) detected in the global configuration.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "REVIEW" ]; then
    NOTES+="INFO: SSH access configuration detected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the listed users/groups against local site policy to ensure adherence."
elif [ "$RESULT" == "FAIL" ]; then
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}