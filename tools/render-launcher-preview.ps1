param(
  [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\images\launcher-interface-v2.7.png')
)

$ErrorActionPreference = 'Stop'
$launcherPath = Join-Path $PSScriptRoot '..\scripts\DabinLauncher.ps1'
$source = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $launcherPath))

$renderTail = @'
$form.Show()
[Windows.Forms.Application]::DoEvents()
Start-Sleep -Milliseconds 100

$art.Visible = $false
$overlay = New-Object Drawing.Bitmap($form.ClientSize.Width, $form.ClientSize.Height)
$form.DrawToBitmap($overlay, (New-Object Drawing.Rectangle(0, 0, $overlay.Width, $overlay.Height)))
$art.Visible = $true

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
  [void](New-Item -ItemType Directory -Path $outputDirectory -Force)
}
$canvas = New-Object Drawing.Bitmap($form.ClientSize.Width, $form.ClientSize.Height)
$graphics = [Drawing.Graphics]::FromImage($canvas)
$attributes = New-Object Drawing.Imaging.ImageAttributes
try {
  $graphics.Clear($form.BackColor)
  $graphics.DrawImage($art.Image, (New-Object Drawing.Rectangle(0, -42, $form.ClientSize.Width, $form.ClientSize.Height)))
  $attributes.SetColorKey($form.BackColor, $form.BackColor)
  $graphics.DrawImage($overlay, (New-Object Drawing.Rectangle(0, 0, $canvas.Width, $canvas.Height)), 0, 0, $overlay.Width, $overlay.Height, [Drawing.GraphicsUnit]::Pixel, $attributes)
  $canvas.Save($OutputPath, [Drawing.Imaging.ImageFormat]::Png)
} finally {
  $attributes.Dispose()
  $graphics.Dispose()
  $canvas.Dispose()
  $overlay.Dispose()
  $form.Close()
  $form.Dispose()
}
'@

$pattern = '(?s)if \(\$SelfTest\) \{.*?\n\} else \{\s*\[void\]\$form\.ShowDialog\(\)\s*\}\s*\$form\.Dispose\(\)'
$renderSource = [regex]::Replace($source, $pattern, $renderTail, 1)
if ($renderSource -eq $source) { throw 'Unable to locate launcher display block.' }
$launcherDirectory = Split-Path -Parent (Resolve-Path -LiteralPath $launcherPath)
$renderSource = [regex]::Replace($renderSource, '(?m)^(?:\uFEFF)?param\(\[switch\]\$SelfTest\)\r?\n', "`$0`$PSScriptRoot = '$launcherDirectory'`r`n", 1)
& ([scriptblock]::Create($renderSource))
Write-Output $OutputPath
