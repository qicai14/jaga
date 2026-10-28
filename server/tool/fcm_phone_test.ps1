<#
.SYNOPSIS
Sends one real family alert through FcmPush (#54) to a phone running the app from PR #48.

.DESCRIPTION
Builds a debug APK from preston/firebase-push in a temporary git worktree (your checkout is untouched),
installs and launches it, reads the FCM token from logcat, then sends one alert with FcmPush.
GOOGLE_APPLICATION_CREDENTIALS is read from the repo-root .env at runtime. The token, the credentials
and .env are never printed.

You do by hand:
  1. Plug in the phone with USB debugging on (adb devices shows it as "device").
  2. When the app opens, finish co-pilot onboarding (link a person). A background alert is dropped
     without a linked person. Then press Enter in this window.
  3. Check the phone shows the family alert.

.PARAMETER BuildOnly
Build the APK and stop (no phone needed).

.EXAMPLE
powershell -ExecutionPolicy Bypass -File server\tool\fcm_phone_test.ps1
#>
param([switch]$BuildOnly)
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$branch = 'origin/preston/firebase-push'
$tree = Join-Path $env:TEMP 'jaga-fcm-phone-test'
$package = 'my.jaga.jaga'

function Run($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE)" } }

git -C $repo fetch -q origin preston/firebase-push; Run 'git fetch'
if (Test-Path $tree) { git -C $repo worktree remove --force $tree; Run 'git worktree remove' }
git -C $repo worktree add -q --detach $tree $branch; Run 'git worktree add'
try {
    Push-Location "$tree\app"
    try { fvm flutter build apk --debug; Run 'flutter build' } finally { Pop-Location }
    $apk = "$tree\app\build\app\outputs\flutter-apk\app-debug.apk"
    Write-Host "Built $apk"
    if ($BuildOnly) { return }

    if (-not ((adb devices) -match "`tdevice$")) { throw 'No phone found: plug it in with USB debugging on' }
    adb install -r $apk; Run 'adb install'
    adb logcat -c; Run 'adb logcat -c'
    adb shell monkey -p $package -c android.intent.category.LAUNCHER 1 | Out-Null; Run 'app launch'

    Write-Host 'Waiting for the FCM token (up to 90 s)...'
    $token = $null
    foreach ($i in 1..45) {
        $log = adb logcat -d -s flutter
        if ($log -match 'Jaga FCM token failed') { throw 'The app could not get an FCM token' }
        $line = $log | Select-String 'Jaga FCM token: (\S+)' | Select-Object -Last 1
        if ($line) { $token = $line.Matches[0].Groups[1].Value; break }
        Start-Sleep 2
    }
    if (-not $token) { throw 'No FCM token in logcat after 90 s' }
    Write-Host 'Got the FCM token.'

    $cred = Get-Content "$repo\.env" | Where-Object { $_ -match '^\s*GOOGLE_APPLICATION_CREDENTIALS\s*=' } |
        ForEach-Object { ($_ -split '=', 2)[1].Trim().Trim('"', "'") } | Select-Object -First 1
    if (-not $cred -or -not (Test-Path $cred)) { throw 'GOOGLE_APPLICATION_CREDENTIALS in .env is unset or the file is missing' }

    Read-Host 'Finish co-pilot onboarding on the phone, then press Enter to send the alert'
    $env:GOOGLE_APPLICATION_CREDENTIALS = $cred
    $env:JAGA_TEST_FCM_TOKEN = $token  # passed by env so it never appears in a command line or output
    $send = @'
import asyncio, os, sys
from jaga import alerts
from jaga.fcm import FcmPush
alert = alerts.build("alert", "phone-test", "money", "Caller: Pindahkan duit ke akaun selamat sekarang")
try:
    asyncio.run(FcmPush().send(os.environ["JAGA_TEST_FCM_TOKEN"], alert))
except Exception as e:
    sys.exit(f"Send failed ({type(e).__name__})")
'@
    Push-Location "$repo\server"
    try { uv run python -c $send } finally {
        Pop-Location
        Remove-Item Env:JAGA_TEST_FCM_TOKEN, Env:GOOGLE_APPLICATION_CREDENTIALS
    }
    if ($LASTEXITCODE -ne 0) { Write-Host 'FAILED: FCM did not accept the alert'; exit 1 }
    Write-Host 'SUCCESS: FCM accepted the alert. Check the phone shows it.'
} finally {
    git -C $repo worktree remove --force $tree
}
