#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.11"
DESCRIPTION="Ensure world writable files and directories are secured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_smask='01000' # Sticky bit mask
a_file=(); a_dir=() # Array untuk melanggar
# Jalur yang dikecualikan (disusun dalam format find -a/-o)
a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "*/kubelet/plugins/*" -a ! -path "/sys/*" -a ! -path "/snap/*")

# --- FUNGSI PENGUMPULAN ---
# Iterasi melalui target mount (mengecualikan fstype/mount point tertentu)
while IFS= read -r l_mount; do
    # Cari semua file/dir di bawah mount point ini yang memiliki izin -0002 (world writable)
    while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ]; then
            if [ -f "$l_file" ]; then
                # FILE: World Writable File (Selalu Gagal)
                a_file+=("$l_file")
            elif [ -d "$l_file" ]; then
                # DIRECTORY: World Writable Directory (Cek Sticky Bit)
                l_mode="$(stat -Lc '%#a' "$l_file")"
                # Jika sticky bit TIDAK diatur (01000)
                if [ ! $(( l_mode & l_smask )) -gt 0 ]; then
                    a_dir+=("$l_file")
                fi
            fi
        fi
    done < <(find "$l_mount" -xdev \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2> /dev/null)
done < <(findmnt -Dkerno fstype,target | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^(\/run\/user\/|\/tmp|\/var\/tmp)/){print $2}')


# --- Assess Results ---
if (( ${#a_file[@]} > 0 )); then
    RESULT="FAIL"
    a_output2+=(" - Found ${#a_file[@]} World writable FILES. Violations: $(printf '%s' "${a_file[@]}" | head -n 5 | tr '\n' ' ')...")
else
    a_output+=(" - No world writable files exist on the local filesystem.")
fi

if (( ${#a_dir[@]} > 0 )); then
    RESULT="FAIL"
    a_output2+=(" - Found ${#a_dir[@]} World writable DIRECTORIES WITHOUT the sticky bit. Violations: $(printf '%s' "${a_dir[@]}" | head -n 5 | tr '\n' ' ')...")
else
    a_output+=(" - Sticky bit is set on all world writable directories.")
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