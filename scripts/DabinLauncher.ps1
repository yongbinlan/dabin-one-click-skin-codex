Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$scriptRoot = $PSScriptRoot
$packageRoot = Split-Path -Parent $scriptRoot
$backgroundPath = Join-Path $packageRoot 'assets\default-launcher-background-960x720.png'
$script:selectedImage = $null
$script:connectionReady = $false

$form = New-Object Windows.Forms.Form
$form.Text = '大斌 · Codex 换肤'
$form.ClientSize = New-Object Drawing.Size(960, 720)
$form.MinimumSize = New-Object Drawing.Size(976, 759)
$form.MaximumSize = New-Object Drawing.Size(976, 759)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = [Drawing.Color]::FromArgb(244, 228, 210)
$form.ForeColor = [Drawing.Color]::FromArgb(40, 28, 24)
$form.AutoScaleMode = [Windows.Forms.AutoScaleMode]::None
$form.Font = New-Object Drawing.Font('Segoe UI', 10)

function New-Label([string]$Text, [int]$X, [int]$Y, [int]$Width, [int]$Height, [float]$Size, [Drawing.Color]$Color, [bool]$Bold = $false) {
  $label = New-Object Windows.Forms.Label
  $label.Text = $Text
  $label.SetBounds($X, $Y, $Width, $Height)
  $label.ForeColor = $Color
  $label.Font = New-Object Drawing.Font('Segoe UI', $Size, $(if ($Bold) { [Drawing.FontStyle]::Bold } else { [Drawing.FontStyle]::Regular }))
  return $label
}

function New-Button([string]$Text, [int]$X, [int]$Y, [int]$Width, [Drawing.Color]$Back, [Drawing.Color]$Fore, [bool]$Primary = $false) {
  $button = New-Object Windows.Forms.Button
  $button.Text = $Text
  $button.SetBounds($X, $Y, $Width, 44)
  $button.FlatStyle = [Windows.Forms.FlatStyle]::Flat
  $button.FlatAppearance.BorderSize = if ($Primary) { 0 } else { 1 }
  $button.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(167, 132, 112)
  $button.BackColor = $Back
  $button.ForeColor = $Fore
  $button.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
  $button.Cursor = [Windows.Forms.Cursors]::Hand
  return $button
}

if (Test-Path -LiteralPath $backgroundPath) {
  $art = New-Object Windows.Forms.PictureBox
  $art.SetBounds(0, 0, 960, 720)
  $art.SizeMode = [Windows.Forms.PictureBoxSizeMode]::StretchImage
  $art.BackColor = [Drawing.Color]::FromArgb(244, 228, 210)
  $art.Image = [Drawing.Image]::FromFile($backgroundPath)
  $form.Controls.Add($art)
}

$headerPlate = New-Object Windows.Forms.Panel
$headerPlate.SetBounds(26, 20, 362, 78)
$headerPlate.BackColor = [Drawing.Color]::FromArgb(255, 248, 237)
$form.Controls.Add($headerPlate)
$title = New-Label '大斌 · Codex 换肤' 16 11 330 31 18 ([Drawing.Color]::FromArgb(88, 34, 29)) $true
$subtitle = New-Label '选择本地图片，为当前 Codex 主界面换肤' 17 44 326 20 9 ([Drawing.Color]::FromArgb(99, 67, 54))
$rule = New-Object Windows.Forms.Panel
$rule.SetBounds(16, 67, 330, 2)
$rule.BackColor = [Drawing.Color]::FromArgb(180, 52, 43)
$headerPlate.Controls.AddRange(@($title, $subtitle, $rule))

$connectionChip = New-Object Windows.Forms.Label
$connectionChip.Text = '●  待连接'
$connectionChip.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$connectionChip.SetBounds(842, 28, 92, 30)
$connectionChip.BackColor = [Drawing.Color]::FromArgb(136, 43, 36)
$connectionChip.ForeColor = [Drawing.Color]::FromArgb(255, 248, 237)
$connectionChip.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$form.Controls.Add($connectionChip)

$workbench = New-Object Windows.Forms.Panel
$workbench.SetBounds(24, 470, 912, 226)
$workbench.BackColor = [Drawing.Color]::FromArgb(255, 248, 237)
$workbench.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($workbench)
if ($null -ne $art) {
  $art.SetBounds(0, -42, 960, 720)
  $art.SendToBack()
}

$topRule = New-Object Windows.Forms.Panel
$topRule.SetBounds(0, 0, 910, 4)
$topRule.BackColor = [Drawing.Color]::FromArgb(181, 47, 39)
$workbench.Controls.Add($topRule)
$workbench.Controls.Add((New-Label '主题工作台' 18 14 160 23 12 ([Drawing.Color]::FromArgb(61, 40, 32)) $true))
$workbench.Controls.Add((New-Label '选择图片 → 检查连接 → 应用主题' 18 37 330 18 9 ([Drawing.Color]::FromArgb(124, 82, 64))))

