param(
  [ValidateSet('Install','Remove')]
  [string]$Action = 'Install'
)

$ErrorActionPreference = 'Stop'
$profilePath = [string]$PROFILE.CurrentUserAllHosts
$startMarker = '# >>> AYRES DEV TERMINAL >>>'
$endMarker = '# <<< AYRES DEV TERMINAL <<<'
$block = @'
# >>> AYRES DEV TERMINAL >>>
if ($Host.Name -eq 'ConsoleHost') {
  Write-Host ''
  Write-Host '  .------------------------------------------------------.' -ForegroundColor DarkGreen
  Write-Host '  |          AYRES DEV // MASKED TERMINAL               |' -ForegroundColor Green
  Write-Host '  |       LOCAL SYSTEM // CODEX // GIT // READY         |' -ForegroundColor DarkCyan
  Write-Host '  `------------------------------------------------------`' -ForegroundColor DarkGreen
  Write-Host ('  OPERATOR: ' + $env:USERNAME + '  //  ' + (Get-Date -Format 'dd/MM/yyyy HH:mm')) -ForegroundColor DarkGray
  Write-Host ''
}
# <<< AYRES DEV TERMINAL <<<
'@

$current = if (Test-Path -LiteralPath $profilePath) {
  Get-Content -LiteralPath $profilePath -Raw
} else {
  ''
}

$pattern = '(?s)\r?\n?' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker) + '\r?\n?'
$clean = [regex]::Replace($current, $pattern, [Environment]::NewLine).TrimEnd()

if ($Action -eq 'Remove') {
  if (Test-Path -LiteralPath $profilePath) {
    Set-Content -LiteralPath $profilePath -Value $clean -Encoding utf8
  }
  Write-Host 'Tela inicial AYRES removida do PowerShell.' -ForegroundColor Green
  exit 0
}

$parent = Split-Path -Parent $profilePath
if (-not (Test-Path -LiteralPath $parent)) {
  New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
if (Test-Path -LiteralPath $profilePath) {
  $backup = $profilePath + '.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
  Copy-Item -LiteralPath $profilePath -Destination $backup
  Write-Host ('Backup criado: ' + $backup) -ForegroundColor DarkGray
}
$newContent = if ($clean) {
  $clean + [Environment]::NewLine + [Environment]::NewLine + $block
} else {
  $block
}
Set-Content -LiteralPath $profilePath -Value $newContent -Encoding utf8
Write-Host 'Tela inicial AYRES instalada no perfil deste usuario.' -ForegroundColor Green
Write-Host 'Abra um novo PowerShell para conferir.' -ForegroundColor Cyan
