#!/usr/bin/env bash

CHECK_ID="6.2.3.14"
DESCRIPTION="Ensure events that modify /etc/shadow and /etc/gshadow are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_shadow() {
    local type=$1 output="$2"
    local has_shadow=0 has_gshadow=0

    if echo "$output" | grep -Eq "(path=/etc/shadow -F perm=wa|-w /etc/shadow -p wa)"; then has_shadow=1; fi
    if echo "$output" | grep -Eq "(path=/etc/gshadow -F perm=wa|-w /etc/gshadow -p wa)"; then has_gshadow=1; fi

    if [ "$has_shadow" -eq 1 ] && [ "$has_gshadow" -eq 1 ]; then
        a_output+=(" - $type: shadow and gshadow rules found.")
        return 1
    else
        a_output2+=(" - $type: shadow or gshadow rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*shadow')
f_check_shadow "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- 'shadow' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_shadow "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: shadow rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing shadow rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}