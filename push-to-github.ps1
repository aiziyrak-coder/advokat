# GitHub'ga push qilish
# 1) GitHub'da yangi repo yarating (https://github.com/new) - nomi masalan: adolat-ai
# 2) Quyidagi buyruqni o'z username va repo nomi bilan ishga tushiring:
#    .\push-to-github.ps1
#    yoki URL ni o'zingiz bering:
#    $env:GITHUB_REPO = "https://github.com/SIZNING_USERNAME/adolat-ai.git"; .\push-to-github.ps1

$repoUrl = $env:GITHUB_REPO
if (-not $repoUrl) {
    Write-Host "GITHUB_REPO o'rnatilmagan. GitHub'da repo yarating va URL ni kiriting:" -ForegroundColor Yellow
    $repoUrl = Read-Host "Masalan: https://github.com/username/adolat-ai.git"
}
if (-not $repoUrl) { Write-Host "Bekor qilindi."; exit 1 }

$git = "C:\Program Files\Git\bin\git.exe"
$root = $PSScriptRoot

& $git -C $root remote remove origin 2>$null
& $git -C $root remote add origin $repoUrl
& $git -C $root branch -M main 2>$null
& $git -C $root push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push xatolik bilan tugadi. Repo mavjudligi va token/SSH ni tekshiring." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Muvaffaqiyatli push qilindi." -ForegroundColor Green
