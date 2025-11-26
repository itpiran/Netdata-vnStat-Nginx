# Nginx reverse-proxy template for Netdata
# Place this file in /etc/nginx/sites-available/{DOMAIN} (the installer does this)

server {
    listen 80;
    server_name __DOMAIN__;

    # Redirect all HTTP to HTTPS (certbot will handle SSL later)
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 302 https://__DOMAIN__$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name __DOMAIN__;

    # SSL will be configured by certbot; cert paths below are placeholders.
    ssl_certificate /etc/letsencrypt/live/__DOMAIN__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__DOMAIN__/privkey.pem;

    # Optional Basic Auth - the install script will create an htpasswd file and enable it.
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/htpasswd/__DOMAIN__.htpasswd;

    location / {
        proxy_pass http://127.0.0.1:__NETDATA_PORT__/;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Optional: restrict access to specific IPs (uncomment and edit)
    # allow 1.2.3.4;
    # deny all;
}
