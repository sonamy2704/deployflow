#!/bin/bash
# Usage: ./deploy.sh <full-image-ref>
# Pulls the image, starts it, health-checks it, and rolls back on failure.
set -e
IMAGE="$1"
[ -z "$IMAGE" ] && { echo "usage: $0 <image>"; exit 2; }

APP=deployflow
STATE="$HOME/deploy-state"
mkdir -p "$STATE"

PREVIOUS=$(cat "$STATE/current" 2>/dev/null || echo "")

run_container() {
  docker run -d --name "$APP" -p 5000:5000 --restart unless-stopped \
    -v "$STATE":/deploy-state:ro -e DEPLOY_LOG=/deploy-state/history.log \
    "$1"
}

docker pull "$IMAGE"
docker rm -f "$APP" 2>/dev/null || true
run_container "$IMAGE"

for i in $(seq 1 10); do
  if curl -fs http://127.0.0.1:5000/health > /dev/null; then
    echo "$IMAGE" > "$STATE/current"
    echo "$PREVIOUS" > "$STATE/previous"
    echo "$(date -Is) SUCCESS $IMAGE" >> "$STATE/history.log"
    echo "Deployed $IMAGE"
    exit 0
  fi
  sleep 3
done

echo "Health check failed for $IMAGE"
docker rm -f "$APP" 2>/dev/null || true
if [ -n "$PREVIOUS" ]; then
  run_container "$PREVIOUS"
  echo "$(date -Is) FAILED $IMAGE rolled back to $PREVIOUS" >> "$STATE/history.log"
else
  echo "$(date -Is) FAILED $IMAGE no previous version to roll back to" >> "$STATE/history.log"
fi
exit 1
