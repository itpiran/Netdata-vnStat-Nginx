#!/usr/bin/env bash
set -euo pipefail
# Installs Netdata and vnStat on Debian/Ubuntu

echo "Installing Netdata..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --disable-telemetry || true

echo "Installing vnStat..."
apt update
apt install -y vnstat

# Enable services
systemctl enable netdata || true
systemctl enable vnstat || true

echo "Restarting services..."
systemctl restart netdata || true
systemctl restart vnstat || true
echo "Netdata and vnStat installed."
