#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
# KIETSUU TERMUX TOOLKIT v1.0
# Safe, local/admin utilities for Termux
# ============================================================

set -u

APP="KIETSUU TERMUX TOOLKIT"
VER="1.0"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

pause() {
    echo
    read -r -p "Tekan Enter untuk kembali..." _
}

header() {
    clear
    printf "${CYAN}"
    cat <<'EOF'
╔══════════════════════════════════════════╗
║        ██╗  ██╗██╗███████╗████████╗     ║
║        ██║ ██╔╝██║██╔════╝╚══██╔══╝     ║
║        █████╔╝ ██║█████╗     ██║        ║
║        ██╔═██╗ ██║██╔══╝     ██║        ║
║        ██║  ██╗██║██║        ██║        ║
║        ╚═╝  ╚═╝╚═╝╚═╝        ╚═╝        ║
║          TERMUX TOOLKIT v1.0             ║
╚══════════════════════════════════════════╝
EOF
    printf "${RESET}\n"
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1
}

run_pkg() {
    if need_cmd pkg; then
        pkg "$@"
    else
        echo -e "${RED}pkg tidak ditemukan. Pastikan ini Termux.${RESET}"
    fi
}

device_info() {
    header
    echo -e "${YELLOW}📱 INFORMASI PERANGKAT${RESET}"
    echo "Model       : $(getprop ro.product.model 2>/dev/null || echo unknown)"
    echo "Brand       : $(getprop ro.product.brand 2>/dev/null || echo unknown)"
    echo "Android     : $(getprop ro.build.version.release 2>/dev/null || echo unknown)"
    echo "SDK         : $(getprop ro.build.version.sdk 2>/dev/null || echo unknown)"
    echo "Arsitektur  : $(getprop ro.product.cpu.abi 2>/dev/null || uname -m)"
    echo "Kernel      : $(uname -r)"
    echo "Hostname    : $(hostname 2>/dev/null)"
    pause
}

cpu_info() {
    header
    echo -e "${YELLOW}⚡ CPU${RESET}"
    echo "CPU cores   : $(nproc 2>/dev/null || echo unknown)"
    if [ -r /proc/cpuinfo ]; then
        grep -m1 -E 'model name|Hardware|Processor' /proc/cpuinfo | sed 's/^[^:]*:[[:space:]]*//' || true
    fi
    echo
    echo "Load average:"
    uptime 2>/dev/null || true
    pause
}

ram_info() {
    header
    echo -e "${YELLOW}🧠 RAM${RESET}"
    if need_cmd free; then
        free -h
    else
        awk '/MemTotal|MemAvailable/ {printf "%-15s %s\n",$1,$2}' /proc/meminfo
    fi
    pause
}

storage_info() {
    header
    echo -e "${YELLOW}💾 STORAGE${RESET}"
    df -h "$HOME" 2>/dev/null || df -h
    pause
}

battery_info() {
    header
    echo -e "${YELLOW}🔋 BATTERY${RESET}"
    if need_cmd termux-battery-status; then
        termux-battery-status
    else
        echo "Perintah termux-battery-status belum tersedia."
        echo "Install: pkg install termux-api"
    fi
    pause
}

network_info() {
    header
    echo -e "${YELLOW}🌐 NETWORK${RESET}"
    echo "Interfaces:"
    if need_cmd ip; then
        ip -brief addr 2>/dev/null || ip addr
    else
        ifconfig 2>/dev/null || true
    fi
    echo
    echo "Routes:"
    ip route 2>/dev/null || true
    pause
}

ping_test() {
    header
    read -r -p "Host (contoh: google.com): " host
    [ -z "$host" ] && return
    echo
    ping -c 4 "$host"
    pause
}

dns_lookup() {
    header
    read -r -p "Domain: " domain
    [ -z "$domain" ] && return
    echo
    if need_cmd nslookup; then
        nslookup "$domain"
    elif need_cmd dig; then
        dig "$domain"
    else
        getent hosts "$domain" 2>/dev/null || echo "Install dnsutils: pkg install dnsutils"
    fi
    pause
}

public_ip() {
    header
    echo -e "${YELLOW}🌍 PUBLIC IP${RESET}"
    if need_cmd curl; then
        curl -fsS --max-time 10 https://api.ipify.org || echo "Gagal mengambil IP."
        echo
    else
        echo "curl belum terpasang: pkg install curl"
    fi
    pause
}

