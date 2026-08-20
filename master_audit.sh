#!/bin/bash

# ==============================================================================
# CIS Benchmark Automated Audit Runner - Debian 13
# ==============================================================================

# Pastikan dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Script audit CIS harus dijalankan sebagai root (sudo)." >&2
   exit 1
fi

SCRIPT_DIR="./scripts"
RESULTS_DIR="./results"
OUTPUT_FILE="${RESULTS_DIR}/audit_report_$(date +'%Y%m%d_%H%M%S').csv"
LOG_ERROR="${RESULTS_DIR}/audit_errors.log"

# Pastikan folder results ada
mkdir -p "$RESULTS_DIR"

# Tulis header CSV
echo '"CIS_ID","Deskripsi_Pengecekan","Status_Audit","Catatan_Detail"' > "$OUTPUT_FILE"

# Counter statistik
COUNT_PASS=0
COUNT_FAIL=0
COUNT_MANUAL=0
COUNT_ERROR=0

echo "=== Memulai Audit CIS Benchmark Debian 13 ==="
echo "Menyimpan laporan ke: $OUTPUT_FILE"
echo "---------------------------------------------"

# Cari dan urutkan script secara numerik (sort -V)
while IFS= read -r -d $'\0' SCRIPT; do
    SCRIPT_NAME=$(basename "$SCRIPT")
    echo -n "[RUNNING] $SCRIPT_NAME ... "
    
    # Jalankan script: tangkap stdout untuk CSV, pisahkan stderr ke log
    SCRIPT_OUTPUT=$(bash "$SCRIPT" 2>> "$LOG_ERROR")
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ] && [ -n "$SCRIPT_OUTPUT" ]; then
        # Parse output berformat: ID|DESKRIPSI|STATUS|CATATAN
        IFS='|' read -r CIS_ID DESC STATUS NOTES <<< "$SCRIPT_OUTPUT"
        
        # Bersihkan whitespace ekstra & sanitasi kutip ganda
        CIS_ID=$(echo "$CIS_ID" | xargs | sed 's/"/""/g')
        DESC=$(echo "$DESC" | xargs | sed 's/"/""/g')
        STATUS=$(echo "$STATUS" | xargs | sed 's/"/""/g')
        NOTES=$(echo "$NOTES" | xargs | sed 's/"/""/g')

        # Tulis baris CSV yang aman
        echo "\"${CIS_ID}\",\"${DESC}\",\"${STATUS}\",\"${NOTES}\"" >> "$OUTPUT_FILE"
        echo "[$STATUS]"

        # Update counter
        case "$STATUS" in
            PASS)   ((COUNT_PASS++)) ;;
            FAIL)   ((COUNT_FAIL++)) ;;
            MANUAL|REVIEW) ((COUNT_MANUAL++)) ;;
            *)      ((COUNT_ERROR++)) ;;
        esac
    else
        echo "[ERROR]"
        echo "\"UNKNOWN\",\"$SCRIPT_NAME\",\"ERROR\",\"Script gagal dieksekusi atau output kosong. Cek $LOG_ERROR\"" >> "$OUTPUT_FILE"
        ((COUNT_ERROR++))
    fi

done < <(find "$SCRIPT_DIR" -type f -name '*.sh' -print0 | sort -zV)

echo "---------------------------------------------"
echo "=== Ringkasan Hasil Audit ==="
echo "PASS   : $COUNT_PASS"
echo "FAIL   : $COUNT_FAIL"
echo "MANUAL : $COUNT_MANUAL"
echo "ERROR  : $COUNT_ERROR"
echo "---------------------------------------------"
echo "Laporan lengkap: $OUTPUT_FILE"