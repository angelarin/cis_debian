#!/usr/bin/env bash

CHECK_ID="6.2.3.23"
DESCRIPTION="Ensure login and logout events are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_login() {
    local type=$1 output="$2"
    local has_lastlog=0 has_faillock=0

    if echo "$output" | grep -Eq "(path=/var/log/lastlog -F perm=wa|-w /var/log/lastlog -p wa)"; then has_lastlog=1; fi
    if echo "$output" | grep -Eq "(path=/var/run/faillock -F perm=wa|-w /var/run/faillock -p wa)"; then has_faillock=1; fi

    if [ "$has_lastlog" -eq 1 ] && [ "$has_faillock" -eq 1 ]; then
        a_output+=(" - $type: lastlog and faillock rules found.")
        return 1
    else
        a_output2+=(" - $type: lastlog or faillock rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '(lastlog|faillock)')
f_check_login "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '(lastlog|faillock)' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_login "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Login and logout tracking rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing login and logout tracking rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}