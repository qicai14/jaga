<#
Runs the web Demo Bank on http://localhost:5000 against Jaga on Fly, with the pause token from the repo-root .env.
  powershell -ExecutionPolicy Bypass -File app\tool\run_demo_bank.ps1 [-SyncFly]
-SyncFly first copies JAGA_PAUSE_TOKEN from .env to the Fly app (this restarts the machine).
Never prints the pause token.
#>
param(
  [switch]$SyncFly,
  [string]$ServerUrl = 'https://jaga-server.fly.dev',
  [string]$FlyApp = 'jaga-server',
  [string]$EnvFile = (Join-Path $PSScriptRoot '..\..\.env')
)
$ErrorActionPreference = 'Stop'

# Read it like dotenv: last line wins, split on the first '=' only, drop quotes or an unquoted ' # comment'.
$line = Get-Content -LiteralPath $EnvFile -Encoding UTF8 |
  Where-Object { $_ -match '^\s*JAGA_PAUSE_TOKEN\s*=' } | Select-Object -Last 1
if (-not $line) { throw "JAGA_PAUSE_TOKEN is missing from $EnvFile" }
$value = $line.Substring($line.IndexOf('=') + 1).Trim()
if ($value -match '^"(.*)"' -or $value -match "^'(.*)'") { $token = $Matches[1] }
else { $token = ($value -replace '\s+#.*$', '').Trim() }
if (-not $token) { throw "JAGA_PAUSE_TOKEN is empty in $EnvFile" }

if ($SyncFly) {
  Write-Host "Setting JAGA_PAUSE_TOKEN on Fly app $FlyApp ..."
  & fly secrets set -a $FlyApp "JAGA_PAUSE_TOKEN=$token" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "fly secrets set failed (exit $LASTEXITCODE)" }
}

# One real ask, so a wrong token fails here and not on camera. Retries cover a machine that is restarting.
$body = @{ pauseToken = $token } | ConvertTo-Json -Compress
$answer = $null
foreach ($try in 1..6) {
  try {
    $answer = Invoke-RestMethod -Method Post -Uri "$ServerUrl/pause" -ContentType 'application/json' -Body $body
    break
  } catch {
    $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    if ($code -eq 404) {
      throw "$ServerUrl does not accept the JAGA_PAUSE_TOKEN in $EnvFile (404). Run again with -SyncFly."
    }
    if ($try -eq 6) { throw "Could not reach $ServerUrl/pause: $($_.Exception.Message)" }
    Start-Sleep -Seconds 5
  }
}
if ($answer.inScam) {
  Write-Warning "Jaga Pause says inScam (stage $($answer.stage)), so transfers will be held."
} else {
  Write-Host "Jaga Pause accepts the token (inScam false)."
}

# A define file keeps the token off the command line, away from PowerShell and .bat quoting.
$defines = Join-Path ([IO.Path]::GetTempPath()) "jaga-demo-bank-$PID.json"
$json = @{ JAGA_SERVER_URL = $ServerUrl; JAGA_PAUSE_TOKEN = $token } | ConvertTo-Json
[IO.File]::WriteAllText($defines, $json)  # UTF-8 without a BOM
Push-Location (Join-Path $PSScriptRoot '..')
try {
  & fvm flutter run -d web-server --web-port 5000 -t lib/main_demo_bank.dart "--dart-define-from-file=$defines"
} finally {
  Pop-Location
  Remove-Item -LiteralPath $defines -ErrorAction SilentlyContinue
}
