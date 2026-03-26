Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $root 'assets\images'

$width = 1600
$height = 900
$random = [System.Random]::new(190318)

function New-Canvas {
  param(
    [int]$Width,
    [int]$Height,
    [System.Drawing.Color]$BaseColor
  )

  $bitmap = [System.Drawing.Bitmap]::new($Width, $Height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $graphics.Clear($BaseColor)

  [PSCustomObject]@{
    Bitmap   = $bitmap
    Graphics = $graphics
  }
}

function Save-Canvas {
  param(
    [Parameter(Mandatory)]$Canvas,
    [Parameter(Mandatory)][string]$Name
  )

  $path = Join-Path $outputDir $Name
  $Canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $Canvas.Graphics.Dispose()
  $Canvas.Bitmap.Dispose()
}

function Fill-Gradient {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.RectangleF]$Rect,
    [System.Drawing.Color]$TopColor,
    [System.Drawing.Color]$BottomColor,
    [System.Drawing.Drawing2D.LinearGradientMode]$Mode = [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
  )

  $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new($Rect, $TopColor, $BottomColor, $Mode)
  $Graphics.FillRectangle($brush, $Rect)
  $brush.Dispose()
}

function Add-Vignette {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height,
    [int]$Steps = 12
  )

  for ($i = 0; $i -lt $Steps; $i++) {
    $alpha = [Math]::Min(150, 10 + ($i * 10))
    $inset = $i * 26
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb($alpha, 4, 6, 11), 28)
    $Graphics.DrawRectangle($pen, $inset, $inset, $Width - ($inset * 2), $Height - ($inset * 2))
    $pen.Dispose()
  }
}

function Add-FogBands {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height,
    [int]$Count = 8
  )

  for ($i = 0; $i -lt $Count; $i++) {
    $w = 480 + $random.Next(280)
    $h = 80 + $random.Next(60)
    $x = -120 + $random.Next($Width - 120)
    $y = [int]($Height * (0.42 + ($i * 0.06))) + $random.Next(40)
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18 + $random.Next(18), 205, 219, 224))
    $Graphics.FillEllipse($brush, $x, $y, $w, $h)
    $brush.Dispose()
  }
}

function Add-Rain {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height,
    [int]$Count = 340
  )

  for ($i = 0; $i -lt $Count; $i++) {
    $x = $random.Next($Width)
    $y = $random.Next($Height)
    $len = 18 + $random.Next(26)
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(18 + $random.Next(42), 200, 215, 230), 1)
    $Graphics.DrawLine($pen, $x, $y, $x - 12, $y + $len)
    $pen.Dispose()
  }
}

function Add-StarsOrDust {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height,
    [int]$Count = 200,
    [System.Drawing.Color]$Color = [System.Drawing.Color]::FromArgb(55, 215, 225, 232)
  )

  $brush = [System.Drawing.SolidBrush]::new($Color)
  for ($i = 0; $i -lt $Count; $i++) {
    $size = 1 + $random.Next(3)
    $x = $random.Next($Width)
    $y = $random.Next($Height)
    $Graphics.FillEllipse($brush, $x, $y, $size, $size)
  }
  $brush.Dispose()
}

function Add-Lightning {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$StartX,
    [int]$StartY,
    [int]$Segments = 9
  )

  $points = [System.Collections.Generic.List[System.Drawing.Point]]::new()
  $x = $StartX
  $y = $StartY
  $points.Add([System.Drawing.Point]::new($x, $y))

  for ($i = 0; $i -lt $Segments; $i++) {
    $x += $random.Next(-70, 40)
    $y += 50 + $random.Next(35)
    $points.Add([System.Drawing.Point]::new($x, $y))
  }

  $glow = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(90, 195, 225, 255), 16)
  $bolt = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(235, 242, 249, 255), 4)
  $Graphics.DrawLines($glow, $points.ToArray())
  $Graphics.DrawLines($bolt, $points.ToArray())
  $glow.Dispose()
  $bolt.Dispose()
}

function Add-Windows {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Rectangle[]]$Rects,
    [int]$Alpha = 150
  )

  foreach ($rect in $Rects) {
    $glowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb([Math]::Min(50, $Alpha), 255, 204, 111))
    $coreBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb($Alpha, 255, 214, 136))
    $Graphics.FillRectangle($glowBrush, $rect.X - 5, $rect.Y - 5, $rect.Width + 10, $rect.Height + 10)
    $Graphics.FillRectangle($coreBrush, $rect)
    $glowBrush.Dispose()
    $coreBrush.Dispose()
  }
}

