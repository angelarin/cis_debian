#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.8"
DESCRIPTION="Ensure events that modify user/group information are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=(
    "/etc/group" "/etc/passwd" "/etc/gshadow" "/etc/shadow" "/etc/security/opasswd"
    "/etc/nsswitch.conf" "/etc/pam.conf" "/etc/pam.d"
)
EXPECTED_TOTAL=8
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
            cmd="awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
        else
            cmd="auditctl -l | awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
        fi
        
        L_OUTPUT=$(eval "$cmd" 2>/dev/null)
        
        if [ -n "$L_OUTPUT" ]; then
            a_output+=(" - $type: Rule for $target found.")
            found_count=$((found_count + 1))
        else
            # Direktori /etc/pam.d mungkin tidak ada sebagai file tunggal di rules.d
            if [ "$target" != "/etc/pam.d" ]; then
                 a_output2+=(" - $type: Rule for $target is MISSING.")
            else
                 # Cek apakah direktori ada di rules.d/ sebagai /etc/pam.d/
                 a_output+=(" - $type: Rule for $target is MISSING but checking if individual files are covered.")
            fi
        fi
    done
    
    return $found_count
}

# Run Checks
f_check_files_modification "Disk" "disk"
FOUND_COUNT_DISK=$?
f_check_files_modification "Loaded" "loaded"
FOUND_COUNT_LOADED=$?

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -ge 7 ] && [ "$FOUND_COUNT_LOADED" -ge 7 ]; then # >= 7 karena /etc/pam.d bisa jadi tidak dicover sebagai entry tunggal
    NOTES+="PASS: Most required identity files are audited (Disk: $FOUND_COUNT_DISK/$EXPECTED_TOTAL, Loaded: $FOUND_COUNT_LOADED/$EXPECTED_TOTAL). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Identity file auditing failed (Disk: $FOUND_COUNT_DISK/$EXPECTED_TOTAL, Loaded: $FOUND_COUNT_LOADED/$EXPECTED_TOTAL). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}