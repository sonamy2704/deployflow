#!/bin/bash
# Manual rollback to the previously deployed image.
set -e
APP=deployflow
STATE="$HOME/deploy-state"
PREVIOUS=$(cat "$STATE/previous" 2>/dev/null || echo "")
[ -z "$PREVIOUS" ] && { echo "No previous version recorded."; exit 1; }
CURRENT=$(cat "$STATE/current" 2>/dev/null || echo "")

docker rm -f "$APP" 2>/dev/null || true
docker run -d --name "$APP" -p 5000:5000 --restart unless-stopped \
  -v "$STATE":/deploy-state:ro -e DEPLOY_LOG=/deploy-state/history.log "$PREVIOUS"

echo "$PREVIOUS" > "$STATE/current"
echo "$CURRENT" > "$STATE/previous"
echo "$(date -Is) ROLLBACK manual rollback from $CURRENT to $PREVIOUS" >> "$STATE/history.log"
echo "Rolled back to $PREVIOUS"
