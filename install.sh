#!/bin/sh
# installer_v23.sh — smsforward v2.3 (OpenWrt)
# - Config via /etc/config/smsforward (UCI)
# - Prompt user untuk bot_token, chat_id, thread_id jika kosong
# - Fix body single-line & multi-line (field-per-projection)
# - thread_id auto-detect (hanya dipakai jika angka)
# - --test / -t: kirim pesan uji setelah install

set -eu
say(){ printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

# ---- Arg parsing ----
TEST=0
case "${1-}" in
  --test|-t) TEST=1;;
  "" ) : ;;
  *   ) say "Arg tidak dikenal: $1"; say "Gunakan: sh installer_v23.sh [--test]"; exit 2;;
 esac

CONF=/etc/config/smsforward

say "Membuat direktori..."
mkdir -p /usr/bin /etc/init.d /etc/config

# ---- Buat config jika belum ada ----
if [ ! -f "$CONF" ]; then
  cat > "$CONF" <<'EOF_CFG'
config settings 'main'
    option bot_token ''
    option chat_id   ''
    option thread_id ''
    option interval '10'
EOF_CFG
fi

# ---- Prompt user jika kosong ----
BOT_TOKEN="$(uci -q get smsforward.main.bot_token 2>/dev/null || echo '')"
CHAT_ID="$(uci -q get smsforward.main.chat_id 2>/dev/null || echo '')"
THREAD_ID="$(uci -q get smsforward.main.thread_id 2>/dev/null || echo '')"

if [ -z "$BOT_TOKEN" ]; then
  printf "Masukkan BOT_TOKEN: "; read -r BOT_TOKEN
  uci set smsforward.main.bot_token="$BOT_TOKEN"
fi
if [ -z "$CHAT_ID" ]; then
  printf "Masukkan CHAT_ID: "; read -r CHAT_ID
  uci set smsforward.main.chat_id="$CHAT_ID"
fi
if [ -z "$THREAD_ID" ]; then
  printf "Masukkan THREAD_ID (boleh kosong): "; read -r THREAD_ID
  [ -n "$THREAD_ID" ] && uci set smsforward.main.thread_id="$THREAD_ID" || true
fi
uci commit smsforward

say "Menulis /usr/bin/forward-loop-sms.sh ..."
cat > /usr/bin/forward-loop-sms.sh <<'EOF_SCRIPT'
#!/bin/sh
# forward-loop-sms.sh v2.3 — UCI config, robust body parser, HTML + urlencode

set -eu
export LANG="C.UTF-8" || true
export LC_ALL="C.UTF-8" || true

