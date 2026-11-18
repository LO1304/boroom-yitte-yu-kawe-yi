param(
    [ValidateSet("edge", "web-server", "android", "windows")]
    [string]$Target = "edge",
    [int]$Port = 8080,
    [string]$EnvFile = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$MobileDir = Join-Path $RepoRoot "mobile"

Push-Location $MobileDir
try {
    $argsList = @("run", "-d", $Target)
    if ($Target -eq "web-server" -or $Target -eq "edge") {
        $argsList += @("--web-port", "$Port")
    }
    if ($EnvFile -ne "" -and (Test-Path $EnvFile)) {
        $argsList += @("--dart-define-from-file=$EnvFile")
    } elseif (Test-Path (Join-Path $MobileDir "env.dev.json")) {
        $argsList += @("--dart-define-from-file=env.dev.json")
    }

    Write-Host "=== BOROOM YITTÉ YU KAWÉ YI — Live Preview ===" -ForegroundColor Green
    Write-Host "Command: flutter $($argsList -join ' ')" -ForegroundColor Cyan
    Write-Host "Hot Reload: press [r]   |   Hot Restart: press [R]   |   Quit: press [q]" -ForegroundColor Yellow

    & "C:\flutter\bin\flutter.bat" @argsList
} finally {
    Pop-Location
}
