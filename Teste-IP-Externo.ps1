$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "AYRES DEV // TESTE DE IP EXTERNO"

function Stop-ExternalTest([string]$Message) {
    Write-Host ""
    Write-Host ("  " + $Message) -ForegroundColor Yellow
    [void](Read-Host "Pressione ENTER para voltar")
    exit 0
}

Clear-Host
Write-Host ""
Write-Host "  .============================================================================." -ForegroundColor DarkGreen
Write-Host "  | AYRES DEV 4.2.8 // EXTERNAL IP TEST GATE                                  |" -ForegroundColor Green
Write-Host "  | OUTRA INTERNET ======> IP PUBLICO:PORTA ======> SEU SERVIDOR                |" -ForegroundColor Magenta
Write-Host "  '============================================================================'" -ForegroundColor DarkGreen
Write-Host ""
Write-Host "  Execute esta opcao em um PC conectado a OUTRA internet." -ForegroundColor Yellow
Write-Host "  Ela testa somente o servidor HTTP informado, nao o roteador inteiro." -ForegroundColor Gray
Write-Host "  O AYRES nao abre portas, nao altera firewall e nao descobre senhas." -ForegroundColor DarkGray
Write-Host ""

$ipText = (Read-Host "IP publico IPv4 do seu servidor").Trim()
$address = $null
if (-not [System.Net.IPAddress]::TryParse($ipText, [ref]$address) -or
    $address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
    Stop-ExternalTest "Informe um IPv4 publico valido."
}

$bytes = $address.GetAddressBytes()
$isPrivate = (
    $bytes[0] -eq 10 -or
    ($bytes[0] -eq 172 -and $bytes[1] -ge 16 -and $bytes[1] -le 31) -or
    ($bytes[0] -eq 192 -and $bytes[1] -eq 168) -or
    ($bytes[0] -eq 100 -and $bytes[1] -ge 64 -and $bytes[1] -le 127) -or
    $bytes[0] -eq 127 -or
    ($bytes[0] -eq 169 -and $bytes[1] -eq 254) -or
    $bytes[0] -eq 0 -or
    $bytes[0] -ge 224
)
if ($isPrivate) {
    Stop-ExternalTest "Esse e um IP local/privado. Esta opcao exige o IP publico."
}

$portText = (Read-Host "Porta do servidor [80]").Trim()
if ([string]::IsNullOrWhiteSpace($portText)) { $portText = "80" }
$port = 0
if (-not [int]::TryParse($portText, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
    Stop-ExternalTest "Porta invalida. Use um numero entre 1 e 65535."
}

$protocolInput = (Read-Host "Protocolo: [1] HTTP  [2] HTTPS").Trim().ToUpperInvariant()
switch ($protocolInput) {
    ""      { $protocol = if ($port -eq 443) { "HTTPS" } else { "HTTP" } }
    "1"     { $protocol = "HTTP" }
    "HTTP"  { $protocol = "HTTP" }
    "80"    { $protocol = "HTTP"; $port = 80 }
    "2"     { $protocol = "HTTPS" }
    "HTTPS" { $protocol = "HTTPS" }
    "443"   { $protocol = "HTTPS"; $port = 443 }
    default { Stop-ExternalTest "Opcao invalida. Digite 1 para HTTP ou 2 para HTTPS." }
}

$url = $protocol.ToLowerInvariant() + "://" + $address.IPAddressToString + ":" + $port + "/"
Write-Host ""
Write-Host ("  Destino externo preparado: " + $url) -ForegroundColor Cyan
Write-Host "  A confirmacao final aparecera na proxima tela." -ForegroundColor DarkGray
Start-Sleep -Milliseconds 700

& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot "Teste-Carga.ps1") -Url $url
