# 🎬 StreamFlow — Panduan Install di VPS Ubuntu 22.04

Panduan ini dibuat berdasarkan pengalaman instalasi [StreamFlow](https://github.com/bangtutorial/streamflow) di VPS Ubuntu 22.04, lengkap dengan solusi untuk semua error yang mungkin muncul.

---

## 📋 Spesifikasi VPS yang Direkomendasikan

| Komponen | Minimum | Yang Dipakai |
|----------|---------|--------------|
| CPU | 1 vCPU | 2 vCPU |
| RAM | 1 GB | 4 GB |
| Storage | 20 GB | 60 GB |
| OS | Ubuntu 22.04 | Ubuntu 22.04 |
| Region | Bebas | Singapore |

---

## 🛠️ Yang Dibutuhkan Sebelum Mulai

### 1. Akses VPS
- Koneksi SSH ke VPS (username `ubuntu` atau `root`)
- IP Address VPS kamu

### 2. Domain (untuk Google OAuth)
Google OAuth **tidak menerima IP address langsung** sebagai redirect URI. Kamu butuh domain, bisa pakai gratis dari:
- [DuckDNS](https://www.duckdns.org) — gratis, mudah, langsung bisa dipakai
- Buat subdomain (contoh: `streamflow.duckdns.org`), arahkan ke IP VPS kamu

### 3. Google Cloud Console
Siapkan OAuth credentials untuk akses YouTube API:
1. Buka [console.cloud.google.com](https://console.cloud.google.com)
2. Buat project baru
3. Enable **YouTube Data API v3**
4. Buat **OAuth 2.0 Client ID** (tipe: Web application)
5. Di bagian **Authorized redirect URIs**, masukkan:
   ```
   http://nama-kamu.duckdns.org:7575/auth/youtube/callback
   ```
6. Di **OAuth consent screen → Test users**, tambahkan email Google/YouTube kamu sendiri
7. Catat `Client ID` dan `Client Secret`

> **Catatan:** App tidak perlu dipublish ke "In production". Tetap di mode **Testing** sudah cukup untuk pemakaian pribadi, dan tidak memerlukan HTTPS.

---

## 🚀 Cara Install (Menggunakan `install-fixed.sh`)

### Langkah 1 — SSH masuk ke VPS
```bash
ssh ubuntu@IP_VPS_KAMU
```

### Langkah 2 — Buat file script installer
```bash
nano install-fixed.sh
```

### Langkah 3 — Paste isi script
Copy seluruh isi file `install-fixed.sh` dari repo ini, paste ke terminal (klik kanan → paste), lalu simpan:
- Tekan `Ctrl+O` → Enter (untuk save)
- Tekan `Ctrl+X` (untuk keluar dari nano)

### Langkah 4 — Jalankan script
```bash
chmod +x install-fixed.sh
./install-fixed.sh
```

Script akan otomatis menjalankan semua langkah instalasi. Tunggu sampai muncul pesan **"SELESAI!"**.

### Langkah 5 — Setup PM2 auto-start saat reboot
Setelah script selesai, jalankan:
```bash
pm2 startup
```
Akan muncul 1 baris command panjang seperti:
```
sudo env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
```
Copy-paste dan jalankan command itu, lalu:
```bash
pm2 save
```

### Langkah 6 — Akses aplikasi
Buka browser dan akses:
```
http://nama-kamu.duckdns.org:7575
```

---

## ⚙️ Konfigurasi `.env`

File `.env` berada di folder `~/streamflow/.env`. Isi minimal yang dibutuhkan:

```env
PORT=7575
SESSION_SECRET=isi_dengan_hasil_generate_secret
```

`SESSION_SECRET` di-generate otomatis oleh script saat pertama kali install. Kalau ingin generate ulang manual:
```bash
cd ~/streamflow
node generate-secret.js
```

---

## 🔧 Perintah PM2 yang Sering Dipakai

```bash
pm2 status                        # cek status aplikasi
pm2 logs streamflow               # lihat log real-time
pm2 logs streamflow --lines 50    # lihat 50 baris log terakhir
pm2 restart streamflow            # restart aplikasi
pm2 stop streamflow               # stop aplikasi
pm2 start app.js --name streamflow  # jalankan ulang dari nol
pm2 save                          # simpan konfigurasi PM2
```

---

## 🐛 Troubleshooting — Error yang Mungkin Muncul

### ❌ `SyntaxError: Unexpected token '.'`
**Sebab:** Node.js yang aktif masih versi lama (v12), tidak support optional chaining `?.`.

**Solusi:**
```bash
sudo apt-get purge -y nodejs nodejs-doc libnode-dev libnode72 npm
sudo apt-get autoremove -y
sudo rm -f /usr/bin/node /usr/bin/nodejs /usr/bin/npm
hash -r
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version   # harus muncul v22.x.x
```

---

### ❌ `GLIBC_2.38 not found` (sqlite3 error)
**Sebab:** npm mendownload prebuilt binary sqlite3 untuk sistem yang butuh glibc 2.38, sedangkan Ubuntu 22.04 pakai glibc 2.35.

**Solusi:** Build sqlite3 dari source:
```bash
sudo apt install -y build-essential python3 make g++
cd ~/streamflow
rm -rf node_modules/sqlite3
npm install sqlite3 --build-from-source
pm2 restart streamflow
```

---

### ❌ PM2 status "online" tapi tidak bisa diakses di browser
**Sebab:** App sebenarnya gagal listen di port, tapi PM2 tidak mendeteksinya sebagai crash.

**Cek dengan:**
```bash
sudo ss -tulpn | grep 7575
```
Kalau hasilnya kosong (tidak ada output), app tidak benar-benar listen. Lihat log untuk cari errornya:
```bash
pm2 logs streamflow --lines 80 --nostream
```
Atau jalankan tanpa PM2 untuk lihat error langsung:
```bash
cd ~/streamflow
node app.js
```

---

### ❌ Website mati setelah SSH/terminal ditutup
**Sebab:** Dijalankan langsung dengan `node app.js`, bukan lewat PM2.

**Solusi:** Selalu gunakan PM2:
```bash
pm2 start app.js --name streamflow
pm2 save
```

---

### ❌ Google OAuth — "Invalid Redirect: must end with a public top-level domain"
**Sebab:** Redirect URI menggunakan IP address langsung, tidak diizinkan Google.

**Solusi:** Pakai domain gratis dari [DuckDNS](https://www.duckdns.org):
1. Daftar/login ke DuckDNS
2. Buat subdomain baru, masukkan IP VPS kamu
3. Update redirect URI di Google Console jadi:
   ```
   http://nama-kamu.duckdns.org:7575/auth/youtube/callback
   ```

---

### ❌ Google Console — "Publish app" gagal karena tidak ada HTTPS
**Sebab:** Google mewajibkan HTTPS untuk publish ke "In production".

**Solusi untuk pemakaian pribadi:** Tidak perlu publish. Tetap di mode **"Testing"** dan daftarkan email kamu di **OAuth consent screen → Test users**. Login YouTube tetap berfungsi normal.

---

## 🔒 Firewall (UFW)

Urutan ini **wajib** diikuti — jangan `enable` UFW sebelum `allow ssh`, atau koneksi SSH bisa terputus dan VPS perlu di-reset:

```bash
sudo ufw allow ssh      # WAJIB PERTAMA
sudo ufw allow 7575
sudo ufw allow 80       # opsional, kalau pakai Nginx
sudo ufw allow 443      # opsional, kalau pakai HTTPS
sudo ufw enable         # baru enable setelah semua port dibuka
sudo ufw status
```

---

## 📁 Struktur File Penting

```
~/streamflow/
├── app.js              # file utama aplikasi
├── .env                # konfigurasi (PORT, SESSION_SECRET)
├── package.json        # daftar dependencies
├── generate-secret.js  # generate SESSION_SECRET
├── node_modules/       # dependencies (jangan di-commit ke git)
├── logs/               # log aplikasi
└── public/             # file frontend
```

---

## 📦 Backup Data Penting

Sebelum reset VPS, backup folder ini:
```bash
cd ~/streamflow
zip -r streamflow-backup.zip . -x "node_modules/*"
```
Download via SCP dari komputer lokal:
```bash
scp ubuntu@IP_VPS_KAMU:~/streamflow/streamflow-backup.zip .
```

---

## 📎 Referensi

- Repo asli StreamFlow: https://github.com/bangtutorial/streamflow
- DuckDNS (domain gratis): https://www.duckdns.org
- Google Cloud Console: https://console.cloud.google.com
- PM2 Documentation: https://pm2.io
