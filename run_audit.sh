#!/bin/bash

# Folder tempat script audit individual berada
SCRIPT_DIR="./scripts"

# File output CSV
OUTPUT_FILE="./results/audit_report.csv"

# Pastikan folder results ada
mkdir -p ./results

# 1. Tulis header CSV
echo "CIS_ID,Deskripsi_Pengecekan,Status_Audit,Catatan/Detail" > "$OUTPUT_FILE"

# 2. Cari semua script .sh di dalam SCRIPT_DIR dan jalankan satu per satu
# -name '*.sh': Hanya file dengan ekstensi .sh
# -print0: Menggunakan null-character sebagai pemisah (lebih aman untuk nama file yang mengandung spasi)
# xargs -0: Membaca input yang dipisahkan oleh null-character
find "$SCRIPT_DIR" -type f -name '*.sh' -print0 | while IFS= read -r -d $'\0' SCRIPT; do
    echo "Menjalankan: $SCRIPT"
    # Jalankan script dan tangkap outputnya
    # Output diasumsikan dalam format: CHECK_ID|DESCRIPTION|RESULT|NOTES
    
    # Jalankan script dengan bash dan ganti pemisah '|' menjadi koma ',' untuk CSV
    SCRIPT_OUTPUT=$(bash "$SCRIPT" 2>&1)
    
    # Periksa apakah output berhasil didapatkan
    if [ -n "$SCRIPT_OUTPUT" ]; then
        # Mengganti pemisah | menjadi koma ,
        CSV_LINE=$(echo "$SCRIPT_OUTPUT" | tr '|' ',')
        
        # Tambahkan baris ke file CSV
        echo "$CSV_LINE" >> "$OUTPUT_FILE"
    else
        # Jika script gagal atau tidak menghasilkan output yang diharapkan
        echo "ERROR,Gagal menjalankan $SCRIPT,ERROR,Output kosong atau error saat eksekusi" >> "$OUTPUT_FILE"
    fi

done

echo "---"
echo "Audit selesai. Hasil disimpan di: $OUTPUT_FILE"
echo "---"
# Tambahkan permission execute pada script master
# chmod +x master_audit.sh 
# chmod +x scripts/*.sh