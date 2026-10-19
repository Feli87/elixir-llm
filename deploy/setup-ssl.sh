#!/bin/bash
set -e

DOMAIN="wa.felidev.com"
EMAIL="${CERTBOT_EMAIL:-admin@felidev.com}"
WEBROOT="/var/www/certbot"
NGINX_CONF="/etc/nginx/sites-available/elixir-llm"
NGINX_LINK="/etc/nginx/sites-enabled/elixir-llm"

echo "==> Installing certbot if needed..."
if ! command -v certbot &> /dev/null; then
    apt-get update -qq
    apt-get install -y -qq certbot
fi

echo "==> Creating webroot for ACME challenges..."
mkdir -p "$WEBROOT"

# Paso 1: config temporal HTTP-only para que certbot valide
echo "==> Writing temporary HTTP-only nginx config..."
cat > "$NGINX_CONF" << HTTPCONF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root $WEBROOT;
    }

    location / {
        return 200 'waiting for ssl setup';
        add_header Content-Type text/plain;
    }
}
HTTPCONF

ln -sf "$NGINX_CONF" "$NGINX_LINK"
nginx -t && systemctl reload nginx

# Paso 2: obtener certificado
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "==> Certificate for $DOMAIN already exists, skipping..."
else
    echo "==> Requesting certificate for $DOMAIN..."
    certbot certonly \
        --webroot \
        --webroot-path "$WEBROOT" \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive
fi

# Paso 3: instalar config nginx con SSL
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/nginx.conf" "$NGINX_CONF"
nginx -t && systemctl reload nginx

# Paso 4: auto-renewal
if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -
    echo "==> Added certbot renewal cron"
fi

echo ""
echo "==> Done! https://$DOMAIN"
