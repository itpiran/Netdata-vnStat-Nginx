#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run this script as root." >&2
  exit 1
fi

##########################
# User input
##########################

read -rp "Domain (FQDN): " DOMAIN
read -rp "Enable SSL with Let's Encrypt? (y/n): " ENABLE_SSL
read -rp "Enable Basic Auth? (y/n): " ENABLE_AUTH

EMAIL=""
if [[ "$ENABLE_SSL" =~ ^[Yy] ]]; then
    read -rp "Email for Let's Encrypt: " EMAIL
fi

BASIC_USER=""
BASIC_PASS=""
if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
    read -rp "Basic Auth username: " BASIC_USER
    read -srp "Basic Auth password: " BASIC_PASS
    echo
fi

##########################
# Variables
##########################

NETDATA_PORT=19999
NGINX_AV="/etc/nginx/sites-available"
NGINX_EN="/etc/nginx/sites-enabled"
SITE_CONF="$NGINX_AV/$DOMAIN"
WEBROOT="/var/www/certbot"
HTPASS_DIR="/etc/nginx/htpasswd"
HTPASS_FILE="$HTPASS_DIR/$DOMAIN.htpasswd"
CRED_FILE="$HOME/monitoring_credentials.txt"

##########################
# Install packages
##########################

apt update
apt install -y nginx curl

if [[ "$ENABLE_SSL" =~ ^[Yy] ]]; then
    apt install -y certbot python3-certbot-nginx
fi

##########################
# Install Netdata + vnStat
##########################

if [[ -f "./scripts/install_netdata.sh" ]]; then
    echo "Running Netdata installer..."
    bash ./scripts/install_netdata.sh
else
    echo "WARNING: scripts/install_netdata.sh missing. Skipping."
fi

##########################
# Initial Nginx HTTP-only config
##########################

mkdir -p "$WEBROOT" "$HTPASS_DIR"

cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root $WEBROOT;
    }

    location / {
        proxy_pass http://127.0.0.1:$NETDATA_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Upgrade \$http_upgrade;
    }
}
EOF

ln -sf "$SITE_CONF" "$NGINX_EN/$DOMAIN"

nginx -t
systemctl reload nginx

##########################
# Basic Auth
##########################

if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
    echo "Creating Basic Auth file..."
    mkdir -p "$HTPASS_DIR"

    if ! command -v htpasswd >/dev/null; then
        apt install -y apache2-utils
    fi

    htpasswd -b -c "$HTPASS_FILE" "$BASIC_USER" "$BASIC_PASS"

    chown root:www-data "$HTPASS_FILE"
    chmod 640 "$HTPASS_FILE"

    {
        echo "URL: http://$DOMAIN/"
        echo "User: $BASIC_USER"
        echo "Pass: $BASIC_PASS"
    } > "$CRED_FILE"
fi

##########################
# SSL generation
##########################

CERT_OK=0

if [[ "$ENABLE_SSL" =~ ^[Yy] ]]; then
    echo "Requesting ECDSA Let's Encrypt certificate..."

    set +e
    certbot certonly --webroot \
        -w "$WEBROOT" \
        -d "$DOMAIN" \
        --cert-name "$DOMAIN" \
        --key-type ecdsa \
        --agree-tos -m "$EMAIL" \
        --non-interactive
    CERT_OK=$?
    set -e

    if [[ "$CERT_OK" -ne 0 ]]; then
        echo "WARNING: SSL failed. Keeping HTTP-only."
        ENABLE_SSL="n"
    fi
fi

##########################
# Final Nginx configuration
##########################

if [[ "$ENABLE_SSL" =~ ^[Yy] ]]; then

cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root $WEBROOT;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

EOF

if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
cat >> "$SITE_CONF" <<EOF
    auth_basic "Restricted Netdata";
    auth_basic_user_file $HTPASS_FILE;

EOF
fi

cat >> "$SITE_CONF" <<EOF
    location / {
        proxy_pass http://127.0.0.1:$NETDATA_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Upgrade \$http_upgrade;
    }
}
EOF

else

cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root $WEBROOT;
    }
EOF

if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
cat >> "$SITE_CONF" <<EOF

    auth_basic "Restricted Netdata";
    auth_basic_user_file $HTPASS_FILE;

EOF
fi

cat >> "$SITE_CONF" <<EOF
    location / {
        proxy_pass http://127.0.0.1:$NETDATA_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Upgrade \$http_upgrade;
    }
}
EOF

fi

ln -sf "$SITE_CONF" "$NGINX_EN/$DOMAIN"

nginx -t
systemctl reload nginx

##########################
# FINISH
##########################

if [[ "$ENABLE_SSL" =~ ^[Yy] ]]; then
    echo "Done. Visit: https://$DOMAIN/"
else
    echo "Done. Visit: http://$DOMAIN/"
fi

if [[ "$ENABLE_AUTH" =~ ^[Yy] ]]; then
    echo "Credentials saved in: $CRED_FILE"
fi
