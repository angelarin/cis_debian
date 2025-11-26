#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.15"
DESCRIPTION="Ensure successful and unsuccessful attempts to use the chcon command are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_PATH="/usr/bin/chcon"
ARCHS=("b64" "b32")
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# Dapatkan UID_MIN
L_UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$L_UID_MIN" ] && L_UID_MIN=1000

# Fungsi bantu untuk cek arsitektur dan mengembalikan 1 jika PASS
f_check_chcon() {
    local type=$1 source=$2
    local cmd=""
    
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *auid>=${L_UID_MIN}/ && / -F *perm=x/ && / -F *path=${TARGET_PATH}/ && / key=perm_chng/{print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *auid>=${L_UID_MIN}/ && / -F *perm=x/ && / -F *path=${TARGET_PATH}/ && / key=perm_chng/{print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    
    # Karena chcon hanya berlaku untuk satu path, kita hanya cek keberadaannya
    if [ -n "$L_OUTPUT" ] && echo "$L_OUTPUT" | grep -q "path=$TARGET_PATH" && echo "$L_OUTPUT" | grep -q "key=perm_chng"; then
        a_output+=(" - $type: chcon rule found.")
        return 1
    else
        a_output2+=(" - $type: chcon rule MISSING or incorrect.")
        return 0
    fi
}

# Run Checks
FOUND_COUNT_DISK=$(f_check_chcon "Disk" "disk")
FOUND_COUNT_LOADED=$(f_check_chcon "Loaded" "loaded")

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq 1 ] && [ "$FOUND_COUNT_LOADED" -eq 1 ]; then
    NOTES+="PASS: All required chcon rules found (Disk: $FOUND_COUNT_DISK/1, Loaded: $FOUND_COUNT_LOADED/1). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: chcon auditing failed (Disk: $FOUND_COUNT_DISK/1, Loaded: $FOUND_COUNT_LOADED/1). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}