# PowerShell Script to Localize All Screens
Write-Host "Starting automatic localization..." -ForegroundColor Cyan

$files = @(
    "lib\presentation\screens\auth\signup_screen.dart",
    "lib\presentation\screens\home\home_screen.dart",
    "lib\presentation\screens\dashboard\dashboard_screen.dart",
    "lib\presentation\screens\relatives\relatives_screen.dart"
)

$importLine = "import '../../../generated/l10n/app_localizations.dart';"

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing: $file" -ForegroundColor Yellow
        
        $content = Get-Content $file -Raw
        
        # Add import if not present
        if ($content -notlike "*app_localizations.dart*") {
            $content = $content -replace "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`n$importLine"
            Write-Host "  Added import" -ForegroundColor Green
        }
        
        # Replace AppStrings
        $content = $content -replace "AppStrings\.welcome", "l10n.welcome"
        $content = $content -replace "AppStrings\.login", "l10n.login"
        $content = $content -replace "AppStrings\.signup", "l10n.signup"
        $content = $content -replace "AppStrings\.email", "l10n.email"
        $content = $content -replace "AppStrings\.password", "l10n.password"
        $content = $content -replace "AppStrings\.settings", "l10n.settings"
        $content = $content -replace "AppStrings\.dashboard", "l10n.dashboard"
        $content = $content -replace "AppStrings\.relatives", "l10n.relatives"
        $content = $content -replace "AppStrings\.activity", "l10n.activity"
        
        Set-Content $file -Value $content -NoNewline
        Write-Host "  Updated" -ForegroundColor Green
    }
}

Write-Host "Done! Remember to add 'final l10n = AppLocalizations.of(context)!' in build methods" -ForegroundColor Cyan
