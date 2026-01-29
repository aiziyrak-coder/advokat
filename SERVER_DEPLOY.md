# Serverga joylash va qayta ishga tushirish

Bitta repo: **https://github.com/aiziyrak-coder/advokat** (backend + frontend).  
Domenlar: **https://advokat.cdcgroup.uz** (frontend), **https://advokatapi.cdcgroup.uz** (backend).

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

# Frontend
cd /opt/advokat/frontend
npm ci
npm run build
```

Nginx konfig o‘zgarmasa `reload` kerak emas; frontend yangi build avtomatik beriladi.

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
