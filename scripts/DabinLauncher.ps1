Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$base = Split-Path -Parent $PSScriptRoot
$form = New-Object Windows.Forms.Form
$form.Text = 'Dabin One-click Codex Skin'
$form.ClientSize = New-Object Drawing.Size(620, 570)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [Drawing.Color]::FromArgb(28, 32, 36)

$title = New-Object Windows.Forms.Label
$title.Text = 'Dabin One-click Codex Skin'
$title.ForeColor = [Drawing.Color]::White
$title.Font = New-Object Drawing.Font('Segoe UI', 18, [Drawing.FontStyle]::Bold)
$title.SetBounds(28, 24, 560, 38)
$form.Controls.Add($title)

$preview = New-Object Windows.Forms.PictureBox
$preview.SetBounds(28, 88, 564, 310)
$preview.SizeMode = 'Zoom'
$preview.BackColor = [Drawing.Color]::FromArgb(15, 18, 20)
$form.Controls.Add($preview)

$status = New-Object Windows.Forms.Label
$status.Text = 'Choose an image, then apply it to Codex.'
$status.ForeColor = [Drawing.Color]::White
$status.SetBounds(28, 510, 564, 32)
$form.Controls.Add($status)

$script:selected = $null
function Show-Preview([string]$path) {
  $image = [Drawing.Image]::FromFile($path)
  try { $copy = $image.Clone() } finally { $image.Dispose() }
  if ($preview.Image) { $preview.Image.Dispose() }
  $preview.Image = $copy
}

$choose = New-Object Windows.Forms.Button
$choose.Text = 'Choose image'
$choose.SetBounds(28, 430, 178, 48)
$apply = New-Object Windows.Forms.Button
$apply.Text = 'Apply to Codex'
$apply.SetBounds(221, 430, 178, 48)
$restore = New-Object Windows.Forms.Button
$restore.Text = 'Restore native'
$restore.SetBounds(414, 430, 178, 48)
@($choose, $apply, $restore) | ForEach-Object { $_.Font = New-Object Drawing.Font('Segoe UI', 10); $form.Controls.Add($_) }

$choose.Add_Click({
  $dialog = New-Object Windows.Forms.OpenFileDialog
  $dialog.Filter = 'Images|*.png;*.jpg;*.jpeg;*.bmp;*.webp'
  if ($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
    try { Show-Preview $dialog.FileName; $script:selected = $dialog.FileName; $status.Text = 'Image selected.' }
    catch { $status.Text = 'This image cannot be read.' }
  }
  $dialog.Dispose()
})

$apply.Add_Click({
  if (-not $script:selected) { $status.Text = 'Choose an image first.'; return }
  $status.Text = 'Applying theme. Codex may restart...'
  $apply.Enabled = $false
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'dabin-skin.ps1') -Action Apply -ImagePath $script:selected
  $status.Text = if ($LASTEXITCODE -eq 0) { 'Theme applied successfully.' } else { 'Theme failed. Review the console output.' }
  $apply.Enabled = $true
})

$restore.Add_Click({
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'dabin-skin.ps1') -Action Restore
  $status.Text = if ($LASTEXITCODE -eq 0) { 'Native Codex restored.' } else { 'Restore failed.' }
})

[void]$form.ShowDialog()
if ($preview.Image) { $preview.Image.Dispose() }
$form.Dispose()
