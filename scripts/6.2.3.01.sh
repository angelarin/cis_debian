#!/usr/bin/env bash

CHECK_ID="6.2.3.1"
DESCRIPTION="Ensure modification of the /etc/sudoers file is collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

f_check_sudoers() {
    local type=$1 output="$2"
    local has_file=0 has_dir=0

    # Pengecekan support format baru (-F path) atau lama (-w)
    if echo "$output" | grep -Eq "(path=/etc/sudoers.*perm=wa|-w /etc/sudoers.*-p wa)"; then
        has_file=1
    fi
    if echo "$output" | grep -Eq "(dir=/etc/sudoers.d.*perm=wa|-w /etc/sudoers.d.*-p wa)"; then
        has_dir=1
    fi

    if [ "$has_file" -eq 1 ] && [ "$has_dir" -eq 1 ]; then
        a_output+=(" - $type: /etc/sudoers and /etc/sudoers.d rules found.")
        return 1
    else
        a_output2+=(" - $type: Rules for /etc/sudoers or /etc/sudoers.d are missing.")
        return 0
    fi
}

# Check Running (Loaded)
RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/etc\/sudoers')
f_check_sudoers "loaded" "$RUNNING"
LOADED_OK=$?

# Check Disk
DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/etc\/sudoers' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_sudoers "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: All required rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Audit rules for sudoers are incomplete. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}