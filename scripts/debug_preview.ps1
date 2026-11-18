param(
    [ValidateSet("edge", "android", "web-server")]
    [string]$Target = "edge",
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$MobileDir = Join-Path $RepoRoot "mobile"

Push-Location $MobileDir
try {
    Write-Host "=== BOROOM YITTÉ YU KAWÉ YI — Debug Mode (DevTools + Verbose) ===" -ForegroundColor Cyan
    Write-Host "Astuces Debug Flutter :" -ForegroundColor Yellow
    Write-Host "  [r] Hot Reload (mise à jour UI instantanée avec conservation d'état)"
    Write-Host "  [R] Hot Restart (réinitialise l'état complet)"
    Write-Host "  [p] Grille de débogage / bordures de mise en page"
    Write-Host "  [v] Ouvrir Flutter DevTools dans le navigateur"
    Write-Host ""

    $argsList = @("run", "--debug", "-d", $Target)
    if ($Target -eq "edge" -or $Target -eq "web-server") {
        $argsList += @("--web-port", "$Port")
    }
    & "C:\flutter\bin\flutter.bat" @argsList
} finally {
    Pop-Location
}
