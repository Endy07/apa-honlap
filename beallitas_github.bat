@echo off
chcp 65001 >nul
echo ========================================================
echo Elso GitHub Beallitas
echo ========================================================
echo.
echo Kerlek, eloszor hozz letre egy URES repository-t a GitHub.com-on!
echo (Ne pipáld be a README vagy gitignore hozzáadását, legyen teljesen üres!)
echo.
echo Ha megvan, masold ki a linkjet (pl. https://github.com/neved/repo.git)
echo es illeszd be ide (jobb klikk vagy Ctrl+V):
echo.
set /p giturl="GitHub link: "

git remote add origin %giturl%
git branch -M main

echo.
echo Hozzaadas es feltoltes...
git add .
git commit -m "Elso feltoltes"
git push -u origin main

echo.
echo ========================================================
echo Sikeresen osszekotve a GitHub-bal!
echo A kodok kimentek. 
echo Innentol kezdve csak a 'feltoltes.bat' fajlt kell hasznalnod,
echo ha uj HTML-t raksz a mappaba!
echo ========================================================
pause
