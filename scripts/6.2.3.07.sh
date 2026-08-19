#!/usr/bin/env bash

CHECK_ID="6.2.3.7"
DESCRIPTION="Ensure events that modify /etc/hosts and /etc/hostname are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_hosts() {
    local type=$1 output="$2"
    local has_hosts=0 has_hostname=0

    if echo "$output" | grep -Eq "(path=/etc/hosts -F perm=wa|-w /etc/hosts -p wa)"; then has_hosts=1; fi
    if echo "$output" | grep -Eq "(path=/etc/hostname -F perm=wa|-w /etc/hostname -p wa)"; then has_hostname=1; fi

    if [ "$has_hosts" -eq 1 ] && [ "$has_hostname" -eq 1 ]; then
        a_output+=(" - $type: hosts/hostname rules found.")
        return 1
    else
        a_output2+=(" - $type: hosts/hostname rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/host')
f_check_hosts "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/host' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_hosts "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}