$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$assetsDir = Join-Path $root 'assets'
$iconPath = Join-Path $assetsDir 'DisplaySnooze.ico'
$previewPath = Join-Path $assetsDir 'logo-256.png'

New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
Add-Type -AssemblyName System.Drawing

function New-LogoBitmap {
    param([int] $Size)

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = $Size / 256.0
    function S([double] $Value) { return [single]($Value * $scale) }

    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 16, 24, 32))
    $screenBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 23, 36, 48))
    $accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 107, 228, 214))
    $moonBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 247, 215, 116))
    $screenPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 107, 228, 214)), (S 10)

    $graphics.FillRectangle($bgBrush, 0, 0, $Size, $Size)
    $graphics.FillRectangle($screenBrush, (S 42), (S 56), (S 172), (S 112))
    $graphics.DrawRectangle($screenPen, (S 42), (S 56), (S 172), (S 112))
    $graphics.FillRectangle($accentBrush, (S 113), (S 163), (S 30), (S 30))
    $graphics.FillRectangle($accentBrush, (S 78), (S 184), (S 100), (S 14))

    $graphics.FillEllipse($moonBrush, (S 101), (S 68), (S 76), (S 76))
    $graphics.FillEllipse($screenBrush, (S 115), (S 56), (S 78), (S 78))

    $star = New-Object System.Drawing.Drawing2D.GraphicsPath
    $points = @(
        [System.Drawing.PointF]::new((S 187), (S 73)),
        [System.Drawing.PointF]::new((S 193), (S 87)),
        [System.Drawing.PointF]::new((S 207), (S 93)),
        [System.Drawing.PointF]::new((S 193), (S 99)),
        [System.Drawing.PointF]::new((S 187), (S 113)),
        [System.Drawing.PointF]::new((S 181), (S 99)),
        [System.Drawing.PointF]::new((S 167), (S 93)),
        [System.Drawing.PointF]::new((S 181), (S 87))
    )
    $star.AddPolygon($points)
    $graphics.FillPath($moonBrush, $star)

    $star.Dispose()
    $screenPen.Dispose()
    $bgBrush.Dispose()
    $screenBrush.Dispose()
    $accentBrush.Dispose()
    $moonBrush.Dispose()
    $graphics.Dispose()

    return $bitmap
}

function Convert-BitmapToPngBytes {
    param([System.Drawing.Bitmap] $Bitmap)

    $stream = New-Object System.IO.MemoryStream
    $Bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $stream.ToArray()
    $stream.Dispose()
    return ,$bytes
}

$sizes = @(16, 24, 32, 48, 64, 128, 256)
$images = @()

foreach ($size in $sizes) {
    $bitmap = New-LogoBitmap -Size $size
    if ($size -eq 256) {
        $bitmap.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $images += [PSCustomObject]@{
        Size = $size
        Bytes = Convert-BitmapToPngBytes -Bitmap $bitmap
    }
    $bitmap.Dispose()
}

$stream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter $stream
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]$images.Count)

$offset = 6 + (16 * $images.Count)
foreach ($image in $images) {
    $encodedSize = if ($image.Size -eq 256) { 0 } else { $image.Size }
    $writer.Write([byte]$encodedSize)
    $writer.Write([byte]$encodedSize)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]$image.Bytes.Length)
    $writer.Write([UInt32]$offset)
    $offset += $image.Bytes.Length
}

foreach ($image in $images) {
    $writer.Write($image.Bytes)
}

[System.IO.File]::WriteAllBytes($iconPath, $stream.ToArray())
$writer.Dispose()
$stream.Dispose()

Write-Host "Wrote $iconPath"
Write-Host "Wrote $previewPath"
