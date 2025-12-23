#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.12"
DESCRIPTION="Ensure no files or directories without an owner and a group exist"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
a_nouser=(); a_nogroup=() # Array untuk melanggar

# Jalur yang dikecualikan
a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/fs/cgroup/memory/*" -a ! -path "/var/*/private/*")

# --- FUNGSI PENGUMPULAN ---
# Iterasi melalui target mount (mengecualikan fstype/mount point tertentu)
while IFS= read -r l_mount; do
    # Cari file/dir dengan -nouser ATAU -nogroup
    while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ]; then
            # Cek status secara eksplisit menggunakan stat (untuk menangani UNKNOWN)
            while IFS=: read -r l_user l_group; do
                if [ "$l_user" = "UNKNOWN" ] || stat -c '%u' "$l_file" 2>/dev/null | grep -q '^4294967294$'; then
                    a_nouser+=("$l_file")
                fi
                if [ "$l_group" = "UNKNOWN" ] || stat -c '%g' "$l_file" 2>/dev/null | grep -q '^4294967294$'; then
                    a_nogroup+=("$l_file")
                fi
            done < <(stat -Lc '%U:%G' "$l_file" 2>/dev/null)
        fi
    done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2> /dev/null)
done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\//){print $2}')

# Hapus duplikat dari array pelanggaran
a_nouser=($(printf "%s\n" "${a_nouser[@]}" | sort -u))
a_nogroup=($(printf "%s\n" "${a_nogroup[@]}" | sort -u))

# --- Assess Results ---
if (( ${#a_nouser[@]} > 0 )); then
    RESULT="FAIL"
    a_output2+=(" - Found ${#a_nouser[@]} unowned files or directories. Violations (sample): $(printf '%s\n' "${a_nouser[@]}" | head -n 5 | tr '\n' ' ')...")
else
    a_output+=(" - No files or directories without an owner exist on the local filesystem.")
fi

if (( ${#a_nogroup[@]} > 0 )); then
    RESULT="FAIL"
    a_output2+=(" - Found ${#a_nogroup[@]} ungrouped files or directories. Violations (sample): $(printf '%s\n' "${a_nogroup[@]}" | head -n 5 | tr '\n' ' ')...")
else
    a_output+=(" - No files or directories without a group exist on the local filesystem.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}