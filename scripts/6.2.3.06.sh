#!/usr/bin/env bash

CHECK_ID="6.2.3.6"
DESCRIPTION="Ensure events that modify /etc/issue and /etc/issue.net are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_issue() {
    local type=$1 output="$2"
    local has_issue=0 has_issuenet=0

    if echo "$output" | grep -Eq "(path=/etc/issue -F perm=wa|-w /etc/issue -p wa)"; then has_issue=1; fi
    if echo "$output" | grep -Eq "(path=/etc/issue.net -F perm=wa|-w /etc/issue.net -p wa)"; then has_issuenet=1; fi

    if [ "$has_issue" -eq 1 ] && [ "$has_issuenet" -eq 1 ]; then
        a_output+=(" - $type: issue/issue.net rules found.")
        return 1
    else
        a_output2+=(" - $type: issue/issue.net rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/issue')
f_check_issue "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/issue' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_issue "disk" "$DISK"
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