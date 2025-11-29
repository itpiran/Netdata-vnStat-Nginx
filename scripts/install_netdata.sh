#!/usr/bin/env bash
# Installer for Netdata (Debian/Ubuntu)
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run this script as root." >&2
  exit 1
fi

echo "Updating repositories..."
apt update -y

echo "Installing Netdata + vnStat..."
apt install -y netdata

echo "Enabling services..."
systemctl enable --now netdata || true

echo "Checking Netdata status:"
systemctl --no-pager --full status netdata || true

echo "Netdata installed successfully."
