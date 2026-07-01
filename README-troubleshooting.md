# StreamFlow - Install Notes & Troubleshooting

Catatan ini dibuat berdasarkan pengalaman instalasi StreamFlow
(https://github.com/bangtutorial/streamflow) di VPS Ubuntu 22.04
(2 vCPU / 4GB RAM, Singapore).

## Cara Pakai

```bash
chmod +x install-fixed.sh
./install-fixed.sh
```

Script ini menjalankan instalasi lengkap sekaligus memperbaiki
masalah-masalah umum yang sering muncul (lihat di bawah).

## Masalah yang Pernah Terjadi & Solusinya

### 1. `SyntaxError: Unexpected token '.'` saat menjalankan `app.js`
**Sebab:** Node.js yang aktif masih versi lama (v12), padahal app butuh
fitur `?.` (optional chaining) yang baru didukung Node 14+.
Ini terjadi walau sudah install Node 22, karena ada Node lama bawaan
sistem yang masih nyangkut di PATH / belum benar-benar terhapus.

**Solusi:**
```bash
sudo apt-get purge -y nodejs nodejs-doc libnode-dev libnode72 npm
sudo apt-get autoremove -y
sudo rm -f /usr/bin/node /usr/bin/nodejs /usr/bin/npm
hash -r
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version   # pastikan muncul v22.x.x
```

### 2. `Error: .../libm.so.6: version 'GLIBC_2.38' not found (required by node_sqlite3.node)`
**Sebab:** `npm install` mendownload prebuilt binary sqlite3 yang
dibuat untuk sistem dengan glibc lebih baru, tidak cocok dengan
Ubuntu 22.04 (glibc 2.35).

**Solusi:** Build sqlite3 dari source, bukan pakai binary download:
```bash
sudo apt install -y build-essential python3 make g++
rm -rf node_modules/sqlite3
npm install sqlite3 --build-from-source
```

### 3. Aplikasi tidak bisa diakses dari browser meski PM2 status "online"
**Sebab:** PM2 hanya tahu proses hidup, bukan berarti server HTTP
berhasil listen di port. Cek dengan:
```bash
sudo ss -tulpn | grep 7575
```
Kalau kosong, app gagal listen — biasanya karena error di atas
(Node version / sqlite3) yang membuat startup gagal diam-diam.
Cek log lengkap dengan:
```bash
pm2 logs streamflow --lines 50 --nostream
```
atau jalankan langsung tanpa PM2 untuk lihat error real-time:
```bash
node app.js
```

### 4. Website mati setelah SSH/terminal ditutup
**Sebab:** Dijalankan langsung dengan `node app.js`, bukan lewat PM2.
Proses ikut mati saat terminal ditutup.

**Solusi:** Selalu jalankan lewat PM2:
```bash
pm2 start app.js --name streamflow
pm2 save
pm2 startup     # copy-paste command yang muncul, lalu jalankan
pm2 save
```

### 5. Firewall / UFW
**Urutan WAJIB** — buka SSH dulu sebelum `ufw enable`, supaya
koneksi SSH tidak terputus dan VPS tidak perlu di-reset:
```bash
sudo ufw allow ssh
sudo ufw allow 7575
sudo ufw enable
```

### 6. Google OAuth (YouTube login) — redirect URI ditolak
**Sebab:** Google tidak menerima redirect URI berupa IP address
langsung (misal `http://43.x.x.x:7575/...`).

**Solusi:** Pakai domain gratis dari [DuckDNS](https://www.duckdns.org),
arahkan ke IP VPS, lalu gunakan domain itu sebagai redirect URI:
```
http://nama-kamu.duckdns.org:7575/auth/youtube/callback
```

Untuk pemakaian pribadi, app **tidak perlu di-publish ke "production"**
(yang mewajibkan HTTPS) — cukup tetap di mode **"Testing"** dan
daftarkan email kamu sendiri sebagai **Test user** di OAuth consent
screen. HTTP tetap berfungsi normal dalam mode Testing.

(Opsional, kalau suatu saat ingin HTTPS: pasang Nginx reverse proxy
+ Certbot/Let's Encrypt menggunakan domain DuckDNS yang sama.)

## Spek VPS yang Dipakai (terbukti cukup)
- CPU: 2 vCPU
- RAM: 4 GB
- Storage: 60 GB
- OS: Ubuntu 22.04
- Region: Singapore
