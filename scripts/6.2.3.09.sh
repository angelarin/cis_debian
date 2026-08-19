#!/usr/bin/env bash

CHECK_ID="6.2.3.9"
DESCRIPTION="Ensure events that modify /etc/NetworkManager directory are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_nm() {
    local type=$1 output="$2"
    if echo "$output" | grep -Eq "(dir=/etc/NetworkManager/? -F perm=wa|-w /etc/NetworkManager/? -p wa)"; then
        a_output+=(" - $type: NetworkManager rule found.")
        return 1
    else
        a_output2+=(" - $type: NetworkManager rule missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '\/etc/NetworkManager')
f_check_nm "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '\/etc\/NetworkManager' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_nm "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: NetworkManager rule found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing NetworkManager rule. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}