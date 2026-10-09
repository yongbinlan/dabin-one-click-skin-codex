# Local launcher preference only; importing this file never applies a theme.
function Get-LauncherImagePath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { throw '图片路径为空。' }
  $item = Get-Item -LiteralPath $Path -ErrorAction Stop
  if ($item.PSIsContainer -or $item.Extension.ToLowerInvariant() -notin @('.png','.jpg','.jpeg','.bmp','.webp')) { throw '请选择 PNG、JPG、BMP 或 WebP 图片。' }
  if ($item.Length -gt 8MB) { throw '图片不能超过 8 MB。' }
  return $item.FullName
}
function Save-LauncherSelection([string]$StorePath, [string]$ImagePath) {
  $fullPath = Get-LauncherImagePath $ImagePath
  $directory = Split-Path -Parent $StorePath
  [void][IO.Directory]::CreateDirectory($directory)
  $temporary = $StorePath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
  try {
    $json = @{ schemaVersion = 1; imagePath = $fullPath } | ConvertTo-Json
    [IO.File]::WriteAllText($temporary, $json, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporary -Destination $StorePath -Force -ErrorAction Stop
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
  }
}
function Read-LauncherSelection([string]$StorePath) {
  if (-not (Test-Path -LiteralPath $StorePath -PathType Leaf)) { return $null }
  $saved = [IO.File]::ReadAllText($StorePath) | ConvertFrom-Json -ErrorAction Stop
  if ($saved.schemaVersion -ne 1 -or $saved.imagePath -isnot [string]) { throw '选图记录格式无效。' }
  return Get-LauncherImagePath $saved.imagePath
}
