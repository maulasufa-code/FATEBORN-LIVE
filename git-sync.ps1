$ErrorActionPreference = "Stop"

Write-Host "=== FATEBORN Git Sync ==="

# Pastikan berada di repository
git rev-parse --is-inside-work-tree | Out-Null

# Jangan sync kalau ada perubahan lokal
$status = git status --porcelain

if ($status) {
    Write-Host ""
    Write-Host "STOP: Ada perubahan lokal yang belum di-commit."
    git status --short
    exit 1
}

Write-Host "Fetching GitHub..."
git fetch origin

Write-Host "Pulling fast-forward only..."
git pull --ff-only origin main

Write-Host "Pushing local commits..."
git push origin main

Write-Host ""
Write-Host "Git sync selesai."
git status