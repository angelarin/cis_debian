#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.7"
DESCRIPTION="Ensure unsuccessful file access attempts are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_SYSCALLS=("creat" "open" "truncate") # Mencari superset creat|open|truncate
EXIT_CODES=("-EACCES" "-EPERM")
ARCHS=("b64" "b32")
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0
EXPECTED_TOTAL=8 # 2 exit codes * 2 archs * 2 sources (disk/loaded) = 8

# Dapatkan UID_MIN
L_UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$L_UID_MIN" ] && L_UID_MIN=1000

# --- FUNGSI AUDIT SYSCALLS ---
f_check_syscalls() {
    local source=$1 type=$2
    local cmd=""
    
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -F *auid>=${L_UID_MIN}/ && / -S/ && /creat/ && /open/ && /truncate/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -F *auid>=${L_UID_MIN}/ && / -S/ && /creat/ && /open/ && /truncate/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    local local_found_count=0

    for arch in "${ARCHS[@]}"; do
        for exit_code in "${EXIT_CODES[@]}"; do
            # Mencari S open/creat/truncate, F exit=<code>, F arch=<arch>, F auid>=<UID_MIN>, F key=access
            if echo "$L_OUTPUT" | grep -q "arch=b${arch/b/}" && echo "$L_OUTPUT" | grep -q "exit=${exit_code}" && echo "$L_OUTPUT" | grep -q "auid>=${L_UID_MIN}" && echo "$L_OUTPUT" | grep -q "key=access"; then
                local_found_count=$((local_found_count + 1))
                a_output+=(" - $type: Access rule found for arch=$arch, exit=$exit_code.")
            else
                a_output2+=(" - $type: Access rule MISSING for arch=$arch, exit=$exit_code.")
            fi
        done
    done
    
    return $local_found_count
}

# Run Checks
f_check_syscalls "disk" "Disk"
FOUND_COUNT_DISK=$?
f_check_syscalls "loaded" "Loaded"
FOUND_COUNT_LOADED=$?

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq 4 ] && [ "$FOUND_COUNT_LOADED" -eq 4 ]; then
    NOTES+="PASS: All 8 required rules (4 disk, 4 loaded) found. ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Access auditing failed (Disk: $FOUND_COUNT_DISK/4, Loaded: $FOUND_COUNT_LOADED/4). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}