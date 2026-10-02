# 작업 스케줄러가 3시간마다 실행한다. 한 회차 = claude -p 한 번.
# 겹침 방지(lock), 시간 제한(150분), 실행 로그(loop/runs/)를 맡는다. 판단은 전부 LOOP.md에 있다.
$ErrorActionPreference = 'Stop'
$loop = Split-Path $MyInvocation.MyCommand.Path
$repo = Split-Path (Split-Path $loop)
$runs = Join-Path $loop 'runs'
$lock = Join-Path $loop '.lock'
New-Item -ItemType Directory -Force $runs | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$log = Join-Path $runs "$stamp.log"

if (Test-Path $lock) {
  $old = Get-Content $lock -ErrorAction SilentlyContinue
  if ($old -and (Get-Process -Id ([int]$old) -ErrorAction SilentlyContinue)) {
    "$(Get-Date -Format s) skip: previous tick (pid $old) still running" | Add-Content (Join-Path $runs 'skipped.log')
    exit 0
  }
}
$PID | Set-Content $lock

try {
  Set-Location $repo
  $now = Get-Date -Format 'yyyy-MM-dd HH:mm'
  $prompt = "Read effect-house-lab/loop/LOOP.md fully and execute exactly one loop tick as it instructs. Current local time: $now (Asia/Seoul). Write all records and notifications in Korean. Finish within about 130 minutes."
  $claude = "$env:USERPROFILE\.local\bin\claude.exe"
  $p = Start-Process -FilePath $claude -ArgumentList @('-p', "`"$prompt`"", '--output-format', 'text') `
        -WorkingDirectory $repo -NoNewWindow -PassThru `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
  if (-not $p.WaitForExit(150 * 60 * 1000)) {
    & taskkill /PID $p.Id /T /F | Out-Null
    "`n[run-tick] killed after 150 min timeout" | Add-Content $log
  }
  "`n[run-tick] exit=$($p.ExitCode) end=$(Get-Date -Format s)" | Add-Content $log
}
finally {
  Remove-Item $lock -ErrorAction SilentlyContinue
}