function Draw-MansionSilhouette {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$BaseX,
    [int]$BaseY,
    [double]$Scale = 1.0,
    [switch]$WarmWindows
  )

  $bodyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 24, 27, 34))
  $roofBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 13, 15, 20))
  $outlinePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 56, 61, 71), 3)

  $mainRect = [System.Drawing.Rectangle]::new($BaseX, $BaseY, [int](460 * $Scale), [int](190 * $Scale))
  $leftWing = [System.Drawing.Rectangle]::new($BaseX - [int](160 * $Scale), $BaseY + [int](30 * $Scale), [int](170 * $Scale), [int](160 * $Scale))
  $rightWing = [System.Drawing.Rectangle]::new($BaseX + [int](450 * $Scale), $BaseY + [int](20 * $Scale), [int](150 * $Scale), [int](170 * $Scale))
  $tower = [System.Drawing.Rectangle]::new($BaseX + [int](330 * $Scale), $BaseY - [int](65 * $Scale), [int](90 * $Scale), [int](255 * $Scale))

  $Graphics.FillRectangle($bodyBrush, $mainRect)
  $Graphics.FillRectangle($bodyBrush, $leftWing)
  $Graphics.FillRectangle($bodyBrush, $rightWing)
  $Graphics.FillRectangle($bodyBrush, $tower)

  $roofPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $roofPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new($BaseX - [int](20 * $Scale), $BaseY),
      [System.Drawing.Point]::new($BaseX + [int](100 * $Scale), $BaseY - [int](90 * $Scale)),
      [System.Drawing.Point]::new($BaseX + [int](220 * $Scale), $BaseY),
      [System.Drawing.Point]::new($BaseX + [int](250 * $Scale), $BaseY - [int](65 * $Scale)),
      [System.Drawing.Point]::new($BaseX + [int](370 * $Scale), $BaseY),
      [System.Drawing.Point]::new($BaseX + [int](410 * $Scale), $BaseY - [int](55 * $Scale)),
      [System.Drawing.Point]::new($BaseX + [int](510 * $Scale), $BaseY),
      [System.Drawing.Point]::new($BaseX + [int](540 * $Scale), $BaseY - [int](75 * $Scale)),
      [System.Drawing.Point]::new($BaseX + [int](620 * $Scale), $BaseY)
    ))
  $Graphics.FillPath($roofBrush, $roofPath)

  for ($i = 0; $i -lt 5; $i++) {
    $chimney = [System.Drawing.Rectangle]::new($BaseX + [int]((60 + ($i * 110)) * $Scale), $BaseY - [int]((70 + ($i % 2) * 30) * $Scale), [int](24 * $Scale), [int](80 * $Scale))
    $Graphics.FillRectangle($roofBrush, $chimney)
  }

  $Graphics.DrawRectangle($outlinePen, $mainRect)
  $Graphics.DrawRectangle($outlinePen, $leftWing)
  $Graphics.DrawRectangle($outlinePen, $rightWing)
  $Graphics.DrawRectangle($outlinePen, $tower)

  if ($WarmWindows) {
    Add-Windows -Graphics $Graphics -Rects @(
      [System.Drawing.Rectangle]::new($BaseX + [int](32 * $Scale), $BaseY + [int](34 * $Scale), [int](28 * $Scale), [int](42 * $Scale)),
      [System.Drawing.Rectangle]::new($BaseX + [int](102 * $Scale), $BaseY + [int](32 * $Scale), [int](28 * $Scale), [int](42 * $Scale)),
      [System.Drawing.Rectangle]::new($BaseX + [int](254 * $Scale), $BaseY + [int](36 * $Scale), [int](30 * $Scale), [int](44 * $Scale)),
      [System.Drawing.Rectangle]::new($BaseX + [int](380 * $Scale), $BaseY + [int](42 * $Scale), [int](30 * $Scale), [int](44 * $Scale)),
      [System.Drawing.Rectangle]::new($BaseX + [int](458 * $Scale), $BaseY + [int](50 * $Scale), [int](28 * $Scale), [int](42 * $Scale))
    ) -Alpha 135
  }

  $doorBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 31, 18, 17))
  $Graphics.FillRectangle($doorBrush, $BaseX + [int](190 * $Scale), $BaseY + [int](95 * $Scale), [int](56 * $Scale), [int](95 * $Scale))

  $doorBrush.Dispose()
  $bodyBrush.Dispose()
  $roofBrush.Dispose()
  $outlinePen.Dispose()
  $roofPath.Dispose()
}

function Add-BloodMist {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height,
    [int]$Count = 10
  )

  for ($i = 0; $i -lt $Count; $i++) {
    $w = 220 + $random.Next(180)
    $h = 80 + $random.Next(100)
    $x = $random.Next($Width) - 80
    $y = [int]($Height * 0.45) + $random.Next([int]($Height * 0.45))
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18 + $random.Next(24), 138, 13, 24))
    $Graphics.FillEllipse($brush, $x, $y, $w, $h)
    $brush.Dispose()
  }
}

function Draw-StudyRoom {
  param(
    [System.Drawing.Graphics]$Graphics,
    [switch]$Blood
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 12, 18, 27)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 48, 28, 23))

  $wallBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 28, 33, 44))
  $floorBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 69, 40, 28))
  $woodBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 83, 48, 34))
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70, 0, 0, 0))
  $fireGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(60, 255, 168, 83))

  $Graphics.FillRectangle($wallBrush, 0, 0, $width, 620)
  $Graphics.FillRectangle($floorBrush, 0, 620, $width, 280)
  $Graphics.FillEllipse($fireGlow, 920, 170, 330, 190)

  $windowPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 119, 129, 146), 6)
  $windowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 36, 63, 82))
  $Graphics.FillRectangle($windowBrush, 1120, 90, 280, 320)
  for ($i = 0; $i -lt 4; $i++) {
    $Graphics.DrawLine($windowPen, 1120 + ($i * 70), 90, 1120 + ($i * 70), 410)
  }
  for ($i = 0; $i -lt 4; $i++) {
    $Graphics.DrawLine($windowPen, 1120, 90 + ($i * 80), 1400, 90 + ($i * 80))
  }
  Add-Rain -Graphics $Graphics -Width 280 -Height 320

  $bookcaseBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 42, 27, 24))
  $Graphics.FillRectangle($bookcaseBrush, 90, 70, 300, 460)
  for ($row = 0; $row -lt 5; $row++) {
    $shelfPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 70, 45, 35), 4)
    $Graphics.DrawLine($shelfPen, 100, 135 + ($row * 72), 380, 135 + ($row * 72))
    $shelfPen.Dispose()
    for ($book = 0; $book -lt 12; $book++) {
      $bookBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 60 + $random.Next(60), 24 + $random.Next(24), 20 + $random.Next(20)))
      $Graphics.FillRectangle($bookBrush, 110 + ($book * 22), 88 + ($row * 72), 14 + $random.Next(4), 42 + $random.Next(14))
      $bookBrush.Dispose()
    }
  }

  $deskPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $deskPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(470, 490),
      [System.Drawing.Point]::new(1080, 490),
      [System.Drawing.Point]::new(1210, 710),
      [System.Drawing.Point]::new(320, 710)
    ))
  $Graphics.FillPath($woodBrush, $deskPath)
  $Graphics.FillRectangle($woodBrush, 410, 520, 70, 240)
  $Graphics.FillRectangle($woodBrush, 1070, 520, 70, 240)

  $lampBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 178, 128, 57))
  $lampPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 231, 188, 121), 4)
  $Graphics.FillEllipse($lampBrush, 770, 250, 100, 52)
  $Graphics.DrawLine($lampPen, 820, 300, 820, 460)
  $Graphics.FillEllipse($fireGlow, 680, 240, 270, 170)

  $paperBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 226, 215, 190))
  $Graphics.FillRectangle($paperBrush, 540, 530, 190, 110)
  $Graphics.FillRectangle($paperBrush, 760, 560, 170, 90)
  $Graphics.FillEllipse($shadowBrush, 500, 660, 520, 90)

  if ($Blood) {
    Add-BloodMist -Graphics $Graphics -Width $width -Height $height -Count 7
    $bloodBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(190, 128, 8, 19))
    $Graphics.FillEllipse($bloodBrush, 585, 585, 260, 110)
    $Graphics.FillEllipse($bloodBrush, 865, 628, 120, 54)
    for ($i = 0; $i -lt 18; $i++) {
      $Graphics.FillEllipse($bloodBrush, 610 + $random.Next(320), 560 + $random.Next(180), 12 + $random.Next(16), 14 + $random.Next(22))
    }
    $corpseBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 19, 17, 22))
    $Graphics.FillEllipse($corpseBrush, 640, 470, 320, 170)
    $Graphics.FillRectangle($corpseBrush, 720, 420, 120, 120)
    $Graphics.FillEllipse($corpseBrush, 610, 510, 90, 54)
    $corpseBrush.Dispose()
    $bloodBrush.Dispose()
  }

  Add-Vignette -Graphics $Graphics -Width $width -Height $height

  $wallBrush.Dispose()
  $floorBrush.Dispose()
  $woodBrush.Dispose()
  $shadowBrush.Dispose()
  $fireGlow.Dispose()
  $windowPen.Dispose()
  $windowBrush.Dispose()
  $bookcaseBrush.Dispose()
  $deskPath.Dispose()
  $lampBrush.Dispose()
  $lampPen.Dispose()
  $paperBrush.Dispose()
}

