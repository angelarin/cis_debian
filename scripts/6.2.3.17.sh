#!/usr/bin/env bash

CHECK_ID="6.2.3.17"
DESCRIPTION="Ensure events that modify /etc/pam.conf and /etc/pam.d/ information are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_pam() {
    local type=$1 output="$2"
    local has_pamconf=0 has_pamd=0

    # Catatan: Terdapat typo pada dokumen CIS asli (-F perm-wa), script ini mendukung "perm=wa" maupun "perm-wa".
    if echo "$output" | grep -Eq "(path=/etc/pam.conf -F perm[=-]wa|-w /etc/pam.conf -p wa)"; then has_pamconf=1; fi
    if echo "$output" | grep -Eq "(dir=/etc/pam.d/? -F perm[=-]wa|-w /etc/pam.d/? -p wa)"; then has_pamd=1; fi

    if [ "$has_pamconf" -eq 1 ] && [ "$has_pamd" -eq 1 ]; then
        a_output+=(" - $type: pam rules found.")
        return 1
    else
        a_output2+=(" - $type: pam.conf or pam.d rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/pam')
f_check_pam "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/pam' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_pam "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: PAM configuration rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing PAM configuration rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}