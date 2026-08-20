#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.11"
DESCRIPTION="Ensure world writable files and directories are secured"
# -----------------------------------------------------

{
a_output=() a_output2=() a_warn=() RESULT="PASS" NOTES=""
a_file=()
a_dir=()

# Dapatkan daftar mount point lokal yang relevan
mapfile -t a_mounts < <(findmnt -Dkerno target,fstype | awk '$2 !~ /^\s*(proc|sysfs|devtmpfs|devpts|tmpfs|cgroup|cgroup2|pstore|bpf|tracefs|debugfs|securityfs|fuse|iso9660|nfs|smb|vfat|efivarfs)/ {print $1}')

for l_mount in "${a_mounts[@]}"; do
    # 1. Cari world-writable files (-type f)
    while IFS= read -r -d $'\0' f; do
        a_file+=("$f")
    done < <(find "$l_mount" -xdev -type f -perm -0002 -print0 2>/dev/null)

    # 2. Cari world-writable directories TANPA sticky bit
    while IFS= read -r -d $'\0' d; do
        a_dir+=("$d")
    done < <(find "$l_mount" -xdev -type d -perm -0002 ! -perm -1000 -print0 2>/dev/null)
done

TOTAL_VIOLATIONS=$(( ${#a_file[@]} + ${#a_dir[@]} ))

# Ambil cuplikan (maksimal 5 item) untuk dimasukkan ke log
sample_files=$(printf '%s, ' "${a_file[@]:0:5}" | sed 's/, $//')
sample_dirs=$(printf '%s, ' "${a_dir[@]:0:5}" | sed 's/, $//')

# Evaluasi Ambang Batas (Minimal 5 -> FAIL)
if [ "$TOTAL_VIOLATIONS" -ge 5 ]; then
    RESULT="FAIL"
    [ "${#a_file[@]}" -gt 0 ] && a_output2+=("Found ${#a_file[@]} world-writable files (Sample: [$sample_files]).")
    [ "${#a_dir[@]}" -gt 0 ] && a_output2+=("Found ${#a_dir[@]} dirs without sticky bit (Sample: [$sample_dirs]).")
elif [ "$TOTAL_VIOLATIONS" -gt 0 ]; then
    RESULT="PASS"
    a_warn+=("WARNING: Found $TOTAL_VIOLATIONS violation(s) which is below threshold of 5 (Files: ${#a_file[@]}, Dirs: ${#a_dir[@]}).")
else
    RESULT="PASS"
    a_output+=("No world-writable files or unsecured directories found.")
fi

# Format Output Master Script
if [ "$RESULT" = "PASS" ]; then
    NOTES+="PASS: ${a_output[*]} ${a_warn[*]}"
else
    NOTES+="FAIL: Total violations >= 5. Details: ${a_output2[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}