$previewFrame = New-Object Windows.Forms.Panel
$previewFrame.SetBounds(18, 57, 144, 112)
$previewFrame.BackColor = [Drawing.Color]::FromArgb(249, 237, 224)
$previewFrame.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$workbench.Controls.Add($previewFrame)
$preview = New-Object Windows.Forms.PictureBox
$preview.Dock = [Windows.Forms.DockStyle]::Fill
$preview.SizeMode = [Windows.Forms.PictureBoxSizeMode]::Zoom
$preview.BackColor = [Drawing.Color]::FromArgb(249, 237, 224)
$previewFrame.Controls.Add($preview)
$emptyState = New-Object Windows.Forms.Panel
$emptyState.Dock = [Windows.Forms.DockStyle]::Fill
$emptyState.BackColor = [Drawing.Color]::FromArgb(249, 237, 224)
$emptyState.Cursor = [Windows.Forms.Cursors]::Hand
$emptyState.Controls.Add((New-Label '＋' 48 16 48 38 23 ([Drawing.Color]::FromArgb(181, 47, 39))))
$emptyText = New-Label '选择主题图片' 16 57 112 19 9.5 ([Drawing.Color]::FromArgb(88, 34, 29)) $true
$emptyText.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$emptyHint = New-Label '点击开始预览' 16 79 112 16 8.5 ([Drawing.Color]::FromArgb(124, 82, 64))
$emptyHint.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$emptyState.Controls.AddRange(@($emptyText, $emptyHint))
$previewFrame.Controls.Add($emptyState)

$fileTitle = New-Label '尚未选择主题图片' 182 61 280 23 10.5 ([Drawing.Color]::FromArgb(61, 40, 32)) $true
$fileInfo = New-Label "支持 PNG、JPG/JPEG、BMP、WebP`n单张图片最大 8 MB，仅在本机使用。" 182 87 280 39 8.7 ([Drawing.Color]::FromArgb(124, 82, 64))
$choose = New-Button '选择图片' 182 135 260 ([Drawing.Color]::FromArgb(255, 248, 237)) ([Drawing.Color]::FromArgb(126, 42, 35))
$choose.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(153, 57, 48)
$workbench.Controls.AddRange(@($fileTitle, $fileInfo, $choose))

$check = New-Button '检查连接' 490 74 180 ([Drawing.Color]::FromArgb(255, 248, 237)) ([Drawing.Color]::FromArgb(126, 42, 35))
$check.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(153, 57, 48)
$apply = New-Button '应用到 Codex' 684 74 204 ([Drawing.Color]::FromArgb(181, 47, 39)) ([Drawing.Color]::FromArgb(255, 248, 237)) $true
$apply.Enabled = $false
$apply.BackColor = [Drawing.Color]::FromArgb(220, 190, 171)
$apply.ForeColor = [Drawing.Color]::FromArgb(113, 78, 62)
$actionInfo = New-Label "连接成功后才可应用主题。`n不会改写 Codex 程序文件。" 490 130 398 38 8.8 ([Drawing.Color]::FromArgb(124, 82, 64))
$workbench.Controls.AddRange(@($check, $apply, $actionInfo))

$statusBar = New-Object Windows.Forms.Panel
$statusBar.SetBounds(18, 180, 876, 32)
$statusBar.BackColor = [Drawing.Color]::FromArgb(248, 231, 215)
$workbench.Controls.Add($statusBar)
$statusDot = New-Object Windows.Forms.Label
$statusDot.Text = '●'
$statusDot.SetBounds(13, 6, 16, 20)
$statusDot.ForeColor = [Drawing.Color]::FromArgb(181, 47, 39)
$statusBar.Controls.Add($statusDot)
$status = New-Label '下一步：选择一张图片开始。' 34 6 670 20 9.2 ([Drawing.Color]::FromArgb(88, 34, 29))
$status.AutoEllipsis = $true
$statusBar.Controls.Add($status)
$restore = New-Button '恢复原生' 744 -1 120 ([Drawing.Color]::FromArgb(248, 231, 215)) ([Drawing.Color]::FromArgb(153, 57, 48))
$restore.Height = 32
$restore.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(190, 111, 99)
$statusBar.Controls.Add($restore)
function Set-ApplyEnabled([bool]$Enabled) {
  $apply.Enabled = $Enabled
  if ($Enabled) {
    $apply.BackColor = [Drawing.Color]::FromArgb(181, 47, 39)
    $apply.ForeColor = [Drawing.Color]::FromArgb(255, 248, 237)
  } else {
    $apply.BackColor = [Drawing.Color]::FromArgb(220, 190, 171)
    $apply.ForeColor = [Drawing.Color]::FromArgb(113, 78, 62)
  }
}

