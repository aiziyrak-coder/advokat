# Serverga joylash va qayta ishga tushirish

Adolat AI loyihasi **backend** (Django) va **frontend** (Vite/React) dan iborat. Serverda Linux (Ubuntu/Debian), Nginx, systemd ishlatiladi.

---

## 1. Birinchi marta serverga joylash (deploy)

### Talablar
- Ubuntu/Debian server (root yoki sudo)
- Domenlar: `advokat.cdcgroup.uz` (frontend), `advokatapi.cdcgroup.uz` (backend) — yoki o'zingizniki

### Variant A: Skriptni serverda ishga tushirish

Serverga SSH orqali kiring va skriptni yuklab ishga tushiring:

```bash
# Serverda (masalan root sifatida):
cd /opt
# Agar deploy-server.sh yo'q bo'lsa, quyidagini yozing yoki scp bilan yuboring:
bash deploy-server.sh
```

Yoki loyiha papkasidan skriptni serverga yuborib, keyin ishga tushiring:

```bash
# Lokal mashinadan:
scp deploy-server.sh root@SERVER_IP:/root/
ssh root@SERVER_IP "bash /root/deploy-server.sh"
```

### Variant B: Qo'lda qadamlar

#### 1.1 Paketlar
```bash
sudo apt update -y
sudo apt install -y git python3 python3-venv python3-pip nginx nodejs npm
```

#### 1.2 Backend (/opt/backend)
```bash
sudo mkdir -p /opt
cd /opt
sudo git clone https://github.com/aiziyrak-coder/AdvokatB.git backend
cd backend

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
python manage.py migrate

# .env yarating (ixtiyoriy, production uchun)
# echo "DJANGO_DEBUG=False" > .env
# echo "DJANGO_SECRET_KEY=..." >> .env
```

#### 1.3 Backend servis (systemd)
```bash
sudo nano /etc/systemd/system/advokat-backend.service
```

Ichiga:
```ini
[Unit]
Description=Advokat Django backend
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/opt/backend
Environment="DJANGO_DEBUG=False"
ExecStart=/opt/backend/venv/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Keyin:
```bash
sudo systemctl daemon-reload
sudo systemctl enable advokat-backend
sudo systemctl start advokat-backend
```

#### 1.4 Frontend (/opt/frontend)
```bash
cd /opt
sudo git clone https://github.com/aiziyrak-coder/AdvokatF.git frontend
cd frontend
npm ci
npm run build
```

#### 1.5 Nginx
```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo nano /etc/nginx/sites-available/advokat
```

Ichiga (domenlarni o'zingiznikiga almashtiring):
```nginx
server {
    listen 80;
    server_name advokatapi.cdcgroup.uz;
    client_max_body_size 50M;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
server {
    listen 80;
    server_name advokat.cdcgroup.uz;
    root /opt/frontend/dist;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Keyin:
```bash
sudo ln -sf /etc/nginx/sites-available/advokat /etc/nginx/sites-enabled/advokat
sudo nginx -t
sudo systemctl reload nginx
```

HTTPS kerak bo'lsa: `certbot` (Let's Encrypt) bilan sertifikat oling va Nginx da 443 qo'shing.

---

## 2. Yangilash va qayta ishga tushirish

Kod o'zgarganda yoki "qayta run" qilmoqchi bo'lsangiz.

### Backend yangilash va restart
```bash
cd /opt/backend
sudo git pull
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
sudo systemctl restart advokat-backend
```

### Frontend yangilash va qayta build
```bash
cd /opt/frontend
sudo git pull
npm ci
npm run build
# Nginx statik fayllarni /opt/frontend/dist dan o'qiydi, qo'shimcha restart kerak emas
```

### Nginx qayta yuklash (konfig o'zgarganda)
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Barchasini bir vaqtda yangilash
```bash
# Backend
cd /opt/backend && sudo git pull && source venv/bin/activate && pip install -r requirements.txt && python manage.py migrate && sudo systemctl restart advokat-backend

# Frontend
cd /opt/frontend && sudo git pull && npm ci && npm run build
```

---

## 3. Servislarni boshqarish

| Vazifa | Buyruq |
|--------|--------|
| Backend holati | `sudo systemctl status advokat-backend` |
| Backend to'xtatish | `sudo systemctl stop advokat-backend` |
| Backend ishga tushirish | `sudo systemctl start advokat-backend` |
| Backend qayta yuklash | `sudo systemctl restart advokat-backend` |
| Backend loglar | `sudo journalctl -u advokat-backend -f` |
| Nginx qayta yuklash | `sudo systemctl reload nginx` |
| Nginx holati | `sudo systemctl status nginx` |

---

## 4. Qisqa xulosa

| Narsa | Joy |
|-------|-----|
| Backend kod | `/opt/backend` (AdvokatB repo) |
| Frontend kod | `/opt/frontend` (AdvokatF repo) |
| Frontend build (statik) | `/opt/frontend/dist` |
| Backend servis | `advokat-backend` (systemd) |
| API | `https://advokatapi.cdcgroup.uz` (yoki server_name) |
| Sayt | `https://advokat.cdcgroup.uz` (yoki server_name) |

**"Qayta run"** = backend uchun `systemctl restart advokat-backend`, frontend uchun `git pull` + `npm run build` (yangi build kerak bo'lsa).
