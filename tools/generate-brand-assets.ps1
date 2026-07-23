Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$brandRoot = Join-Path $root "public\brand"
$legacyAssetsRoot = Join-Path $root "assets"
$script:TaglineText = "GEST" + [char]0x00C3 + "O DE PONTO SIMPLIFICADA"
$script:TaglineSvg = "GEST&#x00C3;O DE PONTO SIMPLIFICADA"

function Ensure-Dir($path) {
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Write-Utf8($path, $content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Get-SymbolSvg($mono, $monoColor) {
  $paint = if ($mono) { $monoColor } else { "url(#jornadaGradient)" }
  $defs = if ($mono) { "" } else {
@"
  <defs>
    <linearGradient id="jornadaGradient" x1="176" y1="214" x2="760" y2="812" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#57e3c8"/>
      <stop offset="0.48" stop-color="#16bfa9"/>
      <stop offset="1" stop-color="#5db8f2"/>
    </linearGradient>
  </defs>
"@
  }

@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-labelledby="title">
  <title id="title">Jornada</title>
$defs
  <g fill="none" stroke="$paint" stroke-linecap="round" stroke-linejoin="round">
    <path d="M494 236H732V544C732 708 602 838 438 838C274 838 144 708 144 544C144 390 260 268 408 252" stroke-width="74"/>
    <path d="M270 542H304" stroke-width="36"/>
    <path d="M594 542H628" stroke-width="36"/>
    <path d="M450 326V360" stroke-width="36"/>
    <path d="M450 724V758" stroke-width="36"/>
    <path d="M334 516L425 606L594 414" stroke-width="72"/>
  </g>
</svg>
"@
}

function Get-LogoSvg($textColor, $mono, $monoColor) {
  $paint = if ($mono) { $monoColor } else { "url(#jornadaGradient)" }
  $subtitleColor = if ($mono) { $monoColor } else { "#57e3c8" }

@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 512" role="img" aria-labelledby="title">
  <title id="title">Jornada - Gest&#x00E3;o de Ponto Simplificada</title>
  <defs>
    <linearGradient id="jornadaGradient" x1="176" y1="214" x2="760" y2="812" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#57e3c8"/>
      <stop offset="0.48" stop-color="#16bfa9"/>
      <stop offset="1" stop-color="#5db8f2"/>
    </linearGradient>
  </defs>
  <g transform="translate(86 114) scale(0.27)" fill="none" stroke="$paint" stroke-linecap="round" stroke-linejoin="round">
    <path d="M494 236H732V544C732 708 602 838 438 838C274 838 144 708 144 544C144 390 260 268 408 252" stroke-width="74"/>
    <path d="M270 542H304" stroke-width="36"/>
    <path d="M594 542H628" stroke-width="36"/>
    <path d="M450 326V360" stroke-width="36"/>
    <path d="M450 724V758" stroke-width="36"/>
    <path d="M334 516L425 606L594 414" stroke-width="72"/>
  </g>
  <text x="392" y="267" fill="$textColor" font-family="Inter, Segoe UI, Arial, sans-serif" font-size="118" font-weight="850">Jornada</text>
  <text x="397" y="336" fill="$subtitleColor" font-family="Inter, Segoe UI, Arial, sans-serif" font-size="36" font-weight="650" letter-spacing="6">$script:TaglineSvg</text>
</svg>
"@
}

function New-SymbolPath {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.StartFigure()
  $path.AddLine(494, 236, 732, 236)
  $path.AddLine(732, 236, 732, 544)
  $path.AddBezier(732, 544, 732, 708, 602, 838, 438, 838)
  $path.AddBezier(438, 838, 274, 838, 144, 708, 144, 544)
  $path.AddBezier(144, 544, 144, 390, 260, 268, 408, 252)
  return $path
}

function Draw-Symbol($graphics, $rect, $mono, $monoColor) {
  $state = $graphics.Save()
  $graphics.TranslateTransform($rect.X, $rect.Y)
  $graphics.ScaleTransform($rect.Width / 1024.0, $rect.Height / 1024.0)

  if ($mono) {
    $brush = New-Object System.Drawing.SolidBrush $monoColor
  } else {
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
      (New-Object System.Drawing.Point 176, 214),
      (New-Object System.Drawing.Point 760, 812),
      [System.Drawing.ColorTranslator]::FromHtml("#57e3c8"),
      [System.Drawing.ColorTranslator]::FromHtml("#5db8f2")
    )
    $blend = New-Object System.Drawing.Drawing2D.ColorBlend
    $blend.Positions = [single[]](0, 0.48, 1)
    $blend.Colors = [System.Drawing.Color[]](
      [System.Drawing.ColorTranslator]::FromHtml("#57e3c8"),
      [System.Drawing.ColorTranslator]::FromHtml("#16bfa9"),
      [System.Drawing.ColorTranslator]::FromHtml("#5db8f2")
    )
    $brush.InterpolationColors = $blend
  }

  $penOuter = New-Object System.Drawing.Pen $brush, 74
  $penOuter.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $penOuter.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $penOuter.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $graphics.DrawPath($penOuter, (New-SymbolPath))

  $penTick = New-Object System.Drawing.Pen $brush, 72
  $penTick.StartCap = [System.Drawing.Drawing2D.LineCap]::Square
  $penTick.EndCap = [System.Drawing.Drawing2D.LineCap]::Square
  $penTick.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Miter
  $graphics.DrawLines($penTick, [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF 334, 516),
    (New-Object System.Drawing.PointF 425, 606),
    (New-Object System.Drawing.PointF 594, 414)
  ))

  $penMark = New-Object System.Drawing.Pen $brush, 36
  $penMark.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $penMark.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawLine($penMark, 270, 542, 304, 542)
  $graphics.DrawLine($penMark, 594, 542, 628, 542)
  $graphics.DrawLine($penMark, 450, 326, 450, 360)
  $graphics.DrawLine($penMark, 450, 724, 450, 758)

  $penOuter.Dispose()
  $penTick.Dispose()
  $penMark.Dispose()
  $brush.Dispose()
  $graphics.Restore($state)
}

