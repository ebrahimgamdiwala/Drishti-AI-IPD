# Complete Localization Script
# This script copies the complete English ARB file to replace the existing one

Write-Host "Starting complete localization update..." -ForegroundColor Green

# Backup existing files
Write-Host "Creating backups..." -ForegroundColor Yellow
Copy-Item "lib/l10n/app_en.arb" "lib/l10n/app_en.arb.backup" -Force

# Replace English ARB with complete version
Write-Host "Updating English ARB file..." -ForegroundColor Yellow
Copy-Item "lib/l10n/app_en_complete.arb" "lib/l10n/app_en.arb" -Force

Write-Host "Regenerating localization files..." -ForegroundColor Yellow
flutter gen-l10n

Write-Host "`nComplete! Now you need to:" -ForegroundColor Green
Write-Host "1. Translate the new strings in app_hi.arb, app_ta.arb, app_te.arb, app_bn.arb" -ForegroundColor Cyan
Write-Host "2. Update all screens to use l10n strings instead of hardcoded text" -ForegroundColor Cyan
Write-Host "3. Run 'flutter gen-l10n' again after translations" -ForegroundColor Cyan

Write-Host "`nBackup created at: lib/l10n/app_en.arb.backup" -ForegroundColor Yellow
