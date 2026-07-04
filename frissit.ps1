$hermesPath = "C:\xampp\htdocs\2026\Hermes"
$apaPath = "C:\xampp\htdocs\2026\Hermes\APA\Eredmenyek"
$keywords = @("apa", "kárai mihály", "karai mihaly", "karai_mihaly", "kárai_mihály")

if (-not (Test-Path $apaPath)) {
    New-Item -ItemType Directory -Path $apaPath | Out-Null
}

# ALAP KÖNYVTÁR MÁSOLÁSA (JS Hivatkozások miatt!)
# Mivel a JS kódból dinamikusan is hivatkoznak képekre, a statikus elemző nem mindig találja meg őket.
# Ezért a teljes apa_festmenyek mappát garantáltan felmásoljuk a gyökérbe.
$festmenyekSource = Join-Path $hermesPath "apa_festmenyek"
$festmenyekDest = Join-Path $apaPath "apa_festmenyek"
if (Test-Path $festmenyekSource) {
    if (-not (Test-Path $festmenyekDest)) {
        New-Item -ItemType Directory -Path $festmenyekDest | Out-Null
    }
    Copy-Item -Path "$festmenyekSource\*" -Destination $festmenyekDest -Recurse -Force
}

$files = Get-ChildItem -Path $hermesPath -Filter *.html -Recurse | Where-Object {
    if ($_.FullName.StartsWith($apaPath)) { return $false }
    if ($_.FullName -eq "C:\xampp\htdocs\2026\Hermes\APA\index.html") { return $false }

    $name = $_.Name.ToLower()
    $match = $false
    foreach ($kw in $keywords) {
        if ($name -match [regex]::Escape($kw.ToLower())) {
            $match = $true
            break
        }
    }
    $match
}

$fileList = @()
foreach ($file in $files) {
    $relPath = $file.FullName.Substring($hermesPath.Length + 1)
    $destFile = Join-Path $apaPath $relPath
    $destDir = Split-Path $destFile -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # -------------------------------------------------------------
    # DINAMIKUS KÉP FELDERÍTÉS ÉS MÁSOLÁS (Intelligens útvonal-javítás)
    # -------------------------------------------------------------
    $content = [regex]::Replace($content, '(?i)(?:src|href)="([^"]+)"', {
        param($m)
        $val = $m.Groups[1].Value
        $attr = $m.Value.Substring(0, $m.Value.IndexOf('='))
        
        # 1. Ha a link hardkódolt localhost-os (előző script miatt)
        if ($val -match "^http://localhost/2026/Hermes/(.*)") {
            $val = $matches[1]
            $sourceItem = Join-Path $hermesPath $val
        } 
        # 2. Ha relatív link (nem webes, nem data)
        elseif ($val -notmatch "^http" -and $val -notmatch "^data:" -and $val -notmatch "^#") {
            try {
                $sourceItem = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($file.DirectoryName, $val.Replace('/','\')))
            } catch {
                return $m.Value
            }
        } 
        # 3. Egyéb esetek (pl. külső linkek)
        else {
            return $m.Value
        }
        
        $sourceItemClean = $sourceItem -replace '\?.*$', ''
        
        # Ha létezik a kép a lemezen
        if (Test-Path $sourceItemClean -PathType Leaf) {
            if ($sourceItemClean.StartsWith($hermesPath)) {
                $itemRelPath = $sourceItemClean.Substring($hermesPath.Length + 1)
                $itemDest = Join-Path $apaPath $itemRelPath
                $itemDestDir = Split-Path $itemDest -Parent
                
                if (-not (Test-Path $itemDestDir)) {
                    New-Item -ItemType Directory -Path $itemDestDir -Force | Out-Null
                }
                
                # Átmásoljuk a képet a GitHub-os mappába!
                Copy-Item -Path $sourceItemClean -Destination $itemDest -Force
                
                # Kiszámoljuk az új relatív útvonalat a HTML fájlból a képhez
                $newRelUrl = $itemRelPath.Replace('\','/')
                $depth = ($relPath -split '\\').Count - 1
                $backPath = ""
                for ($i = 0; $i -lt $depth; $i++) { $backPath += "../" }
                
                $finalUrl = $backPath + $newRelUrl
                
                if ($sourceItem -match '(\?.*)$') {
                    $finalUrl += $matches[1]
                }
                
                return "$attr=`"$finalUrl`""
            }
        }
        
        return $m.Value
    })
    
    # -------------------------------------------------------------
    # JS STRING JAVÍTÁS (Közvetlen apa_festmenyek/ hivatkozások JS kódokban)
    # -------------------------------------------------------------
    $depth = ($relPath -split '\\').Count - 1
    $backPath = ""
    for ($i = 0; $i -lt $depth; $i++) { $backPath += "../" }
    
    $content = $content -replace '(?i)(?<=["''`])apa_festmenyek/', "${backPath}apa_festmenyek/"
    
    # HTML fájl elmentése az új linkekkel
    Set-Content -Path $destFile -Value $content -Encoding UTF8
    
    # Lista építése
    $htmlRelPath = "Eredmenyek/" + $relPath.Replace('\', '/')
    $fileList += $htmlRelPath
}

if ($fileList) {
    $fileList | ConvertTo-Json | Set-Content files.json -Encoding UTF8
} else {
    '[]' | Set-Content files.json -Encoding UTF8
}
