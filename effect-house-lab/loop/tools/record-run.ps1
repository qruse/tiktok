# Effect House 미리보기 패널의 녹화 버튼으로 한 판을 녹화해 저장한다. 앱 녹화본에는 소리가 없다.
# -Audio를 주면 PC 스피커 출력(WASAPI 루프백)을 함께 녹음해서, 박자를 맞춘 소리 있는 영상 <Out 이름>-sound.mp4(540px)도 만든다.
# MCP record_preview_video_mp4가 실패할 때(2026-10-03 확인) 쓰는 우회로다.
# 전제: Effect House가 오른쪽 모니터(원점 0,0)에 최대화되어 있고, 녹화 버튼이 (1284,594)에 있다. 창 배치가 바뀌면 좌표를 다시 찾는다.
#   record-run.ps1 -Video "preview_face_idle||3" -Out C:\Users\Public\EHTest\Projects\_src\run-idle3.mp4 [-Seconds 36] [-Audio]
param([string]$Video = '', [Parameter(Mandatory)][string]$Out, [int]$Seconds = 34, [int]$RecX = 1284, [int]$RecY = 594, [switch]$Audio)
$tools = Split-Path $MyInvocation.MyCommand.Path
$wav = [IO.Path]::ChangeExtension($Out, '.wav')
$rec = $null
if ($Audio) {
  # 녹음은 영상 교체·녹화 시작보다 먼저 시작하고 끝난 뒤까지 이어지게 넉넉히 잡는다. 맞추기는 mux-audio.py가 한다.
  $rec = Start-Process python -ArgumentList @("`"$tools\rec-loopback.py`"", "`"$wav`"", "$($Seconds + 16)") -PassThru -WindowStyle Hidden
  Start-Sleep 1
}
if ($Video) { & "$tools\eh-mcp.ps1" -Action call -Tool set_preview_video -ArgsJson ('{"video_name":"' + $Video + '"}') | Out-Null; Start-Sleep 4 }
& "$tools\scr.ps1" -Action focus -Text 'Effect House' | Out-Null
& "$tools\scr.ps1" -Action click -X $RecX -Y $RecY | Out-Null
Start-Sleep $Seconds
& "$tools\scr.ps1" -Action click -X $RecX -Y $RecY | Out-Null
Start-Sleep 4
# 저장 창: 파일 이름 칸에 전체 경로를 붙여넣는다(한글 입력기 때문에 직접 타이핑하지 않는다)
Set-Clipboard -Value $Out
& "$tools\scr.ps1" -Action keys -Text '^a' | Out-Null
& "$tools\scr.ps1" -Action keys -Text '^v' | Out-Null
Start-Sleep -Milliseconds 400
& "$tools\scr.ps1" -Action keys -Text '{ENTER}' | Out-Null
for ($i = 0; $i -lt 20 -and -not (Test-Path $Out); $i++) { Start-Sleep 1 }
if (Test-Path $Out) { "saved $Out $((Get-Item $Out).Length) bytes" } else { "NOT saved: $Out (저장 창 상태를 캡처해서 확인할 것)" }
if ($Audio) {
  if (-not $rec.WaitForExit(60000)) { $rec.Kill() }
  if ((Test-Path $Out) -and (Test-Path $wav)) {
    $sound = Join-Path (Split-Path $Out) (([IO.Path]::GetFileNameWithoutExtension($Out)) + '-sound.mp4')
    python "$tools\mux-audio.py" $Out $wav $sound
  } else { "NOT muxed: video or audio missing ($wav)" }
}
