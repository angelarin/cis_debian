#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="7.2.10"
DESCRIPTION="Ensure local interactive user dot files access is configured"
# -----------------------------------------------------

{
a_output=() a_output2=() a_output3=() RESULT="PASS" NOTES=""
l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells 2>/dev/null | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
a_user_and_home=()

while read -r l_local_user l_local_user_home; do
    [[ -n "$l_local_user" && -n "$l_local_user_home" ]] && a_user_and_home+=("$l_local_user:$l_local_user_home")
done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd 2>/dev/null)"


file_access_chk()
{
    local l_hdfile="$1" l_mode="$2" l_owner="$3" l_gowner="$4" l_user="$5" l_group="$6" l_mask="$7" l_max="$8"
    local a_access_out=()
    
    if [ $(( l_mode & l_mask )) -gt 0 ]; then
        a_access_out+=("Mode: \"$l_mode\" should be mode: \"$l_max\" or more restrictive")
    fi
    if [[ ! "$l_owner" =~ (^$l_user$) ]]; then
        a_access_out+=("Owned by: \"$l_owner\" and should be owned by \"$l_user\"")
    fi
    if [[ ! "$l_gowner" =~ ($l_group) ]]; then
        a_access_out+=("Group owned by: \"$l_gowner\" and should be group owned by \"${l_group}\"")
    fi
    printf '%s\n' "${a_access_out[@]}"
}

# --- AUDIT PER USER ---
for user_home in "${a_user_and_home[@]}"; do
    l_user=$(echo "$user_home" | cut -d: -f1)
    l_home=$(echo "$user_home" | cut -d: -f2)
    
    a_dot_file=(); a_netrc=(); a_netrc_warn=(); a_bhout=(); a_hdirout=()

    if [ -d "$l_home" ]; then
        l_group="$(id -gn "$l_user" 2>/dev/null | xargs)";
        l_group="${l_group// /|}" # Grup primer user

        while IFS= read -r -d $'\0' l_hdfile; do
            l_mode=$(stat -Lc '%#a' "$l_hdfile" 2>/dev/null)
            l_owner=$(stat -Lc '%U' "$l_hdfile" 2>/dev/null)
            l_gowner=$(stat -Lc '%G' "$l_hdfile" 2>/dev/null)

            case "$(basename "$l_hdfile")" in
            .forward | .rhost )
                # File yang dilarang
                a_dot_file+=(" - File: \"$l_hdfile\" exists (should be removed or empty)")
                ;;
            .netrc )
                # Mode 600 atau lebih ketat
                l_mask='0177'; l_max='0600'
                ACCESS_ISSUES=$(file_access_chk "$l_hdfile" "$l_mode" "$l_owner" "$l_gowner" "$l_user" "$l_group" "$l_mask" "$l_max")
                if [ -n "$ACCESS_ISSUES" ]; then
                    a_netrc+=("${ACCESS_ISSUES//$'\n'/ | }")
                else
                    a_netrc_warn+=(" - File: \"$l_hdfile\" exists (mode compliant, needs manual review)")
                fi
                ;;
            .bash_history )
                # Mode 600 atau lebih ketat
                l_mask='0177'; l_max='0600'
                ACCESS_ISSUES=$(file_access_chk "$l_hdfile" "$l_mode" "$l_owner" "$l_gowner" "$l_user" "$l_group" "$l_mask" "$l_max")
                [ -n "$ACCESS_ISSUES" ] && a_bhout+=("${ACCESS_ISSUES//$'\n'/ | }")
                ;;
            * )
                # Default files (Mode 644 atau lebih ketat)
                l_mask='0133'; l_max='0644'
                ACCESS_ISSUES=$(file_access_chk "$l_hdfile" "$l_mode" "$l_owner" "$l_gowner" "$l_user" "$l_group" "$l_mask" "$l_max")
                [ -n "$ACCESS_ISSUES" ] && a_hdirout+=("${ACCESS_ISSUES//$'\n'/ | }")
                ;;
            esac
        done < <(find "$l_home" -xdev -type f -name '.*' -print0 2>/dev/null)
    fi # end if -d $l_home

    # Kumpulkan semua pelanggaran
    if [[ "${#a_dot_file[@]}" -gt 0 || "${#a_netrc[@]}" -gt 0 || "${#a_bhout[@]}" -gt 0 || "${#a_hdirout[@]}" -gt 0 ]]; then
        RESULT="FAIL"
        a_output2+=(" - User: \"$l_user\" Home: \"$l_home\"")
        [ "${#a_dot_file[@]}" -gt 0 ] && a_output2+=(" | FORBIDDEN: ${a_dot_file[*]}")
        [ "${#a_netrc[@]}" -gt 0 ] && a_output2+=(" | NETRC VIOLATION: ${a_netrc[*]}")
        [ "${#a_bhout[@]}" -gt 0 ] && a_output2+=(" | BASH HISTORY VIOLATION: ${a_bhout[*]}")
        [ "${#a_hdirout[@]}" -gt 0 ] && a_output2+=(" | OTHER DOTFILE VIOLATION: ${a_hdirout[*]}")
    fi
    
    # Kumpulkan warning netrc (jika compliant, tapi ada)
    [ "${#a_netrc_warn[@]}" -gt 0 ] && a_output3+=(" - User: \"$l_user\" Home: \"$l_home\" ${a_netrc_warn[*]}")
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: All checked dot files are compliant."
    [ "${#a_output3[@]}" -gt 0 ] && NOTES+=" | WARNING (Manual Review): Netrc files exist but are compliant. ${a_output3[*]}"
else
    NOTES+="FAIL: Detected non-compliant or forbidden dot files. ${a_output2[*]}"
    [ "${#a_output3[@]}" -gt 0 ] && NOTES+=" | WARNING (Manual Review): Netrc files exist but are compliant. ${a_output3[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}