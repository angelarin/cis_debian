#!/usr/bin/env bash

CHECK_ID="6.2.3.12"
DESCRIPTION="Ensure events that modify /etc/group information are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_group() {
    local type=$1 output="$2"
    if echo "$output" | grep -Eq "(path=/etc/group -F perm=wa|-w /etc/group -p wa)"; then
        a_output+=(" - $type: /etc/group rule found.")
        return 1
    else
        a_output2+=(" - $type: /etc/group rule missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/group')
f_check_group "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/group' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_group "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: /etc/group rule found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing /etc/group rule. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}