function Set-Status([string]$Text, [string]$Kind = 'ready') {
  $status.Text = $Text
  switch ($Kind) {
    'working' { $statusDot.ForeColor = [Drawing.Color]::FromArgb(212, 155, 57); $connectionChip.Text = '●  检测中'; $connectionChip.ForeColor = [Drawing.Color]::FromArgb(255, 232, 182) }
    'error' { $statusDot.ForeColor = [Drawing.Color]::FromArgb(229, 138, 125); $connectionChip.Text = '●  需检查'; $connectionChip.ForeColor = [Drawing.Color]::FromArgb(255, 205, 198) }
    'connected' { $statusDot.ForeColor = [Drawing.Color]::FromArgb(94, 155, 120); $connectionChip.Text = '●  已连接'; $connectionChip.ForeColor = [Drawing.Color]::FromArgb(200, 238, 212) }
    'applied' { $statusDot.ForeColor = [Drawing.Color]::FromArgb(94, 155, 120); $connectionChip.Text = '●  已应用'; $connectionChip.ForeColor = [Drawing.Color]::FromArgb(200, 238, 212) }
    default { $statusDot.ForeColor = [Drawing.Color]::FromArgb(216, 194, 177); $connectionChip.Text = '●  待连接'; $connectionChip.ForeColor = [Drawing.Color]::FromArgb(255, 246, 237) }
  }
  [Windows.Forms.Application]::DoEvents()
}

function Show-Preview([string]$Path) {
  $image = [Drawing.Image]::FromFile($Path)
  try { $copy = $image.Clone() } finally { $image.Dispose() }
  if ($preview.Image) { $preview.Image.Dispose() }
  $preview.Image = $copy
  $emptyState.Visible = $false
}

function Invoke-Engine([string]$Action, [string]$Path = $null) {
  $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $scriptRoot 'dabin-skin.ps1'), '-Action', $Action)
  if ($Path) { $arguments += @('-ImagePath', $Path) }
  $result = & powershell.exe @arguments 2>&1 | Out-String
  return @{ ExitCode = $LASTEXITCODE; Output = $result.Trim() }
}

function Select-ThemeImage {
  $dialog = New-Object Windows.Forms.OpenFileDialog
  $dialog.Title = '选择 Codex 主题图片'
  $dialog.Filter = '图片文件|*.png;*.jpg;*.jpeg;*.bmp;*.webp'
  $dialog.Multiselect = $false
  if ($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
    try {
      Show-Preview $dialog.FileName
      $script:selectedImage = $dialog.FileName
      $script:connectionReady = $false
      $size = [Math]::Round((Get-Item -LiteralPath $dialog.FileName).Length / 1MB, 2)
      $fileTitle.Text = [IO.Path]::GetFileName($dialog.FileName)
      $fileInfo.Text = "$size MB  ·  图片已准备好`n下一步：检查 Codex 主窗口连接。"
      Set-ApplyEnabled $false
      Set-Status '图片已准备好。下一步请检查 Codex 主窗口连接。' 'ready'
    } catch { Set-Status "无法读取这张图片：$($_.Exception.Message)" 'error' }
  }
  $dialog.Dispose()
}

$choose.Add_Click({ Select-ThemeImage })
$emptyState.Add_Click({ Select-ThemeImage })
$emptyText.Add_Click({ Select-ThemeImage })
$emptyHint.Add_Click({ Select-ThemeImage })

$check.Add_Click({
  $check.Enabled = $false
  Set-ApplyEnabled $false
  Set-Status '正在检查 Codex 主窗口连接…' 'working'
  $result = Invoke-Engine 'Check'
  $check.Enabled = $true
  if ($result.ExitCode -eq 0) {
    $script:connectionReady = $true
    if ($script:selectedImage) { Set-ApplyEnabled $true }
    Set-Status '连接正常：已发现 Codex 主窗口，可以应用主题。' 'connected'
  } else {
    $script:connectionReady = $false
    Set-Status ($result.Output -replace '\s+', ' ') 'error'
  }
})

$apply.Add_Click({
  if (-not $script:selectedImage) { Set-Status '请先选择一张主题图片。' 'error'; return }
  if (-not $script:connectionReady) { Set-Status '请先检查 Codex 主窗口连接。' 'error'; return }
  $check.Enabled = $false
  Set-ApplyEnabled $false
  Set-Status '正在注入主题并启动本地控制器…' 'working'
  $result = Invoke-Engine 'Apply' $script:selectedImage
  $check.Enabled = $true
  if ($result.ExitCode -eq 0) {
    Set-ApplyEnabled $true
    Set-Status '已应用。请回到 Codex 检查背景与文字对比度。' 'applied'
  } else {
    $script:connectionReady = $false
    Set-Status ($result.Output -replace '\s+', ' ') 'error'
  }
})

$restore.Add_Click({
  $check.Enabled = $false
  Set-ApplyEnabled $false
  Set-Status '正在移除当前主题…' 'working'
  $result = Invoke-Engine 'Restore'
  $check.Enabled = $true
  $script:connectionReady = $false
  if ($result.ExitCode -eq 0) { Set-Status '已恢复原生界面。需要再次检查连接后才能应用。' 'ready' }
  else { Set-Status ($result.Output -replace '\s+', ' ') 'error' }
})

$form.Add_FormClosed({
  if ($preview.Image) { $preview.Image.Dispose() }
  if ($art -and $art.Image) { $art.Image.Dispose() }
})
[void]$form.ShowDialog()
$form.Dispose()
