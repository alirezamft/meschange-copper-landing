#!/bin/zsh

set -u

launcher_dir="$(cd "$(dirname "$0")" && pwd)"
port=8777

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 روی این مک پیدا نشد. لطفاً Python 3 را نصب کنید."
  read "?برای بستن Enter بزنید..."
  exit 1
fi

while lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; do
  existing_url="http://127.0.0.1:$port/"
  if curl -fsS "$existing_url" 2>/dev/null | grep -q "بازار مس"; then
    open "$existing_url"
    exit 0
  fi
  port=$((port + 1))
done

cd "$launcher_dir" || exit 1
log_file="/tmp/meschange-local-$port.log"
python3 -m http.server "$port" --bind 127.0.0.1 >"$log_file" 2>&1 &
server_pid=$!

cleanup() {
  kill "$server_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

site_url="http://127.0.0.1:$port/"
for attempt in {1..30}; do
  if curl -fsS "$site_url" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

open "$site_url"
echo ""
echo "مس‌چنج در مرورگر باز شد: $site_url"
echo "این پنجره را باز نگه دارید. برای توقف سرور Control+C بزنید."
echo ""

wait "$server_pid"