package_menu() {
    while true; do
        header
        echo -e "${YELLOW}📦 PACKAGE MANAGER${RESET}"
        echo "1. Update package list"
        echo "2. Upgrade packages"
        echo "3. Search package"
        echo "4. Install package"
        echo "5. Uninstall package"
        echo "0. Kembali"
        echo
        read -r -p "Pilih: " c
        case "$c" in
            1) run_pkg update; pause ;;
            2) run_pkg upgrade; pause ;;
            3) read -r -p "Nama package: " p; run_pkg search "$p"; pause ;;
            4) read -r -p "Package yang diinstall: " p; [ -n "$p" ] && run_pkg install "$p"; pause ;;
            5) read -r -p "Package yang dihapus: " p; [ -n "$p" ] && run_pkg uninstall "$p"; pause ;;
            0) return ;;
            *) echo "Pilihan tidak valid"; sleep 1 ;;
        esac
    done
}

install_common() {
    header
    echo -e "${YELLOW}🛠️ INSTALL PACKAGE UMUM${RESET}"
    echo "Package: git curl wget nano vim python openssh zip unzip tar"
    echo
    read -r -p "Install sekarang? [y/N]: " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        run_pkg update
        run_pkg install -y git curl wget nano vim python openssh zip unzip tar
    fi
    pause
}

python_info() {
    header
    echo -e "${YELLOW}🐍 PYTHON${RESET}"
    if need_cmd python; then
        python --version
        python -m pip --version 2>/dev/null || true
    else
        echo "Python belum terpasang."
        echo "Gunakan menu Install Package Umum."
    fi
    pause
}

git_info() {
    header
    echo -e "${YELLOW}📚 GIT${RESET}"
    if need_cmd git; then
        git --version
        echo
        read -r -p "Folder repository (Enter untuk HOME): " dir
        dir="${dir:-$HOME}"
        if [ -d "$dir/.git" ]; then
            git -C "$dir" status --short --branch
        else
            echo "Bukan repository Git: $dir"
        fi
    else
        echo "Git belum terpasang."
    fi
    pause
}

file_manager() {
    while true; do
        header
        echo -e "${YELLOW}📂 FILE MANAGER${RESET}"
        echo "Lokasi: $PWD"
        echo
        ls -lah
        echo
        echo "1. Pindah folder"
        echo "2. Buat folder"
        echo "3. Hapus file/folder"
        echo "4. Salin"
        echo "5. Pindahkan/rename"
        echo "6. Tampilkan file"
        echo "0. Kembali"
        read -r -p "Pilih: " c
        case "$c" in
            1) read -r -p "Folder: " d; [ -d "$d" ] && cd -- "$d" || echo "Folder tidak ditemukan"; sleep 1 ;;
            2) read -r -p "Nama folder: " d; mkdir -p -- "$d"; sleep 1 ;;
            3) read -r -p "Path yang dihapus: " p; [ -n "$p" ] && rm -ri -- "$p"; sleep 1 ;;
            4) read -r -p "Sumber: " a; read -r -p "Tujuan: " b; cp -ri -- "$a" "$b"; sleep 1 ;;
            5) read -r -p "Sumber: " a; read -r -p "Tujuan: " b; mv -i -- "$a" "$b"; sleep 1 ;;
            6) read -r -p "File: " f; [ -f "$f" ] && less "$f" || echo "File tidak ditemukan"; sleep 1 ;;
            0) return ;;
            *) echo "Pilihan tidak valid"; sleep 1 ;;
        esac
    done
}

password_gen() {
    header
    echo -e "${YELLOW}🔐 PASSWORD GENERATOR${RESET}"
    read -r -p "Panjang [16]: " n
    n="${n:-16}"
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt 256 ]; then
        echo "Panjang tidak valid."
        pause
        return
    fi
    if need_cmd openssl; then
        openssl rand -base64 256 | tr -dc 'A-Za-z0-9_@#%+=-' | head -c "$n"
        echo
    else
        tr -dc 'A-Za-z0-9_@#%+=' < /dev/urandom | head -c "$n"
        echo
    fi
    pause
}

