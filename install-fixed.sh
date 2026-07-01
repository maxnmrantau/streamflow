#!/bin/bash
# ============================================================
# StreamFlow - Fixed Install Script
# Untuk Ubuntu 22.04 (atau sejenis), berdasarkan troubleshooting
# Memperbaiki masalah umum:
#  - Node.js versi lama (v12) tidak ke-update meski sudah install Node 22
#  - sqlite3 prebuilt binary error GLIBC (harus build dari source)
#  - PM2 ikut mati saat terminal/SSH ditutup (pakai PM2 + startup)
# ============================================================

set -e  # stop script kalau ada command yang gagal

echo "=== 1. Update sistem ==="
sudo apt update && sudo apt upgrade -y

echo "=== 2. Bersihkan Node.js lama (kalau ada) ==="
sudo apt-get purge -y nodejs nodejs-doc libnode-dev libnode72 npm 2>/dev/null || true
sudo apt-get autoremove -y
sudo rm -f /usr/bin/node /usr/bin/nodejs /usr/bin/npm /usr/local/bin/node /usr/local/bin/npm
hash -r

echo "=== 3. Install Node.js 22.x (dari NodeSource) ==="
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
hash -r

echo "=== 4. Verifikasi Node.js ==="
node --version
npm --version

echo "=== 5. Install build tools (WAJIB untuk compile sqlite3 dari source) ==="
sudo apt install -y build-essential python3 make g++

echo "=== 6. Install FFmpeg & Git ==="
sudo apt install -y ffmpeg git

echo "=== 7. Clone StreamFlow ==="
if [ ! -d "streamflow" ]; then
  git clone https://github.com/bangtutorial/streamflow
fi
cd streamflow

echo "=== 8. Install dependencies (force build sqlite3 dari source, hindari GLIBC error) ==="
rm -rf node_modules package-lock.json
npm install
npm install sqlite3 --build-from-source

echo "=== 9. Generate Secret Key ==="
if [ ! -f ".env" ]; then
  node generate-secret.js
fi

echo "=== 10. Setup Firewall (urutan WAJIB: SSH dulu sebelum enable!) ==="
sudo ufw allow ssh
sudo ufw allow 7575
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo "=== 11. Install PM2 ==="
sudo npm install -g pm2

echo "=== 12. Jalankan aplikasi dengan PM2 ==="
pm2 delete streamflow 2>/dev/null || true
pm2 start app.js --name streamflow
pm2 save

echo ""
echo "============================================================"
echo " SELESAI! StreamFlow sudah jalan."
echo ""
echo " Cek status   : pm2 status"
echo " Cek log      : pm2 logs streamflow"
echo " Akses via    : http://<IP_VPS_KAMU>:7575"
echo ""
echo " PENTING - Auto-start saat reboot server:"
echo " Jalankan 'pm2 startup' lalu copy-paste command yang muncul,"
echo " setelah itu jalankan 'pm2 save' sekali lagi."
echo "============================================================"
