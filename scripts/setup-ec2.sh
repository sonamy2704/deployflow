#!/bin/bash
# Run once on a fresh Ubuntu EC2 instance:  bash scripts/setup-ec2.sh
set -e
sudo apt update
sudo apt install -y docker.io nginx curl
sudo usermod -aG docker "$USER"
sudo systemctl enable --now docker nginx

# Nginx reverse proxy (expects nginx/deployflow.conf next to the scripts/ folder)
CONF="$(dirname "$0")/../nginx/deployflow.conf"
if [ -f "$CONF" ]; then
  sudo cp "$CONF" /etc/nginx/sites-available/default
  sudo nginx -t && sudo systemctl reload nginx
fi

mkdir -p "$HOME/deploy-state"
echo "Done. Log out and back in so the docker group applies."
