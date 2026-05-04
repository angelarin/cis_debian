#!/usr/bin/env bash

{
  l_output=""
  l_output2=""
  a_suid=()
  a_sgid=()

  # --- 1. Mencari Mount Point yang Relevan ---
  # Mengabaikan file sistem virtual, jaringan, dan mount dengan opsi noexec/nosuid
  while IFS= read -r l_mount; do
    while IFS= read -r -d $'\0' l_file; do
      if [ -e "$l_file" ]; then
        l_mode="$(stat -Lc '%#a' "$l_file")"
        # Cek bit SUID (4000)
        [ $(( $l_mode & 04000 )) -gt 0 ] && a_suid+=("$l_file")
        # Cek bit SGID (2000)
        [ $(( $l_mode & 02000 )) -gt 0 ] && a_sgid+=("$l_file")
      fi
    done < <(find "$l_mount" -xdev -type f \( -perm -2000 -o -perm -4000 \) -print0 2>/dev/null)
  done < <(findmnt -Dkerno fstype,target,options | awk '($1 !~ /^\s*(nfs|proc|smb|vfat|iso9660|efivarfs|selinuxfs)/ && $2 !~ /^\/run\/user\// && $3 !~/noexec/ && $3 !~/nosuid/) {print $2}')

  # --- 2. Memproses Temuan SUID ---
  if ! (( ${#a_suid[@]} > 0 )); then
    l_output="$l_output\n - No executable SUID files exist on the system"
  else
    l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_suid[@]}")\" SUID executable files:\n$(printf '%s\n' "${a_suid[@]}")\n - end of list -\n"
  fi

  # --- 3. Memproses Temuan SGID ---
  if ! (( ${#a_sgid[@]} > 0 )); then
    l_output="$l_output\n - No SGID files exist on the system"
  else
    l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_sgid[@]}")\" SGID executable files:\n$(printf '%s\n' "${a_sgid[@]}")\n - end of list -\n"
  fi

  # --- 4. Pelaporan Hasil Audit ---
  [ -n "$l_output2" ] && l_output2="$l_output2\n- Review the preceding list(s) of SUID and/or SGID files to\n- ensure that no rogue programs have been introduced onto the system.\n"

  unset a_arr; unset a_suid; unset a_sgid 

  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n$l_output\n"
  else
    echo -e "\n- Audit Result:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "$l_output\n"
  fi
}