function Draw-Corridor {
  param(
    [System.Drawing.Graphics]$Graphics
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 14, 18, 30)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 30, 18, 17))

  $leftWall = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 23, 24, 32))
  $rightWall = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 18, 20, 29))
  $floorBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 59, 34, 28))
  $trimPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(150, 94, 82, 70), 4)

  $leftPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $leftPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(0, 0),
      [System.Drawing.Point]::new(450, 0),
      [System.Drawing.Point]::new(780, 560),
      [System.Drawing.Point]::new(560, 900),
      [System.Drawing.Point]::new(0, 900)
    ))
  $Graphics.FillPath($leftWall, $leftPath)

  $rightPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $rightPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(1150, 0),
      [System.Drawing.Point]::new(1600, 0),
      [System.Drawing.Point]::new(1600, 900),
      [System.Drawing.Point]::new(1040, 900),
      [System.Drawing.Point]::new(820, 560)
    ))
  $Graphics.FillPath($rightWall, $rightPath)

  $floorPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $floorPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(560, 900),
      [System.Drawing.Point]::new(1040, 900),
      [System.Drawing.Point]::new(820, 560),
      [System.Drawing.Point]::new(780, 560)
    ))
  $Graphics.FillPath($floorBrush, $floorPath)

  for ($i = 0; $i -lt 4; $i++) {
    $baseY = 120 + ($i * 165)
    $doorBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 41, 25, 21))
    $Graphics.FillRectangle($doorBrush, 145, $baseY, 120, 200)
    $Graphics.FillRectangle($doorBrush, 1335, $baseY + 10, 120, 195)
    $doorBrush.Dispose()
    $Graphics.DrawRectangle($trimPen, 145, $baseY, 120, 200)
    $Graphics.DrawRectangle($trimPen, 1335, $baseY + 10, 120, 195)
  }

  for ($i = 0; $i -lt 5; $i++) {
    $light = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 255, 209, 145))
    $Graphics.FillEllipse($light, 710 + ($i * 22), 80 + ($i * 12), 180, 90)
    $light.Dispose()
  }

  Add-Windows -Graphics $Graphics -Rects @(
    [System.Drawing.Rectangle]::new(750, 120, 90, 150),
    [System.Drawing.Rectangle]::new(762, 325, 76, 110)
  ) -Alpha 95

  Add-FogBands -Graphics $Graphics -Width $width -Height $height -Count 6
  Add-Vignette -Graphics $Graphics -Width $width -Height $height

  $leftWall.Dispose()
  $rightWall.Dispose()
  $floorBrush.Dispose()
  $trimPen.Dispose()
  $leftPath.Dispose()
  $rightPath.Dispose()
  $floorPath.Dispose()
}

function Draw-Exterior {
  param(
    [System.Drawing.Graphics]$Graphics
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 10, 20, 33)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 23, 37, 51))

  $seaBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 19, 43, 56))
  $cliffBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 27, 31, 34))
  $foamPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 207, 227, 233), 4)

  $cloudBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 32, 44, 60))
  for ($i = 0; $i -lt 12; $i++) {
    $Graphics.FillEllipse($cloudBrush, -100 + ($i * 130), 40 + $random.Next(140), 320 + $random.Next(120), 100 + $random.Next(90))
  }

  $seaPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $seaPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(0, 560),
      [System.Drawing.Point]::new(510, 510),
      [System.Drawing.Point]::new(820, 575),
      [System.Drawing.Point]::new(1180, 535),
      [System.Drawing.Point]::new(1600, 620),
      [System.Drawing.Point]::new(1600, 900),
      [System.Drawing.Point]::new(0, 900)
    ))
  $Graphics.FillPath($seaBrush, $seaPath)

  $cliffPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $cliffPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(860, 430),
      [System.Drawing.Point]::new(1415, 365),
      [System.Drawing.Point]::new(1540, 720),
      [System.Drawing.Point]::new(980, 760),
      [System.Drawing.Point]::new(700, 635)
    ))
  $Graphics.FillPath($cliffBrush, $cliffPath)

  Draw-MansionSilhouette -Graphics $Graphics -BaseX 930 -BaseY 300 -Scale 0.9 -WarmWindows
  Add-Lightning -Graphics $Graphics -StartX 500 -StartY 40 -Segments 8
  Add-Rain -Graphics $Graphics -Width $width -Height $height -Count 420

  for ($i = 0; $i -lt 14; $i++) {
    $Graphics.DrawBezier($foamPen,
      0 + ($i * 115), 650 + $random.Next(120),
      120 + ($i * 115), 620 + $random.Next(100),
      190 + ($i * 115), 710 + $random.Next(80),
      280 + ($i * 115), 670 + $random.Next(90))
  }

  Add-Vignette -Graphics $Graphics -Width $width -Height $height

  $seaBrush.Dispose()
  $cliffBrush.Dispose()
  $foamPen.Dispose()
  $cloudBrush.Dispose()
  $seaPath.Dispose()
  $cliffPath.Dispose()
}

