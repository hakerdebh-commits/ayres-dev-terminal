# AYRES DEV TERMINAL 4.2.5 - launcher PowerShell, ASCII-only.
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'AYRES DEV TERMINAL 4.2.5'
$core = Join-Path $PSScriptRoot 'AyresDev.ps1'
$profileInstaller = Join-Path $PSScriptRoot 'Instalar-Perfil-Ayres.ps1'
$lolbasAudit = Join-Path $PSScriptRoot 'Verificar-LOLBAS.ps1'

function Header {
  Clear-Host
  Write-Host '  .--------------------------------------------------------.' -ForegroundColor DarkGreen
  Write-Host '  |   _   _   _   _   _   _   _   _   _   _   _   _       |' -ForegroundColor Green
  Write-Host '  |  / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \ / \      |' -ForegroundColor Green
  Write-Host '  | ( A | Y | R | E | S | - | 4 | . | 2 | . | 5 )        |' -ForegroundColor Cyan
  Write-Host '  |  \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/      |' -ForegroundColor Green
  Write-Host '  |                                                        |' -ForegroundColor DarkGreen
  Write-Host '  |           [ MASKED OPERATOR TERMINAL ]                 |' -ForegroundColor Magenta
  Write-Host '  |              .-""-.     .-""-.                         |' -ForegroundColor Green
  Write-Host '  |             /  o o  \___/  o o  \                        |' -ForegroundColor Green
  Write-Host '  |             \     /  _  \     /                        |' -ForegroundColor Green
  Write-Host '  |              `---/__/ \__\---`                         |' -ForegroundColor Green
  Write-Host '  |    PROJECTS // CODEX // GIT // SAFE LOCAL CONTROL      |' -ForegroundColor DarkCyan
  Write-Host '  `--------------------------------------------------------`' -ForegroundColor DarkGreen
  Write-Host ''
}
function Pause-Here { [void](Read-Host 'Pressione ENTER para voltar') }
function Existing-Folder([string]$prompt) {
  $value=(Read-Host $prompt).Trim().Trim('"')
  if([string]::IsNullOrWhiteSpace($value)){Write-Host 'Nenhuma pasta informada.' -ForegroundColor Yellow;return $null}
  if(-not(Test-Path -LiteralPath $value -PathType Container)){Write-Host 'Pasta nao encontrada.' -ForegroundColor Yellow;return $null}
  return (Resolve-Path -LiteralPath $value).Path
}
function Open-Codex([string]$folder) {
  if(-not(Get-Command codex -ErrorAction SilentlyContinue)){Write-Host 'Codex nao encontrado. Use [1] e depois [I] para preparar este PC.' -ForegroundColor Yellow;Pause-Here;return}
  Set-Location -LiteralPath $folder
  codex
}
function New-Project {
  $parent=Existing-Folder 'Cole a pasta onde o projeto sera criado'
  if(-not $parent){Pause-Here;return}
  $name=(Read-Host 'Nome do projeto').Trim()
  $safe=($name -replace '[^a-zA-Z0-9_-]','-').Trim('-')
  if([string]::IsNullOrWhiteSpace($safe)){Write-Host 'Nome invalido.' -ForegroundColor Yellow;Pause-Here;return}
  $target=Join-Path $parent $safe
  if(Test-Path -LiteralPath $target){Write-Host 'Essa pasta ja existe.' -ForegroundColor Yellow;Pause-Here;return}
  if((Read-Host "Criar $target e iniciar Git? (S/N)") -notmatch '^[sS]$'){return}
  New-Item -ItemType Directory -Path $target | Out-Null
  Set-Content -LiteralPath (Join-Path $target 'README.md') -Value "# $name`n`nProjeto criado pelo AYRES DEV 4.2." -Encoding utf8
  Push-Location $target;try{git init | Out-Host}finally{Pop-Location}
  Write-Host 'Projeto criado. Abra [1] para configurar, trabalhar e publicar.' -ForegroundColor Green
  Pause-Here
}

do {
  Header
  Write-Host '[1] Entrar no painel completo AYRES DEV 4.2.5' -ForegroundColor Green
  Write-Host '    Painel Ayres e Site Adriana, Workbench, servidor, testes e GitHub.' -ForegroundColor DarkGray
  Write-Host '[2] Abrir somente Codex em uma pasta' -ForegroundColor Green
  Write-Host '[3] Criar novo projeto Git local' -ForegroundColor Green
  Write-Host '[4] Instalar tela AYRES ao abrir o PowerShell' -ForegroundColor Magenta
  Write-Host '[5] Remover tela AYRES do PowerShell' -ForegroundColor DarkMagenta
  Write-Host '[6] Abrir terminal livre na pasta do AYRES DEV' -ForegroundColor Cyan
  Write-Host '[7] Auditoria defensiva LOLBAS (somente leitura)' -ForegroundColor Yellow
  Write-Host '[0] Sair' -ForegroundColor DarkGray
  $choice=Read-Host 'Escolha uma opcao'
  switch($choice){
    '1' { & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $core -Mode Dashboard }
    '2' { $folder=Existing-Folder 'Cole o caminho da pasta';if($folder){Open-Codex $folder}else{Pause-Here} }
    '3' { New-Project }
    '4' {
      if((Read-Host 'Personalizar o PowerShell deste usuario? (S/N)') -match '^[sS]$'){
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $profileInstaller -Action Install
      }
      Pause-Here
    }
    '5' {
      if((Read-Host 'Remover somente a tela inicial AYRES? (S/N)') -match '^[sS]$'){
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $profileInstaller -Action Remove
      }
      Pause-Here
    }
    '6' {
      Write-Host ('Abrindo terminal em: ' + $PSScriptRoot) -ForegroundColor Green
      Start-Process powershell.exe -WorkingDirectory $PSScriptRoot -ArgumentList '-NoExit'
      Pause-Here
    }
    '7' {
      & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $lolbasAudit
    }
    '0' { break }
    default { Write-Host 'Opcao invalida.' -ForegroundColor Yellow;Start-Sleep -Seconds 1 }
  }
}while($choice -ne '0')
