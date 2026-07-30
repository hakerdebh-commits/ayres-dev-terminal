param(
    [string]$Url = "",
    [int]$Usuarios = 0,
    [int]$DuracaoSegundos = 0,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "AYRES DEV // TESTE DE CARGA AUTORIZADO"

function Write-LoadHeader {
    Clear-Host
    Write-Host ""
    Write-Host "  .============================================================================." -ForegroundColor DarkGreen
    Write-Host "  | AYRES DEV 4.2.9 // AUTHORIZED LOAD LAB                                    |" -ForegroundColor Green
    Write-Host "  | URL PUBLICA OU LOCAL // LIMITES DE SEGURANCA // RESULTADO EM TEMPO REAL     |" -ForegroundColor DarkCyan
    Write-Host "  |                                                                            |" -ForegroundColor DarkGreen
    Write-Host "  |       [CLIENTS] ======> [HTTP GATE] ======> [TARGET] ======> [METRICS]      |" -ForegroundColor Magenta
    Write-Host "  '============================================================================'" -ForegroundColor DarkGreen
    Write-Host ""
}

function Stop-WithMessage([string]$Message) {
    Write-Host ("  " + $Message) -ForegroundColor Yellow
    if (-not $NoPause) { [void](Read-Host "Pressione ENTER para voltar") }
    exit 0
}

Write-LoadHeader
Write-Host "  Use somente em sistema seu ou quando possuir autorizacao expressa." -ForegroundColor Yellow
Write-Host "  O teste nao tenta burlar protecoes nem remover limites do servidor." -ForegroundColor DarkGray
Write-Host ""

if ([string]::IsNullOrWhiteSpace($Url)) {
    $Url = (Read-Host "URL ou IP completo [ex.: http://192.168.0.10:5173]").Trim()
}

$target = $null
if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$target) -or
    $target.Scheme -notin @("http", "https")) {
    Stop-WithMessage "URL invalida. Use http:// ou https://."
}

$isLocal = $target.Host -in @("localhost", "127.0.0.1", "::1")
$targetIp = $null
$isDirectIp = [System.Net.IPAddress]::TryParse($target.Host, [ref]$targetIp)
$maxUsers = if ($isLocal) { 500 } else { 100 }
$maxDuration = if ($isLocal) { 900 } else { 300 }
$maxRequests = if ($isLocal) { 50000 } else { 10000 }

if ($Usuarios -le 0) {
    $typed = Read-Host "Usuarios simultaneos [1-$maxUsers]"
    if (-not [int]::TryParse($typed, [ref]$Usuarios)) { Stop-WithMessage "Numero de usuarios invalido." }
}
if ($DuracaoSegundos -le 0) {
    $typed = Read-Host "Duracao em segundos [5-$maxDuration]"
    if (-not [int]::TryParse($typed, [ref]$DuracaoSegundos)) { Stop-WithMessage "Duracao invalida." }
}
if ($Usuarios -lt 1 -or $Usuarios -gt $maxUsers) {
    Stop-WithMessage "Limite para este destino: $maxUsers usuarios simultaneos."
}
if ($DuracaoSegundos -lt 5 -or $DuracaoSegundos -gt $maxDuration) {
    Stop-WithMessage "Duracao permitida para este destino: 5 a $maxDuration segundos."
}

Write-Host ""
Write-Host ("  TARGET ....... " + $target.AbsoluteUri) -ForegroundColor Cyan
Write-Host ("  TIPO ......... " + $(if ($isLocal) { "LOCAL" } else { "URL PUBLICA" })) -ForegroundColor Cyan
Write-Host ("  USUARIOS ..... " + $Usuarios) -ForegroundColor White
Write-Host ("  DURACAO ...... " + $DuracaoSegundos + " segundos") -ForegroundColor White
Write-Host ("  LIMITE ....... " + $maxRequests + " requisicoes") -ForegroundColor DarkGray
if ($isDirectIp -and $target.Scheme -eq "https") {
    Write-Host ""
    Write-Host "  [AVISO TLS] HTTPS por IP exige certificado valido para esse IP." -ForegroundColor Yellow
    Write-Host "  Se todas falharem, teste o dominio HTTPS ou a porta HTTP autorizada." -ForegroundColor DarkYellow
}
Write-Host ""

if (-not $NoPause) {
    $confirmation = Read-Host "Digite AUTORIZADO para iniciar"
    if ($confirmation -cne "AUTORIZADO") { Stop-WithMessage "Teste cancelado." }
}