function Draw-GreenhouseTrap {
  param(
    [System.Drawing.Graphics]$Graphics
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 7, 22, 25)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 18, 36, 26))

  $glassPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(130, 132, 177, 164), 3)
  $leafBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(170, 29, 69, 48))
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 13, 18, 16))
  $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(160, 140, 12, 26))

  $framePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $framePath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(210, 160),
      [System.Drawing.Point]::new(1380, 160),
      [System.Drawing.Point]::new(1510, 760),
      [System.Drawing.Point]::new(120, 760)
    ))
  $Graphics.FillPath($shadowBrush, $framePath)

  for ($i = 0; $i -lt 9; $i++) {
    $x = 240 + ($i * 130)
    $Graphics.DrawLine($glassPen, $x, 170, $x - 60, 760)
  }
  for ($i = 0; $i -lt 7; $i++) {
    $y = 220 + ($i * 80)
    $Graphics.DrawLine($glassPen, 220, $y, 1400, $y)
  }

  for ($i = 0; $i -lt 38; $i++) {
    $Graphics.FillEllipse($leafBrush, 80 + $random.Next(1450), 360 + $random.Next(450), 140 + $random.Next(180), 70 + $random.Next(100))
  }

  $pathPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 105, 86, 76), 30)
  $Graphics.DrawLine($pathPen, 800, 900, 830, 620)

  $trapPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $trapPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(650, 520),
      [System.Drawing.Point]::new(960, 520),
      [System.Drawing.Point]::new(1030, 640),
      [System.Drawing.Point]::new(590, 640)
    ))
  $Graphics.FillPath($redBrush, $trapPath)

  for ($i = 0; $i -lt 16; $i++) {
    $thornPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 173, 199, 175), 4)
    $sx = 650 + ($i * 22)
    $Graphics.DrawLine($thornPen, $sx, 520, $sx + 60, 640)
    $Graphics.DrawLine($thornPen, $sx + 12, 640, $sx + 90, 520)
    $thornPen.Dispose()
  }

  Add-BloodMist -Graphics $Graphics -Width $width -Height $height -Count 6
  Add-FogBands -Graphics $Graphics -Width $width -Height $height -Count 5
  Add-Vignette -Graphics $Graphics -Width $width -Height $height

  $glassPen.Dispose()
  $leafBrush.Dispose()
  $shadowBrush.Dispose()
  $redBrush.Dispose()
  $pathPen.Dispose()
  $framePath.Dispose()
  $trapPath.Dispose()
}

function Draw-Portrait {
  param(
    [System.Drawing.Graphics]$Graphics
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 18, 17, 30)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 31, 17, 19))

  $curtainBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 72, 12, 20))
  $frameBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 144, 111, 58))
  $frameInner = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 47, 36, 28))
  $canvasBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 22, 29, 39))
  $skinBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 210, 202, 193))
  $hairBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 38, 19, 18))
  $dressBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 17, 23, 31))
  $accentBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(200, 135, 17, 33))

  $Graphics.FillRectangle($curtainBrush, 0, 0, 230, $height)
  $Graphics.FillRectangle($curtainBrush, 1370, 0, 230, $height)

  $Graphics.FillRectangle($frameBrush, 420, 90, 760, 720)
  $Graphics.FillRectangle($frameInner, 470, 140, 660, 620)
  $Graphics.FillRectangle($canvasBrush, 500, 170, 600, 560)

  $Graphics.FillEllipse($accentBrush, 520, 220, 540, 420)
  $Graphics.FillEllipse($dressBrush, 610, 430, 370, 250)
  $Graphics.FillEllipse($skinBrush, 690, 255, 210, 250)
  $Graphics.FillEllipse($hairBrush, 645, 210, 290, 230)

  $neckBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 198, 184, 173))
  $Graphics.FillRectangle($neckBrush, 760, 440, 44, 62)

  $eyePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 230, 234, 236), 4)
  $lipPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(170, 152, 44, 54), 5)
  $Graphics.DrawArc($eyePen, 732, 335, 48, 18, 180, 180)
  $Graphics.DrawArc($eyePen, 814, 335, 48, 18, 180, 180)
  $Graphics.DrawArc($lipPen, 758, 390, 80, 24, 10, 150)

  Add-StarsOrDust -Graphics $Graphics -Width $width -Height $height -Count 170 -Color ([System.Drawing.Color]::FromArgb(30, 219, 206, 175))
  Add-Vignette -Graphics $Graphics -Width $width -Height $height

  $curtainBrush.Dispose()
  $frameBrush.Dispose()
  $frameInner.Dispose()
  $canvasBrush.Dispose()
  $skinBrush.Dispose()
  $hairBrush.Dispose()
  $dressBrush.Dispose()
  $accentBrush.Dispose()
  $neckBrush.Dispose()
  $eyePen.Dispose()
  $lipPen.Dispose()
}