function Save-Png($path, $width, $height, $draw) {
  $bmp = New-Object System.Drawing.Bitmap $width, $height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear([System.Drawing.Color]::Transparent)
  & $draw $g
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

function Save-SymbolPng($path, $size, $mono, $monoColor, $withBackground) {
  Save-Png $path $size $size {
    param($g)
    if ($withBackground) {
      $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point $size, $size),
        [System.Drawing.ColorTranslator]::FromHtml("#09111f"),
        [System.Drawing.ColorTranslator]::FromHtml("#101b30")
      )
      $g.FillRectangle($bg, 0, 0, $size, $size)
      $bg.Dispose()
    }
    $pad = [int]($size * 0.12)
    Draw-Symbol $g (New-Object System.Drawing.Rectangle $pad, $pad, ($size - 2 * $pad), ($size - 2 * $pad)) $mono $monoColor
  }
}

function Save-LogoPng($path, $textColor, $mono, $monoColor) {
  Save-Png $path 1280 512 {
    param($g)
    Draw-Symbol $g (New-Object System.Drawing.Rectangle 86, 114, 276, 276) $mono $monoColor
    $brushText = New-Object System.Drawing.SolidBrush $textColor
    $brushSub = if ($mono) {
      New-Object System.Drawing.SolidBrush $monoColor
    } else {
      New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#57e3c8"))
    }
    $fontTitle = New-Object System.Drawing.Font "Segoe UI", 118, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $fontSub = New-Object System.Drawing.Font "Segoe UI", 36, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
    $format = New-Object System.Drawing.StringFormat
    $g.DrawString("Jornada", $fontTitle, $brushText, 392, 144, $format)
    $g.DrawString($script:TaglineText, $fontSub, $brushSub, 397, 299, $format)
    $format.Dispose()
    $fontTitle.Dispose()
    $fontSub.Dispose()
    $brushText.Dispose()
    $brushSub.Dispose()
  }
}

Ensure-Dir $brandRoot
Ensure-Dir $legacyAssetsRoot
Ensure-Dir (Join-Path $brandRoot "logo")
Ensure-Dir (Join-Path $brandRoot "symbol")
Ensure-Dir (Join-Path $brandRoot "favicon")
Ensure-Dir (Join-Path $brandRoot "app-icon")
Ensure-Dir (Join-Path $brandRoot "pwa")

$logoDir = Join-Path $brandRoot "logo"
$symbolDir = Join-Path $brandRoot "symbol"
$faviconDir = Join-Path $brandRoot "favicon"
$appIconDir = Join-Path $brandRoot "app-icon"
$pwaDir = Join-Path $brandRoot "pwa"

$ink = [System.Drawing.ColorTranslator]::FromHtml("#09111f")
$white = [System.Drawing.Color]::White
$teal = [System.Drawing.ColorTranslator]::FromHtml("#57e3c8")

