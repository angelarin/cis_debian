#!/usr/bin/env bash

# --- Tambahkan ID dan Deskripsi untuk Master Script ---
CHECK_ID="2.1.22"
DESCRIPTION="Ensure only approved services are listening on a network interface (Manual Review Required)"
# -----------------------------------------------------

{
a_output=() a_output2=() RESULT="REVIEW" NOTES=""
TARGET_COMMAND="ss -plntu"

# --- FUNGSI AUDIT LISTENING SERVICES ---

# 1. Jalankan ss -plntu
# Menggunakan ss -plntu untuk mendapatkan daftar port/proses yang listening
# Melakukan filtering untuk hanya menampilkan baris yang relevan (tanpa header)
L_OUTPUT=$($TARGET_COMMAND 2>/dev/null | tail -n +2)
L_LINES=$(echo "$L_OUTPUT" | wc -l)

if [ "$L_LINES" -gt 0 ]; then
    a_output+=(" - $L_LINES services/ports are currently listening on the network interface.")
    
    # Format output menjadi satu baris untuk NOTES
    # Mengganti newline dengan spasi vertikal "|" untuk keterbacaan dalam satu baris CSV
    L_OUTPUT_SINGLE_LINE=$(echo "$L_OUTPUT" | sed 's/  */ /g' | tr '\n' '|')
    
    a_output+=(" - Data: $L_OUTPUT_SINGLE_LINE")
    RESULT="REVIEW"
else
    a_output+=(" - No network services/ports are currently listening (excluding headers).")
    RESULT="PASS"
fi

# --- LOGIKA OUTPUT MASTER SCRIPT ---

if [ "$RESULT" == "PASS" ]; then
    NOTES+="PASS: ${a_output[*]}"
else
    # Status REVIEW karena perlu tinjauan manual
    NOTES+="INFO: Network listening data collected. ${a_output[*]}"
    NOTES+=" | Action: REVIEW the listed services (port, interface, process) against local site policy for approval."
    RESULT="REVIEW"
fi

# Ganti karakter enter/newline/spasi ganda dengan satu spasi untuk output satu baris
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"
}