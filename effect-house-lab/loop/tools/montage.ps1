# 여러 이미지를 같은 높이로 가로로 이어 붙인다. 투명 PNG는 -Bg 색 위에 그린다.
#   montage.ps1 -Files a.png,b.jpg -Out c.jpg [-H 480] [-Bg 60,64,72]
param([string[]]$Files, [string]$Out, [int]$H = 480, [int[]]$Bg = @(60, 64, 72))
Add-Type -AssemblyName System.Drawing
$imgs = $Files | ForEach-Object { [System.Drawing.Image]::FromFile((Resolve-Path $_).Path) }
$ws = @($imgs | ForEach-Object { [int][Math]::Round($_.Width * $H / $_.Height) })
$total = 0; foreach ($w in $ws) { $total += $w + 10 }
$b = New-Object System.Drawing.Bitmap ([int]$total), ([int]$H)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.Clear([System.Drawing.Color]::FromArgb($Bg[0], $Bg[1], $Bg[2]))
$x = 0
for ($i = 0; $i -lt $imgs.Count; $i++) { $g.DrawImage($imgs[$i], $x, 0, $ws[$i], $H); $x += $ws[$i] + 10 }
$b.Save($Out, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$imgs | ForEach-Object { $_.Dispose() }; $g.Dispose(); $b.Dispose()
"saved $Out"