# 화면 조작 도구. Effect House GUI를 무인으로 다루기 위해 쓴다.
#   shot  : 화면(또는 L,T,W,H 영역) 캡처 -> -Out 경로(기본: loop/shots/)
#   click : X,Y 좌클릭 (VirtualScreen 좌표, 원점이 음수일 수 있음)
#   dclick: 더블클릭
#   keys  : SendKeys 문자열 전송 (예: "^s" = Ctrl+S)
#   idle  : 마지막 키보드/마우스 입력 후 경과 초
#   focus : -Text 로 준 프로세스 이름의 주 창을 앞으로
param([string]$Action = 'shot', [int]$X = 0, [int]$Y = 0, [string]$Text = '', [string]$Out = '', [int]$L = 0, [int]$T = 0, [int]$W = 0, [int]$H = 0)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class U {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [StructLayout(LayoutKind.Sequential)] public struct LII { public uint cbSize; public uint dwTime; }
  [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LII p);
}
"@
[U]::SetProcessDPIAware() | Out-Null
$shots = Join-Path (Split-Path (Split-Path $MyInvocation.MyCommand.Path)) 'shots'
function Click([int]$cx, [int]$cy) { [U]::SetCursorPos($cx, $cy) | Out-Null; Start-Sleep -Milliseconds 150; [U]::mouse_event(2,0,0,0,[UIntPtr]::Zero); Start-Sleep -Milliseconds 60; [U]::mouse_event(4,0,0,0,[UIntPtr]::Zero) }
switch ($Action) {
  'shot' {
    New-Item -ItemType Directory -Force $shots | Out-Null
    if (-not $Out) { $Out = (Get-Date -Format 'yyyyMMdd-HHmmss') + '.png' }
    if (-not [System.IO.Path]::IsPathRooted($Out)) { $Out = Join-Path $shots $Out }
    $vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
    if ($W -eq 0) { $L = $vs.Left; $T = $vs.Top; $W = $vs.Width; $H = $vs.Height }
    $bmp = New-Object System.Drawing.Bitmap $W, $H
    [System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($L, $T, 0, 0, $bmp.Size)
    $bmp.Save($Out)
    "saved $Out origin=($L,$T) size=${W}x$H"
  }
  'click'  { Click $X $Y; "clicked $X,$Y" }
  'dclick' { Click $X $Y; Start-Sleep -Milliseconds 80; Click $X $Y; "dclicked $X,$Y" }
  'keys'   { [System.Windows.Forms.SendKeys]::SendWait($Text); "sent $Text" }
  'idle'   { $i = New-Object U+LII; $i.cbSize = 8; [U]::GetLastInputInfo([ref]$i) | Out-Null; [int](([Environment]::TickCount - $i.dwTime) / 1000) }
  'focus'  {
    $p = Get-Process -Name $Text -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0 | Select-Object -First 1
    if (-not $p) { "no window: $Text"; exit 1 }
    [U]::ShowWindow($p.MainWindowHandle, 9) | Out-Null; [U]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; "focused $Text"
  }
}
