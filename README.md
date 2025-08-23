⚡ smsforward v2.3 ⚡

> 🕶️ Forward SMS Android → Telegram dengan gaya cyberpunk di atas OpenWrt.



<pre align="center">
███████╗███╗   ███╗███████╗███████╗ ██████╗ ██████╗ ██╗    ██╗ █████╗ ██████╗ ██████╗        ██████╗ ██████╗ ███████╗███╗   ██╗██╗    ██╗██████╗ ████████╗
██╔════╝████╗ ████║██╔════╝██╔════╝██╔═══██╗██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔══██╗      ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██║    ██║██╔══██╗╚══██╔══╝
███████╗██╔████╔██║███████╗█████╗  ██║   ██║██████╔╝██║ █╗ ██║███████║██████╔╝██║  ██║█████╗██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║ █╗ ██║██████╔╝   ██║   
╚════██║██║╚██╔╝██║╚════██║██╔══╝  ██║   ██║██╔══██╗██║███╗██║██╔══██║██╔══██╗██║  ██║╚════╝██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║███╗██║██╔══██╗   ██║   
███████║██║ ╚═╝ ██║███████║██║     ╚██████╔╝██║  ██║╚███╔███╔╝██║  ██║██║  ██║██████╔╝      ╚██████╔╝██║     ███████╗██║ ╚████║╚███╔███╔╝██║  ██║   ██║   
╚══════╝╚═╝     ╚═╝╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝        ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   
                                                          S M S F O R W A R D  -  O P E N W R T
</pre>
---

🚀 Instalasi Cepat

Copy & paste 1 baris di bawah ini langsung di terminal OpenWrt kamu:

# Copy Script Di Bawah Dan Paste Di Terminal
bash -c "$(wget -qO - 'https://raw.githubusercontent.com/edikurexe/adbsmsforward-openwrt/refs/heads/main/install.sh')"

Script akan otomatis:

Membuat config /etc/config/smsforward.

Prompt kamu untuk memasukkan bot_token, chat_id, dan thread_id (opsional).

Menulis service init.d & start otomatis.



---

⚙️ Konfigurasi

Lokasi: /etc/config/smsforward

config settings 'main'
    option bot_token '123456:ABCDEF'
    option chat_id   '-1001234567890'
    option thread_id ''
    option interval '10'

🔑 Keterangan:

bot_token → token bot dari @BotFather.

chat_id → ID chat user/grup. Grup supergroup = -100XXXXXXXXXX.

thread_id → opsional, hanya jika grup kamu pakai forum topics.

interval → interval polling ADB (detik).



---

▶️ Jalankan Service

/etc/init.d/smsforward enable
/etc/init.d/smsforward start
logread -f


---

🔍 Test Manual

Kalau pesan test gagal, jalankan:

/usr/bin/smsforward-test

Script ini akan menampilkan output API Telegram supaya gampang debug.


---

📦 Dependensi

Pastikan paket berikut terpasang di OpenWrt:

opkg update
opkg install adb curl ca-bundle ca-certificates


---

🎨 Nuansa Cyberpunk

💬 SMS kamu akan muncul di Telegram dengan format HTML (emoji, newline aman).

⚡ Forwarding cepat, ringan, jalan di OpenWrt.

🕶️ Bergaya tapi tetap fungsional.



---

📜 Lisensi

MIT License — bebas dipakai & diubah. Just keep it cool 😎

