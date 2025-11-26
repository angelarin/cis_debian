#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.1.4.1"
DESCRIPTION="Ensure access to all logfiles has been configured"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""

# --- FUNGSI UTAMA AUDIT PER FILE ---
f_file_test_chk()
{
    local l_fname="$1" l_mode="$2" l_user="$3" l_group="$4"
    local perm_mask="$5" l_auser="$6" l_agroup="$7"
    local a_out2=()
    local maxperm
    maxperm="$( printf '%o' $(( 0777 & ~$perm_mask)) )"

    # 1. Cek Izin (Mode)
    # Jika mode saat ini ($l_mode) memiliki bit izin yang tidak boleh ada ($perm_mask)
    if [ $(( l_mode & perm_mask )) -gt 0 ]; then
        a_out2+=("Mode: \"$l_mode\" should be \"$maxperm\" or more restrictive")
    fi

    # 2. Cek Pemilik (User)
    if [[ ! "$l_user" =~ $l_auser ]]; then
        a_out2+=("Owned by: \"$l_user\" and should be owned by \"${l_auser//|/ or }\"")
    fi

    # 3. Cek Grup
    if [[ ! "$l_group" =~ $l_agroup ]]; then
        a_out2+=("Group owned by: \"$l_group\" and should be group owned by \"${l_agroup//|/ or }\"")
    fi

    [ "${#a_out2[@]}" -gt 0 ] && a_output2+=(" - File: \"$l_fname\" is NON-COMPLIANT:" "${a_out2[@]}")
}

# --- ITERASI FILE DAN PENENTUAN MASK/OWNERSHIP ---

# Mencari semua file di /var/log, mengabaikan permission 0137 (yaitu, setidaknya 640 atau 750)
while IFS= read -r -d $'\0' l_file; do
    while IFS=: read -r l_fname l_mode l_user l_group; do
        l_basename=$(basename "$l_fname")
        l_dirname=$(dirname "$l_fname")
        
        # Inisialisasi variabel untuk pengecekan
        perm_mask='0137'
        l_auser="(root|syslog)"
        l_agroup="(root|adm)"
        
        # 1. Kasus Khusus: /var/log/apt/
        if grep -Pq -- '\/(apt)\h*$' <<< "$l_dirname"; then
            perm_mask='0133' # Mode 644
            l_auser="root"
            l_agroup="(root|adm)"
        
        # 2. Kasus Khusus: Log Otentikasi/Terminal
        elif [[ "$l_basename" =~ ^lastlog ]] || \
             [[ "$l_basename" =~ ^wtmp ]] || \
             [[ "$l_basename" =~ ^btmp ]] || \
             [[ "$l_basename" = "README" ]]; then
            perm_mask='0113' # Mode 604
            l_auser="root"
            l_agroup="(root|utmp)"
        
        # 3. Kasus Khusus: Log Cloud/Local
        elif [[ "$l_basename" =~ ^cloud-init\.log ]] || \
             [[ "$l_basename" =~ ^localmessages ]] || \
             [[ "$l_basename" =~ ^waagent\.log ]]; then
            perm_mask='0133' # Mode 644
            l_auser="(root|syslog)"
            l_agroup="(root|adm)"

        # 4. Kasus Khusus: Log Keamanan (secure, auth, syslog)
        elif [[ "$l_basename" =~ ^secure ]] || \
             [[ "$l_basename" = "auth.log" ]] || \
             [[ "$l_basename" = "syslog" ]] || \
             [[ "$l_basename" = "messages" ]]; then
            perm_mask='0137' # Mode 640
            l_auser="(root|syslog)"
            l_agroup="(root|adm)"

        # 5. Kasus Khusus: Log SSSD
        elif [[ "$l_basename" =~ ^SSSD ]] || [[ "$l_basename" =~ ^sssd ]]; then
            perm_mask='0117' # Mode 600
            l_auser="(root|SSSD)"
            l_agroup="(root|SSSD)"

        # 6. Kasus Khusus: Log GDM
        elif [[ "$l_basename" = "gdm" ]] || [[ "$l_basename" = "gdm3" ]]; then
            perm_mask='0117' # Mode 600
            l_auser="root"
            l_agroup="(root|gdm|gdm3)"

        # 7. Kasus Khusus: Journald Logs
        elif [[ "$l_basename" =~ \.journal$ ]] || [[ "$l_basename" =~ \.journal~$ ]]; then
            perm_mask='0137' # Mode 640
            l_auser="root"
            l_agroup="(root|systemd-journal)"

        # 8. Kasus Default
        else
            # Jika user file bukan root DAN user TIDAK memiliki shell login yang valid,
            # maka user dan group file bisa diizinkan menjadi pemilik.
            if [ "$l_user" = "root" ] || ! grep -Pq -- "^\h*$(awk -F: '$1=="'"$l_user"'" {print $7}' /etc/passwd 2>/dev/null)\b" /etc/shells; then
                ! grep -Pq -- "$l_auser" <<< "$l_user" && l_auser="(root|syslog|$l_user)"
                ! grep -Pq -- "$l_agroup" <<< "$l_group" && l_agroup="(root|adm|$l_group)"
            fi
            perm_mask='0137' # Default Mode 640
        fi
        
        # Jalankan pemeriksaan
        f_file_test_chk "$l_fname" "$l_mode" "$l_user" "$l_group" "$perm_mask" "$l_auser" "$l_agroup"

    done < <(stat -Lc '%n:%#a:%U:%G' "$l_file")
done < <(find -L /var/log -type f \( -perm /0137 -o ! -user root -o ! -group root \) -print0 2>/dev/null)

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    a_output+=(" - All checked files in \"/var/log/\" have appropriate permissions and ownership.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}