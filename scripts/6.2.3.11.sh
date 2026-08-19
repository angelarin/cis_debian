#!/usr/bin/env bash

CHECK_ID="6.2.3.11"
DESCRIPTION="Ensure unsuccessful file access attempts are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# Mendapatkan UID_MIN dari /etc/login.defs (default biasanya 1000)
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
[ -z "$UID_MIN" ] && UID_MIN=1000

f_check_access() {
    local type=$1 output="$2"
    local eacces=0 eperm=0

    if echo "$output" | grep -q "exit=-EACCES" && echo "$output" | grep -q "auid>=${UID_MIN}"; then eacces=1; fi
    if echo "$output" | grep -q "exit=-EPERM" && echo "$output" | grep -q "auid>=${UID_MIN}"; then eperm=1; fi

    if [ "$eacces" -eq 1 ] && [ "$eperm" -eq 1 ]; then
        a_output+=(" - $type: Unsuccessful file access rules found.")
        return 1
    else
        a_output2+=(" - $type: Unsuccessful file access rules missing/incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '(EACCES|EPERM)')
f_check_access "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '(EACCES|EPERM)' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_access "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Rules found using UID_MIN=${UID_MIN}. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}