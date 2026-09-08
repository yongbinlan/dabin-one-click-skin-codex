param(
  [ValidateSet('Check','Apply','Status','Pause','Restore')][string]$Action = 'Check',
  [string]$ImagePath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $root 'payload\engine'
$node = (Get-Command node.exe -ErrorAction Stop).Source

function Require-WindowsX64 {
  if (-not [Environment]::Is64BitOperatingSystem -or -not [Environment]::Is64BitProcess) {
    throw 'Run this launcher with 64-bit Windows PowerShell.'
  }
}

function Convert-ThemeImage([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { throw "Image not found: $Path" }
  Add-Type -AssemblyName System.Drawing
  $source = [Drawing.Image]::FromFile($Path)
  try {
    $width = [Math]::Min(1280, $source.Width)
    $height = [Math]::Max(1, [int][Math]::Round($source.Height * ($width / [double]$source.Width)))
    $bitmap = [Drawing.Bitmap]::new($width, $height)
    try {
      $graphics = [Drawing.Graphics]::FromImage($bitmap)
      try { $graphics.DrawImage($source, 0, 0, $width, $height) } finally { $graphics.Dispose() }
      $output = Join-Path $root 'payload\selected-theme.jpg'
      $codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
      $params = [Drawing.Imaging.EncoderParameters]::new(1)
      try {
        $params.Param[0] = [Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality, [long]88)
        $bitmap.Save($output, $codec, $params)
      } finally { $params.Dispose() }
      return $output
    } finally { $bitmap.Dispose() }
  } finally { $source.Dispose() }
}

Require-WindowsX64
if (-not (Test-Path "$engine\src\cli.mjs")) { throw 'The embedded theme engine is missing.' }
if ([int]((& $node --version).TrimStart('v').Split('.')[0]) -lt 22) { throw 'Node.js 22 or newer is required.' }

switch ($Action) {
  'Check' { Write-Output 'Windows x64 and embedded engine checks passed.'; exit 0 }
  'Status' { & $node "$engine\src\cli.mjs" status --port 9341; exit $LASTEXITCODE }
  'Pause' { & "$engine\scripts\windows\pause.ps1" -Port 9341; exit $LASTEXITCODE }
  'Restore' { & "$engine\scripts\windows\restore.ps1" -Port 9341; exit $LASTEXITCODE }
  'Apply' {
    $normalized = Convert-ThemeImage $ImagePath
    $created = & $node "$engine\src\cli.mjs" create --image $normalized --name 'Dabin Custom Skin'
    if ($LASTEXITCODE -ne 0) { throw ($created -join "`n") }
    $theme = ($created -join "`n") | ConvertFrom-Json
    if (-not $theme.id) { throw 'Theme creation did not return an ID.' }
    & "$engine\scripts\windows\apply.ps1" -Theme $theme.id -Port 9341
    if ($LASTEXITCODE -ne 0) { throw 'Theme apply failed.' }
    & $node "$engine\src\cli.mjs" status --port 9341
    exit $LASTEXITCODE
  }
}
