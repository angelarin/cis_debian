#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.9"
DESCRIPTION="Ensure discretionary access control permission modification events are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
ARCHS=("b64" "b32")
FOUND_COUNT_DISK=0
FOUND_COUNT_LOADED=0
EXPECTED_TOTAL=12 # 6 rule per arch * 2 archs

# Dapatkan UID_MIN
L_UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$L_UID_MIN" ] && L_UID_MIN=1000

# Fungsi bantu untuk cek arsitektur dan mengembalikan 1 jika PASS
f_check_dac_arch() {
    local arch=$1 type=$2
    local cmd=""
    
    if [ "$type" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *arch=b${arch/b/}/ && / -F *auid>=${L_UID_MIN}/ && / -S/ && (/(chmod|fchmod|fchmodat)/ || /(chown|fchown|fchownat|lchown)/ || /(setxattr|lsetxattr|fsetxattr)/) && / key=perm_mod/{print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b${arch/b/}/ && / -F *auid>=${L_UID_MIN}/ && / -S/ && (/(chmod|fchmod|fchmodat)/ || /(chown|fchown|fchownat|lchown)/ || /(setxattr|lsetxattr|fsetxattr)/) && / key=perm_mod/{print \$0}'"
    fi
    
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    
    if [ -n "$L_OUTPUT" ] && echo "$L_OUTPUT" | grep -q "key=perm_mod"; then
        a_output+=(" - $type: DAC rules for arch=$arch found.")
        return 1
    else
        a_output2+=(" - $type: DAC rules for arch=$arch MISSING or incorrect.")
        return 0
    fi
}

# Run Checks
for arch in "${ARCHS[@]}"; do
    f_check_dac_arch "$arch" "Disk"
    FOUND_COUNT_DISK=$((FOUND_COUNT_DISK + $?))
    f_check_dac_arch "$arch" "Loaded"
    FOUND_COUNT_LOADED=$((FOUND_COUNT_LOADED + $?))
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$FOUND_COUNT_DISK" -eq 2 ] && [ "$FOUND_COUNT_LOADED" -eq 2 ]; then
    NOTES+="PASS: All required DAC modification rules found (Disk: $FOUND_COUNT_DISK/2, Loaded: $FOUND_COUNT_LOADED/2). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: DAC modification auditing failed (Disk: $FOUND_COUNT_DISK/2, Loaded: $FOUND_COUNT_LOADED/2). ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}