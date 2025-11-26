#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.5"
DESCRIPTION="Ensure events that modify the system's network environment are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_SYSCALLS=("sethostname" "setdomainname")
TARGET_FILES=("/etc/issue" "/etc/issue.net" "/etc/hosts" "/etc/networks" "/etc/network" "/etc/netplan")
ARCHS=("b64" "b32")
FOUND_SYSCALL_DISK=0
FOUND_FILE_DISK=0
EXPECTED_FILE_RULES=6
FILE_RULE_COUNT_DISK=0
FILE_RULE_COUNT_LOADED=0

# --- FUNGSI AUDIT SYSCALLS ---
f_check_syscalls() {
    local type=$1 cmd=""
    if [ "$type" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ && (/(sethostname)/ || /(setdomainname)/) && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ && (/(sethostname)/ || /(setdomainname)/) && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    local found_count=0
    
    for arch in "${ARCHS[@]}"; do
        if echo "$L_OUTPUT" | grep -q "arch=b${arch/b/}" && echo "$L_OUTPUT" | grep -q "key=system-locale"; then
            found_count=$((found_count + 1))
        fi
    done
    
    if [ "$found_count" -ge 2 ]; then
        a_output+=(" - $type: System-locale syscall rules found for both archs.")
        return 1
    else
        a_output2+=(" - $type: System-locale syscall rules MISSING or incomplete (Found $found_count/2 archs).")
        return 0
    fi
}

# --- FUNGSI AUDIT FILE ---
f_check_file() {
    local type=$1
    local found_count=0
    
    for target in "${TARGET_FILES[@]}"; do
        # Escape path for regex matching
        local escaped_target=$(echo "$target" | sed 's/\//\\\/g')
        local cmd=""
        
        if [ "$type" = "disk" ]; then
            cmd="awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
        else
            cmd="auditctl -l | awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
        fi
        
        L_OUTPUT=$(eval "$cmd" 2>/dev/null)
        
        if [ -n "$L_OUTPUT" ]; then
            a_output+=(" - $type: Rule for $target found.")
            found_count=$((found_count + 1))
        else
            a_output2+=(" - $type: Rule (-w $target -p wa -k system-locale) is MISSING.")
        fi
    done
    
    if [ "$found_count" -eq "$EXPECTED_FILE_RULES" ]; then
        return 1
    else
        return 0
    fi
}

# Run Checks
f_check_syscalls "disk"
FOUND_SYSCALL_DISK=$?
f_check_syscalls "loaded"
FOUND_SYSCALL_LOADED=$?

f_check_file "disk"
FOUND_FILE_DISK=$?
FILE_RULE_COUNT_DISK=$? # Mengembalikan 0 atau 1, tidak menghitung jumlah.

f_check_file "loaded"
FOUND_FILE_LOADED=$?


# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_SYSCALL_DISK" -eq 1 ] && [ "$FOUND_SYSCALL_LOADED" -eq 1 ] && \
   [ "$FOUND_FILE_DISK" -eq 1 ] && [ "$FOUND_FILE_LOADED" -eq 1 ]; then
    NOTES+="PASS: All required rules (syscalls and files) found (Disk and Loaded). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Network environment auditing failed. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}