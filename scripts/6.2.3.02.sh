#!/usr/bin/env bash

CHECK_ID="6.2.3.2"
DESCRIPTION="Ensure actions as another user are always logged"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_execve() {
    local type=$1 output="$2"
    
    # Mencari kata kunci execve, euid!=uid (atau sebaliknya), dan auid!=unset (atau -1)
    if echo "$output" | grep -q "execve" && \
       echo "$output" | grep -Eq "(euid!=uid|uid!=euid)" && \
       echo "$output" | grep -Eq "(auid!=unset|auid!=-1|auid!=4294967295)"; then
        
        a_output+=(" - $type: Rule for execve (euid!=uid) found.")
        return 1
    else
        a_output2+=(" - $type: Rule for execve (euid!=uid) is missing or incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep execve)
f_check_execve "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- 'execve' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_execve "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: All required rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: User emulation audit rules missing. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}