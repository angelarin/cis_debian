#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="1.6.1"
DESCRIPTION="Ensure message of the day is configured properly"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="PASS" NOTES=""
TARGET_FILE="/etc/motd"

# Dapatkan ID OS untuk pengecualian
OS_ID=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | sed -e 's/"//g')
# Escape sequences yang dilarang
BANNED_SEQUENCES="(\\\v|\\\r|\\\m|\\\s|${OS_ID})"

# --- LOGIKA UTAMA: CEK KEBERADAAN FILE ---

if [ -f "$TARGET_FILE" ]; then
    # KASUS A: FILE ADA. Lanjutkan dengan pemeriksaan penuh.
    
    L_CONTENT=$(cat "$TARGET_FILE")
    a_output+=(" - Contents of $TARGET_FILE: ${L_CONTENT//[$'\n']/\n}")

    # Lakukan pengecekan GREP (hanya jika file ada)
    L_OUTPUT_GREP=$(grep -E -i "$BANNED_SEQUENCES" "$TARGET_FILE" 2>/dev/null)

    if [ -z "$L_OUTPUT_GREP" ]; then
        a_output+=(" - $TARGET_FILE does not contain banned escape sequences or OS ID.")
    else
        RESULT="FAIL"
        a_output2+=(" - $TARGET_FILE contains banned escape sequences or OS ID. Offending output: $L_OUTPUT_GREP")
    fi
    
    NOTES+="INFO: Content collected. | Action: REVIEW content against site policy. "

else
    # KASUS B: FILE TIDAK ADA. Otomatis PASS dan Lewati pemeriksaan konten.
    
    a_output+=(" - $TARGET_FILE does not exist. Audit set to PASS based on policy to ignore missing motd.")
    RESULT="PASS"
    # Tidak ada pengecekan lebih lanjut, a_output2 tetap kosong
fi


# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "$RESULT" == "PASS" ] && [ "${#a_output2[@]}" -le 0 ]; then
    NOTES+="PASS: No issues found. ${a_output[*]}"
    RESULT="PASS"
else
    # Hanya masuk ke sini jika RESULT disetel ke FAIL (karena ada banned sequence)
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
    RESULT="FAIL"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}