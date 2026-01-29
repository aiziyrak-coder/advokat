#!/bin/bash
# Bitta repo: https://github.com/aiziyrak-coder/advokat
# Server: /opt/advokat (backend + frontend)
# Domenlar: https://advokat.cdcgroup.uz (frontend), https://advokatapi.cdcgroup.uz (backend)
set -e

APP_USER=root
REPO_URL="https://github.com/aiziyrak-coder/advokat.git"
APP_DIR="/opt/advokat"
BACKEND_DIR="${APP_DIR}/backend"
FRONTEND_DIR="${APP_DIR}/frontend"
SERVICE_NAME="advokat-backend"
export DJANGO_DEBUG=False

echo "=== Paketlarni o'rnatish ==="
apt update -y
apt install -y git python3 python3-venv python3-pip nginx curl
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt install -y nodejs
fi

echo "=== Advokat repo (bitta) deploy ==="
mkdir -p /opt
cd /opt

if [ -d "$APP_DIR/.git" ]; then
  echo "Repo yangilanmoqda..."
  cd "$APP_DIR" && git pull
else
  echo "Repo klon qilinmoqda..."
  rm -rf "$APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

echo "=== Backend ($BACKEND_DIR) ==="
cd "$BACKEND_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
python manage.py migrate

echo "=== Gunicorn servis (advokat-backend) ==="
cat >/etc/systemd/system/${SERVICE_NAME}.service << EOSVC
[Unit]
Description=Advokat Django backend
After=network.target

[Service]
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${BACKEND_DIR}
Environment="DJANGO_DEBUG=False"
Environment="DJANGO_ALLOWED_HOSTS=advokat.cdcgroup.uz,advokatapi.cdcgroup.uz,.cdcgroup.uz,localhost,127.0.0.1"
ExecStart=${BACKEND_DIR}/venv/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOSVC

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl restart ${SERVICE_NAME}
echo "Backend servis ishga tushirildi"

echo "=== Frontend ($FRONTEND_DIR) ==="
cd "$FRONTEND_DIR"
if command -v npm >/dev/null 2>&1; then
  npm ci
  # Production build uchun VITE_GEMINI_API_KEY o'rnatish
  # Agar .env.production mavjud bo'lsa, undan o'qiadi; aks holda environment variable dan
  if [ -f .env.production ]; then
    echo "Frontend build: .env.production faylidan API kalit olinmoqda..."
  elif [ -n "$VITE_GEMINI_API_KEY" ]; then
    echo "Frontend build: VITE_GEMINI_API_KEY environment variable dan olinmoqda..."
  else
    echo "OGOHLANTIRISH: VITE_GEMINI_API_KEY topilmadi. Frontend buildda API kalit bo'lmasligi mumkin."
    echo "  Serverni build qilishdan oldin: export VITE_GEMINI_API_KEY='your_key' yoki .env.production yarating."
  fi
  npm run build
  echo "Frontend build tugadi"
else
  echo "npm topilmadi, frontend build o'tkazildi"
fi

echo "=== Nginx (advokat.cdcgroup.uz, advokatapi.cdcgroup.uz) ==="
rm -f /etc/nginx/sites-enabled/default
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
nginx -t
systemctl reload nginx
echo "Nginx sozlandi"

echo ""
echo "=== Deploy tugadi ==="
echo "Frontend: https://advokat.cdcgroup.uz"
echo "Backend:  https://advokatapi.cdcgroup.uz"
echo "Backend holati:"
systemctl status ${SERVICE_NAME} --no-pager -l | head -8
