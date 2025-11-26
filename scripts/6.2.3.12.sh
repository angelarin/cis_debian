#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.12"
DESCRIPTION="Ensure login and logout events are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=("/var/log/lastlog" "/var/run/faillock")
EXPECTED_TOTAL=2
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# --- FUNGSI AUDIT FILE MODIFICATION ---
f_check_files_modification() {
    local type=$1 source=$2
    local found_count=0
    
    for target in "${TARGET_FILES[@]}"; do
        local escaped_target=$(echo "$target" | sed 's/\//\\\/g')
        local cmd=""
        
        if [ "$source" = "disk" ]; then
            cmd="awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && / key= *[!-~]* *$/{print \$0}' /etc/audit/rules.d/*.rules"
        else
            cmd="auditctl -l | awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && / key= *[!-~]* *$/{print \$0}'"
        fi
        
        L_OUTPUT=$(eval "$cmd" 2>/dev/null)
        
        if [ -n "$L_OUTPUT" ] && echo "$L_OUTPUT" | grep -q "key=logins"; then
            a_output+=(" - $type: Rule for $target found.")
            found_count=$((found_count + 1))
        else
            a_output2+=(" - $type: Rule for $target (key=logins) is MISSING.")
        fi
    done
    
    return $found_count
}

# Run Checks
FOUND_COUNT_DISK=$(f_check_files_modification "Disk" "disk")
FOUND_COUNT_LOADED=$(f_check_files_modification "Loaded" "loaded")

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq "$EXPECTED_TOTAL" ] && [ "$FOUND_COUNT_LOADED" -eq "$EXPECTED_TOTAL" ]; then
    NOTES+="PASS: All $EXPECTED_TOTAL rules found (Disk and Loaded). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Login/Logout auditing failed (Disk: $FOUND_COUNT_DISK/$EXPECTED_TOTAL, Loaded: $FOUND_COUNT_LOADED/$EXPECTED_TOTAL). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}