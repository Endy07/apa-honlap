@echo off
echo ========================================================
echo Apa / Karai Mihaly Weboldal Feltolto es Frissito Szkript
echo ========================================================
echo.
echo 1. Keszitem a fajl listat (files.json)...
powershell -ExecutionPolicy Bypass -File frissit.ps1

echo 2. Fajlok listaja sikeresen frissitve.
echo.

echo 3. Fajlok szinkronizalasa a GitHub-al...
git add .
git commit -m "Automatikus feltoltes: frissult az apa weboldalak listaja"
git push

echo.
echo ========================================================
echo Kesz! A fajlok kimentek a GitHub-ra.
echo ========================================================
pause