if (-not ("AyresLoadLab" -as [type])) {
    Add-Type -AssemblyName System.Net.Http
    $httpAssembly = [System.Net.Http.HttpClient].Assembly.Location
    Add-Type -Language CSharp -ReferencedAssemblies $httpAssembly -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

public sealed class AyresLoadResult {
    public long Requests;
    public long Success;
    public long Failures;
    public long TotalMilliseconds;
    public long MinMilliseconds = long.MaxValue;
    public long MaxMilliseconds;
    public double ElapsedSeconds;
}

public static class AyresLoadLab {
    public static AyresLoadResult Run(string url, int workers, int durationSeconds, int maxRequests) {
        var result = new AyresLoadResult();
        var stopAt = DateTime.UtcNow.AddSeconds(durationSeconds);
        var wall = Stopwatch.StartNew();
        using (var client = new HttpClient()) {
            client.Timeout = TimeSpan.FromSeconds(10);
            client.DefaultRequestHeaders.UserAgent.ParseAdd("AYRES-DEV-Authorized-Load-Lab/4.2.9");
            var tasks = new Task[workers];
            for (int i = 0; i < workers; i++) {
                tasks[i] = Task.Run(async () => {
                    while (DateTime.UtcNow < stopAt && Interlocked.Read(ref result.Requests) < maxRequests) {
                        var sw = Stopwatch.StartNew();
                        bool ok = false;
                        try {
                            using (var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead)) {
                                ok = ((int)response.StatusCode >= 200 && (int)response.StatusCode < 400);
                            }
                        } catch { }
                        sw.Stop();
                        Interlocked.Increment(ref result.Requests);
                        if (ok) Interlocked.Increment(ref result.Success);
                        else Interlocked.Increment(ref result.Failures);
                        Interlocked.Add(ref result.TotalMilliseconds, sw.ElapsedMilliseconds);
                        UpdateMin(ref result.MinMilliseconds, sw.ElapsedMilliseconds);
                        UpdateMax(ref result.MaxMilliseconds, sw.ElapsedMilliseconds);
                    }
                });
            }
            Task.WaitAll(tasks);
        }
        wall.Stop();
        result.ElapsedSeconds = wall.Elapsed.TotalSeconds;
        if (result.MinMilliseconds == long.MaxValue) result.MinMilliseconds = 0;
        return result;
    }

    public static Task<AyresLoadResult> RunAsync(string url, int workers, int durationSeconds, int maxRequests) {
        return Task.Run(() => Run(url, workers, durationSeconds, maxRequests));
    }

    private static void UpdateMin(ref long target, long value) {
        long current;
        do {
            current = Interlocked.Read(ref target);
            if (value >= current) return;
        } while (Interlocked.CompareExchange(ref target, value, current) != current);
    }

    private static void UpdateMax(ref long target, long value) {
        long current;
        do {
            current = Interlocked.Read(ref target);
            if (value <= current) return;
        } while (Interlocked.CompareExchange(ref target, value, current) != current);
    }
}
"@
}

Write-Host ""
Write-Host "  [RUNNING] Pressione Ctrl+C para cancelar." -ForegroundColor Green
$startedAt = Get-Date
$loadTask = [AyresLoadLab]::RunAsync($target.AbsoluteUri, $Usuarios, $DuracaoSegundos, $maxRequests)
while (-not $loadTask.IsCompleted) {
    $elapsed = [int]((Get-Date) - $startedAt).TotalSeconds
    $remaining = [math]::Max(0, $DuracaoSegundos - $elapsed)
    $percent = [math]::Min(100, [math]::Round(($elapsed * 100.0) / $DuracaoSegundos))
    Write-Host ("`r  PROGRESSO ..... " + $percent.ToString().PadLeft(3) + "% // faltam ate " + $remaining + "s   ") -NoNewline -ForegroundColor Cyan
    Start-Sleep -Seconds 1
}
Write-Host ""
$result = $loadTask.GetAwaiter().GetResult()
$average = if ($result.Requests -gt 0) { [math]::Round($result.TotalMilliseconds / $result.Requests, 1) } else { 0 }
$rps = if ($result.ElapsedSeconds -gt 0) { [math]::Round($result.Requests / $result.ElapsedSeconds, 1) } else { 0 }
$successRate = if ($result.Requests -gt 0) { [math]::Round(($result.Success * 100.0) / $result.Requests, 1) } else { 0 }

Write-Host ""
Write-Host "  +---------------------------- RESULTADO --------------------------------+" -ForegroundColor DarkGreen
Write-Host ("  REQUISICOES .... " + $result.Requests) -ForegroundColor White
Write-Host ("  SUCESSO ......... " + $result.Success + " (" + $successRate + "%)") -ForegroundColor Green
Write-Host ("  FALHAS .......... " + $result.Failures) -ForegroundColor $(if ($result.Failures -gt 0) { "Yellow" } else { "Green" })
Write-Host ("  VELOCIDADE ...... " + $rps + " req/s") -ForegroundColor Cyan
Write-Host ("  TEMPO MEDIO ..... " + $average + " ms") -ForegroundColor Cyan
Write-Host ("  MIN / MAX ....... " + $result.MinMilliseconds + " / " + $result.MaxMilliseconds + " ms") -ForegroundColor DarkCyan
Write-Host "  +------------------------------------------------------------------------+" -ForegroundColor DarkGreen
Write-Host ""
if (-not $NoPause) { [void](Read-Host "Pressione ENTER para voltar") }
