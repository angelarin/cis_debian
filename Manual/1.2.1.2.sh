#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.1.2"
DESCRIPTION="Ensure package manager repositories are configured (Manual Review Required)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""

# --- FUNGSI AUDIT APT REPOSITORIES ---
L_OUTPUT=$(apt-cache policy 2>&1)
L_EXIT_CODE=$?

if [ $L_EXIT_CODE -eq 0 ]; then
    RESULT="REVIEW"
    # Menangkap hanya baris yang menunjukkan sumber (Source/Repository)
    REPOS=$(echo "$L_OUTPUT" | grep -E '(\*|http|ftp|file|cdrom):')
    a_output+=("APT Repository list collected.")
    NOTES+="INFO: Repository Policy Output: ${REPOS}"
else
    RESULT="FAIL"
    a_output2+=("apt-cache policy command failed (Exit Code: $L_EXIT_CODE). Check package manager status.")
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

NOTES+=" | Action: REVIEW the output to verify repository configuration IAW site policy."

# Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}