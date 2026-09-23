#!/bin/bash
# Studio watchdog — SILENT when healthy; prints one line only when it restarted the studio.
# Set STUDIO_DIR / STUDIO_PORT if your install differs from the defaults.
# Wire it up: hermes cron create 'every 5m' --name 'Studio health check' --no-agent --script studio-watchdog.sh
STUDIO_DIR="${STUDIO_DIR:-${GALLERY_DIR:-/opt/data/studio}}"
STUDIO_PORT="${STUDIO_PORT:-${GALLERY_PORT:-80}}"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:${STUDIO_PORT}/" 2>/dev/null)
if [ "$code" != "200" ] && [ "$code" != "302" ]; then
  cd "$STUDIO_DIR" 2>/dev/null || exit 0
  bash start.sh >> /opt/data/studio-watchdog.log 2>&1
  echo "[studio-watchdog] studio was ${code:-down} — restarted"
fi
