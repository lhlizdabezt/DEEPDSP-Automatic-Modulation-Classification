param(
    [switch]$Headless
)

$ErrorActionPreference = "Stop"

$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvRoot = Join-Path $appRoot ".venv"
$venvPython = Join-Path $venvRoot "Scripts\python.exe"
$requirementsPath = Join-Path $appRoot "requirements.txt"
$markerPath = Join-Path $venvRoot ".requirements.sha256"

Set-Location -LiteralPath $appRoot

function Assert-LastExitCode([string]$Step) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Step failed with exit code $LASTEXITCODE."
    }
}

Write-Host ""
Write-Host "DEEPDSP-AMC | DSP/ML Workbench" -ForegroundColor Cyan
Write-Host "Isolated runtime: $venvRoot"

if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Host "[1/3] Creating the isolated Python environment (.venv)..." -ForegroundColor Yellow
    $pyLauncher = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($null -ne $pyLauncher) {
        & $pyLauncher.Source -3.14 -m venv $venvRoot
        Assert-LastExitCode "Create .venv with Python 3.14"
    } else {
        $pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
        if ($null -eq $pythonCommand) {
            throw "Python was not found. Install Python 3.14 x64 and try again."
        }
        & $pythonCommand.Source -m venv $venvRoot
        Assert-LastExitCode "Create .venv"
    }
}

$requirementsHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $requirementsPath).Hash
$installedHash = if (Test-Path -LiteralPath $markerPath) {
    (Get-Content -Raw -LiteralPath $markerPath).Trim()
} else {
    ""
}

if ($installedHash -ne $requirementsHash) {
    Write-Host "[2/3] Installing the compatible dependency set..." -ForegroundColor Yellow
    & $venvPython -m pip install --disable-pip-version-check --upgrade pip
    Assert-LastExitCode "Upgrade pip in .venv"
    & $venvPython -m pip install --disable-pip-version-check --requirement $requirementsPath
    Assert-LastExitCode "Install requirements.txt"
    [System.IO.File]::WriteAllText($markerPath, $requirementsHash)
} else {
    Write-Host "[2/3] Dependencies are ready." -ForegroundColor Green
}

& $venvPython -c "import click, joblib, numpy, pandas, plotly, scipy, sklearn, streamlit, torch; print('Dependency check: PASS | Streamlit', streamlit.__version__, '| pandas', pandas.__version__)"
Assert-LastExitCode "Dependency check"

Write-Host "[3/3] Opening the app at http://localhost:8501 ..." -ForegroundColor Green
Write-Host "Press Ctrl+C in this window to stop the app."
$headlessValue = if ($Headless) { "true" } else { "false" }
& $venvPython -m streamlit run (Join-Path $appRoot "app.py") --server.headless $headlessValue
Assert-LastExitCode "Run Streamlit"
