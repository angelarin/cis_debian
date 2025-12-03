#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.11"
DESCRIPTION="Ensure session initiation information is collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=("/var/run/utmp" "/var/log/wtmp" "/var/log/btmp")
EXPECTED_TOTAL=3
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# --- FUNGSI AUDIT FILE MODIFICATION ---
f_check_files_modification() {
    local type=$1 source=$2
    local found_count=0
    
    for target in "${TARGET_FILES[@]}"; do
        # PERBAIKAN ESCAPING
        local escaped_target=$(echo "$target" | sed 's/\//\\\//g')
        local cmd=""
        
        # PERBAIKAN AWK QUERY (menambahkan opsi ||/ -k ... /)
        if [ "$source" = "disk" ]; then
            cmd="awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}' /etc/audit/rules.d/*.rules"
        else
            cmd="sudo auditctl -l | awk '/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}'"
        fi
        
        # NOTE: Menambahkan sudo pada auditctl di sini karena biasanya butuh root.
        
        L_OUTPUT=$(eval "$cmd" 2>/dev/null)
        
        # Memastikan output valid dan mengandung key=session (walaupun key=session sudah dicari oleh awk)
        if [ -n "$L_OUTPUT" ]; then 
            a_output+=(" - $type: Rule for $target found.")
            found_count=$((found_count + 1))
        else
            a_output2+=(" - $type: Rule for $target is MISSING.")
        fi
    done
    
    return $found_count
}

# PERBAIKAN PEMANGGILAN FUNGSI (Menggunakan $? untuk return code)
f_check_files_modification "Disk" "disk"
FOUND_COUNT_DISK=$?

f_check_files_modification "Loaded" "loaded"
FOUND_COUNT_LOADED=$?

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq "$EXPECTED_TOTAL" ] && [ "$FOUND_COUNT_LOADED" -eq "$EXPECTED_TOTAL" ]; then
    RESULT="PASS"
    NOTES+="PASS: All $EXPECTED_TOTAL rules found (Disk and Loaded). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Session auditing failed (Disk: $FOUND_COUNT_DISK/$EXPECTED_TOTAL, Loaded: $FOUND_COUNT_LOADED/$EXPECTED_TOTAL). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
