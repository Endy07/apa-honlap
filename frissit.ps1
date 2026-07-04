$hermesPath = "C:\xampp\htdocs\2026\Hermes"
$keywords = @("apa", "kárai mihály", "karai mihaly", "karai_mihaly", "kárai_mihály")

$files = Get-ChildItem -Path $hermesPath -Filter *.html -Recurse | Where-Object {
    $name = $_.Name.ToLower()
    $match = $false
    foreach ($kw in $keywords) {
        if ($name -match [regex]::Escape($kw.ToLower())) {
            $match = $true
            break
        }
    }
    $match
} | ForEach-Object {
    # Relatív útvonal a Hermes mappától, + '../' mert az APA mappából nézzük
    "../" + $_.FullName.Substring($hermesPath.Length + 1).Replace('\', '/')
}

if ($files) {
    $files | ConvertTo-Json | Set-Content files.json -Encoding UTF8
} else {
    '[]' | Set-Content files.json -Encoding UTF8
}