log(){ printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" 1>&2; }
html_escape(){ sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
uci_get(){ uci -q get "smsforward.main.$1" 2>/dev/null || echo ""; }

BOT_TOKEN="$(uci_get bot_token)"
CHAT_ID="$(uci_get chat_id)"
THREAD_ID="$(uci_get thread_id)"
POLL_INTERVAL="$(uci_get interval)"; [ -n "${POLL_INTERVAL:-}" ] || POLL_INTERVAL=10
LAST_ID_FILE="/tmp/last_sms_id"

[ -n "${BOT_TOKEN:-}" ] || { log "ERROR: bot_token kosong"; exit 1; }
[ -n "${CHAT_ID:-}" ]   || { log "ERROR: chat_id kosong"; exit 1; }

ensure_adb_ready(){ adb get-state >/dev/null 2>&1; }

fetch_latest_id(){
  adb shell content query --uri content://sms/inbox --projection _id --sort "date DESC" \
  | head -n 1 | sed -n 's/.*_id=\([0-9][0-9]*\).*/\1/p'
}

get_field_by_id(){
  key="$1"; id="$2"
  adb shell content query --uri content://sms/inbox --projection "$key" --where "_id=${id}" \
  | awk -v k="$key" 'BEGIN{st=0}{ if(!st){ sub(/^Row: [0-9]+[ \t]*/, ""); i=index($0,k"="); if(i>0){ print substr($0,i+length(k)+1); st=1; next } } else print }'
}

format_datetime(){ ms="$1"; sec=$(( ms / 1000 )); date -d @"$sec" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$sec"; }

send_telegram(){
  text="$1"; url="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
  if [ -n "${THREAD_ID:-}" ] && printf '%s' "$THREAD_ID" | grep -Eq '^[0-9]+$'; then
    curl -sS -X POST "$url" \
      --data-urlencode "chat_id=${CHAT_ID}" \
      --data-urlencode "message_thread_id=${THREAD_ID}" \
      --data-urlencode "text=${text}" \
      --data-urlencode "parse_mode=HTML" \
      --data-urlencode "disable_web_page_preview=true"
  else
    curl -sS -X POST "$url" \
      --data-urlencode "chat_id=${CHAT_ID}" \
      --data-urlencode "text=${text}" \
      --data-urlencode "parse_mode=HTML" \
      --data-urlencode "disable_web_page_preview=true"
  fi
}

get_hostname(){ cat /proc/sys/kernel/hostname 2>/dev/null || hostname 2>/dev/null || echo unknown; }

main_loop(){
  while :; do
    if ! ensure_adb_ready; then sleep "$POLL_INTERVAL"; continue; fi

    id="$(fetch_latest_id 2>/dev/null || true)"; [ -n "$id" ] || { sleep "$POLL_INTERVAL"; continue; }
    [ -f "$LAST_ID_FILE" ] && last_id="$(cat "$LAST_ID_FILE" 2>/dev/null || true)" || last_id=""
    [ "$id" = "$last_id" ] && { sleep "$POLL_INTERVAL"; continue; }

    addr="$(get_field_by_id address "$id")"
    date_ms="$(get_field_by_id date "$id")"
    body_raw="$(get_field_by_id body "$id")"

    [ -n "${date_ms:-}" ] || { sleep "$POLL_INTERVAL"; continue; }
    dt="$(format_datetime "$date_ms")"; host="$(get_hostname)"

    esc_body="$(printf '%s' "$body_raw" | html_escape)"
    esc_addr="$(printf '%s' "$addr" | html_escape)"
    esc_host="$(printf '%s' "$host" | html_escape)"
    esc_time="$(printf '%s' "$dt" | html_escape)"

    msg=$(cat <<EOF2
<b>📩 SMS Baru Masuk!</b>

<b>🖥 Hostname:</b> ${esc_host}
<b>📱 Pengirim:</b> ${esc_addr}
<b>🕒 Waktu:</b> ${esc_time}

<b>💬 Isi Pesan:</b>

<i>${esc_body}</i>
EOF2
)
    if send_telegram "$msg"; then
      echo "$id" > "$LAST_ID_FILE"; log "INFO: terkirim ID=$id dari $addr"
    else
      log "ERROR: gagal mengirim ke Telegram"; fi
    sleep "$POLL_INTERVAL"
  done
}

main_loop
EOF_SCRIPT
chmod 755 /usr/bin/forward-loop-sms.sh

say "Menulis /etc/init.d/smsforward ..."
cat > /etc/init.d/smsforward <<'EOF_INIT'
#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROCD=1
PROG="/usr/bin/forward-loop-sms.sh"

start_service(){
    procd_open_instance
    procd_set_param command "$PROG"
    procd_set_param respawn 2000 5 0
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
EOF_INIT
chmod 755 /etc/init.d/smsforward

say "Enable & start service..."
/etc/init.d/smsforward enable || true
/etc/init.d/smsforward restart || /etc/init.d/smsforward start || true

# ---- Test message (optional) ----
if [ "$TEST" = 1 ]; then
  say "Mengirim pesan uji ke Telegram..."
  BOT_TOKEN="$(uci -q get smsforward.main.bot_token 2>/dev/null || echo '')"
  CHAT_ID="$(uci -q get smsforward.main.chat_id 2>/dev/null || echo '')"
  HN="$(cat /proc/sys/kernel/hostname 2>/dev/null || hostname 2>/dev/null || echo unknown)"
  NOW="$(date '+%Y-%m-%d %H:%M:%S')"
  TEST_MSG="<b>✅ smsforward v2.3 terpasang</b>%0AHost: $HN%0AWaktu: $NOW"
  curl -sS -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${TEST_MSG}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "disable_web_page_preview=true" >/dev/null || true
  say "Pesan uji dikirim."
fi

say "Selesai. Cek log: logread -f"
