#!/usr/bin/env bash

{
    a_output=()
    a_output2=()

    # --- 1. Fungsi Pengecekan Izin & Kepemilikan ---
    f_file_test_chk() {
        a_out2=()
        maxperm="$(printf '%o' $((0777 & ~$perm_mask)))"
        
        # Cek Mode (Permissions)
        if [ $(($l_mode & $perm_mask)) -gt 0 ]; then
            a_out2+=("o Mode: \"$l_mode\" should be \"$maxperm\" or more restrictive")
        fi
        
        # Cek User (Owner)
        if [[ ! "$l_user" =~ $l_auser ]]; then
            a_out2+=("o Owned by: \"$l_user\" and should be owned by \"${l_auser//|/ or }\"")
        fi
        
        # Cek Group
        if [[ ! "$l_group" =~ $l_agroup ]]; then
            a_out2+=("o Group owned by: \"$l_group\" and should be group owned by \"${l_agroup//|/ or }\"")
        fi
        
        # Jika ada temuan, masukkan ke output utama
        [ "${#a_out2[@]}" -gt 0 ] && a_output2+=(" - File: \"$l_fname\" is:" "${a_out2[@]}")
    }

    # --- 2. Loop Utama Pencarian File di /var/log ---
    while IFS= read -r -d $'\0' l_file; do
        while IFS=: read -r l_fname l_mode l_user l_group; do
            
            # Kategori: APT Logs
            if grep -Pq -- '\/(apt)\h*$' <<< "$(dirname "$l_fname")"; then
                perm_mask='0133'; l_auser="root"; l_agroup="(root|adm)"
                f_file_test_chk
            else
                case "$(basename "$l_fname")" in
                    # Kategori: Log Sistem Login
                    lastlog | lastlog.* | wtmp | wtmp.* | wtmp-* | btmp | btmp.* | btmp-* | README)
                        perm_mask='0113'; l_auser="root"; l_agroup="(root|utmp)"
                        f_file_test_chk ;;
                    
                    # Kategori: Cloud & Agent Logs
                    cloud-init.log* | localmessages* | waagent.log*)
                        perm_mask='0133'; l_auser="(root|syslog)"; l_agroup="(root|adm)"
                        f_file_test_chk ;;
                    
                    # Kategori: Auth & Critical Messages
                    secure{,*.*,.*,-*} | auth.log | syslog | messages)
                        perm_mask='0137'; l_auser="(root|syslog)"; l_agroup="(root|adm)"
                        f_file_test_chk ;;
                    
                    # Kategori: SSSD
                    SSSD | sssd)
                        perm_mask='0117'; l_auser="(root|SSSD)"; l_agroup="(root|SSSD)"
                        f_file_test_chk ;;
                    
                    # Kategori: GDM (Desktop)
                    gdm | gdm3)
                        perm_mask='0117'; l_auser="root"; l_agroup="(root|gdm|gdm3)"
                        f_file_test_chk ;;
                    
                    # Kategori: Systemd Journal
                    *.journal | *.journal~)
                        perm_mask='0137'; l_auser="root"; l_agroup="(root|systemd-journal)"
                        f_file_test_chk ;;
                    
                    # Kategori: Lainnya (Default)
                    *)
                        perm_mask='0137'; l_auser="(root|syslog)"; l_agroup="(root|adm)"
                        # Dinamis: Izinkan service account jika tidak memiliki login shell
                        if [ "$l_user" = "root" ] || ! grep -Pq -- "^\h*$(awk -F: '$1=="'"$l_user"'" {print $7}' /etc/passwd)\b" /etc/shells; then
                            ! grep -Pq -- "$l_auser" <<< "$l_user" && l_auser="(root|syslog|$l_user)"
                            ! grep -Pq -- "$l_agroup" <<< "$l_group" && l_agroup="(root|adm|$l_group)"
                        fi
                        f_file_test_chk ;;
                esac
            fi
        done < <(stat -Lc '%n:%#a:%U:%G' "$l_file")
    done < <(find -L /var/log -type f \( -perm /0137 -o ! -user root -o ! -group root \) -print0)

    # --- 3. Pelaporan Hasil Audit ---
    if [ "${#a_output2[@]}" -le 0 ]; then
        a_output+=(" - All files in \"/var/log/\" have appropriate permissions and ownership")
        printf '\n%s' "- Audit Result:" " ** PASS **" "${a_output[@]}" ""
    else
        printf '\n%s' "- Audit Result:" " ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}" ""
    fi
}