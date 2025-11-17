#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.1.2.1.2"
DESCRIPTION="Ensure nodev option set on /tmp partition"
# -----------------------------------------------------

{
a_output=()     # Untuk kondisi yang BENAR (PASS)
a_output2=()    # Untuk kondisi yang SALAH (FAIL)
RESULT=""
NOTES=""

# --- FUNGSI AUDIT nodev ---
# Perintah: findmnt -kn /tmp | grep -v nodev
# Output KOSONG = PASS

L_OUTPUT=$(findmnt -kn /tmp | grep -v nodev)

if [ -z "$L_OUTPUT" ]; then
    RESULT="PASS"
    a_output+=("/tmp mount options correctly include 'nodev'.")
    NOTES+="PASS: ${a_output[*]}"
else
    RESULT="FAIL"
    a_output2+=("/tmp is mounted WITHOUT the 'nodev' option. Findmnt output: $L_OUTPUT")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

# Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')

# Cetak output dalam format ID|DESKRIPSI|RESULT|NOTES
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
# --------------------------------------------------------------------------
}