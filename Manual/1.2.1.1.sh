#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.2.1.1"
DESCRIPTION="Ensure GPG keys are configured (Manual Review Required)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
TARGET_FILES="/etc/apt/trusted.gpg.d/*.{gpg,asc} /etc/apt/sources.list.d/*.{gpg,asc}"
INFO_COLLECTED=""

# --- FUNGSI AUDIT GPG KEYS ---
for file in $TARGET_FILES; do
    if [ -f "$file" ]; then
        INFO_COLLECTED+="File: $file | "
        
        # Ekstrak Key ID
        KEY_ID=$(gpg --list-packets "$file" 2>/dev/null | awk '/keyid/ && !seen[$NF]++ {print "keyid:", $NF}')
        INFO_COLLECTED+="$KEY_ID | "

        # Ekstrak Signed-By (jika ada)
        SIGNED_BY=$(gpg --list-packets "$file" 2>/dev/null | awk '/Signed-By:/ {print "signed-by:", $NF}')
        INFO_COLLECTED+="$SIGNED_BY; "
    fi
done

if [ -n "$INFO_COLLECTED" ]; then
    a_output+=("GPG Key Information collected: $INFO_COLLECTED")
else
    a_output2+=("No GPG key files found in standard APT directories.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "${#a_output2[@]}" -gt 0 ]; then
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    NOTES+=" | Review Required: Check file presence and content."
    RESULT="FAIL" # Set ke FAIL jika tidak ada file yang ditemukan
else
    NOTES+="INFO: Collected GPG Key Data: ${a_output[*]}"
    NOTES+=" | Action: REVIEW and VERIFY IAW site policy."
    RESULT="REVIEW"
fi

# Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}