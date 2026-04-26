# nuna-llm-local installer (Windows)
# Usage:
#   irm https://raw.githubusercontent.com/chevp/nuna-llm-local/main/install.ps1 | iex
#   pwsh -File install.ps1 [-NoModels]
#
# Env overrides:
#   $env:NUNA_CHAT_MODEL   (default: mistral:7b-instruct-q4_K_M)
#   $env:NUNA_EMBED_MODEL  (default: nomic-embed-text)

param([switch]$NoModels)

$ErrorActionPreference = 'Stop'

$ChatModel  = if ($env:NUNA_CHAT_MODEL)  { $env:NUNA_CHAT_MODEL }  else { 'mistral:7b-instruct-q4_K_M' }
$EmbedModel = if ($env:NUNA_EMBED_MODEL) { $env:NUNA_EMBED_MODEL } else { 'nomic-embed-text' }

function Log  ($m) { Write-Host "▶ $m" -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "✓ $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "! $m" -ForegroundColor Yellow }

# 1. Install Ollama if missing
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    $ver = (ollama --version 2>&1 | Select-Object -First 1)
    Ok "Ollama already installed: $ver"
} else {
    Log "Downloading Ollama installer..."
    $installer = Join-Path $env:TEMP 'OllamaSetup.exe'
    Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $installer -UseBasicParsing
    Log "Running installer (silent)... If a UAC prompt appears, accept it."
    Start-Process -FilePath $installer -ArgumentList '/SILENT' -Wait
    # Refresh PATH for current session so 'ollama' is callable below
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path','User')
    Ok "Ollama installed"
}

# 2. Wait for API (Windows installer auto-starts the service)
Log "Waiting for API on localhost:11434..."
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    try {
        $null = Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 2
        $ready = $true
        break
    } catch { Start-Sleep -Seconds 1 }
}
if (-not $ready) {
    throw "API did not come up. Open Services console and check 'Ollama', or restart the machine."
}
Ok "API ready"

# 3. Pull default models
if ($NoModels) {
    Warn "Skipping model pull (-NoModels)"
} else {
    Log "Pulling chat model: $ChatModel"
    & ollama pull $ChatModel
    Log "Pulling embedding model: $EmbedModel"
    & ollama pull $EmbedModel
    Ok "Models ready: $ChatModel + $EmbedModel"
}

Ok "Done. Smoke test:"
$body = '{"model":"' + $ChatModel + '","prompt":"Hallo","stream":false}'
Write-Host "    Invoke-RestMethod http://localhost:11434/api/generate -Method Post -Body '$body'"
