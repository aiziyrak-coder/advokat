# Serverga joylash va qayta ishga tushirish

Bitta repo: **https://github.com/aiziyrak-coder/advokat** (backend + frontend).  
Domenlar: **https://advokat.cdcgroup.uz** (frontend), **https://advokatapi.cdcgroup.uz** (backend).  
Server IP: **167.71.53.238** | SSH: `ssh root@167.71.53.238`

---

## 0. Globalda (domenlarda) ishlashi uchun

1. **DNS** — Domen provayderingizda (cdcgroup.uz) quyidagi A-yozuvlarni qo‘shing:
   - `advokat.cdcgroup.uz` → **167.71.53.238**
   - `advokatapi.cdcgroup.uz` → **167.71.53.238**  
   Tarqalishi 5–60 daqiqa vaqt olishi mumkin.

2. **Serverga kirish:** `ssh root@167.71.53.238`

3. **Deploy** — Quyidagi [1. Birinchi marta](#1-birinchi-marta-serverga-joylash) bo‘limidagi skriptni ishlating yoki qo‘lda qadamlar bajariladi.

4. **HTTPS (ixtiyoriy)** — Brauzer xavfsiz ko‘rsatishi uchun Let's Encrypt o‘rnatish mumkin (qadamlar pastda).

---

## 1. Birinchi marta serverga joylash

### Skript orqali (tavsiya)

Serverda (root yoki sudo):

```bash
cd /opt
# Skriptni yuklab oling (yoki scp bilan yuboring)
# Masalan: git clone https://github.com/aiziyrak-coder/advokat.git /tmp/advokat && cp /tmp/advokat/deploy-server.sh /root/
bash deploy-server.sh
```

Skript:
- Reponi **/opt/advokat** ga klon qiladi (yoki `git pull`)
- Backend: **/opt/advokat/backend** (venv, migrate, gunicorn servis `advokat-backend`)
- Frontend: **/opt/advokat/frontend** (npm ci, npm run build)
- Nginx: **advokat.cdcgroup.uz** → `/opt/advokat/frontend/dist`, **advokatapi.cdcgroup.uz** → `127.0.0.1:8000`

---

## 2. Yangilash va qayta ishga tushirish

Kod o‘zgargach (GitHub’da yangi commit):

```bash
# Bitta papkada hammasi
cd /opt/advokat
git pull

# Backend
cd /opt/advokat/backend
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
sudo systemctl restart advokat-backend

# Frontend (API kalit bilan build)
cd /opt/advokat/frontend
npm ci
# Agar .env.production mavjud bo'lsa, undan o'qiadi; aks holda environment variable:
export VITE_GEMINI_API_KEY='your_gemini_api_key_here'
npm run build
```

Nginx konfig o‘zgarmasa `reload` kerak emas; frontend yangi build avtomatik beriladi.

---

## 2.1. Frontend uchun Gemini API kalit sozlash

Frontend buildda **VITE_GEMINI_API_KEY** kerak. Ikki usul:

**Usul A: `.env.production` fayli (tavsiya)**

```bash
cd /opt/advokat/frontend
cp .env.production.example .env.production
nano .env.production
# VITE_GEMINI_API_KEY=your_actual_api_key_here yozing
```

Keyin `npm run build` avtomatik `.env.production` dan o‘qiydi.

**Usul B: Environment variable**

```bash
export VITE_GEMINI_API_KEY='your_gemini_api_key_here'
cd /opt/advokat/frontend
npm run build
```

**Eslatma:** API kalit build vaqtida kodga qo‘shiladi, shuning uchun har safar build qilganda qayta o‘rnatish kerak.

---

## 3. Servislar

| Vazifa | Buyruq |
|--------|--------|
| Backend holati | `sudo systemctl status advokat-backend` |
| Backend qayta yuklash | `sudo systemctl restart advokat-backend` |
| Backend loglar | `sudo journalctl -u advokat-backend -f` |
| Nginx qayta yuklash | `sudo systemctl reload nginx` |

---

## 4. Eski joylashuvni o‘chirish (ixtiyoriy)

Agar ilgari **/opt/backend** va **/opt/frontend** (alohida AdvokatB/AdvokatF) ishlatilgan bo‘lsa, yangi **/opt/advokat** ishlagach ularni o‘chirishingiz mumkin:

```bash
sudo systemctl stop advokat-backend   # agar eski servis boshqa papkaga bog‘liq bo‘lsa, avval yangi deploy qiling
# Keyin eski papkalarni o‘chirish:
# sudo rm -rf /opt/backend /opt/frontend
```

Yangi deployda servis allaqachon **/opt/advokat/backend** ga yo‘naltirilgan, shuning uchun faqat Nginx yangi **/opt/advokat/frontend/dist** ni ko‘rsatadi.

---

## 5. HTTPS (Let's Encrypt) — ixtiyoriy

Domenlar globalda ishlagach, HTTPS qo‘shish uchun serverda:

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d advokat.cdcgroup.uz -d advokatapi.cdcgroup.uz
```

Certbot Nginx konfigini o‘zi yangilaydi. Keyin brauzerda **https://advokat.cdcgroup.uz** va **https://advokatapi.cdcgroup.uz** ishlaydi.

---

## 6. 404 — "Django tried these URL patterns" (advokat.cdcgroup.uz da)

Agar **https://advokat.cdcgroup.uz/** ochilganda Django 404 ko‘rsatsa, Nginx **frontend** o‘rniga so‘rovni **backend** ga yubormoqda. Tuzatish:

**Serverda (SSH):**

```bash
# 1) Frontend papka bormi
ls -la /opt/advokat/frontend/dist/index.html

# 2) Nginx konfigini to‘g‘rilash — faqat advokatapi backend ga, advokat frontend static
sudo tee /etc/nginx/sites-available/advokat << 'EOF'
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
EOF

sudo ln -sf /etc/nginx/sites-available/advokat /etc/nginx/sites-enabled/advokat
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

**Agar HTTPS (certbot) ishlatilsa**, certbot qo‘shgan `listen 443 ssl` bloklarini ham saqlab, **advokat.cdcgroup.uz** uchun `root` va `try_files` bo‘lishi kerak, `proxy_pass` bo‘lmasligi kerak. Kerak bo‘lsa: `sudo nano /etc/nginx/sites-available/advokat` — `advokat.cdcgroup.uz` server blokida `proxy_pass` o‘rniga `root /opt/advokat/frontend/dist;` va `try_files $uri $uri/ /index.html;` bo‘lsin.

---

## 7. 400 Bad Request (backendda HTTPS da)

Agar **https://advokatapi.cdcgroup.uz** da 400 chiqsa, Django HTTPS orqali kelayotgan so‘rovni to‘g‘ri tanlamayapti. Tuzatish:

1. **Backend** — Loyihada qo‘shilgan: `SECURE_PROXY_SSL_HEADER`, `ALLOWED_HOSTS` (.cdcgroup.uz). Serverni yangilang: `cd /opt/advokat && git pull`, keyin `sudo systemctl restart advokat-backend`.

2. **Nginx** — **advokatapi** uchun `location /` ichida `proxy_set_header X-Forwarded-Proto $scheme;` bo‘lishi kerak. Agar certbot dan keyin bu qator yo‘q bo‘lsa: `sudo nano /etc/nginx/sites-available/advokat` — `advokatapi.cdcgroup.uz` server blokidagi `location /` da `proxy_set_header X-Forwarded-Proto $scheme;` qatorini qo‘shing. Saqlab: `sudo nginx -t && sudo systemctl reload nginx`.

---

## 8. Login/Register da "Network Error" (ERR_NETWORK)

Brauzerda **advokat.cdcgroup.uz** da login/register qilganda "Network Error" chiqsa:

1. **Backend ishlayaptimi** — serverda: `sudo systemctl status advokat-backend`. Agar `active (running)` bo‘lmasa: `sudo systemctl restart advokat-backend`.
2. **API javob bermayaptimi** — serverda yoki kompyuteringizda:
   ```bash
   curl -v -X POST https://advokatapi.cdcgroup.uz/api/auth/login/ -H "Content-Type: application/json" -d '{"username":"test","password":"test"}'
   ```
   Agar `Connection refused` yoki javob kelmasa — backend yoki Nginx muammosi. Nginx: `sudo nginx -t && sudo systemctl reload nginx`.
3. **CORS** — Backendda `CORS_ALLOWED_ORIGINS` da `https://advokat.cdcgroup.uz` bo‘lishi kerak (loyihada qo‘shilgan). Kod yangilang: `cd /opt/advokat && git pull`, keyin backend qayta ishga tushiring.
4. **Brauzerda** — F12 → Network: login so‘rovida qaysi URL ga borayapti va qanday javob (yoki xato) kelayapti — tekshiring.

3. **400 hali bo‘lsa** — Backend logini ko‘ring (Django qaysi xatoni yozayotganini bilish uchun):
   ```bash
   sudo journalctl -u advokat-backend -n 80 --no-pager
   ```
   Systemd da ALLOWED_HOSTS aniq berilgan bo‘lishi kerak:
   ```bash
   sudo systemctl edit --full advokat-backend
   ```
   `[Service]` ostida qatorlar bo‘lsin:
   ```ini
   Environment="DJANGO_DEBUG=False"
   Environment="DJANGO_ALLOWED_HOSTS=advokat.cdcgroup.uz,advokatapi.cdcgroup.uz,.cdcgroup.uz,localhost,127.0.0.1"
   ```
   Saqlab: `sudo systemctl daemon-reload && sudo systemctl restart advokat-backend`.
