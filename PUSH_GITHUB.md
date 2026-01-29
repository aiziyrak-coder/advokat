# GitHub'ga push qilish

Frontend build qilindi va barcha o'zgarishlar commit qilindi. GitHub'ga yuborish uchun:

## 1. GitHub'da yangi repo yarating

1. https://github.com/new ga kiring
2. Repository name: masalan `adolat-ai`
3. Public tanlang, **README, .gitignore qo'shmang** (loyihada bor)
4. Create repository tugmasini bosing

## 2. Remote qo'shing va push qiling

PowerShell da (loyiha papkasida):

```powershell
# O'z GitHub username va repo nomingizni yozing:
$env:GITHUB_REPO = "https://github.com/SIZNING_USERNAME/adolat-ai.git"
.\push-to-github.ps1
```

Yoki qo'lda:

```powershell
& "C:\Program Files\Git\bin\git.exe" remote add origin https://github.com/SIZNING_USERNAME/adolat-ai.git
& "C:\Program Files\Git\bin\git.exe" push -u origin main
```

**SIZNING_USERNAME** o'rniga GitHub foydalanuvchi nomingizni yozing.

## Build qayta kerak bo'lsa

```powershell
cd frontend
npm run build
# yoki Node PATH da bo'lsa: node node_modules/vite/bin/vite.js build
```
