# Effect House 내장 자동화 서버(MCP "tteh") 호출 도구.
# Effect House가 켜져 있을 때 127.0.0.1:<포트>/mcp 로 열린다. 포트는 실행마다 바뀔 수 있어 자동으로 찾는다.
#   list           : 도구 목록(이름과 설명 첫 줄)
#   schema -Tool x : 도구 x의 입력 스키마
#   call -Tool x -ArgsJson '{...}' (또는 -ArgsFile 경로) : 도구 실행, 결과 텍스트 출력
param([string]$Action = 'list', [string]$Tool = '', [string]$ArgsJson = '{}', [string]$ArgsFile = '', [int]$Port = 0, [int]$Timeout = 120)
$ErrorActionPreference = 'Stop'
function Find-Port {
  $ids = (Get-Process -Name 'Effect House' -ErrorAction SilentlyContinue).Id
  $ports = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $ids -contains $_.OwningProcess -and $_.LocalAddress -eq '127.0.0.1' } | Select-Object -ExpandProperty LocalPort
  foreach ($p in $ports) {
    try { $r = Rpc $p 'tools/list' @{} 3; if ($r) { return $p } } catch {}
  }
  throw 'tteh MCP 포트를 찾지 못했다'
}
function Rpc([int]$p, [string]$method, $params, [int]$to) {
  $body = @{ jsonrpc = '2.0'; id = 1; method = $method; params = $params } | ConvertTo-Json -Depth 50 -Compress
  $bytes = [Text.Encoding]::UTF8.GetBytes($body)
  $r = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$p/mcp" -Method Post -Body $bytes -ContentType 'application/json; charset=utf-8' -Headers @{ Accept = 'application/json, text/event-stream' } -TimeoutSec $to
  $text = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  $line = ($text -split "`n" | Where-Object { $_ -like 'data:*' } | Select-Object -Last 1)
  if (-not $line) { $line = $text } else { $line = $line.Substring(5) }
  return ($line | ConvertFrom-Json)
}
if ($Port -eq 0) { $Port = Find-Port }
switch ($Action) {
  'list' {
    $r = Rpc $Port 'tools/list' @{} 30
    foreach ($t in $r.result.tools) { $d = ($t.description -split "`n")[0]; if ($d.Length -gt 140) { $d = $d.Substring(0, 140) }; "$($t.name) :: $d" }
  }
  'schema' {
    $r = Rpc $Port 'tools/list' @{} 30
    $t = $r.result.tools | Where-Object name -eq $Tool
    $t.description; $t.inputSchema | ConvertTo-Json -Depth 30
  }
  'call' {
    if ($ArgsFile) { $ArgsJson = [IO.File]::ReadAllText($ArgsFile) }
    $a = $ArgsJson | ConvertFrom-Json
    $r = Rpc $Port 'tools/call' @{ name = $Tool; arguments = $a } $Timeout
    if ($r.error) { 'ERROR: ' + ($r.error | ConvertTo-Json -Depth 10) }
    $shots = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) 'shots'; $k = 0
    foreach ($c in $r.result.content) {
      if ($c.type -eq 'text') { $c.text }
      elseif ($c.type -eq 'image') { $k++; $ext = if ($c.mimeType -like '*png') { 'png' } else { 'jpg' }; $o = Join-Path $shots ("mcp-" + (Get-Date -Format 'HHmmss') + "-$k.$ext"); [IO.File]::WriteAllBytes($o, [Convert]::FromBase64String($c.data)); "[image saved: $o]" }
      else { "[$($c.type)]" }
    }
    if ($r.result.isError) { 'isError=true' }
  }
}
