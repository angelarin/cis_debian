#!/usr/bin/env bash
{
l_output="" 
l_output2="" 
l_perm_mask="0022"
# Hitung mode maksimum yang diizinkan (0755)
l_maxperm="$( printf '%o' $(( 0777 & ~$l_perm_mask )) )"

# Daftar alat audit
a_audit_tools=("/sbin/auditctl" "/sbin/aureport" "/sbin/ausearch" "/sbin/autrace" "/sbin/auditd" "/sbin/augenrules")

for l_audit_tool in "${a_audit_tools[@]}"; do
    
    # --- PENTING: Periksa apakah file ada sebelum menjalankan stat ---
    if [ ! -e "$l_audit_tool" ]; then
        l_output2="$l_output2\n - FAIL: Audit tool \"$l_audit_tool\" tidak ditemukan/tidak ada (Melewati audit perizinan)."
        continue # Lanjut ke item berikutnya
    fi
    # ----------------------------------------------------------------
    
    # Ambil mode perizinan dalam format oktal (e.g., 0755)
    l_mode="$(stat -Lc '%#a' "$l_audit_tool")"
    
    # Cek apakah mode tersebut memiliki bit yang lebih permisif dari yang diizinkan (0022 = group write, others write)
    if [ $(( "$l_mode" & "$l_perm_mask" )) -gt 0 ]; then
        l_output2="$l_output2\n - Audit tool \"$l_audit_tool\" mode: \"$l_mode\" dan seharusnya: \"$l_maxperm\" (0755) atau lebih ketat"
    else
        l_output="$l_output\n - Audit tool \"$l_audit_tool\" dikonfigurasi dengan benar mode: \"$l_mode\""
    fi
done

if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - * Konfigurasi Benar * :$l_output"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Alasan Kegagalan Audit * :$l_output2\n"
    # Tampilkan hasil yang benar juga jika ada
    [ -n "$l_output" ] && echo -e "\n - * Konfigurasi Benar * :\n$l_output\n"
fi

unset a_audit_tools
}
