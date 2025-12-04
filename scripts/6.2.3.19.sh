#!/usr/bin/env bash

# --- Definisi Metadata Skrip ---
CHECK_ID="6.1.13"
DESCRIPTION="Memastikan audit terhadap modifikasi dan eksekusi modul kernel."
RESULT="FAIL"
NOTES=""

# --- Variabel Global dan Utilitas ---
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null)
[ -z "$UID_MIN" ] && UID_MIN=1000 # Default jika tidak ditemukan
AUDIT_TARGET_SYSCALLS="(init_module|finit_module|delete_module|create_module|query_module)"

# Status hasil per sub-check
CHECK_1_RESULT="FAIL"
CHECK_2_RESULT="FAIL"
CHECK_3_RESULT="FAIL"

# Logika untuk auid!=unset/4294967295/-1
# Ini adalah bagian dari regex umum untuk memastikan auid diverifikasi,
# yang merupakan persyaratan umum untuk aturan audit pengguna.
AU_ID_CHECK="(/ -F auid!=unset/ || / -F auid!=-1/ || / -F auid!=4294967295/)"
# ------------------------------------

# ==============================================================================
# SUB-CHECK 1: Memeriksa Aturan Audit Modul Kernel di Disk (Harus ditemukan 2)
# ==============================================================================
f_check_disk_rules() {
    local L_OUTPUT_SC=""
    local L_OUTPUT_KMOD=""
    local FOUND_COUNT=0
    local NOTE_DETAIL="Disk Rules: "

    # Target 1: Aturan Panggilan Sistem (Syscalls)
    # Mencari aturan yang mencakup syscalls modul dan arch=b(32|64), auid>=UID_MIN, key=
    L_OUTPUT_SC=$(
        awk "
        /^\s*-a *always,exit/ &&
        / -F *arch=b(32|64)/ &&
        / -F *auid>=\s*${UID_MIN}/ &&
        ${AU_ID_CHECK} &&
        / -S/ &&
        /${AUDIT_TARGET_SYSCALLS}/ &&
        (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)
        " /etc/audit/rules.d/*.rules
    )

    # Target 2: Aturan Eksekusi kmod
    # Mencari aturan yang mencakup path=/usr/bin/kmod, perm=x, auid>=UID_MIN, key=
    L_OUTPUT_KMOD=$(
        awk "
        /^\s*-a *always,exit/ &&
        / -F *auid>=\s*${UID_MIN}/ &&
        ${AU_ID_CHECK} &&
        / -F *perm=x/ &&
        / -F *path=\/usr\/bin\/kmod/ &&
        (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)
        " /etc/audit/rules.d/*.rules
    )

    # Logika Hitung (Diharapkan 2 aturan)
    # Kita hanya menghitung apakah pola untuk Syscalls dan pola untuk kmod path ditemukan setidaknya satu kali
    if [ -n "$L_OUTPUT_SC" ]; then
        FOUND_COUNT=$((FOUND_COUNT + 1))
        NOTE_DETAIL+="Syscall(OK) "
    else
        NOTE_DETAIL+="Syscall(MISSING) "
    fi

    if [ -n "$L_OUTPUT_KMOD" ]; then
        FOUND_COUNT=$((FOUND_COUNT + 1))
        NOTE_DETAIL+="kmod_Path(OK) "
    else
        NOTE_DETAIL+="kmod_Path(MISSING) "
    fi

    if [ "$FOUND_COUNT" -ge 2 ]; then
        CHECK_1_RESULT="PASS"
        NOTES+="[DISK: PASS] $NOTE_DETAIL | "
    else
        NOTES+="[DISK: FAIL] $NOTE_DETAIL | "
    fi
}

