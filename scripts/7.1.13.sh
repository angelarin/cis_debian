#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.13"
DESCRIPTION="Ensure SUID and SGID files are reviewed (Manual Review)"
# -----------------------------------------------------

{
a_output=() RESULT="REVIEW" NOTES=""
a_suid=()
a_sgid=()

# Dapatkan partisi yang tidak berstatus nosuid/noexec dan bukan filesystem virtual
mapfile -t a_mounts < <(findmnt -Dkerno target,fstype,options | awk '($2 !~ /^\s*(proc|sysfs|devtmpfs|devpts|tmpfs|cgroup|cgroup2|pstore|bpf|tracefs|debugfs|securityfs|fuse|iso9660|nfs|smb|vfat|efivarfs)/ && $1 !~ /^\/run\/user\// && $3 !~ /noexec/ && $3 !~ /nosuid/) {print $1}')

for l_mount in "${a_mounts[@]}"; do
    # 1. Cari file dengan bit SUID (4000)
    while IFS= read -r -d $'\0' f; do
        a_suid+=("$f")
    done < <(find "$l_mount" -xdev -type f -perm /4000 -print0 2>/dev/null)

    # 2. Cari file dengan bit SGID (2000)
    while IFS= read -r -d $'\0' g; do
        a_sgid+=("$g")
    done < <(find "$l_mount" -xdev -type f -perm /2000 -print0 2>/dev/null)
done

# Cuplikan 5 file pertama yang aman
sample_suid=$(printf '%s, ' "${a_suid[@]:0:5}" | sed 's/, $//')
sample_sgid=$(printf '%s, ' "${a_sgid[@]:0:5}" | sed 's/, $//')

# Evaluasi SUID
if (( ${#a_suid[@]} > 0 )); then
    a_output+=("Detected ${#a_suid[@]} SUID file(s) (Sample: [$sample_suid]).")
else
    a_output+=("No SUID files found.")
fi

# Evaluasi SGID
if (( ${#a_sgid[@]} > 0 )); then
    a_output+=("Detected ${#a_sgid[@]} SGID file(s) (Sample: [$sample_sgid]).")
else
    a_output+=("No SGID files found.")
fi

# Format Output Master Script
NOTES="REVIEW: ${a_output[*]} Verify that all executable binaries with SUID/SGID bits are required and legitimate."

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}