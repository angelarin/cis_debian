# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="5.1.5"
DESCRIPTION="Ensure sshd Banner is configured with legal warning"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="" NOTES=""
TARGET_SETTING='^banner\h+\/\H+'

REQUIRED_TEXT="Authorized users only. All activity may be monitored and reported. Violators will be prosecuted."

# 1. Cek apakah Banner diset
L_BANNER_SET=$(sshd -T 2>/dev/null | grep -Pi -- "$TARGET_SETTING")

if [ -n "$L_BANNER_SET" ]; then
    L_BANNER_PATH=$(echo "$L_BANNER_SET" | awk '$1 == "banner" {print $2}')
    a_output+=(" - Banner setting found: $L_BANNER_SET")
    
    # 2. Cek apakah file Banner ada
    if [ -e "$L_BANNER_PATH" ]; then
        
        # 3. Cek konten Banner untuk teks yang diwajibkan
        # Menggunakan 'grep -q' untuk keberadaan string. '-F' untuk fixed string, '-i' untuk case-insensitive.
        if grep -Fqi "$REQUIRED_TEXT" "$L_BANNER_PATH"; then
            
            # --- Pengecekan Sekunder (Escape Sequences & OS ID) DILAKUKAN DI SINI ---
            
            # Dapatkan ID OS untuk pengecekan escape sequences (HANYA JIKA LOLOS TES TEKS WAJIB)
            OS_ID=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | sed -e 's/"//g')
            # Tambahkan $REQUIRED_TEXT ke Pengecekan, jika kita mau memastikan TEKS LEGAL HANYA 1 BARIS (Opsional)
            BANNED_SEQUENCES="(\\\v|\\\r|\\\m|\\\s|\b$OS_ID\b)" 
            
            L_CONTENT_VIOLATION=$(grep -Psi -- "$BANNED_SEQUENCES" "$L_BANNER_PATH")

            if [ -z "$L_CONTENT_VIOLATION" ]; then
                a_output+=(" - Banner file content ($L_BANNER_PATH) does NOT contain banned escape sequences/OS ID.")
                RESULT="PASS" # LOLOS teks wajib dan sequences bersih
            else
                RESULT="FAIL"
                a_output2+=(" - Banner content contains banned sequences/OS ID, despite having the required legal text.")
            fi
            
            # --- AKHIR Pengecekan Sekunder ---
            
        else
            RESULT="FAIL"
            a_output2+=(" - Banner content ($L_BANNER_PATH) does NOT contain the required legal warning.")
        fi
        
        L_CONTENT_SAMPLE=$(head -n 2 "$L_BANNER_PATH" | tr '\n' ' ')
        a_output+=(" - Banner file contents sample: $L_CONTENT_SAMPLE")
        
    else
        RESULT="FAIL"
        a_output2+=(" - Banner file specified ($L_BANNER_PATH) does NOT exist.")
    fi
else
    RESULT="FAIL"
    a_output2+=(" - Banner directive is NOT set globally.")
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---
if [ "${#a_output2[@]}" -le 0 ]; then
    RESULT="PASS"
    NOTES+="PASS: ${a_output[*]}"
else
    NOTES+="FAIL: Reason(s) for audit failure: ${a_output2[*]}"
    [ "${#a_output[@]}" -gt 0 ] && NOTES+=" | INFO: ${a_output[*]}"
fi

NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}