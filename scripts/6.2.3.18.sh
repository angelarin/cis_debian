#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.18"
DESCRIPTION="Ensure successful and unsuccessful attempts to use the usermod command are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_PATH="/usr/sbin/usermod"
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# Dapatkan UID_MIN
L_UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$L_UID_MIN" ] && L_UID_MIN=1000

# Fungsi bantu untuk cek dan mengembalikan 1 jika PASS
f_check_usermod() {
    local type=$1 source=$2
    local cmd=""
    
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *auid>=${L_UID_MIN}/ && / -F *perm=x/ && / -F *path=${TARGET_PATH}/ && / key=usermod/{print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *auid>=${L_UID_MIN}/ && / -F *perm=x/ && / -F *path=${TARGET_PATH}/ && / key=usermod/{print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ] && echo "$L_OUTPUT" | grep -q "path=$TARGET_PATH" && echo "$L_OUTPUT" | grep -q "key=usermod"; then
        a_output+=(" - $type: usermod rule found.")
        return 1
    else
        a_output2+=(" - $type: usermod rule MISSING or incorrect.")
        return 0
    fi
}

# Run Checks
FOUND_COUNT_DISK=$(f_check_usermod "Disk" "disk")
FOUND_COUNT_LOADED=$(f_check_usermod "Loaded" "loaded")

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq 1 ] && [ "$FOUND_COUNT_LOADED" -eq 1 ]; then
    NOTES+="PASS: All required usermod rules found (Disk: $FOUND_COUNT_DISK/1, Loaded: $FOUND_COUNT_LOADED/1). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: usermod auditing failed (Disk: $FOUND_COUNT_DISK/1, Loaded: $FOUND_COUNT_LOADED/1). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}