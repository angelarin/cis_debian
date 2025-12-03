#!/usr/bin/env bash

# --- Informasi Audit ---
CHECK_ID="6.2.3.8"
DESCRIPTION="Ensure events that modify user/group information are collected"
# -----------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES=(
    "/etc/group" "/etc/passwd" "/etc/gshadow" "/etc/shadow" "/etc/security/opasswd"
    "/etc/nsswitch.conf" "/etc/pam.conf" "/etc/pam.d"
)
EXPECTED_TOTAL=${#TARGET_FILES[@]}
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0

# --- FUNGSI AUDIT FILE MODIFICATION ---
f_check_files_modification() {
    local type=$1 source=$2
    local found_count=0
    
    for target in "${TARGET_FILES[@]}"; do
        # PERBAIKAN: Mengganti / dengan \/ agar awk bisa mencocokkan path secara literal
        local escaped_target=$(echo "$target" | sed 's/\//\\\//g') 
        local cmd=""
        
        # AWK Pattern yang digunakan: /target/ && / -p wa/ && / key=.../
        local awk_pattern="/^ *-w/ && /${escaped_target}/ && / +-p *wa/ && (/ key= *[!-~]* *$/||/ -k *[!-~]* *$/){print \$0}"
        
        if [ "$source" = "disk" ]; then
            # Pengecekan Disk: Mengarahkan error 'No such file' ke /dev/null
            # Perhatikan: Karena Anda menggunakan path eksplisit /etc/audit/rules.d/50-identity.rules 
            # dalam manual check Anda, kita tetap menggunakan *.rules untuk fleksibilitas, 
            # dan menekan error 'No such file' yang disebabkan oleh globbing yang gagal.
            cmd="awk '${awk_pattern}' /etc/audit/rules.d/*.rules 2>/dev/null"
        else
            # Pengecekan Loaded: auditctl -l
            cmd="sudo auditctl -l | awk '${awk_pattern}'"
        fi
        
        # Eksekusi perintah
        L_OUTPUT=$(eval "$cmd")
        
        if [ -n "$L_OUTPUT" ]; then
            a_output+=(" - $type: Rule for $target found.")
            found_count=$((found_count + 1))
        else
            a_output2+=(" - $type: Rule for $target is MISSING.")
        fi
    done
    
    return $found_count
}

# Jalankan Pengecekan
f_check_files_modification "Disk" "disk"
FOUND_COUNT_DISK=$?
f_check_files_modification "Loaded" "loaded"
FOUND_COUNT_LOADED=$?

# --- LOGIKA OUTPUT FINAL ---
REQUIRED_PASS_COUNT=8 

if [ "$FOUND_COUNT_DISK" -ge $REQUIRED_PASS_COUNT ] && [ "$FOUND_COUNT_LOADED" -ge $REQUIRED_PASS_COUNT ]; then
    RESULT="PASS"
    NOTES+="PASS: All required identity files are audited (Disk: $FOUND_COUNT_DISK/$EXPECTED_TOTAL, Loaded: $FOUND_COUNT_LOADED/$EXPECTED_TOTAL). ${a_output[*]}"
else
    RESULT="FAIL"
    # Menampilkan file yang hilang (a_output2) dan yang ditemukan (a_output) untuk detail
    NOTES+="FAIL: Identity file auditing failed (Disk: $FOUND_COUNT_DISK/$EXPECTED_TOTAL, Loaded: $FOUND_COUNT_LOADED/$EXPECTED_TOTAL)."
    [ "${#a_output2[@]}" -gt 0 ] && NOTES+=" MISSING: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" FOUND: ${a_output[*]}"
fi

# Format output akhir
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}
