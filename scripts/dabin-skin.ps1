param(
  [ValidateSet('Check','Apply','Status','Pause','Restore')][string]$Action = 'Check',
  [string]$ImagePath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cli = Join-Path $root 'src\codex-skin.mjs'
$node = (Get-Command node.exe -ErrorAction Stop).Source

function Assert-Requirements {
  if (-not [Environment]::Is64BitOperatingSystem -or -not [Environment]::Is64BitProcess) {
    throw '请使用 64 位 Windows PowerShell 运行此启动器。'
  }
  if (-not (Test-Path -LiteralPath $cli)) { throw '原创换肤引擎文件缺失：src\codex-skin.mjs。' }
  $major = [int]((& $node --version).Trim().TrimStart('v').Split('.')[0])
  if ($major -lt 22) { throw '需要 Node.js 22 或更高版本。' }
}

function Invoke-Skin([string[]]$Arguments) {
  & $node $cli @Arguments
  if ($LASTEXITCODE -ne 0) { throw '换肤引擎未完成操作。请查看上方具体错误。' }
}

Assert-Requirements
switch ($Action) {
  'Check'   { Invoke-Skin @('check') }
  'Status'  { Invoke-Skin @('status') }
  'Pause'   { Invoke-Skin @('pause') }
  'Restore' { Invoke-Skin @('restore') }
  'Apply' {
    if ([string]::IsNullOrWhiteSpace($ImagePath)) { throw '请提供 -ImagePath 图片绝对路径。' }
    Invoke-Skin @('apply', $ImagePath)
  }
}
