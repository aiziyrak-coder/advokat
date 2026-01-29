# Kill processes on ports 3000 and 8000
foreach ($port in @(3000, 8000)) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $conn.OwningProcess | Sort-Object -Unique | ForEach-Object {
            Write-Host "Stopping process $_ on port $port"
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 500
    }
}

# Start backend on 8000
Write-Host "Starting backend on :8000..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location 'c:\Users\alocomputers\Downloads\adolataidavomi\backend'; py -3 manage.py runserver 8000" -WindowStyle Minimized

# Start frontend on 3000
Write-Host "Starting frontend on :3000..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location 'c:\Users\alocomputers\Downloads\adolataidavomi\frontend'; npm run dev -- --port 3000" -WindowStyle Minimized

Write-Host "Done. Frontend: http://localhost:3000  Backend: http://localhost:8000"
