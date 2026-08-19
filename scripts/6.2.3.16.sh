#!/usr/bin/env bash

CHECK_ID="6.2.3.16"
DESCRIPTION="Ensure events that modify /etc/nsswitch.conf file are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_nsswitch() {
    local type=$1 output="$2"
    if echo "$output" | grep -Eq "(path=/etc/nsswitch.conf -F perm=wa|-w /etc/nsswitch.conf -p wa)"; then
        a_output+=(" - $type: nsswitch.conf rule found.")
        return 1
    else
        a_output2+=(" - $type: nsswitch.conf rule missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/nsswitch.conf')
f_check_nsswitch "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- 'nsswitch.conf' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_nsswitch "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: nsswitch.conf rule found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing nsswitch.conf rule. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}