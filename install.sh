#!/usr/bin/env bash
set -euo pipefail
# Main installer for Netdata + vnStat + Nginx + Let's Encrypt
# Usage: sudo bash install.sh

##########################
# User inputs
##########################
read -p "Domain to use for Netdata (e.g. monitor.example.com): " DOMAIN
read -p "Email for Let's Encrypt (for urgent notices): " EMAIL
read -p "Enable Basic Auth for the Netdata dashboard? (y/n): " ENABLE_AUTH

if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
  read -p "Basic auth username: " BASIC_USER
  read -s -p "Basic auth password: " BASIC_PASS
  echo
fi

# Optional: Netdata port (local)
NETDATA_PORT=19999
TARGET_SITE_CONF="/etc/nginx/sites-available/${DOMAIN}"
CREDENTIALS_FILE="$HOME/monitoring_credentials.txt"

##########################
# Prep
##########################
echo "Updating apt and installing prerequisites..."
apt update
apt install -y curl wget apt-transport-https gnupg2 ca-certificates lsb-release software-properties-common

##########################
# Install Netdata & vnStat (separate script)
##########################
bash "$(pwd)/scripts/install_netdata_vnstat.sh"

##########################
# Install Nginx & Certbot
##########################
echo "Installing Nginx and Certbot..."
apt install -y nginx
apt install -y snapd
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot || true

##########################
# Configure Nginx site
##########################
echo "Creating Nginx configuration for ${DOMAIN}..."
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
tpl="$(pwd)/templates/nginx_netdata.conf.tpl"
if [ ! -f "$tpl" ]; then
  echo "Template $tpl not found. Aborting."
  exit 1
fi

sed -e "s|__DOMAIN__|${DOMAIN}|g"         -e "s|__NETDATA_PORT__|${NETDATA_PORT}|g"         "$tpl" > "${TARGET_SITE_CONF}"

ln -sf "${TARGET_SITE_CONF}" /etc/nginx/sites-enabled/${DOMAIN}

# Test nginx config
nginx -t

echo "Reloading Nginx..."
systemctl restart nginx

##########################
# Setup Basic Auth (optional)
##########################
if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
  bash "$(pwd)/scripts/setup_htpasswd.sh" "${DOMAIN}" "${BASIC_USER}" "${BASIC_PASS}"
  echo "Basic Auth enabled for ${DOMAIN}"
  echo "Username: ${BASIC_USER}" > "$CREDENTIALS_FILE"
  echo "Password: ${BASIC_PASS}" >> "$CREDENTIALS_FILE"
  echo "Domain: ${DOMAIN}" >> "$CREDENTIALS_FILE"
  echo "Keep this file safe: $CREDENTIALS_FILE"
fi

##########################
# Obtain Let's Encrypt certificate via Certbot (Nginx plugin)
##########################
echo "Requesting Let's Encrypt certificate via certbot..."
certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" || {
  echo "certbot failed. Please check DNS and ports 80/443. You can try to run certbot manually later."
}

##########################
# Finalize and show info
##########################
systemctl reload nginx || true
echo "Installation finished."
echo "Visit: https://${DOMAIN}/"
if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
  echo "Use credentials saved in $CREDENTIALS_FILE"
fi
