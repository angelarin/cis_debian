#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.3.3"
DESCRIPTION="Ensure cryptographic mechanisms are used to protect the integrity of audit tools"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
l_tool_dir="$(readlink -f /sbin)"
a_items=("p" "i" "n" "u" "g" "s" "b" "acl" "xattrs" "sha512") # Atribut wajib
l_aide_cmd="$(whereis aide 2>/dev/null | awk '{print $2}' | head -n 1)"
a_audit_files=("auditctl" "auditd" "ausearch" "aureport" "autrace" "augenrules")

# --- FUNGSI AUDIT KONFIGURASI AIDE ---
f_file_par_chk()
{
    local l_file="$1" l_out="$2"
    local a_out2=()
    
    for l_item in "${a_items[@]}"; do
        # Cek apakah opsi wajib ada dalam konfigurasi yang dimuat
        if ! grep -Psiq -- '(\h+|\+)'"$l_item"'(\h+|\+)' <<< "$l_out"; then
            a_out2+=(" - Missing the \"$l_item\" option")
        fi
    done
    
    if [ "${#a_out2[@]}" -gt "0" ]; then
        a_output2+=(" - Audit tool file: \"$l_file\" is missing required attributes: ${a_out2[*]}")
    else
        a_output+=(" - Audit tool file: \"$l_file\" includes all required attributes: ${a_items[*]}")
    fi
}

if [ -f "$l_aide_cmd" ] && command -v "$l_aide_cmd" &>/dev/null; then
    # Dapatkan file konfigurasi AIDE
    a_aide_conf_files=("$(find -L /etc -type f -name 'aide.conf' 2>/dev/null)")
    
    if [ "${#a_aide_conf_files[@]}" -eq 0 ]; then
        a_output2+=(" - Configuration file 'aide.conf' was not found in /etc.")
        RESULT="FAIL"
    else
        # Iterasi dan cek setiap audit tool
        for l_file in "${a_audit_files[@]}"; do
            if [ -f "$l_tool_dir/$l_file" ]; then
                # Gunakan AIDE untuk membaca konfigurasi efektif untuk file tersebut
                l_out="$("$l_aide_cmd" --config "${a_aide_conf_files[0]}" -p f:"$l_tool_dir/$l_file" 2>/dev/null)"
                f_file_par_chk "$l_file" "$l_out"
            else
                a_output+=(" - Audit tool file \"$l_file\" doesn't exist.")
            fi
        done
    fi
else
    a_output2+=(" - The command \"aide\" was not found. Please install AIDE.")
    RESULT="FAIL"
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