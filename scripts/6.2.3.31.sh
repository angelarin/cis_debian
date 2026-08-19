#!/usr/bin/env bash

CHECK_ID="6.2.3.31"
DESCRIPTION="Ensure kernel module loading unloading and modification is collected"

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$UID_MIN" ] && UID_MIN=1000

f_check_kmod() {
    local type=$1 output="$2"
    if echo "$output" | grep -Eq "(path=/usr/bin/kmod -F perm=x|-w /usr/bin/kmod -p x)" && \
       echo "$output" | grep -q "auid>=${UID_MIN}" && \
       echo "$output" | grep -Eq "(auid!=unset|auid!=-1|auid!=4294967295)"; then
        a_output+=(" - $type: kmod execution rule found.")
        return 1
    else
        a_output2+=(" - $type: kmod execution rule missing or incomplete.")
        return 0
    fi
}

RUNNING=$(auditctl -l 2>/dev/null | grep -Ps -- '^\h*[^#\n\r]+\h*\/usr\/bin\/kmod')
f_check_kmod "loaded" "$RUNNING"
LOADED_OK=$?

DISK=$(grep -hPs -- '^\h*[^#\n\r]+\h*\/usr\/bin\/kmod' /etc/audit/rules.d/*.rules 2>/dev/null)
f_check_kmod "disk" "$DISK"
DISK_OK=$?

# Symlink Check
SYMLINK_FAILS=0
a_files=("/usr/sbin/lsmod" "/usr/sbin/rmmod" "/usr/sbin/insmod" "/usr/sbin/modinfo" "/usr/sbin/modprobe" "/usr/sbin/depmod")
KMOD_TARGET=$(readlink -f /bin/kmod 2>/dev/null)

if [ -n "$KMOD_TARGET" ]; then
    for l_file in "${a_files[@]}"; do
        if [ "$(readlink -f "$l_file" 2>/dev/null)" != "$KMOD_TARGET" ]; then
            a_output2+=(" - Symlink issue: $l_file does not point to kmod.")
            SYMLINK_FAILS=$((SYMLINK_FAILS + 1))
        fi
    done
else
    a_output2+=(" - Symlink issue: Could not determine target of /bin/kmod.")
    SYMLINK_FAILS=$((SYMLINK_FAILS + 1))
fi

if [ "$LOADED_OK" -eq 1 ] && [ "$DISK_OK" -eq 1 ] && [ "$SYMLINK_FAILS" -eq 0 ]; then
    NOTES+="PASS: kmod rules and symlinks verified (UID_MIN=${UID_MIN}). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Issues found with kmod rules or symlinks. ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}