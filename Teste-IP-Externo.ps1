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
Write-Host "  | AYRES DEV 4.3.0 // IP-ONLY EXTERNAL TEST                                  |" -ForegroundColor Green
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

function Test-WebPort([System.Net.IPAddress]$Ip, [int]$Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $attempt = $client.BeginConnect($Ip, $Port, $null, $null)
        return $attempt.AsyncWaitHandle.WaitOne(2500, $false) -and $client.Connected
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

Write-Host ""
Write-Host "  Verificando automaticamente as portas web 80 e 443..." -ForegroundColor DarkCyan
$httpOpen = Test-WebPort -Ip $address -Port 80
$httpsOpen = Test-WebPort -Ip $address -Port 443

if ($httpOpen) {
    $protocol = "HTTP"
    $port = 80
} elseif ($httpsOpen) {
    $protocol = "HTTPS"
    $port = 443
} else {
    Stop-ExternalTest "As portas 80 e 443 nao responderam. O servidor nao esta acessivel nesse IP."
}

$url = $protocol.ToLowerInvariant() + "://" + $address.IPAddressToString + ":" + $port + "/"
Write-Host ""
Write-Host ("  HTTP:80 ...... " + $(if ($httpOpen) { "ABERTA" } else { "SEM RESPOSTA" })) -ForegroundColor $(if ($httpOpen) { "Green" } else { "DarkYellow" })
Write-Host ("  HTTPS:443 .... " + $(if ($httpsOpen) { "ABERTA" } else { "SEM RESPOSTA" })) -ForegroundColor $(if ($httpsOpen) { "Green" } else { "DarkYellow" })
Write-Host ("  Destino externo preparado: " + $url) -ForegroundColor Cyan
Write-Host "  A confirmacao final aparecera na proxima tela." -ForegroundColor DarkGray
Start-Sleep -Milliseconds 700

& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot "Teste-Carga.ps1") -Url $url
