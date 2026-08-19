#!/usr/bin/env bash

CHECK_ID="6.2.3.5"
DESCRIPTION="Ensure events that modify sethostname and setdomainname are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
ARCHS=("b32" "b64")

f_check_hostname() {
    local type=$1 output="$2"
    local found=0

    for arch in "${ARCHS[@]}"; do
        if echo "$output" | grep -q "arch=${arch}" && echo "$output" | grep -Eq "sethostname,setdomainname"; then
            found=$((found + 1))
        fi
    done

    if [ "$found" -ge 2 ]; then
        a_output+=(" - $type: sethostname/setdomainname rules found.")
        return 1
    else
        a_output2+=(" - $type: sethostname/setdomainname rules incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- 'sethostname|setdomainname')
f_check_hostname "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- 'sethostname|setdomainname' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_hostname "disk" "$DISK"
DISK_OK=$?

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ]; then
    NOTES+="PASS: Rules found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Syscall rules missing. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}