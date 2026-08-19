#!/usr/bin/env bash

CHECK_ID="6.2.3.10"
DESCRIPTION="Ensure use of privileged commands are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
DISK_FAIL=0 RUNNING_FAIL=0

# Mencari semua file dengan SUID/SGID di partisi lokal
PRIV_FILES=$(findmnt -n -l -k -it $(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd,) | grep -Pv "noexec|nosuid" | awk '{print $1}' | xargs -I {} find "{}" -xdev -perm /6000 -type f 2>/dev/null)

if [ -z "$PRIV_FILES" ]; then
    NOTES="PASS: No privileged files found to audit."
else
    RUNNING=$(auditctl -l 2>/dev/null)
    
    for file in $PRIV_FILES; do
        # Check Disk
        if ! grep -qr "$file" /etc/audit/rules.d; then
            DISK_FAIL=$((DISK_FAIL+1))
            a_output2+=("Disk: $file missing.")
        fi
        
        # Check Loaded
        if ! echo "$RUNNING" | grep -q "$file"; then
            RUNNING_FAIL=$((RUNNING_FAIL+1))
            a_output2+=("Loaded: $file missing.")
        fi
    done
    
    if [ "$DISK_FAIL" -eq 0 ] && [ "$RUNNING_FAIL" -eq 0 ]; then
        NOTES="PASS: All privileged commands are audited."
    else
        RESULT="FAIL"
        NOTES="FAIL: Missing rules for privileged commands. ${a_output2[*]}"
    fi
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}