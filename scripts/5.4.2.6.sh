#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.4.2.6"
DESCRIPTION="Ensure root user umask is configured (umask 0027 or more restrictive)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILES="/root/.bash_profile /root/.bashrc /root/.profile"
MAX_ALLOWED_UMASK=0077 # Umask tidak boleh memberikan izin group/other

# --- FUNGSI AUDIT UMASK ---
L_CONFIGURED_UMASK=""

for file in $TARGET_FILES; do
    if [ -f "$file" ]; then
        L_OUTPUT=$(grep -Psi -- '^\h*umask\h+\H+' "$file" 2>/dev/null)
        if [ -n "$L_OUTPUT" ]; then
            # Mengambil nilai umask dari file konfigurasi terakhir
            L_CONFIGURED_UMASK=$(echo "$L_OUTPUT" | tail -n 1 | awk '{print $2}')
            a_output+=(" - Found umask setting in $file: $L_CONFIGURED_UMASK")
        fi
    fi
done

if [ -z "$L_CONFIGURED_UMASK" ]; then
    a_output+=(" - Root user's umask is NOT explicitly set in standard configuration files. Relying on default system umask.")
    # Default system umask seringkali 0022 atau 0002, yang tidak cukup ketat (FAIL).
    #RESULT="FAIL"
else
    # Asumsikan umask dalam format oktal 4 digit (mis. 0022) atau 3 digit (mis. 022)
    # Target: Memastikan umask membatasi group write (020) dan other rwx (007)
    
    # Konversi umask ke oktal dan periksa apakah ada izin longgar (mask 0027)
    # Izin yang tidak boleh ada: group write (2) dan other (7)
    # Umask 027 (untuk 750/640) atau 077 (untuk 700/600) adalah yang terbaik.

    # 027 (standard CIS benchmark)
    UMASK_VALUE_DECIMAL=$(( 8#$L_CONFIGURED_UMASK ))
    # Periksa izin group write (020) dan other (007)
    if [ $(( $UMASK_VALUE_DECIMAL & 8#0027 )) -ne 8#0027 ]; then
         a_output2+=(" - Configured umask ($L_CONFIGURED_UMASK) is NOT restrictive enough (Does not restrict group write and/or other rwx fully). Recommended minimum is 0027.")
         RESULT="FAIL"
    else
        a_output+=(" - Configured umask ($L_CONFIGURED_UMASK) enforces appropriate file permissions (>= 0027).")
    fi
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