function Draw-KnifeAttack {
  param(
    [System.Drawing.Graphics]$Graphics
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 11, 12, 20)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 70, 11, 18))

  $backGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(90, 188, 24, 45))
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 12, 12, 16))
  $steelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 197, 212, 224))
  $dressBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 19, 23, 30))

  $Graphics.FillEllipse($backGlow, 980, 150, 420, 420)
  $Graphics.FillEllipse($shadowBrush, 890, 150, 360, 520)
  $Graphics.FillEllipse($shadowBrush, 960, 90, 170, 180)
  $Graphics.FillEllipse($shadowBrush, 650, 300, 380, 230)
  $Graphics.FillEllipse($dressBrush, 790, 460, 520, 320)

  $armPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $armPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(960, 390),
      [System.Drawing.Point]::new(1210, 270),
      [System.Drawing.Point]::new(1295, 320),
      [System.Drawing.Point]::new(1030, 450)
    ))
  $Graphics.FillPath($shadowBrush, $armPath)

  $knifePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $knifePath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(1160, 260),
      [System.Drawing.Point]::new(1455, 150),
      [System.Drawing.Point]::new(1495, 170),
      [System.Drawing.Point]::new(1215, 300)
    ))
  $Graphics.FillPath($steelBrush, $knifePath)
  $handleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 76, 28, 22))
  $Graphics.FillRectangle($handleBrush, 1100, 270, 110, 32)

  Add-BloodMist -Graphics $Graphics -Width $width -Height $height -Count 8
  Add-Vignette -Graphics $Graphics -Width $width -Height $height

  $backGlow.Dispose()
  $shadowBrush.Dispose()
  $steelBrush.Dispose()
  $dressBrush.Dispose()
  $armPath.Dispose()
  $knifePath.Dispose()
  $handleBrush.Dispose()
}

function Draw-BadEnding {
  param(
    [System.Drawing.Graphics]$Graphics
  )

  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 7, 7, 12)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 45, 5, 10))

  $bloodBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(185, 132, 7, 21))
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(240, 10, 10, 14))

  for ($i = 0; $i -lt 14; $i++) {
    $Graphics.FillEllipse($bloodBrush, -120 + ($i * 120), 90 + $random.Next(560), 380 + $random.Next(160), 120 + $random.Next(120))
  }

  $Graphics.FillEllipse($shadowBrush, 460, 350, 700, 250)
  $Graphics.FillEllipse($shadowBrush, 650, 240, 150, 150)
  $Graphics.FillRectangle($shadowBrush, 805, 300, 48, 280)

  for ($i = 0; $i -lt 40; $i++) {
    $dropBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(170 + $random.Next(60), 166, 12, 27))
    $Graphics.FillEllipse($dropBrush, $random.Next($width), 120 + $random.Next(720), 10 + $random.Next(28), 26 + $random.Next(100))
    $dropBrush.Dispose()
  }

  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 16

  $bloodBrush.Dispose()
  $shadowBrush.Dispose()
}

function Add-SilhouetteFigure {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$CenterX,
    [int]$BottomY,
    [double]$Scale = 1.0,
    [System.Drawing.Color]$Color = ([System.Drawing.Color]::FromArgb(235, 12, 12, 16))
  )

  $brush = [System.Drawing.SolidBrush]::new($Color)
  $Graphics.FillEllipse($brush, $CenterX - [int](52 * $Scale), $BottomY - [int](250 * $Scale), [int](104 * $Scale), [int](114 * $Scale))
  $Graphics.FillEllipse($brush, $CenterX - [int](120 * $Scale), $BottomY - [int](160 * $Scale), [int](240 * $Scale), [int](170 * $Scale))
  $Graphics.FillRectangle($brush, $CenterX - [int](38 * $Scale), $BottomY - [int](170 * $Scale), [int](76 * $Scale), [int](150 * $Scale))
  $brush.Dispose()
}

function Draw-StudyWindowClue {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  $glassPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220, 205, 223, 235), 4)
  $glowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(80, 180, 220, 255))
  $Graphics.FillEllipse($glowBrush, 1060, 210, 260, 140)
  foreach ($segment in @(
    @(1100, 520, 1180, 610), @(1185, 495, 1260, 585), @(1260, 520, 1330, 610),
    @(1125, 600, 1205, 690), @(1235, 600, 1305, 690)
  )) {
    $Graphics.DrawLine($glassPen, $segment[0], $segment[1], $segment[2], $segment[3])
  }
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $glassPen.Dispose()
  $glowBrush.Dispose()
}

function Draw-DoorConfrontation {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  $doorGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(100, 210, 170, 110))
  $Graphics.FillEllipse($doorGlow, 180, 260, 260, 260)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 250 -BottomY 760 -Scale 1.1
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 460 -BottomY 760 -Scale 0.9 -Color ([System.Drawing.Color]::FromArgb(170, 18, 18, 24))
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $doorGlow.Dispose()
}

function Draw-CurtainHide {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  $curtainBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 76, 8, 19))
  $Graphics.FillPolygon($curtainBrush, [System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(310, 0),
      [System.Drawing.Point]::new(210, 900), [System.Drawing.Point]::new(0, 900)
    ))
  $Graphics.FillPolygon($curtainBrush, [System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(1600, 0), [System.Drawing.Point]::new(1280, 0),
      [System.Drawing.Point]::new(1360, 900), [System.Drawing.Point]::new(1600, 900)
    ))
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1180 -BottomY 760 -Scale 1.0
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $curtainBrush.Dispose()
}

function Draw-SecretPassage {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(210, 10, 10, 12))
  $glowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(85, 255, 186, 98))
  $Graphics.FillRectangle($shadowBrush, 85, 120, 220, 350)
  $Graphics.FillPie($glowBrush, 160, 190, 340, 340, 210, 80)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 430 -BottomY 760 -Scale 0.82
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $shadowBrush.Dispose()
  $glowBrush.Dispose()
}

function Draw-CorridorExplore {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Corridor -Graphics $Graphics
  $beamBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70, 229, 236, 210))
  $beamPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $beamPath.AddPolygon([System.Drawing.Point[]]@(
      [System.Drawing.Point]::new(920, 520), [System.Drawing.Point]::new(1380, 340),
      [System.Drawing.Point]::new(1420, 460), [System.Drawing.Point]::new(980, 610)
    ))
  $Graphics.FillPath($beamBrush, $beamPath)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 860 -BottomY 760 -Scale 0.9
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $beamBrush.Dispose()
  $beamPath.Dispose()
}