# ==============================================================================
# SUB-CHECK 2: Memeriksa Aturan Audit Modul Kernel yang Dimuat (Harus ditemukan 2)
# ==============================================================================
f_check_loaded_rules() {
    local L_OUTPUT_SC=""
    local L_OUTPUT_KMOD=""
    local FOUND_COUNT=0
    local NOTE_DETAIL="Loaded Rules: "

    # Ambil semua aturan yang dimuat
    local ALL_LOADED_RULES=$(auditctl -l 2>/dev/null)

    if [ -z "$ALL_LOADED_RULES" ]; then
        NOTES+="[LOADED: FAIL] Auditctl gagal membaca aturan. | "
        return
    fi

    # Target 1: Aturan Panggilan Sistem (Syscalls)
    L_OUTPUT_SC=$(
        echo "$ALL_LOADED_RULES" | awk "
        /^\s*-a *always,exit/ &&
        / -F *arch=b(32|64)/ &&
        / -F *auid>=\s*${UID_MIN}/ &&
        ${AU_ID_CHECK} &&
        / -S/ &&
        /${AUDIT_TARGET_SYSCALLS}/ &&
        (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)
        "
    )

    # Target 2: Aturan Eksekusi kmod
    # Catatan: Aturan yang dimuat mungkin tidak menyertakan AU_ID_CHECK jika hanya menggunakan -F auid>=1000
    L_OUTPUT_KMOD=$(
        echo "$ALL_LOADED_RULES" | awk "
        /^\s*-a *always,exit/ &&
        / -F *auid>=\s*${UID_MIN}/ &&
        / -F *perm=x/ &&
        / -F *path=\/usr\/bin\/kmod/ &&
        (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)
        "
    )

    # Logika Hitung (Diharapkan 2 aturan)
    if [ -n "$L_OUTPUT_SC" ]; then
        FOUND_COUNT=$((FOUND_COUNT + 1))
        NOTE_DETAIL+="Syscall(OK) "
    else
        NOTE_DETAIL+="Syscall(MISSING) "
    fi

    if [ -n "$L_OUTPUT_KMOD" ]; then
        FOUND_COUNT=$((FOUND_COUNT + 1))
        NOTE_DETAIL+="kmod_Path(OK) "
    else
        NOTE_DETAIL+="kmod_Path(MISSING) "
    fi

    if [ "$FOUND_COUNT" -ge 2 ]; then
        CHECK_2_RESULT="PASS"
        NOTES+="[LOADED: PASS] $NOTE_DETAIL | "
    else
        NOTES+="[LOADED: FAIL] $NOTE_DETAIL | "
    fi
}

# ==============================================================================
# SUB-CHECK 3: Memeriksa Symlink Program Modul
# ==============================================================================
f_check_symlinks() {
    local a_files=("/usr/sbin/lsmod" "/usr/sbin/rmmod" "/usr/sbin/insmod" "/usr/sbin/modinfo" "/usr/sbin/modprobe" "/usr/sbin/depmod")
    local target_kmod_path="$(readlink -f /bin/kmod 2>/dev/null)"
    local ISSUES_FOUND=0
    local NOTE_DETAIL="Symlinks: "

    if [ -z "$target_kmod_path" ]; then
        NOTES+="[SYMLINK: FAIL] Path target /bin/kmod tidak ditemukan. | "
        return
    fi

    for l_file in "${a_files[@]}"; do
        if [ "$(readlink -f "$l_file" 2>/dev/null)" = "$target_kmod_path" ]; then
            NOTE_DETAIL+="($l_file: OK) "
        else
            ISSUES_FOUND=1
            NOTE_DETAIL+="($l_file: Issue) "
        fi
    done

    if [ "$ISSUES_FOUND" -eq 0 ]; then
        CHECK_3_RESULT="PASS"
        NOTES+="[SYMLINK: PASS] $NOTE_DETAIL"
    else
        NOTES+="[SYMLINK: FAIL] $NOTE_DETAIL"
    fi
}

# --- Jalankan Semua Pemeriksaan ---
f_check_disk_rules
f_check_loaded_rules
f_check_symlinks

# --- Logika Penentuan Hasil Akhir ---
if [ "$CHECK_1_RESULT" = "PASS" ] && [ "$CHECK_2_RESULT" = "PASS" ] && [ "$CHECK_3_RESULT" = "PASS" ]; then
    RESULT="PASS"
else
    RESULT="FAIL"
fi

# --- Format Output CSV ---
# Bersihkan catatan dari baris baru
NOTES=$(echo "$NOTES" | tr '\n' ' ' | sed 's/  */ /g')
echo "$CHECK_ID|$DESCRIPTION|$RESULT|$NOTES"