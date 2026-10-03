# Turn a preview recording (mp4) into a sample GIF for the user's review page (loop/gallery).
# Output goes to loop/shots/gifs/ (gitignored). Shrinks automatically until the GIF is under -MaxMB.
param(
  [Parameter(Mandatory = $true)][string]$Video,
  [Parameter(Mandatory = $true)][string]$Name,      # e.g. blink-v1.1-scare  -> shots/gifs/blink-v1.1-scare.gif
  [double]$Start = 0,
  [double]$Duration = 0,                            # 0 = to the end
  [double]$MaxMB = 8
)
$ErrorActionPreference = 'Stop'
$loop = Split-Path (Split-Path $MyInvocation.MyCommand.Path)
$outDir = Join-Path $loop 'shots\gifs'
New-Item -ItemType Directory -Force $outDir | Out-Null
$out = Join-Path $outDir "$Name.gif"
$ff = Get-ChildItem "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0\LocalCache\local-packages\Python311\site-packages\imageio_ffmpeg\binaries\ffmpeg*.exe" | Select-Object -First 1 -ExpandProperty FullName
if (-not $ff) { throw 'ffmpeg not found (pip install --user imageio-ffmpeg)' }

$cut = @('-ss', "$Start")
if ($Duration -gt 0) { $cut += @('-t', "$Duration") }
foreach ($q in @(@{w = 320; fps = 12; c = 128 }, @{w = 288; fps = 10; c = 96 }, @{w = 240; fps = 10; c = 64 }, @{w = 216; fps = 8; c = 64 })) {
  $vf = "fps=$($q.fps),scale=$($q.w):-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=$($q.c):stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4"
  & $ff -hide_banner -loglevel error -y @cut -i $Video -vf $vf -loop 0 $out
  $mb = (Get-Item $out).Length / 1MB
  if ($mb -le $MaxMB) { break }
}
"{0} ({1:N1} MB, {2}px {3}fps)" -f $out, $mb, $q.w, $q.fps
