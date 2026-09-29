#!/bin/bash
# Machine keep-alive — SILENT when everything is healthy; prints one short line when it
# had to restart something. Written for cron, so it never assumes an interactive shell:
# the schedule line sets HOME, PATH and HERMES_HOME itself (cron's own environment is
# minimal, which is why a bare `hermes` or `cloudflared` "is not found" there).
#
# What it checks, in order:
#   1. the desktop answers inside the machine            (nothing it can restart: the container
#                                                        has to be restarted from hpanel)
#   2. the studio answers on its port                    -> restarted with the studio's own start.sh
#   3. the tunnel process is alive                       -> restarted from its own settings file
#
# Wire it up on the machine's own schedule, /config/crontabs/abc:
#   */5 * * * * HERMES_HOME=/agent-home/.hermes HOME=/config PATH=/config/.local/bin:/usr/local/bin:/usr/bin:/bin /config/cron-notify.sh "Keep-alive" /agent-home/.hermes/studio/scripts/keep-alive.sh
#
# Report one line only when it acted, so silence is success and the log stays empty on a
# healthy machine. Studied from the same design as studio-watchdog.sh.

H="${HERMES_HOME:-/agent-home/.hermes}"
STUDIO_DIR="${STUDIO_DIR:-$H/studio}"
STUDIO_PORT="${STUDIO_PORT:-80}"
DESKTOP_PORT="${DESKTOP_PORT:-3001}"
TUNNEL_CONFIG="$H/.cloudflared/config.yml"
OUT=""

mkdir -p "$H/logs" 2>/dev/null

# 1. The desktop, probed inside the machine. Its certificate is self-signed, hence -k.
code=$(curl -ks -o /dev/null -w '%{http_code}' --max-time 5 "https://localhost:${DESKTOP_PORT}/" 2>/dev/null)
if [ -z "$code" ] || [ "$code" = "000" ]; then
  OUT="$OUT — my cloud computer's desktop is not answering: check the container in hpanel (Docker Manager)"
fi

# 2. The studio: restart it the same way boot does.
if [ -d "$STUDIO_DIR" ]; then
  s=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:${STUDIO_PORT}/" 2>/dev/null)
  if [ "$s" != "200" ] && [ "$s" != "302" ]; then
    ( cd "$STUDIO_DIR" && nohup bash start.sh >> "$H/logs/studio-restart.log" 2>&1 & )
    OUT="$OUT — restarted my studio"
  fi
fi

# 3. The tunnel. It reads its settings only when it starts, so the restart needs the file.
if [ -f "$TUNNEL_CONFIG" ] && ! pgrep -f "cloudflared tunnel run" >/dev/null 2>&1; then
  name=$(awk '/^tunnel:/{print $2; exit}' "$TUNNEL_CONFIG" 2>/dev/null)
  ( nohup cloudflared --config "$TUNNEL_CONFIG" tunnel run ${name:+$name} >> "$H/logs/tunnel.log" 2>&1 & )
  OUT="$OUT — restarted my tunnel"
fi

[ -n "$OUT" ] && echo "[keep-alive]$(date -u +' %Y-%m-%dT%H:%MZ')$OUT"
exit 0