hash_generator() {
    header
    echo -e "${YELLOW}🔑 HASH GENERATOR${RESET}"
    read -r -p "Teks: " text
    echo
    printf "MD5    : "; printf '%s' "$text" | md5sum 2>/dev/null | awk '{print $1}'
    printf "SHA1   : "; printf '%s' "$text" | sha1sum 2>/dev/null | awk '{print $1}'
    printf "SHA256 : "; printf '%s' "$text" | sha256sum 2>/dev/null | awk '{print $1}'
    pause
}

base64_tool() {
    while true; do
        header
        echo -e "${YELLOW}🔤 BASE64 TOOL${RESET}"
        echo "1. Encode"
        echo "2. Decode"
        echo "0. Kembali"
        read -r -p "Pilih: " c
        case "$c" in
            1) read -r -p "Teks: " t; printf '%s' "$t" | base64; pause ;;
            2) read -r -p "Base64: " t; printf '%s' "$t" | base64 -d 2>/dev/null || echo "Base64 tidak valid"; pause ;;
            0) return ;;
            *) echo "Pilihan tidak valid"; sleep 1 ;;
        esac
    done
}

system_monitor() {
    header
    echo -e "${YELLOW}📊 SYSTEM MONITOR${RESET}"
    echo "Tekan Ctrl+C untuk berhenti."
    sleep 1
    if need_cmd top; then
        top
    else
        ps -ef
        pause
    fi
}

cleanup() {
    header
    echo -e "${YELLOW}🧹 MAINTENANCE${RESET}"
    echo "Membersihkan cache package..."
    run_pkg clean
    echo
    echo "Menghapus cache pip jika tersedia..."
    if need_cmd pip; then
        pip cache purge 2>/dev/null || true
    fi
    echo -e "${GREEN}Selesai.${RESET}"
    pause
}

archive_tool() {
    while true; do
        header
        echo -e "${YELLOW}🗜️ ARCHIVE TOOL${RESET}"
        echo "1. Buat ZIP"
        echo "2. Extract ZIP"
        echo "3. Buat TAR.GZ"
        echo "4. Extract TAR.GZ"
        echo "0. Kembali"
        read -r -p "Pilih: " c
        case "$c" in
            1)
                read -r -p "Nama output .zip: " out
                read -r -p "File/folder sumber: " src
                [ -n "$out" ] && [ -e "$src" ] && zip -r "$out" "$src"
                pause ;;
            2)
                read -r -p "File .zip: " f
                read -r -p "Folder tujuan: " d
                mkdir -p "$d"
                unzip "$f" -d "$d"
                pause ;;
            3)
                read -r -p "Nama output .tar.gz: " out
                read -r -p "File/folder sumber: " src
                [ -n "$out" ] && [ -e "$src" ] && tar -czf "$out" "$src"
                pause ;;
            4)
                read -r -p "File .tar.gz: " f
                read -r -p "Folder tujuan: " d
                mkdir -p "$d"
                tar -xzf "$f" -C "$d"
                pause ;;
            0) return ;;
            *) echo "Pilihan tidak valid"; sleep 1 ;;
        esac
    done
}

http_server() {
    header
    echo -e "${YELLOW}🌍 LOCAL HTTP SERVER${RESET}"
    if ! need_cmd python; then
        echo "Python belum terpasang."
        pause
        return
    fi
    read -r -p "Port [8080]: " port
    port="${port:-8080}"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Port tidak valid."
        pause
        return
    fi
    echo "Server: http://127.0.0.1:$port"
    echo "Folder: $PWD"
    echo "Tekan Ctrl+C untuk berhenti."
    python -m http.server "$port"
}

port_check() {
    header
    echo -e "${YELLOW}🔎 PORT CHECK${RESET}"
    echo "Gunakan hanya pada perangkat/host yang kamu miliki atau berhak uji."
    read -r -p "Host [127.0.0.1]: " host
    host="${host:-127.0.0.1}"
    read -r -p "Port (contoh 80): " port
    if need_cmd nc; then
        nc -zv -w 2 "$host" "$port"
    else
        echo "netcat belum terpasang. Install: pkg install netcat-openbsd"
    fi
    pause
}

