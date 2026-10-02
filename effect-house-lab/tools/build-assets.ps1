param([string]$Effect = '01-career-2027')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root "effects/$Effect"
$data = Get-Content -LiteralPath (Join-Path $dir 'content.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$out = Join-Path $dir 'assets'
New-Item -ItemType Directory -Force -Path (Join-Path $out 'answers') | Out-Null
function Brush([string]$hex) { return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex)) }
function Round($g,$b,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r) {
 $p=[System.Drawing.Drawing2D.GraphicsPath]::new()
 $d=2*$r
 $p.AddArc($x,$y,$d,$d,180,90); $p.AddArc($x+$w-$d,$y,$d,$d,270,90)
 $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90); $p.AddArc($x,$y+$h-$d,$d,$d,90,90)
 $p.CloseFigure(); $g.FillPath($b,$p); $p.Dispose()
}
function Text($g,[string]$s,[float]$size,[float]$y,$b,[bool]$bold=$false) {
 $style=[System.Drawing.FontStyle]::Regular
 if($bold){$style=[System.Drawing.FontStyle]::Bold}
 $f=[System.Drawing.Font]::new('Malgun Gothic',$size,$style,[System.Drawing.GraphicsUnit]::Pixel)
 $fmt=[System.Drawing.StringFormat]::new(); $fmt.Alignment=[System.Drawing.StringAlignment]::Center
 $g.DrawString($s,$f,$b,[System.Drawing.RectangleF]::new(26,$y,716,150),$fmt)
 $fmt.Dispose(); $f.Dispose()
}
function Symbol($g,[string]$kind,$ink) {
 $p=[System.Drawing.Pen]::new($ink.Color,7); $p.StartCap='Round'; $p.EndCap='Round'; $p.LineJoin='Round'
 switch($kind) {
  robot { Round $g $ink 341 47 86 62 13; $g.DrawLine($p,384,34,384,47); $g.FillEllipse($ink,378,25,12,12); $white=Brush '#FFFFFF'; $g.FillEllipse($white,358,67,12,12); $g.FillEllipse($white,398,67,12,12); $white.Dispose() }
  building { Round $g $ink 351 29 66 88 6; $white=Brush '#FFFFFF'; foreach($x in 364,391){foreach($y in 43,65,87){$g.FillRectangle($white,$x,$y,12,12)}}; $white.Dispose() }
  game { Round $g $ink 329 48 110 59 20; $white=Brush '#FFFFFF'; $g.FillRectangle($white,348,65,27,8); $g.FillRectangle($white,358,55,8,28); $g.FillEllipse($white,398,64,11,11); $g.FillEllipse($white,415,80,11,11); $white.Dispose() }
  sun { $g.DrawEllipse($p,357,44,54,54); foreach($a in 0,45,90,135,180,225,270,315){$rad=$a*[Math]::PI/180; $g.DrawLine($p,[float](384+40*[Math]::Cos($rad)),[float](71+40*[Math]::Sin($rad)),[float](384+51*[Math]::Cos($rad)),[float](71+51*[Math]::Sin($rad)))} }
  planet { $g.FillEllipse($ink,352,39,64,64); $g.DrawEllipse($p,323,60,123,30) }
  cup { Round $g $ink 345 48 65 58 10; $g.DrawArc($p,393,50,39,37,270,180); $g.DrawLine($p,336,116,431,116); $g.DrawLine($p,366,27,366,36); $g.DrawLine($p,390,27,390,36) }
  plant { $g.DrawLine($p,384,109,384,47); $g.FillEllipse($ink,342,39,42,26); $g.FillEllipse($ink,385,57,42,26); $g.DrawLine($p,350,114,418,114) }
  cat { $g.FillPolygon($ink,[System.Drawing.Point[]]@([System.Drawing.Point]::new(343,43),[System.Drawing.Point]::new(345,14),[System.Drawing.Point]::new(369,38))); $g.FillPolygon($ink,[System.Drawing.Point[]]@([System.Drawing.Point]::new(399,38),[System.Drawing.Point]::new(423,14),[System.Drawing.Point]::new(425,43))); $g.FillEllipse($ink,340,32,88,76); $white=Brush '#FFFFFF'; $g.FillEllipse($white,357,56,11,15); $g.FillEllipse($white,400,56,11,15); $white.Dispose() }
 }
 $p.Dispose()
}
function Card([string]$path,[string]$label,[string]$caption,[string]$color,[string]$symbol,[bool]$isTitle=$false) {
 $bm=[System.Drawing.Bitmap]::new(768,384,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[System.Drawing.Graphics]::FromImage($bm); $g.Clear([System.Drawing.Color]::Transparent)
 $g.SmoothingMode='AntiAlias'; $g.TextRenderingHint='AntiAliasGridFit'
 $ink=Brush '#171D2C'; $bg=Brush $color; $muted=Brush '#465063'
 Round $g $ink 8 12 752 364 32; Round $g $bg 8 4 752 356 32
 if($isTitle){ Text $g 'FUTURE DRAW' 21 37 $muted $true; Text $g '2027' 105 76 $ink $true; Text $g '내 직업은?' 55 203 $ink $true; Text $g $caption 25 291 $muted }
 else { Symbol $g $symbol $ink; Text $g $label 64 128 $ink $true; Text $g $caption 29 222 $muted; Text $g $data.disclaimer 19 302 $muted }
 $bm.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$bm.Dispose();$ink.Dispose();$bg.Dispose();$muted.Dispose()
}
Card (Join-Path $out 'title.png') $data.title $data.subtitle '#FFF9EF' '' $true
$i=0
foreach($r in $data.results){$i++; Card (Join-Path $out ('answers/{0:D2}.png' -f $i)) $r.label $r.caption $r.color $r.symbol}
# Icon source respects 162x162 canvas / central 144x144 safe area.
$bm=[System.Drawing.Bitmap]::new(162,162);$g=[System.Drawing.Graphics]::FromImage($bm);$g.Clear([System.Drawing.Color]::Transparent);$g.SmoothingMode='AntiAlias';$g.TextRenderingHint='AntiAliasGridFit'
$ink=Brush '#171D2C';$cream=Brush '#FFF1B9';Round $g $cream 9 9 144 144 25
$f=[System.Drawing.Font]::new('Malgun Gothic',76,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('?',$f,$ink,52,25);$g.FillEllipse($ink,31,115,12,12);$g.FillEllipse($ink,75,115,12,12);$g.FillEllipse($ink,119,115,12,12)
$bm.Save((Join-Path $out 'icon-162.png'),[System.Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$bm.Dispose();$f.Dispose();$ink.Dispose();$cream.Dispose()
# Contact sheet for visual QA; not imported into Effect House.
$sheet=[System.Drawing.Bitmap]::new(1152,576);$g=[System.Drawing.Graphics]::FromImage($sheet);$g.Clear([System.Drawing.ColorTranslator]::FromHtml('#E6E8EC'))
$files=@((Join-Path $out 'title.png'))+@(Get-ChildItem (Join-Path $out 'answers') -Filter '*.png' | Sort-Object Name | ForEach-Object {$_.FullName})
for($j=0;$j -lt $files.Count;$j++){$im=[System.Drawing.Image]::FromFile($files[$j]);$g.DrawImage($im,[int](($j%3)*384),[int]([Math]::Floor($j/3)*192),384,192);$im.Dispose()}
$sheet.Save((Join-Path $dir 'contact-sheet.png'),[System.Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$sheet.Dispose()
Get-ChildItem -LiteralPath $out -Recurse -File | Select-Object Name,Length | ConvertTo-Json
