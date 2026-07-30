param(
    [switch]$NoPause
)

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "AYRES DEV // AUDITORIA DEFENSIVA LOLBAS"

function Write-AuditHeader {
    Clear-Host
    Write-Host ""
    Write-Host "  .============================================================================." -ForegroundColor DarkGreen
    Write-Host "  | AYRES DEV 4.2.5 // DEFENSIVE LOLBAS INTELLIGENCE                         |" -ForegroundColor Green
    Write-Host "  |                                                                            |" -ForegroundColor DarkGreen
    Write-Host "  |                       .-''''''''''''-.                                     |" -ForegroundColor DarkGreen
    Write-Host "  |                    .-'   _        _   '-.                                  |" -ForegroundColor Green
    Write-Host "  |                   /     / \      / \     \                                 |" -ForegroundColor Green
    Write-Host "  |                  |     | 0 |____| 0 |     |                                |" -ForegroundColor Cyan
    Write-Host "  |                  |      \_/  /\  \_/      |                                |" -ForegroundColor Green
    Write-Host "  |                   \         /  \         /                                 |" -ForegroundColor Green
    Write-Host "  |                    '.___  _/____\_  ___.'                                  |" -ForegroundColor DarkGreen
    Write-Host "  |                         \/      \/                                          |" -ForegroundColor DarkGreen
    Write-Host "  |                                                                            |" -ForegroundColor DarkGreen
    Write-Host "  | [ MASKED BLUE TEAM ]  PROCESS SCAN // READ ONLY // SAFE LOCAL CONTROL      |" -ForegroundColor Magenta
    Write-Host "  '============================================================================'" -ForegroundColor DarkGreen
    Write-Host ""
}

# Regras originais e conservadoras. O catalogo LOLBAS e usado apenas como
# referencia defensiva; nenhum comando ofensivo do catalogo e executado.
$rules = @{
    "bitsadmin.exe"   = "(?i)(/transfer|/addfile|https?://)"
    "certutil.exe"    = "(?i)(-urlcache|-decode|-encode|https?://)"
    "cmstp.exe"       = "(?i)(/s|/au)"
    "installutil.exe" = "(?i)(/logfile=|/u)"
    "msbuild.exe"     = "(?i)(https?://|\\temp\\|\\appdata\\)"
    "mshta.exe"       = "(?i)(https?://|javascript:|vbscript:|\\temp\\|\\appdata\\)"
    "regsvr32.exe"    = "(?i)(/i:|https?://|scrobj\.dll)"
    "rundll32.exe"    = "(?i)(javascript:|https?://|\\temp\\|\\appdata\\)"
    "wmic.exe"        = "(?i)(process\s+call\s+create|/format:https?://)"
}

Write-AuditHeader
Write-Host "  [ NODE 01 ] carregando assinaturas defensivas..." -ForegroundColor DarkCyan
Write-Host "  [ NODE 02 ] consultando processos locais..." -ForegroundColor DarkCyan
Write-Host "  [ NODE 03 ] correlacionando linhas de comando..." -ForegroundColor DarkCyan
if (-not $NoPause) {
    foreach ($frame in @("[=         ]", "[====      ]", "[=======   ]", "[==========]")) {
        Write-Host ("`r  SCANNING " + $frame) -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 90
    }
    Write-Host ""
}
Write-Host ""

$alerts = @()
try {
    $processes = @(Get-CimInstance Win32_Process -ErrorAction Stop)
    foreach ($process in $processes) {
        $name = ([string]$process.Name).ToLowerInvariant()
        if (-not $rules.ContainsKey($name)) { continue }

        $commandLine = [string]$process.CommandLine
        if ([string]::IsNullOrWhiteSpace($commandLine)) { continue }
        if ($commandLine -match $rules[$name]) {
            $alerts += [pscustomobject]@{
                Name = $process.Name
                Pid = $process.ProcessId
                CommandLine = $commandLine
            }
        }
    }
} catch {
    Write-Host "  [AVISO] O Windows nao liberou as linhas de comando dos processos." -ForegroundColor Yellow
    Write-Host "  A auditoria precisa ser aberta em um PowerShell com permissao suficiente." -ForegroundColor Gray
    Write-Host "  Nenhuma alteracao foi realizada." -ForegroundColor DarkGray
    if (-not $NoPause) { [void](Read-Host "Pressione ENTER para voltar") }
    exit 0
}

if ($alerts.Count -eq 0) {
    Write-Host "  +-------------------------- SCAN RESULT ------------------------------+" -ForegroundColor DarkGreen
    Write-Host "  | RISCO: BAIXO // nenhum padrao suspeito encontrado                  |" -ForegroundColor Green
    Write-Host "  +---------------------------------------------------------------------+" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "  Isso e uma verificacao rapida, nao substitui o Microsoft Defender." -ForegroundColor DarkGray
} else {
    Write-Host "  +-------------------------- SCAN RESULT ------------------------------+" -ForegroundColor DarkYellow
    Write-Host ("  | RISCO: REVISAR // " + $alerts.Count + " processo(s) precisam de verificacao manual") -ForegroundColor Yellow
    Write-Host "  +---------------------------------------------------------------------+" -ForegroundColor DarkYellow
    Write-Host ""
    foreach ($alert in $alerts) {
        Write-Host ("  PROCESSO: " + $alert.Name + " // PID " + $alert.Pid) -ForegroundColor Yellow
        $visible = $alert.CommandLine
        if ($visible.Length -gt 180) { $visible = $visible.Substring(0, 180) + "..." }
        Write-Host ("  COMANDO : " + $visible) -ForegroundColor DarkYellow
        Write-Host "  ACAO    : confirme a origem antes de encerrar ou remover qualquer arquivo." -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host ""
Write-Host "  Referencia defensiva: https://lolbas-project.github.io/" -ForegroundColor DarkCyan
Write-Host "  O AYRES nao executou, bloqueou ou apagou nada." -ForegroundColor DarkGray
if (-not $NoPause) { [void](Read-Host "Pressione ENTER para voltar") }
