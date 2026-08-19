#!/usr/bin/env bash

CHECK_ID="6.2.3.34"
DESCRIPTION="Ensure kernel query_module loading unloading and modification is collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$UID_MIN" ] && UID_MIN=1000

f_check_query_module() {
    local type=$1 output="$2"
    if echo "$output" | grep -q "query_module" && \
       echo "$output" | grep -q "auid>=${UID_MIN}" && \
       echo "$output" | grep -Eq "(auid!=unset|auid!=-1|auid!=4294967295)"; then
        a_output+=(" - $type: query_module rule found.")
        return 1
    else
        a_output2+=(" - $type: query_module rule missing or incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- 'query_module')
f_check_query_module "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- 'query_module' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_query_module "disk" "$DISK"
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