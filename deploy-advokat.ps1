# deploy-advokat.ps1
$password = "Ziyrak2025Ai"
$server = "root@167.71.53.238"

$commands = @"
set -e
APP_USER=root
BACKEND_DIR=/opt/backend
FRONTEND_DIR=/opt/frontend
BACKEND_REPO=https://github.com/aiziyrak-coder/AdvokatB.git
FRONTEND_REPO=https://github.com/aiziyrak-coder/AdvokatF.git
SERVICE_NAME=advokat-backend
export DJANGO_DEBUG=False

apt update -y
apt install -y git python3 python3-venv python3-pip nginx

mkdir -p /opt
cd /opt

if [ -d `$BACKEND_DIR/.git ]; then
  cd `$BACKEND_DIR && git pull
else
  rm -rf `$BACKEND_DIR
  git clone `$BACKEND_REPO `$BACKEND_DIR
  cd `$BACKEND_DIR
fi

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
else
  pip install django djangorestframework djangorestframework-simplejwt django-cors-headers gunicorn
fi
python manage.py migrate

cat >/etc/systemd/system/`${SERVICE_NAME}.service << EOSVC
[Unit]
Description=Advokat Django backend
After=network.target

[Service]
User=`${APP_USER}
Group=`${APP_USER}
WorkingDirectory=`${BACKEND_DIR}
Environment="DJANGO_DEBUG=False"
ExecStart=`${BACKEND_DIR}/venv/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOSVC

systemctl daemon-reload
systemctl enable `${SERVICE_NAME}
systemctl restart `${SERVICE_NAME}

cd /opt
if [ -d `$FRONTEND_DIR/.git ]; then
  cd `$FRONTEND_DIR && git pull
else
  rm -rf `$FRONTEND_DIR
  git clone `$FRONTEND_REPO `$FRONTEND_DIR
  cd `$FRONTEND_DIR
fi

if command -v npm >/dev/null 2>&1; then
  if [ -f package-lock.json ]; then npm ci; else npm install; fi
  npm run build
fi

rm -f /etc/nginx/sites-enabled/default
cat >/etc/nginx/sites-available/advokat << 'NGINX'
server {
    listen 80;
    server_name advokatapi.cdcgroup.uz;
    client_max_body_size 50M;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
    }
}
server {
    listen 80;
    server_name advokat.cdcgroup.uz;
    root /opt/frontend/dist;
    index index.html;
    location / {
        try_files `$uri `$uri/ /index.html;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/advokat /etc/nginx/sites-enabled/advokat
nginx -t
systemctl reload nginx
"@

echo $commands | ssh -o StrictHostKeyChecking=no $server bash
