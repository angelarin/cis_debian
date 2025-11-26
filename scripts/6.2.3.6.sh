#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="6.2.3.6"
DESCRIPTION="Ensure use of privileged commands are collected"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
RUNNING_RULES=$(auditctl -l 2>/dev/null)
PASS_COUNT=0
TOTAL_COUNT=0

# Dapatkan daftar partisi yang dapat dieksekusi tanpa nosuid/noexec
TARGET_PARTITIONS=$(findmnt -n -l -k -it $(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd,) 2>/dev/null | grep -Pv "noexec|nosuid" | awk '{print $1}')

# Iterasi pada partisi yang memenuhi syarat
for PARTITION in $TARGET_PARTITIONS; do
    # Cari file SUID/SGID di partisi tersebut
    for PRIVILEGED_FILE in $(find "${PARTITION}" -xdev -perm /6000 -type f 2>/dev/null); do
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        
        # 1. Cek konfigurasi On Disk
        if grep -qr "${PRIVILEGED_FILE}" /etc/audit/rules.d 2>/dev/null; then
            a_output+=(" - Disk: OK: '$PRIVILEGED_FILE' found in on disk rules.")
        else
            a_output2+=(" - Disk: Warning: '$PRIVILEGED_FILE' not found in on disk configuration.")
        fi

        # 2. Cek konfigurasi Loaded
        if [ -n "${RUNNING_RULES}" ] && printf -- "${RUNNING_RULES}" | grep -q "${PRIVILEGED_FILE}"; then
            a_output+=(" - Loaded: OK: '$PRIVILEGED_FILE' found in running rules.")
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            a_output2+=(" - Loaded: Warning: '$PRIVILEGED_FILE' not found in running configuration.")
        fi
    done
done

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$TOTAL_COUNT" -eq 0 ]; then
    a_output+=(" - No privileged SUID/SGID files found on eligible partitions. Audit considered PASS.")
elif [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: All $TOTAL_COUNT privileged files are audited (Disk and Loaded). ${a_output[*]}"
else
    RESULT="FAIL"
    NOTES+="FAIL: Detected missing rules for privileged commands. Total Files: $TOTAL_COUNT. ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}