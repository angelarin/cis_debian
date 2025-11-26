#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.4"
DESCRIPTION="Ensure events that modify date and time information are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_SYSCALLS=("adjtimex" "settimeofday" "clock_settime")
TARGET_FILE="/etc/localtime"
ARCHS=("b64" "b32")
FOUND_SYSCALL_DISK=0
FOUND_FILE_DISK=0
FOUND_SYSCALL_LOADED=0
FOUND_FILE_LOADED=0

# --- FUNGSI AUDIT SYSCALLS ---
f_check_syscalls() {
    local source=$1 type=$2 cmd="" target_archs=("$@")
    
    # Buat string syscalls yang dicari: S adjtimex|settimeofday|clock_settime
    local syscall_regex="S\/\(.*adjtimex\|settimeofday\|clock_settime\).*\/"
    
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ && (/(adjtimex|settimeofday)/ || /clock_settime/) && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -S/ && (/(adjtimex|settimeofday)/ || /clock_settime/) && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    local found_count=0
    
    for arch in "${ARCHS[@]}"; do
        if echo "$L_OUTPUT" | grep -q "arch=b${arch/b/}" && echo "$L_OUTPUT" | grep -q "key=time-change"; then
            found_count=$((found_count + 1))
        fi
    done
    
    if [ "$found_count" -ge 2 ]; then # Setidaknya 2 rule (b64 dan b32) ditemukan
        a_output+=(" - $type: Time-change syscall rules found for both archs.")
        return 1
    else
        a_output2+=(" - $type: Time-change syscall rules MISSING or incomplete (Found $found_count/2 archs).")
        return 0
    fi
}

# --- FUNGSI AUDIT FILE ---
f_check_file() {
    local source=$1 type=$2
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-w/ && /\\/etc\\/localtime/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-w/ && /\\/etc\\/localtime/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ]; then
        a_output+=(" - $type: Rule for $TARGET_FILE found.")
        return 1
    else
        a_output2+=(" - $type: Rule (-w $TARGET_FILE -p wa -k time-change) is MISSING.")
        return 0
    fi
}

# Run Checks
f_check_syscalls "disk" "Disk"
FOUND_SYSCALL_DISK=$?
f_check_file "disk" "Disk"
FOUND_FILE_DISK=$?
f_check_syscalls "loaded" "Loaded"
FOUND_SYSCALL_LOADED=$?
f_check_file "loaded" "Loaded"
FOUND_FILE_LOADED=$?


# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_SYSCALL_DISK" -eq 1 ] && [ "$FOUND_FILE_DISK" -eq 1 ] && \
   [ "$FOUND_SYSCALL_LOADED" -eq 1 ] && [ "$FOUND_FILE_LOADED" -eq 1 ]; then
    NOTES+="PASS: All 4 required rules (Disk and Loaded) found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Time change auditing failed. Failures: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}