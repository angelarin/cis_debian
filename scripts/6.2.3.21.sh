#!/usr/bin/env bash

CHECK_ID="6.2.3.21"
DESCRIPTION="Ensure successful file system mounts are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$UID_MIN" ] && UID_MIN=1000

f_check_mount() {
    local type=$1 output="$2"
    if echo "$output" | grep -q "mount" && \
       echo "$output" | grep -q "auid>=${UID_MIN}" && \
       echo "$output" | grep -Eq "(auid!=unset|auid!=-1|auid!=4294967295)"; then
        a_output+=(" - $type: mount rule found.")
        return 1
    else
        a_output2+=(" - $type: mount rule missing or incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '\-S mount')
f_check_mount "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '\-S mount' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_mount "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Mount rules found using UID_MIN=${UID_MIN}. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing mount rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}