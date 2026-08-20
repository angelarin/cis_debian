#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.12"
DESCRIPTION="Ensure no files or directories without an owner and a group exist"
# -----------------------------------------------------

{
a_output=() a_output2=() a_warn=() RESULT="PASS" NOTES=""
a_nouser=()
a_nogroup=()

# Dapatkan daftar mount point lokal yang relevan
mapfile -t a_mounts < <(findmnt -Dkerno target,fstype | awk '$2 !~ /^\s*(proc|sysfs|devtmpfs|devpts|tmpfs|cgroup|cgroup2|pstore|bpf|tracefs|debugfs|securityfs|fuse|iso9660|nfs|smb|vfat|efivarfs)/ {print $1}')

for l_mount in "${a_mounts[@]}"; do
    # Cari file/direktori tanpa user (nouser)
    while IFS= read -r -d $'\0' f; do
        a_nouser+=("$f")
    done < <(find "$l_mount" -xdev \( -type f -o -type d \) -nouser -print0 2>/dev/null)

    # Cari file/direktori tanpa group (nogroup)
    while IFS= read -r -d $'\0' g; do
        a_nogroup+=("$g")
    done < <(find "$l_mount" -xdev \( -type f -o -type d \) -nogroup -print0 2>/dev/null)
done

TOTAL_VIOLATIONS=$(( ${#a_nouser[@]} + ${#a_nogroup[@]} ))

# Ambil cuplikan (maksimal 5 item) untuk log CSV
sample_nouser=$(printf '%s, ' "${a_nouser[@]:0:5}" | sed 's/, $//')
sample_nogroup=$(printf '%s, ' "${a_nogroup[@]:0:5}" | sed 's/, $//')

# Evaluasi Ambang Batas (Minimal 5 -> FAIL)
if [ "$TOTAL_VIOLATIONS" -ge 5 ]; then
    RESULT="FAIL"
    [ "${#a_nouser[@]}" -gt 0 ] && a_output2+=("Found ${#a_nouser[@]} unowned items (Sample: [$sample_nouser]).")
    [ "${#a_nogroup[@]}" -gt 0 ] && a_output2+=("Found ${#a_nogroup[@]} ungrouped items (Sample: [$sample_nogroup]).")
elif [ "$TOTAL_VIOLATIONS" -gt 0 ]; then
    RESULT="PASS"
    a_warn+=("WARNING: Found $TOTAL_VIOLATIONS violation(s) which is below threshold of 5 (Unowned: ${#a_nouser[@]}, Ungrouped: ${#a_nogroup[@]}).")
else
    RESULT="PASS"
    a_output+=("No unowned or ungrouped files/directories found.")
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