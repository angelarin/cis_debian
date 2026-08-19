#!/usr/bin/env bash

CHECK_ID="6.2.3.15"
DESCRIPTION="Ensure events that modify /etc/security/opasswd are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_opasswd() {
    local type=$1 output="$2"
    if echo "$output" | grep -Eq "(path=/etc/security/opasswd -F perm=wa|-w /etc/security/opasswd -p wa)"; then
        a_output+=(" - $type: opasswd rule found.")
        return 1
    else
        a_output2+=(" - $type: opasswd rule missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/security\/opasswd')
f_check_opasswd "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/security\/opasswd' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_opasswd "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: opasswd rule found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing opasswd rule. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}