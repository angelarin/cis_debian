#!/usr/bin/env bash

CHECK_ID="6.2.3.13"
DESCRIPTION="Ensure events that modify /etc/passwd information are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_passwd() {
    local type=$1 output="$2"
    if echo "$output" | grep -Eq "(path=/etc/passwd -F perm=wa|-w /etc/passwd -p wa)"; then
        a_output+=(" - $type: /etc/passwd rule found.")
        return 1
    else
        a_output2+=(" - $type: /etc/passwd rule missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/passwd')
f_check_passwd "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/passwd' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_passwd "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: /etc/passwd rule found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing /etc/passwd rule. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}