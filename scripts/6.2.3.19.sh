#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.19"
DESCRIPTION="Ensure kernel module loading unloading and modification is collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
KMOD_PATH="/usr/bin/kmod"
SYSCALLS=("init_module" "finit_module" "delete_module" "create_module" "query_module")
ARCHS=("b64" "b32")
EXPECTED_SYSCALL_RULES=2 # 1 rule per arch for syscall group
EXPECTED_KMOD_RULES=2    # 1 rule per arch for kmod path
FOUND_SYSCALL_DISK=0
FOUND_KMOD_DISK=0
FOUND_SYSCALL_LOADED=0
FOUND_KMOD_LOADED=0

# Dapatkan UID_MIN
L_UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$L_UID_MIN" ] && L_UID_MIN=1000

# Fungsi bantu untuk cek Sycalls
f_check_syscalls() {
    local type=$1 source=$2
    local cmd=""
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -F *auid!=(unset|-1|4294967295)/ && / -S/ && (/(init_module|finit_module|delete_module|create_module|query_module)/) && / key=kernel_modules/{print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b(32|64)/ && / -F *auid!=(unset|-1|4294967295)/ && / -S/ && (/(init_module|finit_module|delete_module|create_module|query_module)/) && / key=kernel_modules/{print \$0}'"
    fi
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    local found_count=0
    for arch in "${ARCHS[@]}"; do
        if echo "$L_OUTPUT" | grep -q "arch=b${arch/b/}" && echo "$L_OUTPUT" | grep -q "key=kernel_modules"; then
            found_count=$((found_count + 1))
        fi
    done
    return $found_count
}

# Fungsi bantu untuk cek kmod path
f_check_kmod() {
    local type=$1 source=$2
    local cmd=""
    if [ "$source" = "disk" ]; then
        cmd="awk '/^ *-a *always,exit/ && / -F *auid>=${L_UID_MIN}/ && / -F *perm=x/ && / -F *path=${KMOD_PATH}/ && / key=kernel_modules/{print \$0}' /etc/audit/rules.d/*.rules"
    else
        cmd="auditctl -l | awk '/^ *-a *always,exit/ && / -F *auid>=${L_UID_MIN}/ && / -F *perm=x/ && / -F *path=${KMOD_PATH}/ && / key=kernel_modules/{print \$0}'"
    fi
    L_OUTPUT=$(eval "$cmd" 2>/dev/null)
    if [ -n "$L_OUTPUT" ] && echo "$L_OUTPUT" | grep -q "path=$KMOD_PATH" && echo "$L_OUTPUT" | grep -q "key=kernel_modules"; then
        a_output+=(" - $type: kmod path rule found.")
        return 1
    else
        a_output2+=(" - $type: kmod path rule MISSING or incorrect.")
        return 0
    fi
}

# Run Checks
FOUND_SYSCALL_DISK=$(f_check_syscalls "Disk" "disk")
FOUND_KMOD_DISK=$(f_check_kmod "Disk" "disk")
FOUND_SYSCALL_LOADED=$(f_check_syscalls "Loaded" "loaded")
FOUND_KMOD_LOADED=$(f_check_kmod "Loaded" "loaded")

if [ "$FOUND_SYSCALL_DISK" -eq "$EXPECTED_SYSCALL_RULES" ] && [ "$FOUND_KMOD_DISK" -eq 1 ]; then
    a_output+=(" - Disk: All required kernel module rules found.")
else
    RESULT="FAIL"
    a_output2+=(" - Disk: Kernel module syscalls ($FOUND_SYSCALL_DISK/$EXPECTED_SYSCALL_RULES) or kmod path ($FOUND_KMOD_DISK/1) rules missing/incorrect.")
fi

if [ "$FOUND_SYSCALL_LOADED" -eq "$EXPECTED_SYSCALL_RULES" ] && [ "$FOUND_KMOD_LOADED" -eq 1 ]; then
    a_output+=(" - Loaded: All required kernel module rules found.")
else
    RESULT="FAIL"
    a_output2+=(" - Loaded: Kernel module syscalls ($FOUND_SYSCALL_LOADED/$EXPECTED_SYSCALL_RULES) or kmod path ($FOUND_KMOD_LOADED/1) rules missing/incorrect.")
fi

# --- Cek Symlink (Tambahan) ---
a_files=("/usr/sbin/lsmod" "/usr/sbin/rmmod" "/usr/sbin/insmod" "/usr/sbin/modinfo" "/usr/sbin/modprobe" "/usr/sbin/depmod")
for l_file in "${a_files[@]}"; do
    if [ "$(readlink -f "$l_file" 2>/dev/null)" = "$(readlink -f /bin/kmod 2>/dev/null)" ]; then
        a_output+=(" - Symlink OK: \"$l_file\" points to kmod.")
    else
        a_output2+=(" - Symlink Issue: \"$l_file\" does not point to kmod. Investigation required.")
        RESULT="FAIL"
    fi
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: All required kernel module rules and symlinks are correct. ${a_output[*]}"
else
    NOTES+="FAIL: Kernel module auditing or symlinks failed. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}