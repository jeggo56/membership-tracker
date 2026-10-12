@echo off
chcp 65001 >nul
title 会员管家 · 本地预览服务器
echo ============================================
echo    会员管家 Membership Tracker 本地预览
echo ============================================
echo.
echo 正在启动本地服务器...
echo.

REM 获取本机局域网 IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    goto :gotip
)
:gotip
set IP=%IP: =%

echo   [电脑端]  浏览器打开： http://localhost:8000
if defined IP echo   [手机端]  同一 WiFi 下打开： http://%IP%:8000
echo.
echo  按 Ctrl+C 停止服务器
echo ============================================
echo.

python -m http.server 8000
pause
