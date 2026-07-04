$hermesPath = "C:\xampp\htdocs\2026\Hermes"
$apaPath = "C:\xampp\htdocs\2026\Hermes\APA\Eredmenyek"
$keywords = @("apa", "kárai mihály", "karai mihaly", "karai_mihaly", "kárai_mihály")

if (-not (Test-Path $apaPath)) {
    New-Item -ItemType Directory -Path $apaPath | Out-Null
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
    # Eredeti almappa struktúra lemásolása
    $relPath = $file.FullName.Substring($hermesPath.Length + 1)
    $destFile = Join-Path $apaPath $relPath
    $destDir = Split-Path $destFile -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $content = Get-Content -Path $file.FullName -Raw
    $relDir = (Split-Path $relPath -Parent).Replace('\', '/')
    $baseUrl = "http://localhost/2026/Hermes/"
    if ($relDir) { $baseUrl += $relDir + "/" }
    
    $content = [regex]::Replace($content, '(?i)\bsrc="([^"]+)"', {
        param($m)
        $val = $m.Groups[1].Value
        if ($val -match "^http" -or $val -match "^data:") {
            return $m.Value
        }
        return "src=`"$baseUrl$val`""
    })
    
    Set-Content -Path $destFile -Value $content -Encoding UTF8
    
    # Lista építése (HTML számára)
    $htmlRelPath = "Eredmenyek/" + $relPath.Replace('\', '/')
    $fileList += $htmlRelPath
}

if ($fileList) {
    $fileList | ConvertTo-Json | Set-Content files.json -Encoding UTF8
} else {
    '[]' | Set-Content files.json -Encoding UTF8
}
