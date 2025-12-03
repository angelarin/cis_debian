#!/usr/bin/env bash

# --- 6.2.3.4: Ensure events that modify date and time information are collected ---

CHECK_ID="6.2.3.4"
DESCRIPTION="Ensure events that modify date and time information are collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/localtime"
ARCHS=("b64" "b32")
FOUND_SYSCALL_DISK=0
FOUND_FILE_DISK=0
FOUND_SYSCALL_LOADED=0
FOUND_FILE_LOADED=0

# Filter AWK yang ketat untuk aturan Syscall (memantau adjtimex, settimeofday, clock_settime)
# Logika ini mencari arch=b(32|64), -S (syscall), dan key=time-change
AWK_SYSCALL_FILTER='
    /^ *-a *always,exit/ && 
    / -F *arch=b(32|64)/ && 
    / -S/ && 
    (/(adjtimex|settimeofday)/ || /clock_settime/) && 
    (/ key= *time-change *$/||/ -k *time-change *$/) 
    { print $0 }
'

# Filter AWK yang ketat untuk aturan File Watch (/etc/localtime)
AWK_FILE_FILTER='
    /^ *-w/ && 
    /\/etc\/localtime/ && 
    / +-p *wa/ && 
    (/ key= *time-change *$/||/ -k *time-change *$/) 
    { print $0 }
'

# --- FUNGSI AUDIT SYSCALLS (Memeriksa perubahan waktu) ---
f_check_syscalls() {
    local source=$1 type=$2 cmd=""
    
    if [ "$source" = "disk" ]; then
        # *** PERBAIKAN: Menambahkan 'sudo' agar bisa membaca rules.d ***
        cmd="sudo awk '$AWK_SYSCALL_FILTER' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '$AWK_SYSCALL_FILTER'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    local found_b64=0
    local found_b32=0
    
    # Cek apakah aturan b64 dan b32 ditemukan (Total 4 aturan atau lebih)
    if echo "$L_OUTPUT" | grep -q "arch=b64" && echo "$L_OUTPUT" | grep -q "adjtimex" && echo "$L_OUTPUT" | grep -q "clock_settime"; then
        found_b64=1
    fi
    if echo "$L_OUTPUT" | grep -q "arch=b32" && echo "$L_OUTPUT" | grep -q "adjtimex" && echo "$L_OUTPUT" | grep -q "clock_settime"; then
        found_b32=1
    fi

    if [ "$found_b64" -eq 1 ] && [ "$found_b32" -eq 1 ]; then
        a_output+=(" - $type: Time-change syscall rules found for both archs.")
        return 1
    else
        a_output2+=(" - $type: Time-change syscall rules MISSING or incomplete.")
        return 0
    fi
}

# --- FUNGSI AUDIT FILE (Memeriksa /etc/localtime) ---
f_check_file() {
    local source=$1 type=$2 cmd=""
    
    if [ "$source" = "disk" ]; then
        # *** PERBAIKAN: Menambahkan 'sudo' agar bisa membaca rules.d ***
        cmd="sudo awk '$AWK_FILE_FILTER' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '$AWK_FILE_FILTER'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ]; then
        # Memastikan output juga mengandung key yang benar
        if echo "$L_OUTPUT" | grep -q "$TARGET_FILE" && echo "$L_OUTPUT" | grep -q "time-change"; then
            a_output+=(" - $type: Rule for $TARGET_FILE found.")
            return 1
        fi
    else
        a_output2+=(" - $type: Rule (-w $TARGET_FILE -p wa -k time-change) is MISSING.")
        return 0
    fi
}

# --- Run Checks ---
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
    NOTES+="PASS: All required time change auditing rules are correctly configured and loaded. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Time change auditing failed. Failures: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
