#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.1.13"
DESCRIPTION="Ensure SUID and SGID files are reviewed (Manual Review)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
a_suid=(); a_sgid=() # Array untuk menyimpan file yang ditemukan

# --- FUNGSI PENGUMPULAN ---
# Iterasi melalui mount point yang tidak memiliki nosuid/noexec
while IFS= read -r l_mount; do
    # Cari semua file di bawah mount point ini yang memiliki -2000 (SGID) atau -4000 (SUID)
    while IFS= read -r -d $'\0' l_file; do
        if [ -e "$l_file" ] && [ -f "$l_file" ]; then # Pastikan itu file
            l_mode="$(stat -Lc '%#a' "$l_file")"
            [ $(( l_mode & 04000 )) -gt 0 ] && a_suid+=("$l_file")
            [ $(( l_mode & 02000 )) -gt 0 ] && a_sgid+=("$l_file")
        fi
    done < <(find "$l_mount" -xdev -type f \( -perm -2000 -o -perm -4000 \) -print0 2> /dev/null)
done < <(findmnt -Dkerno fstype,target,options | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\// && $3 !~/noexec/ && $3 !~/nosuid/) {print $2}')

# Hapus duplikat
a_suid=($(printf "%s\n" "${a_suid[@]}" | sort -u))
a_sgid=($(printf "%s\n" "${a_sgid[@]}" | sort -u))


# --- Assess Results ---
if (( ${#a_suid[@]} > 0 )); then
    L_SUID_LIST=$(printf '%s, ' "${a_suid[@]}" | head -c -2) # Pisahkan dengan koma
    a_output+=(" - Detected ${#a_suid[@]} SUID executable files. List (sample): ${L_SUID_LIST:0:200}...")
else
    a_output+=(" - No SUID files found on eligible partitions.")
fi

if (( ${#a_sgid[@]} > 0 )); then
    L_SGID_LIST=$(printf '%s, ' "${a_sgid[@]}" | head -c -2)
    a_output+=(" - Detected ${#a_sgid[@]} SGID executable files. List (sample): ${L_SGID_LIST:0:200}...")
else
    a_output+=(" - No SGID files found on eligible partitions.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
NOTES+="REVIEW: SUID/SGID files require manual inspection to verify they are legitimate and necessary. ${a_output[*]}"
NOTES+=" | Action: Review the preceding list(s) of SUID and/or SGID files to ensure that no rogue programs have been introduced onto the system."

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}