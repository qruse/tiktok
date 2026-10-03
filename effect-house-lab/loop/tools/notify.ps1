# Phone notification for loop ticks. Headless `claude -p` has no Remote Control,
# so PushNotification never reaches the phone. This sends through ntfy.sh instead.
# Config: loop/notify.json {"ntfy_topic": "..."} (gitignored; the topic acts as a password).
# Every call is also appended to loop/runs/notify.log so the message is never lost.
param(
  [Parameter(Mandatory = $true)][string]$Message,
  [string]$Title = 'Effect loop',
  [ValidateSet('min', 'low', 'default', 'high', 'urgent')][string]$Priority = 'default'
)
$ErrorActionPreference = 'Stop'
$loop = Split-Path (Split-Path $MyInvocation.MyCommand.Path)
$runs = Join-Path $loop 'runs'
New-Item -ItemType Directory -Force $runs | Out-Null
$logFile = Join-Path $runs 'notify.log'
$cfgFile = Join-Path $loop 'notify.json'

function Write-NotifyLog([string]$status) {
  $line = "$(Get-Date -Format s) [$status] $Title | $Message"
  [IO.File]::AppendAllText($logFile, $line + "`r`n", (New-Object Text.UTF8Encoding $false))
}

if (-not (Test-Path $cfgFile)) { Write-NotifyLog 'not-configured'; 'not sent: loop/notify.json missing'; exit 0 }
$cfg = [IO.File]::ReadAllText($cfgFile, [Text.Encoding]::UTF8) | ConvertFrom-Json
if (-not $cfg.ntfy_topic) { Write-NotifyLog 'not-configured'; 'not sent: ntfy_topic empty'; exit 0 }

$prio = @{ min = 1; low = 2; default = 3; high = 4; urgent = 5 }[$Priority]
$body = @{ topic = $cfg.ntfy_topic; title = $Title; message = $Message; priority = $prio } | ConvertTo-Json -Compress
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
for ($i = 0; $i -lt 3; $i++) {
  try {
    Invoke-RestMethod -Method Post -Uri 'https://ntfy.sh/' -ContentType 'application/json; charset=utf-8' `
      -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 20 | Out-Null
    Write-NotifyLog 'sent'; 'sent'; exit 0
  } catch { Start-Sleep -Seconds (2 * ($i + 1)) }
}
Write-NotifyLog 'failed'; 'not sent: ntfy.sh unreachable'; exit 0
