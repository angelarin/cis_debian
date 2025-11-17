#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.1.1" 
DESCRIPTION="Ensure /tmp is a separate partition"
# -----------------------------------------------------

{
a_output=()     # Untuk kondisi yang BENAR (PASS)
a_output2=()    # Untuk kondisi yang SALAH (FAIL)
RESULT=""
NOTES=""

# --- FUNGSI AUDIT /TMP ---

# 1. Audit Pemasangan Saat Ini (/tmp mount status)
L_MOUNT_STATUS=$(findmnt -kn /tmp)
if [ -n "$L_MOUNT_STATUS" ]; then
    a_output+=(" - /tmp is currently mounted ($L_MOUNT_STATUS)")
else
    a_output2+=(" - /tmp is NOT mounted")
fi

# 2. Audit Aktivasi Systemd (tmp.mount enabled status)
L_SYSTEMCTL_STATUS=$(systemctl is-enabled tmp.mount 2>/dev/null)

if [[ "$L_SYSTEMCTL_STATUS" == "generated" || "$L_SYSTEMCTL_STATUS" == "enabled" ]]; then
    a_output+=(" - tmp.mount is enabled for boot (Status: $L_SYSTEMCTL_STATUS)")
elif [[ "$L_SYSTEMCTL_STATUS" == "masked" || "$L_SYSTEMCTL_STATUS" == "disabled" ]]; then
    a_output2+=(" - tmp.mount is DISABLED/MASKED (Status: $L_SYSTEMCTL_STATUS)")
else
    a_output2+=(" - tmp.mount has an unexpected status: $L_SYSTEMCTL_STATUS")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

# 1. Tentukan Status dan gabungkan a_output / a_output2
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+="PASS: All checks succeeded: ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | Correctly set: ${a_output[*]}"
fi

# 2. Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')

# 3. Cetak output dalam format ID|DESKRIPSI|RESULT|NOTES
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}