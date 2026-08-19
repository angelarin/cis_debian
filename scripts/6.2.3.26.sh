#!/usr/bin/env bash

CHECK_ID="6.2.3.26"
DESCRIPTION="Ensure events that modify the system's Mandatory Access Controls are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_apparmor() {
    local type=$1 output="$2"
    local has_file=0 has_dir=0

    if echo "$output" | grep -Eq "(path=/etc/apparmor -F perm=wa|-w /etc/apparmor -p wa)"; then has_file=1; fi
    if echo "$output" | grep -Eq "(dir=/etc/apparmor.d/? -F perm=wa|-w /etc/apparmor.d/? -p wa)"; then has_dir=1; fi

    if [ "$has_file" -eq 1 ] && [ "$has_dir" -eq 1 ]; then
        a_output+=(" - $type: AppArmor MAC policy rules found.")
        return 1
    else
        a_output2+=(" - $type: AppArmor MAC policy rules missing.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- 'apparmor')
f_check_apparmor "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- 'apparmor' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_apparmor "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: MAC policy modification rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Missing MAC policy modification rules. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}