# Flutter SDK Kurulum Script'i
# Windows PowerShell için

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Flutter SDK Kurulum Başlatılıyor..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Flutter SDK'nın kurulacağı dizin (genellikle C:\src\flutter)
$flutterDir = "C:\src\flutter"
$flutterZip = "$env:TEMP\flutter_windows.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip"

# Git kontrolü
Write-Host "[1/5] Git kontrol ediliyor..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "Git bulundu: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "HATA: Git kurulu değil!" -ForegroundColor Red
    Write-Host "Lütfen önce Git'i kurun: https://git-scm.com/download/win" -ForegroundColor Red
    Write-Host ""
    Write-Host "Git kurulumundan sonra bu script'i tekrar çalıştırın." -ForegroundColor Yellow
    pause
    exit 1
}

# Flutter dizinini oluştur
Write-Host "[2/5] Flutter dizini oluşturuluyor..." -ForegroundColor Yellow
if (-not (Test-Path "C:\src")) {
    New-Item -ItemType Directory -Path "C:\src" -Force | Out-Null
}

# Flutter zaten kurulu mu?
if (Test-Path $flutterDir) {
    Write-Host "UYARI: Flutter zaten $flutterDir dizininde kurulu görünüyor." -ForegroundColor Yellow
    $response = Read-Host "Devam etmek istiyor musunuz? (E/H)"
    if ($response -ne "E" -and $response -ne "e") {
        Write-Host "Kurulum iptal edildi." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item -Path $flutterDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Flutter SDK'yı indir
Write-Host "[3/5] Flutter SDK indiriliyor (bu biraz zaman alabilir)..." -ForegroundColor Yellow
Write-Host "İndirme URL: $flutterUrl" -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    Write-Host "İndirme tamamlandı!" -ForegroundColor Green
} catch {
    Write-Host "HATA: İndirme başarısız!" -ForegroundColor Red
    Write-Host "Hata mesajı: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternatif: Manuel olarak Flutter'ı şu adresten indirebilirsiniz:" -ForegroundColor Yellow
    Write-Host "https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Cyan
    pause
    exit 1
}

# ZIP'i çıkar
Write-Host "[4/5] Flutter SDK çıkarılıyor..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $flutterZip -DestinationPath "C:\src" -Force
    Write-Host "Çıkarma tamamlandı!" -ForegroundColor Green
    Remove-Item -Path $flutterZip -Force
} catch {
    Write-Host "HATA: ZIP çıkarma başarısız!" -ForegroundColor Red
    Write-Host "Hata mesajı: $_" -ForegroundColor Red
    pause
    exit 1
}

# PATH'e ekle
Write-Host "[5/5] PATH'e Flutter ekleniyor..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterDir\bin", "User")
    Write-Host "Flutter PATH'e eklendi!" -ForegroundColor Green
    Write-Host ""
    Write-Host "ÖNEMLİ: Yeni PATH ayarlarının aktif olması için PowerShell'i kapatıp tekrar açmanız gerekiyor!" -ForegroundColor Yellow
} else {
    Write-Host "Flutter zaten PATH'te mevcut." -ForegroundColor Green
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Kurulum Tamamlandı!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Sonraki adımlar:" -ForegroundColor Yellow
Write-Host "1. PowerShell'i kapatıp tekrar açın" -ForegroundColor White
Write-Host "2. 'flutter doctor' komutunu çalıştırın" -ForegroundColor White
Write-Host "3. Eksik bileşenleri kurun (Android Studio, VS Code, vs.)" -ForegroundColor White
Write-Host ""
Write-Host "Flutter Dokümantasyon: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Cyan
Write-Host ""

pause