function Draw-GreenhouseDark {
  param([System.Drawing.Graphics]$Graphics)
  Draw-GreenhouseTrap -Graphics $Graphics
  $darkBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(150, 4, 8, 10))
  $eyeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 228, 235, 180))
  $Graphics.FillRectangle($darkBrush, 0, 0, $width, $height)
  $Graphics.FillEllipse($eyeBrush, 1020, 340, 36, 18)
  $Graphics.FillEllipse($eyeBrush, 1080, 346, 36, 18)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 18
  $darkBrush.Dispose()
  $eyeBrush.Dispose()
}

function Draw-GreenhouseReveal {
  param([System.Drawing.Graphics]$Graphics)
  Draw-GreenhouseTrap -Graphics $Graphics
  $photoBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(225, 225, 217, 196))
  $accentBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(170, 138, 18, 30))
  $Graphics.FillRectangle($photoBrush, 980, 180, 250, 170)
  $Graphics.FillRectangle($accentBrush, 1010, 205, 190, 42)
  $Graphics.FillRectangle($accentBrush, 1035, 260, 145, 55)
  $Graphics.FillEllipse($accentBrush, 845, 300, 110, 110)
  Add-Lightning -Graphics $Graphics -StartX 260 -StartY 30 -Segments 7
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $photoBrush.Dispose()
  $accentBrush.Dispose()
}

function Draw-RichardRoomSearch {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Corridor -Graphics $Graphics
  $paperBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(210, 224, 215, 188))
  $powderBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 210, 210, 220))
  $Graphics.FillRectangle($paperBrush, 540, 430, 280, 180)
  $Graphics.FillRectangle($paperBrush, 860, 470, 170, 110)
  for ($i = 0; $i -lt 12; $i++) {
    $Graphics.FillEllipse($powderBrush, 500 + $random.Next(420), 630 + $random.Next(80), 18 + $random.Next(22), 10 + $random.Next(18))
  }
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $paperBrush.Dispose()
  $powderBrush.Dispose()
}

function Draw-RichardCaught {
  param([System.Drawing.Graphics]$Graphics)
  Draw-RichardRoomSearch -Graphics $Graphics
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1180 -BottomY 760 -Scale 1.1
  $alertBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(80, 150, 18, 24))
  $Graphics.FillEllipse($alertBrush, 980, 180, 420, 250)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 16
  $alertBrush.Dispose()
}

function Draw-DoctorInterrogation {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1110 -BottomY 760 -Scale 1.0
  $paperBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 222, 214, 190))
  $Graphics.FillRectangle($paperBrush, 570, 520, 160, 100)
  $Graphics.FillRectangle($paperBrush, 740, 560, 180, 90)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $paperBrush.Dispose()
}

function Draw-DoctorHostile {
  param([System.Drawing.Graphics]$Graphics)
  Draw-DoctorInterrogation -Graphics $Graphics
  $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(100, 145, 10, 28))
  $Graphics.FillEllipse($redBrush, 840, 120, 440, 280)
  $Graphics.FillRectangle($redBrush, 720, 470, 120, 40)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 15
  $redBrush.Dispose()
}

function Draw-StudyEvidence {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  $bagBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 73, 50, 33))
  $tagBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 231, 220, 194))
  $Graphics.FillEllipse($bagBrush, 640, 560, 240, 130)
  $Graphics.FillRectangle($tagBrush, 890, 520, 150, 90)
  $Graphics.FillEllipse($tagBrush, 1010, 545, 14, 14)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $bagBrush.Dispose()
  $tagBrush.Dispose()
}

function Draw-SecondMurderPrelude {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Corridor -Graphics $Graphics
  $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120, 152, 11, 26))
  $Graphics.FillEllipse($redBrush, 380, 140, 840, 300)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1220 -BottomY 760 -Scale 0.95
  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 16
  $redBrush.Dispose()
}

function Draw-SecondMurderScene {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Corridor -Graphics $Graphics
  $bloodBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 132, 11, 24))
  $bodyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 15, 14, 20))
  $Graphics.FillEllipse($bodyBrush, 640, 500, 360, 170)
  $Graphics.FillRectangle($bodyBrush, 760, 445, 110, 120)
  $Graphics.FillEllipse($bloodBrush, 580, 610, 420, 120)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 16
  $bloodBrush.Dispose()
  $bodyBrush.Dispose()
}

function Draw-AccuseEvelyn {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Portrait -Graphics $Graphics
  $crackPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(170, 219, 229, 239), 4)
  $Graphics.DrawLine($crackPen, 780, 60, 710, 260)
  $Graphics.DrawLine($crackPen, 710, 260, 820, 430)
  $Graphics.DrawLine($crackPen, 710, 260, 635, 380)
  $Graphics.DrawLine($crackPen, 820, 430, 980, 520)
  $crackPen.Dispose()
}

function Draw-RichardAccusation {
  param([System.Drawing.Graphics]$Graphics)
  Draw-CorridorExplore -Graphics $Graphics
  $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(90, 135, 12, 29))
  $Graphics.FillEllipse($redBrush, 860, 160, 500, 260)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1190 -BottomY 760 -Scale 1.05
  Add-Vignette -Graphics $Graphics -Width $width -Height $height -Steps 15
  $redBrush.Dispose()
}

function Draw-EndingTrue {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyRoom -Graphics $Graphics
  $lightBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(110, 224, 214, 165))
  $Graphics.FillEllipse($lightBrush, 520, 120, 520, 280)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1170 -BottomY 760 -Scale 0.95
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $lightBrush.Dispose()
}

function Draw-EndingEscape {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Corridor -Graphics $Graphics
  $doorGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(90, 210, 185, 118))
  $Graphics.FillEllipse($doorGlow, 1220, 260, 280, 280)
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 1260 -BottomY 760 -Scale 0.8
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $doorGlow.Dispose()
}

