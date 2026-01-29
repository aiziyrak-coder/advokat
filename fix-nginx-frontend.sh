#!/bin/bash
# advokat.cdcgroup.uz -> frontend (static), advokatapi.cdcgroup.uz -> Django
# Serverni tuzatish uchun: bash fix-nginx-frontend.sh
set -e
echo "Frontend papka tekshirilmoqda..."
test -f /opt/advokat/frontend/dist/index.html || { echo "Xato: /opt/advokat/frontend/dist/index.html topilmadi. Avval: cd /opt/advokat/frontend && npm run build"; exit 1; }
echo "Nginx konfigi yozilmoqda..."
cat >/etc/nginx/sites-available/advokat << 'NGINX'
server {
    listen 80;
    server_name advokatapi.cdcgroup.uz;
    client_max_body_size 50M;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
server {
    listen 80;
    server_name advokat.cdcgroup.uz;
    root /opt/advokat/frontend/dist;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/advokat /etc/nginx/sites-enabled/advokat
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
echo "Tayyor. https://advokat.cdcgroup.uz endi frontend (SPA) beradi."
echo "Agar HTTPS ishlatilsa: certbot --nginx -d advokat.cdcgroup.uz -d advokatapi.cdcgroup.uz"