Write-Utf8 (Join-Path $logoDir "jornada-logo-light.svg") (Get-LogoSvg "#09111f" $false "#09111f")
Write-Utf8 (Join-Path $logoDir "jornada-logo-dark.svg") (Get-LogoSvg "#ffffff" $false "#ffffff")
Write-Utf8 (Join-Path $logoDir "jornada-logo-mono-light.svg") (Get-LogoSvg "#09111f" $true "#09111f")
Write-Utf8 (Join-Path $logoDir "jornada-logo-mono-dark.svg") (Get-LogoSvg "#ffffff" $true "#ffffff")
Write-Utf8 (Join-Path $symbolDir "jornada-symbol-light.svg") (Get-SymbolSvg $false "#09111f")
Write-Utf8 (Join-Path $symbolDir "jornada-symbol-dark.svg") (Get-SymbolSvg $false "#ffffff")
Write-Utf8 (Join-Path $symbolDir "jornada-symbol-mono-light.svg") (Get-SymbolSvg $true "#09111f")
Write-Utf8 (Join-Path $symbolDir "jornada-symbol-mono-dark.svg") (Get-SymbolSvg $true "#ffffff")
Write-Utf8 (Join-Path $faviconDir "favicon.svg") (Get-SymbolSvg $false "#09111f")

Save-LogoPng (Join-Path $logoDir "jornada-logo-light.png") $ink $false $ink
Save-LogoPng (Join-Path $logoDir "jornada-logo-dark.png") $white $false $white
Save-LogoPng (Join-Path $logoDir "jornada-logo-mono-light.png") $ink $true $ink
Save-LogoPng (Join-Path $logoDir "jornada-logo-mono-dark.png") $white $true $white

Save-SymbolPng (Join-Path $symbolDir "jornada-symbol-light.png") 1024 $false $ink $false
Save-SymbolPng (Join-Path $symbolDir "jornada-symbol-dark.png") 1024 $false $white $false
Save-SymbolPng (Join-Path $symbolDir "jornada-symbol-mono-light.png") 1024 $true $ink $false
Save-SymbolPng (Join-Path $symbolDir "jornada-symbol-mono-dark.png") 1024 $true $white $false

Save-SymbolPng (Join-Path $faviconDir "favicon-16x16.png") 16 $false $ink $false
Save-SymbolPng (Join-Path $faviconDir "favicon-32x32.png") 32 $false $ink $false
Save-SymbolPng (Join-Path $faviconDir "favicon-48x48.png") 48 $false $ink $false
Save-SymbolPng (Join-Path $faviconDir "apple-touch-icon.png") 180 $false $ink $true

foreach ($size in 48, 72, 96, 144, 192, 512, 1024) {
  Save-SymbolPng (Join-Path $appIconDir "jornada-app-icon-$size.png") $size $false $ink $true
}
Save-SymbolPng (Join-Path $pwaDir "pwa-192x192.png") 192 $false $ink $true
Save-SymbolPng (Join-Path $pwaDir "pwa-512x512.png") 512 $false $ink $true

Save-LogoPng (Join-Path $legacyAssetsRoot "logo-jornada-formulario.png") $white $false $white
Save-SymbolPng (Join-Path $legacyAssetsRoot "favicon-jornada.png") 512 $false $ink $true
Save-Png (Join-Path $legacyAssetsRoot "logo-jornada-nova.png") 1536 864 {
  param($g)
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Point 0, 0),
    (New-Object System.Drawing.Point 1536, 864),
    [System.Drawing.Color]::Black,
    [System.Drawing.ColorTranslator]::FromHtml("#050809")
  )
  $g.FillRectangle($bg, 0, 0, 1536, 864)
  $bg.Dispose()

  $state = $g.Save()
  $g.TranslateTransform(235, 270)
  $g.ScaleTransform(0.84, 0.84)
  Draw-Symbol $g (New-Object System.Drawing.Rectangle 86, 114, 276, 276) $false $white
  $brushTitle = New-Object System.Drawing.SolidBrush $white
  $brushSub = New-Object System.Drawing.SolidBrush $teal
  $fontTitle = New-Object System.Drawing.Font "Segoe UI", 118, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $fontSub = New-Object System.Drawing.Font "Segoe UI", 36, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $format = New-Object System.Drawing.StringFormat
  $g.DrawString("Jornada", $fontTitle, $brushTitle, 392, 144, $format)
  $g.DrawString($script:TaglineText, $fontSub, $brushSub, 397, 299, $format)
  $format.Dispose()
  $fontTitle.Dispose()
  $fontSub.Dispose()
  $brushTitle.Dispose()
  $brushSub.Dispose()
  $g.Restore($state)
}

Write-Host "Brand assets regenerated with original Jornada tagline."
