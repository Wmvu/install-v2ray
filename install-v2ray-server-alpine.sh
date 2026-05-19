#!/bin/sh
set -eu

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }

PORT="${PORT:-10000}"
UUID="${UUID:-$(cat /proc/sys/kernel/random/uuid)}"
CLIENT_EMAIL="${CLIENT_EMAIL:-user@local}"
SERVICE_USER="v2ray"
CONF_DIR="/etc/v2ray"
CONF_FILE="$CONF_DIR/config.json"
INIT_FILE="/etc/init.d/v2ray"
LOG_DIR="/var/log/v2ray"
COLOR_RESET="$(printf '\033[0m')"
COLOR_TITLE="$(printf '\033[1;36m')"
COLOR_LABEL="$(printf '\033[1;33m')"
COLOR_VALUE="$(printf '\033[1;32m')"

apk add --no-cache curl unzip ca-certificates >/dev/null
update-ca-certificates >/dev/null 2>&1 || true

install_v2ray_binary() {
  if apk add --no-cache v2ray >/dev/null 2>&1; then
    if command -v v2ray >/dev/null 2>&1; then
      return 0
    fi
  fi

  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64) ASSET="v2ray-linux-64.zip" ;;
    aarch64|arm64) ASSET="v2ray-linux-arm64-v8a.zip" ;;
    armv7l) ASSET="v2ray-linux-arm32-v7a.zip" ;;
    *)
      echo "unsupported arch: $ARCH"
      exit 1
      ;;
  esac

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT INT TERM
  URL="https://github.com/v2fly/v2ray-core/releases/latest/download/$ASSET"
  curl -fL --retry 3 --connect-timeout 10 "$URL" -o "$TMP/v2ray.zip" >/dev/null
  unzip -q "$TMP/v2ray.zip" -d "$TMP/unpack"
  BIN="$(find "$TMP/unpack" -type f \( -name v2ray -o -name v2ray.exe \) | head -n 1)"
  [ -n "$BIN" ] || { echo "v2ray binary not found"; exit 1; }
  install -d /usr/local/bin
  install -m 755 "$BIN" /usr/local/bin/v2ray

  for f in geoip.dat geosite.dat; do
    SRC="$(find "$TMP/unpack" -type f -name "$f" | head -n 1 || true)"
    [ -n "$SRC" ] && install -D -m 644 "$SRC" "/usr/local/share/v2ray/$f"
  done
}

install_v2ray_binary

adduser -D -H -s /sbin/nologin "$SERVICE_USER" >/dev/null 2>&1 || true
install -d "$CONF_DIR" "$LOG_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$CONF_DIR" "$LOG_DIR"

if [ ! -f "$CONF_FILE" ]; then
cat > "$CONF_FILE" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vmess-in",
      "listen": "0.0.0.0",
      "port": $PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0,
            "email": "$CLIENT_EMAIL",
            "security": "auto"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"],
        "routeOnly": false
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
EOF
fi

cat > "$INIT_FILE" <<'EOF'
#!/sbin/openrc-run

name="v2ray"
description="V2Ray service"
command="/usr/local/bin/v2ray"
command_args="run -config /etc/v2ray/config.json"
command_user="v2ray:v2ray"
supervisor="supervise-daemon"
pidfile="/run/${RC_SVCNAME}.pid"

depend() {
  need net
}
EOF

chmod +x "$INIT_FILE"
rc-update add v2ray default >/dev/null 2>&1 || true
rc-service v2ray restart >/dev/null

PUBLIC_IP="$(curl -fsSL https://api.ipify.org 2>/dev/null || true)"
[ -n "$PUBLIC_IP" ] || PUBLIC_IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
[ -n "$PUBLIC_IP" ] || PUBLIC_IP="$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || true)"

printf '%sV2Ray installed.%s\n\n' "$COLOR_TITLE" "$COLOR_RESET"
printf '%sServer%s\n' "$COLOR_TITLE" "$COLOR_RESET"
printf '  %sIP:%s %s\n' "$COLOR_LABEL" "$COLOR_RESET" "${PUBLIC_IP:-unknown}"
printf '  %sPort:%s %s\n' "$COLOR_LABEL" "$COLOR_RESET" "$PORT"
printf '  %sUUID:%s %s\n' "$COLOR_LABEL" "$COLOR_RESET" "$UUID"
printf '  %sProtocol:%s %s\n' "$COLOR_LABEL" "$COLOR_RESET" "vmess"
printf '  %sNetwork:%s %s\n' "$COLOR_LABEL" "$COLOR_RESET" "tcp"
printf '  %sAlterId:%s %s\n\n' "$COLOR_LABEL" "$COLOR_RESET" "0"

printf '%sConfig%s\n' "$COLOR_TITLE" "$COLOR_RESET"
printf '  %s%s%s\n\n' "$COLOR_VALUE" "$CONF_FILE" "$COLOR_RESET"

printf '%sService%s\n' "$COLOR_TITLE" "$COLOR_RESET"
printf '  %src-service v2ray status%s\n' "$COLOR_VALUE" "$COLOR_RESET"
printf '  %src-service v2ray restart%s\n\n' "$COLOR_VALUE" "$COLOR_RESET"

printf '%sClient JSON snippet%s\n' "$COLOR_TITLE" "$COLOR_RESET"
cat <<EOF
{
  "address": "${PUBLIC_IP:-your-server-ip}",
  "port": $PORT,
  "uuid": "$UUID",
  "alterId": 0,
  "protocol": "vmess",
  "network": "tcp"
}
EOF