function Draw-EndingFalseAccusation {
  param([System.Drawing.Graphics]$Graphics)
  Draw-Corridor -Graphics $Graphics
  $barPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 176, 185, 194), 18)
  for ($i = 0; $i -lt 5; $i++) {
    $x = 520 + ($i * 100)
    $Graphics.DrawLine($barPen, $x, 180, $x, 820)
  }
  Add-SilhouetteFigure -Graphics $Graphics -CenterX 770 -BottomY 780 -Scale 1.1
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $barPen.Dispose()
}

function Draw-EndingUnsolved {
  param([System.Drawing.Graphics]$Graphics)
  Draw-StudyEvidence -Graphics $Graphics
  $folderBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(210, 101, 77, 55))
  $stampBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(160, 122, 12, 22))
  $Graphics.FillRectangle($folderBrush, 540, 360, 380, 220)
  $Graphics.FillRectangle($stampBrush, 760, 420, 110, 52)
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $folderBrush.Dispose()
  $stampBrush.Dispose()
}

function Apply-PhotoTexture {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height
  )

  for ($i = 0; $i -lt 3600; $i++) {
    $size = 1 + $random.Next(3)
    $x = $random.Next($Width)
    $y = $random.Next($Height)
    $tone = 32 + $random.Next(54)
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(6 + $random.Next(10), $tone, $tone, $tone + 6))
    $Graphics.FillRectangle($brush, $x, $y, $size, $size)
    $brush.Dispose()
  }

  for ($i = 0; $i -lt 440; $i++) {
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(8 + $random.Next(10), 214, 221, 229), 1)
    $x = $random.Next($Width)
    $y = $random.Next($Height)
    $Graphics.DrawLine($pen, $x, $y, $x + 18 + $random.Next(60), $y + $random.Next(-6, 8))
    $pen.Dispose()
  }

  for ($i = 0; $i -lt 80; $i++) {
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(7 + $random.Next(10), 242, 216, 180), 2)
    $x1 = $random.Next($Width)
    $y1 = $random.Next($Height)
    $x2 = $x1 + 90 + $random.Next(220)
    $y2 = $y1 + $random.Next(-20, 20)
    $Graphics.DrawBezier(
      $pen,
      $x1, $y1,
      $x1 + 30 + $random.Next(80), $y1 + $random.Next(-20, 20),
      $x2 - 30 - $random.Next(80), $y2 + $random.Next(-20, 20),
      $x2, $y2
    )
    $pen.Dispose()
  }

  for ($i = 0; $i -lt 140; $i++) {
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(5 + $random.Next(6), 255, 255, 255))
    $x = $random.Next($Width)
    $y = $random.Next($Height)
    $Graphics.FillEllipse($brush, $x, $y, 1 + $random.Next(2), 1 + $random.Next(2))
    $brush.Dispose()
  }
}

function Apply-CinematicFinish {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height
  )

  Apply-PhotoTexture -Graphics $Graphics -Width $Width -Height $Height

  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(34, 5, 7, 10))
  $highlightBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18, 232, 222, 196))
  $mistBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(10, 206, 214, 220))

  $Graphics.FillEllipse($highlightBrush, [int]($Width * 0.24), [int]($Height * 0.08), [int]($Width * 0.34), [int]($Height * 0.18))
  $Graphics.FillEllipse($shadowBrush, -120, [int]($Height * 0.72), [int]($Width * 0.62), [int]($Height * 0.28))
  $Graphics.FillEllipse($shadowBrush, [int]($Width * 0.56), [int]($Height * 0.68), [int]($Width * 0.5), [int]($Height * 0.26))

  for ($i = 0; $i -lt 22; $i++) {
    $w = 180 + $random.Next(220)
    $h = 28 + $random.Next(34)
    $x = -80 + $random.Next($Width)
    $y = [int]($Height * 0.5) + $random.Next([int]($Height * 0.34))
    $Graphics.FillEllipse($mistBrush, $x, $y, $w, $h)
  }

  for ($i = 0; $i -lt 28; $i++) {
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(9 + $random.Next(8), 255, 240, 212), 2)
    $x = $random.Next($Width)
    $y = $random.Next([int]($Height * 0.7))
    $Graphics.DrawBezier(
      $pen,
      $x, $y,
      $x + 80 + $random.Next(140), $y + $random.Next(-30, 20),
      $x + 170 + $random.Next(180), $y + $random.Next(-24, 24),
      $x + 260 + $random.Next(220), $y + $random.Next(-12, 28)
    )
    $pen.Dispose()
  }

  $shadowBrush.Dispose()
  $highlightBrush.Dispose()
  $mistBrush.Dispose()
}

function Draw-DetectiveOffice {
  param([System.Drawing.Graphics]$Graphics)
  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 32, 28, 24)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 12, 10, 8))
  
  $deskBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 64, 42, 32))
  $paperBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 225, 218, 195))
  $lampGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70, 255, 200, 100))
  
  $Graphics.FillRectangle($deskBrush, 200, 600, 1200, 300)
  $Graphics.FillRectangle($paperBrush, 450, 550, 200, 250)
  $Graphics.FillRectangle($paperBrush, 700, 580, 220, 180)
  $Graphics.FillEllipse($lampGlow, 850, 300, 400, 400)
  
  Add-StarsOrDust -Graphics $Graphics -Width $width -Height $height -Count 150 -Color ([System.Drawing.Color]::FromArgb(40, 200, 190, 160))
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $deskBrush.Dispose(); $paperBrush.Dispose(); $lampGlow.Dispose()
}

function Draw-TrainStation {
  param([System.Drawing.Graphics]$Graphics)
  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 20, 22, 28)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 45, 48, 55))
  
  $platformBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 40, 40, 45))
  $pillarBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 25, 25, 30))
  $Graphics.FillRectangle($platformBrush, 0, 700, $width, 200)
  for ($i = 0; $i -lt 5; $i++) {
    $Graphics.FillRectangle($pillarBrush, 100 + ($i * 350), 0, 60, 700)
  }
  
  Add-FogBands -Graphics $Graphics -Width $width -Height $height -Count 8
  Add-Rain -Graphics $Graphics -Width $width -Height $height -Count 300
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $platformBrush.Dispose(); $pillarBrush.Dispose()
}

