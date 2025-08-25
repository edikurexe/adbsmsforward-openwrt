# smsforward v1.0

Script untuk forward SMS Android (via ADB) ke Telegram Chat.

## 🚀 Instalasi Cepat
Copy script di bawah lalu paste ke terminal OpenWrt:

```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/edikurexe/adbsmsforward-openwrt/refs/heads/main/installer.sh)"
```

Script akan otomatis:
- Membuat config `/etc/config/smsforward`.
- Prompt kamu untuk memasukkan **bot_token**, **chat_id**, dan **thread_id** (opsional).
- Menulis service init.d & start otomatis.

---

## ⚙️ Konfigurasi
Lokasi: `/etc/config/smsforward`

```ini
config settings 'main'
    option bot_token '123456:ABCDEF'
    option chat_id   '-1001234567890'
    option thread_id ''
    option interval '10'
```

🔑 **Keterangan**:
- **bot_token** → token bot dari @BotFather.
- **chat_id** → ID chat user/grup. Grup supergroup = `-100XXXXXXXXXX`.
- **thread_id** → opsional, hanya jika grup kamu pakai forum topics.
- **interval** → interval polling ADB (detik).

---

## ▶️ Jalankan Service
```bash
/etc/init.d/smsforward enable
/etc/init.d/smsforward start
logread -f
```

---

## 🔍 Test Manual
Kalau pesan test gagal, jalankan:
```bash
/usr/bin/smsforward-test
```

Script ini akan menampilkan **output API Telegram** supaya gampang debug.

---

## 📦 Dependensi
Pastikan paket berikut terpasang di OpenWrt:
```bash
opkg update
opkg install adb curl ca-bundle ca-certificates
```

---

## 📊 Contoh Output
**Log OpenWrt:**
```
[2025-08-23 12:00:01] INFO: terkirim ID=1234 dari +628123456789
```

**Pesan di Telegram:**
```
📩 SMS Baru Masuk!

🖥 Hostname: OpenWrt-Router
📱 Pengirim: +628123456789
🕒 Waktu: 2025-08-23 12:00:01

💬 Isi Pesan:
Kode OTP Anda adalah 123456.
```

---

## ✅ Tested Device
Telah diuji berjalan dengan baik di perangkat Android berikut (mode ADB):
- Xiaomi Redmi 4A  
- Xiaomi Redmi 4X  
- Samsung Galaxy S8  
- Samsung Galaxy S9  

---

## 📜 Lisensi
MIT License
