# Loyiha ildizi (skript joylashgan papka)
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$BackendDir = Join-Path $Root "backend"
$FrontendDir = Join-Path $Root "frontend"

# Portlarni to'xtatish
foreach ($port in @(3000, 8000, 5173)) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $conn.OwningProcess | Sort-Object -Unique | ForEach-Object {
            Write-Host "To'xtatilmoqda: port $port, process $_"
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 500
    }
}

# Backend (Django) – port 8000
Write-Host "Backend ishga tushiryapman :8000..."
$backendCmd = "Set-Location '$BackendDir'; if (Test-Path venv/Scripts/activate.ps1) { . venv/Scripts/activate.ps1 } elseif (Test-Path venv/bin/activate) { . venv/bin/activate }; python manage.py runserver 8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd -WindowStyle Normal

Start-Sleep -Seconds 2

# Frontend (Vite) – port 5173 (Vite default)
Write-Host "Frontend ishga tushiryapman :5173..."
$frontendCmd = "Set-Location '$FrontendDir'; npm run dev"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd -WindowStyle Normal

Write-Host ""
Write-Host "Lokal test:"
Write-Host "  Frontend: http://localhost:5173  (yoki http://localhost:3000)"
Write-Host "  Backend:  http://localhost:8000"
Write-Host ""