function Draw-DiningRoom {
  param([System.Drawing.Graphics]$Graphics)
  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 45, 30, 25)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 20, 15, 12))
  
  $tableBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 80, 50, 40))
  $chairBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 30, 20, 15))
  $Graphics.FillRectangle($tableBrush, 200, 550, 1200, 150)
  for ($i = 0; $i -lt 6; $i++) {
    $Graphics.FillRectangle($chairBrush, 250 + ($i * 200), 450, 80, 250)
  }
  
  $candleGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(60, 255, 180, 100))
  $Graphics.FillEllipse($candleGlow, 700, 350, 200, 300)
  
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $tableBrush.Dispose(); $chairBrush.Dispose(); $candleGlow.Dispose()
}

function Draw-TrainInterior {
  param([System.Drawing.Graphics]$Graphics)
  Fill-Gradient -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new(0, 0, $width, $height)) `
    -TopColor ([System.Drawing.Color]::FromArgb(255, 28, 24, 20)) `
    -BottomColor ([System.Drawing.Color]::FromArgb(255, 45, 35, 30))
  
  $windowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 30, 45, 60))
  $seatBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 60, 20, 15))
  
  $Graphics.FillRectangle($windowBrush, 300, 150, 1000, 400)
  Add-Rain -Graphics $Graphics -Width 1000 -Height 400
  
  $Graphics.FillRectangle($seatBrush, 0, 600, $width, 300)
  $Graphics.FillRectangle($seatBrush, 200, 450, 250, 150)
  
  Add-Vignette -Graphics $Graphics -Width $width -Height $height
  $windowBrush.Dispose(); $seatBrush.Dispose()
}

$scenes = @(
  @{ Name = 'detective_office.png'; Painter = { param($g) Draw-DetectiveOffice -Graphics $g } },
  @{ Name = 'train_station_platform.png'; Painter = { param($g) Draw-TrainStation -Graphics $g } },
  @{ Name = 'train_interior.png'; Painter = { param($g) Draw-TrainInterior -Graphics $g } },
  @{ Name = 'mansion_dining_room.png'; Painter = { param($g) Draw-DiningRoom -Graphics $g } },
  @{ Name = 'stormy_mansion_exterior.png'; Painter = { param($g) Draw-Exterior -Graphics $g } },
  @{ Name = 'mansion_corridor.png'; Painter = { param($g) Draw-Corridor -Graphics $g } },
  @{ Name = 'mansion_study_room.png'; Painter = { param($g) Draw-StudyRoom -Graphics $g } },
  @{ Name = 'mansion_study_room_blood.png'; Painter = { param($g) Draw-StudyRoom -Graphics $g -Blood } },
  @{ Name = 'greenhouse_bloody_trap.png'; Painter = { param($g) Draw-GreenhouseTrap -Graphics $g } },
  @{ Name = 'evelyn_portrait.png'; Painter = { param($g) Draw-Portrait -Graphics $g } },
  @{ Name = 'evelyn_knife_attack.png'; Painter = { param($g) Draw-KnifeAttack -Graphics $g } },
  @{ Name = 'bad_ending_blood.png'; Painter = { param($g) Draw-BadEnding -Graphics $g } },
  @{ Name = 'study_window_clue.png'; Painter = { param($g) Draw-StudyWindowClue -Graphics $g } },
  @{ Name = 'door_confrontation.png'; Painter = { param($g) Draw-DoorConfrontation -Graphics $g } },
  @{ Name = 'curtain_hide.png'; Painter = { param($g) Draw-CurtainHide -Graphics $g } },
  @{ Name = 'secret_passage_reveal.png'; Painter = { param($g) Draw-SecretPassage -Graphics $g } },
  @{ Name = 'corridor_night_explore.png'; Painter = { param($g) Draw-CorridorExplore -Graphics $g } },
  @{ Name = 'greenhouse_dark_whispers.png'; Painter = { param($g) Draw-GreenhouseDark -Graphics $g } },
  @{ Name = 'greenhouse_evidence_reveal.png'; Painter = { param($g) Draw-GreenhouseReveal -Graphics $g } },
  @{ Name = 'richard_room_search.png'; Painter = { param($g) Draw-RichardRoomSearch -Graphics $g } },
  @{ Name = 'richard_room_caught.png'; Painter = { param($g) Draw-RichardCaught -Graphics $g } },
  @{ Name = 'doctor_interrogation.png'; Painter = { param($g) Draw-DoctorInterrogation -Graphics $g } },
  @{ Name = 'doctor_hostile.png'; Painter = { param($g) Draw-DoctorHostile -Graphics $g } },
  @{ Name = 'study_hidden_evidence.png'; Painter = { param($g) Draw-StudyEvidence -Graphics $g } },
  @{ Name = 'second_murder_prelude.png'; Painter = { param($g) Draw-SecondMurderPrelude -Graphics $g } },
  @{ Name = 'second_murder_scene.png'; Painter = { param($g) Draw-SecondMurderScene -Graphics $g } },
  @{ Name = 'accuse_evelyn.png'; Painter = { param($g) Draw-AccuseEvelyn -Graphics $g } },
  @{ Name = 'accuse_richard.png'; Painter = { param($g) Draw-RichardAccusation -Graphics $g } },
  @{ Name = 'ending_true_reveal.png'; Painter = { param($g) Draw-EndingTrue -Graphics $g } },
  @{ Name = 'ending_evelyn_escape.png'; Painter = { param($g) Draw-EndingEscape -Graphics $g } },
  @{ Name = 'ending_false_accusation.png'; Painter = { param($g) Draw-EndingFalseAccusation -Graphics $g } },
  @{ Name = 'ending_unsolved_case.png'; Painter = { param($g) Draw-EndingUnsolved -Graphics $g } }
)

foreach ($scene in $scenes) {
  $canvas = New-Canvas -Width $width -Height $height -BaseColor ([System.Drawing.Color]::Black)
  & $scene.Painter $canvas.Graphics
  Apply-CinematicFinish -Graphics $canvas.Graphics -Width $width -Height $height
  Save-Canvas -Canvas $canvas -Name $scene.Name
  Write-Output "generated $($scene.Name)"
}
