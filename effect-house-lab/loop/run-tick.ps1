# 작업 스케줄러가 3시간마다 실행한다. 한 회차 = claude -p 한 번.
# 겹침 방지(lock), 시간 제한, 실행 로그(loop/runs/), 실패 알림을 맡는다. 판단은 전부 LOOP.md에 있다.
$ErrorActionPreference = 'Stop'
$loop = Split-Path $MyInvocation.MyCommand.Path
$repo = Split-Path (Split-Path $loop)
$runs = Join-Path $loop 'runs'
$lock = Join-Path $loop '.lock'
$notify = Join-Path $loop 'tools\notify.ps1'
New-Item -ItemType Directory -Force $runs | Out-Null
$start = Get-Date
$deadline = $start.AddMinutes(170)   # 스케줄러 제한(3시간)보다 먼저 끝낸다

function Send-Notify([string]$msg, [string]$prio = 'default') {
  try { & $notify -Message $msg -Priority $prio | Out-Null } catch {}
}

# 잠금: 살아 있는 PID이고 170분 이내에 만든 잠금일 때만 건너뛴다(PID 재사용·잠금 잔존 대비)
if (Test-Path $lock) {
  $old = Get-Content $lock -ErrorAction SilentlyContinue | Select-Object -First 1
  $age = ($start - (Get-Item $lock).LastWriteTime).TotalMinutes
  if ($old -and $age -lt 170 -and (Get-Process -Id ([int]$old) -ErrorAction SilentlyContinue)) {
    "$(Get-Date -Format s) skip: previous tick (pid $old, $([int]$age) min) still running" | Add-Content (Join-Path $runs 'skipped.log')
    exit 0
  }
}
$PID | Set-Content $lock

function Invoke-Tick([string]$log, [int]$minutes) {
  $now = Get-Date -Format 'yyyy-MM-dd HH:mm'
  $budget = [Math]::Max(20, $minutes - 20)
  $prompt = "Read effect-house-lab/loop/LOOP.md fully and execute exactly one loop tick as it instructs. Current local time: $now (Asia/Seoul). Write all records and notifications in Korean. Finish within about $budget minutes."
  $claude = "$env:USERPROFILE\.local\bin\claude.exe"
  $p = Start-Process -FilePath $claude -ArgumentList @('-p', "`"$prompt`"", '--output-format', 'text') `
        -WorkingDirectory $repo -NoNewWindow -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
  $null = $p.Handle   # 이 줄이 없으면 PowerShell 5.1에서 ExitCode가 비어 있다
  $timedOut = $false
  if (-not $p.WaitForExit($minutes * 60 * 1000)) {
    & taskkill /PID $p.Id /T /F | Out-Null
    $timedOut = $true
    "`n[run-tick] killed after $minutes min timeout" | Add-Content $log
  }
  $code = $p.ExitCode
  "`n[run-tick] exit=$code end=$(Get-Date -Format s)" | Add-Content $log
  $text = (Get-Content $log -Raw -Encoding UTF8)
  return @{ TimedOut = $timedOut; Code = $code; Text = $text }
}

try {
  Set-Location $repo
  $log = Join-Path $runs "$($start.ToString('yyyyMMdd-HHmm')).log"
  $r = Invoke-Tick $log 150

  # 사용량 한도로 끊겼고 25분 안에 풀리면 기다렸다가 한 번 더 돈다(회차 2는 13분 뒤 풀리는데 3시간을 날렸다)
  $m = [regex]::Match("$($r.Text)", "hit your .*?limit.*?resets\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?", 'IgnoreCase')
  if ($m.Success) {
    $h = [int]$m.Groups[1].Value; $mi = 0; if ($m.Groups[2].Success) { $mi = [int]$m.Groups[2].Value }
    $ap = $m.Groups[3].Value.ToLower()
    if ($ap -eq 'pm' -and $h -lt 12) { $h += 12 }; if ($ap -eq 'am' -and $h -eq 12) { $h = 0 }
    $reset = (Get-Date).Date.AddHours($h).AddMinutes($mi)
    if ($reset -lt (Get-Date).AddMinutes(-5)) { $reset = $reset.AddDays(1) }
    $wait = ($reset.AddMinutes(2) - (Get-Date)).TotalMinutes
    if ($wait -le 25) {
      if ($wait -gt 0) { Start-Sleep -Seconds ([int]($wait * 60)) }
      $left = [int]($deadline - (Get-Date)).TotalMinutes
      $log = Join-Path $runs "$((Get-Date).ToString('yyyyMMdd-HHmm'))-retry.log"
      $r = Invoke-Tick $log $left
    } else {
      Send-Notify "루프 회차를 건너뜀: Claude 사용량 한도($($reset.ToString('HH:mm'))에 풀림). 다음 회차에 이어서 합니다." 'low'
    }
  }
  if ($r.TimedOut) {
    Send-Notify "루프 회차가 시간 제한으로 강제 종료됨. 다음 회차가 WORKING.md에서 이어갑니다." 'default'
  } elseif ($r.Code -ne 0 -and -not ([regex]::IsMatch("$($r.Text)", 'hit your .*?limit', 'IgnoreCase'))) {
    Send-Notify "루프 회차가 오류로 끝남(exit $($r.Code)). 로그: loop/runs/$(Split-Path $log -Leaf)" 'high'
  }
}
catch {
  "$(Get-Date -Format s) run-tick error: $_" | Add-Content (Join-Path $runs 'run-tick-errors.log')
  Send-Notify "루프 실행 스크립트 오류: $($_.Exception.Message)" 'high'
}
finally {
  Remove-Item $lock -ErrorAction SilentlyContinue
}
