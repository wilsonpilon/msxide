param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $testsRoot

$regressionScript = Join-Path $testsRoot "regression\run-regression.ps1"
$smokeScript = Join-Path $testsRoot "smoke\run-help-smoke.ps1"

if (-not (Test-Path -Path $regressionScript)) {
    throw "Script de regressao nao encontrado: $regressionScript"
}
if (-not (Test-Path -Path $smokeScript)) {
    throw "Script de smoke nao encontrado: $smokeScript"
}

Push-Location $repoRoot
try {
    Write-Host "[1/2] Executando regressao..." -ForegroundColor Cyan
    & $regressionScript
    if ($LASTEXITCODE -ne 0) {
        throw "Regressao falhou"
    }

    Write-Host "[2/2] Executando smoke de help..." -ForegroundColor Cyan
    & $smokeScript
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke de help falhou"
    }

    Write-Host "TESTES OK: regressao + smoke" -ForegroundColor Green
}
finally {
    Pop-Location
}