download_file() {
    header
    echo -e "${YELLOW}📥 DOWNLOAD${RESET}"
    if ! need_cmd curl && ! need_cmd wget; then
        echo "Install curl atau wget terlebih dahulu."
        pause
        return
    fi
    read -r -p "URL: " url
    read -r -p "Nama file (kosong = otomatis): " out
    if need_cmd curl; then
        if [ -n "$out" ]; then curl -L --fail --output "$out" "$url"; else curl -L --fail -O "$url"; fi
    else
        if [ -n "$out" ]; then wget -O "$out" "$url"; else wget "$url"; fi
    fi
    pause
}

backup_home() {
    header
    echo -e "${YELLOW}💾 BACKUP HOME${RESET}"
    mkdir -p "$HOME/kiietsuu-backups"
    out="$HOME/kiietsuu-backups/home-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar --exclude="$HOME/kiietsuu-backups" -czf "$out" "$HOME" 2>/dev/null
    echo "Backup dibuat:"
    echo "$out"
    pause
}

termux_storage() {
    header
    echo -e "${YELLOW}📱 TERMUX STORAGE${RESET}"
    if [ -d "$HOME/storage" ]; then
        echo "Storage sudah tersedia:"
        ls -la "$HOME/storage"
    else
        echo "Menjalankan termux-setup-storage..."
        if need_cmd termux-setup-storage; then
            termux-setup-storage
        else
            echo "Perintah tidak tersedia."
        fi
    fi
    pause
}

process_manager() {
    header
    echo -e "${YELLOW}📋 PROCESSES${RESET}"
    ps -ef | head -n 40
    echo
    read -r -p "PID untuk dihentikan (kosong = batal): " pid
    if [ -n "$pid" ] && [[ "$pid" =~ ^[0-9]+$ ]]; then
        kill -TERM "$pid" 2>/dev/null || echo "Tidak dapat menghentikan PID tersebut."
    fi
    pause
}

main_menu() {
    while true; do
        header
        echo -e "${WHITE}Pilih menu:${RESET}"
        echo
        echo " 01. 📱 Device Info"
        echo " 02. ⚡ CPU Info"
        echo " 03. 🧠 RAM Info"
        echo " 04. 💾 Storage Info"
        echo " 05. 🔋 Battery Info"
        echo " 06. 🌐 Network Info"
        echo " 07. 📡 Ping Test"
        echo " 08. 🔎 DNS Lookup"
        echo " 09. 🌍 Public IP"
        echo " 10. 📦 Package Manager"
        echo " 11. 🛠️ Install Package Umum"
        echo " 12. 🐍 Python Info"
        echo " 13. 📚 Git Info"
        echo " 14. 📂 File Manager"
        echo " 15. 🔐 Password Generator"
        echo " 16. 🔑 Hash Generator"
        echo " 17. 🔤 Base64 Tool"
        echo " 18. 📊 System Monitor"
        echo " 19. 🧹 Cleanup"
        echo " 20. 🗜️ Archive Tool"
        echo " 21. 🌍 Local HTTP Server"
        echo " 22. 🔎 Port Check"
        echo " 23. 📥 Download File"
        echo " 24. 💾 Backup HOME"
        echo " 25. 📱 Setup Termux Storage"
        echo " 26. 📋 Process Manager"
        echo " 00. 🚪 Keluar"
        echo
        read -r -p "KIETSUU > " choice

        case "$choice" in
            1|01) device_info ;;
            2|02) cpu_info ;;
            3|03) ram_info ;;
            4|04) storage_info ;;
            5|05) battery_info ;;
            6|06) network_info ;;
            7|07) ping_test ;;
            8|08) dns_lookup ;;
            9|09) public_ip ;;
            10) package_menu ;;
            11) install_common ;;
            12) python_info ;;
            13) git_info ;;
            14) file_manager ;;
            15) password_gen ;;
            16) hash_generator ;;
            17) base64_tool ;;
            18) system_monitor ;;
            19) cleanup ;;
            20) archive_tool ;;
            21) http_server ;;
            22) port_check ;;
            23) download_file ;;
            24) backup_home ;;
            25) termux_storage ;;
            26) process_manager ;;
            0|00) clear; echo "KIETSUU Toolkit ditutup. 👋"; exit 0 ;;
            *) echo -e "${RED}Pilihan tidak valid.${RESET}"; sleep 1 ;;
        esac
    done
}

# Basic Termux check
if [ ! -d "/data/data/com.termux" ]; then
    echo "Peringatan: script ini dibuat untuk Termux."
fi

main_menu
