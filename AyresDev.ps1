param(
    [ValidateSet("Dashboard", "DevServer", "Codex", "SelfTest")]
    [string]$Mode = "Dashboard",
    [string]$ProjectPath = "",
    [string]$LogPath = ""
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
$script:Version = "4.2.9"
$script:Root = $PSScriptRoot
$script:LolbasAudit = Join-Path $script:Root "Verificar-LOLBAS.ps1"
$script:LoadTest = Join-Path $script:Root "Teste-Carga.ps1"
$script:ConfigFile = Join-Path $script:Root "projetos.json"
$script:StateRoot = if ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA "AyresDev"
} else {
    Join-Path $env:USERPROFILE ".ayresdev"
}
$script:PathsRoot = Join-Path $script:StateRoot "paths"
$script:LogsRoot = Join-Path $script:StateRoot "logs"
$script:WorkspacesRoot = Join-Path $script:StateRoot "workspaces"
$script:CurrentProject = $null
$script:CurrentPath = $null
$script:LastNotice = ""
$script:LastNoticeColor = "DarkGray"

function Test-App {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-ShellExecutable {
    if (Test-App "pwsh.exe") { return "pwsh.exe" }
    if (Test-App "pwsh") { return "pwsh" }
    return "powershell.exe"
}

function Initialize-State {
    foreach ($folder in @($script:StateRoot, $script:PathsRoot, $script:LogsRoot, $script:WorkspacesRoot)) {
        if (-not (Test-Path -LiteralPath $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
}

function Get-PackageManager {
    param([string]$Path)
    if (Test-Path -LiteralPath (Join-Path $Path "pnpm-lock.yaml")) {
        if (Test-App "pnpm") { return "pnpm" }
        if (Test-App "corepack") { return "corepack pnpm" }
    }
    if (Test-Path -LiteralPath (Join-Path $Path "yarn.lock")) {
        if (Test-App "yarn") { return "yarn" }
        if (Test-App "corepack") { return "corepack yarn" }
    }
    if (((Test-Path -LiteralPath (Join-Path $Path "bun.lockb")) -or
        (Test-Path -LiteralPath (Join-Path $Path "bun.lock"))) -and (Test-App "bun")) {
        return "bun"
    }
    return "npm"
}

function Invoke-PackageManager {
    param(
        [string]$Manager,
        [string[]]$Arguments
    )
    $parts = @($Manager -split " ")
    $command = $parts[0]
    $prefix = @($parts | Select-Object -Skip 1)
    & $command @prefix @Arguments
}

function Get-NpmScripts {
    param([string]$Path)
    $packageFile = Join-Path $Path "package.json"
    if (-not (Test-Path -LiteralPath $packageFile)) { return @() }
    try {
        $package = Get-Content -LiteralPath $packageFile -Raw | ConvertFrom-Json
        if (-not $package.scripts) { return @() }
        return @($package.scripts.PSObject.Properties.Name)
    } catch {
        return @()
    }
}

function Invoke-PackageScript {
    param(
        [string]$Path,
        [string]$ScriptName
    )
    $manager = Get-PackageManager -Path $Path
    Push-Location -LiteralPath $Path
    try {
        Invoke-PackageManager -Manager $manager -Arguments @("run", $ScriptName)
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

function Write-RunnerLog {
    param([string]$Text)
    $stamp = Get-Date -Format "HH:mm:ss"
    $line = "[$stamp] $Text"
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Start-DevRunner {
    if ([string]::IsNullOrWhiteSpace($ProjectPath) -or [string]::IsNullOrWhiteSpace($LogPath)) {
        throw "Projeto ou arquivo de log nao informado."
    }
    Set-Location -LiteralPath $ProjectPath
    $scripts = @(Get-NpmScripts -Path $ProjectPath)
    if ($scripts -notcontains "dev") {
        Write-RunnerLog "O package.json nao possui o comando dev."
        exit 2
    }
    $manager = Get-PackageManager -Path $ProjectPath
    Write-RunnerLog "Servidor iniciado com: $manager run dev"
    try {
    Invoke-PackageManager -Manager $manager -Arguments @("run", "dev") 2>&1 | ForEach-Object {
            $text = $_.ToString()
            Write-Host $text
            Add-Content -LiteralPath $LogPath -Value $text -Encoding UTF8
        }
        exit $LASTEXITCODE
    } catch {
        Write-RunnerLog ("ERRO: " + $_.Exception.Message)
        exit 1
    }
}

function Start-CodexRunner {
    if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
        throw "Projeto nao informado."
    }
    Set-Location -LiteralPath $ProjectPath
    $Host.UI.RawUI.WindowTitle = "AYRES DEV // CODEX // " + (Split-Path $ProjectPath -Leaf)
    Clear-Host
    Write-Host ""
    Write-Host "  AYRES DEV // CODEX LOCAL" -ForegroundColor Magenta
    Write-Host "  Projeto: $ProjectPath" -ForegroundColor DarkCyan
    Write-Host "  Descreva em portugues o que deseja criar ou corrigir." -ForegroundColor Gray
    Write-Host ""
    & codex --cd $ProjectPath --sandbox workspace-write --ask-for-approval on-request
}

if ($Mode -eq "DevServer") {
    Initialize-State
    Start-DevRunner
    exit
}

if ($Mode -eq "Codex") {
    Start-CodexRunner
    exit
}

function Set-Notice {
    param(
        [string]$Text,
        [string]$Color = "DarkGray"
    )
    $script:LastNotice = $Text
    $script:LastNoticeColor = $Color
}

function Pause-Ayres {
    Write-Host ""
    Write-Host "Pressione qualquer tecla para voltar..." -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
}

function Get-Projects {
    if (-not (Test-Path -LiteralPath $script:ConfigFile)) {
        throw "Arquivo projetos.json nao encontrado."
    }
    try {
        $config = Get-Content -LiteralPath $script:ConfigFile -Raw | ConvertFrom-Json
    } catch {
        throw "projetos.json invalido: $($_.Exception.Message)"
    }
    $projects = @($config.projects)
    if ($projects.Count -eq 0) { throw "Nenhum projeto configurado em projetos.json." }
    foreach ($project in $projects) {
        if (-not $project.id -or -not $project.name -or -not $project.folders) {
            throw "Projeto incompleto em projetos.json. Campos obrigatorios: id, name e folders."
        }
    }
    return $projects
}

function Save-Projects {
    param([object[]]$Projects)
    $config = [ordered]@{
        version = 1
        projects = @($Projects)
    }
    $config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $script:ConfigFile -Encoding UTF8
}

function New-ProjectFromUrl {
    if (-not (Test-App "git")) {
        Set-Notice "Git nao instalado. Use [I] PREPARAR PC." "Red"
        return $null
    }

    Clear-Host
    Write-Host ""
    Write-Host "  NOVO PROJETO // IMPORTAR DO GITHUB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Cole a URL HTTPS do repositorio." -ForegroundColor Gray
    Write-Host "  Exemplo: https://github.com/usuario/meu-projeto.git" -ForegroundColor DarkGray
    Write-Host ""
    $url = (Read-Host "URL").Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        Set-Notice "Importacao cancelada." "DarkGray"
        return $null
    }

    $match = [regex]::Match($url, '^https://github\.com/([^/]+)/([^/#?]+?)(?:\.git)?/?$',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) {
        Set-Notice "URL invalida. Use uma URL HTTPS de repositorio do GitHub." "Red"
        Pause-Ayres
        return $null
    }

    $repoName = $match.Groups[2].Value -replace '\.git$', ''
    $displayName = Read-Host "Nome no painel [$repoName]"
    if ([string]::IsNullOrWhiteSpace($displayName)) { $displayName = $repoName }
    $idBase = (($repoName.ToLowerInvariant() -replace '[^a-z0-9-]+', '-') -replace '^-|-$', '')
    if (-not $idBase) { $idBase = "projeto" }
    $projects = @(Get-Projects)
    $id = $idBase
    $suffix = 2
    while (@($projects | Where-Object { $_.id -eq $id }).Count -gt 0) {
        $id = "$idBase-$suffix"
        $suffix++
    }

    $project = [pscustomobject][ordered]@{
        id = $id
        name = $displayName
        description = "Projeto importado do GitHub"
        repository = $url
        folders = @($repoName)
        defaultUrl = "http://localhost:5173"
        color = "Cyan"
    }
    Save-Projects -Projects @($projects + $project)
    $path = Clone-Project -Project $project
    if (-not $path) {
        Save-Projects -Projects $projects
        return $null
    }
    Save-ProjectPath -Project $project -Path $path
    Set-Notice "Projeto importado e adicionado ao painel." "Green"
    return $project
}

function Test-ProjectFolder {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }
    return (Test-Path -LiteralPath (Join-Path $Path "package.json") -PathType Leaf)
}

function Get-SavedProjectPath {
    param($Project)
    $file = Join-Path $script:PathsRoot ($Project.id + ".txt")
    if (-not (Test-Path -LiteralPath $file)) { return $null }
    $path = (Get-Content -LiteralPath $file -Raw).Trim()
    if (Test-ProjectFolder -Path $path) { return $path }
    return $null
}

function Save-ProjectPath {
    param($Project, [string]$Path)
    $file = Join-Path $script:PathsRoot ($Project.id + ".txt")
    (Resolve-Path -LiteralPath $Path).Path | Set-Content -LiteralPath $file -Encoding UTF8
}

function Find-ProjectPath {
    param($Project)
    $roots = @(
        (Join-Path $env:USERPROFILE "Documents\AyresDev\Projetos"),
        (Join-Path $env:USERPROFILE "Documents\Projetos"),
        (Join-Path $env:USERPROFILE "Documents"),
        (Join-Path $env:USERPROFILE "Desktop"),
        (Join-Path $env:USERPROFILE "source\repos"),
        "C:\Projetos",
        "C:\Dev"
    )
    foreach ($root in $roots) {
        foreach ($folder in @($Project.folders)) {
            $candidate = Join-Path $root $folder
            if (Test-ProjectFolder -Path $candidate) {
                return (Resolve-Path -LiteralPath $candidate).Path
            }
        }
    }
    return $null
}

function Select-ProjectFolder {
    param($Project)
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Escolha a pasta do projeto " + $Project.name
        $dialog.ShowNewFolderButton = $false
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $dialog.SelectedPath
        }
    } catch {
        Set-Notice "Nao foi possivel abrir o seletor de pastas." "Yellow"
    }
    return $null
}

function Clone-Project {
    param($Project)
    if (-not (Test-App "git")) {
        Set-Notice "Git nao instalado. Use [I] PREPARAR PC." "Red"
        return $null
    }
    $base = Join-Path $env:USERPROFILE "Documents\AyresDev\Projetos"
    if (-not (Test-Path -LiteralPath $base)) {
        New-Item -ItemType Directory -Path $base -Force | Out-Null
    }
    $target = Join-Path $base $Project.folders[0]
    if (Test-Path -LiteralPath $target) {
        return $target
    }
    Clear-Host
    Write-Host "Baixando $($Project.name) do GitHub..." -ForegroundColor Cyan
    & git clone $Project.repository $target
    if (($LASTEXITCODE -eq 0) -and (Test-Path -LiteralPath $target)) {
        return $target
    }
    Set-Notice "Falha ao baixar o projeto. Confira o acesso ao GitHub." "Red"
    Pause-Ayres
    return $null
}

function Resolve-ProjectPath {
    param($Project)
    $saved = Get-SavedProjectPath -Project $Project
    if ($saved) { return $saved }
    $found = Find-ProjectPath -Project $Project
    if ($found) {
        Save-ProjectPath -Project $Project -Path $found
        return $found
    }

    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  PROJETO NAO LOCALIZADO // $($Project.name)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] ESCOLHER A PASTA NO PC" -ForegroundColor Cyan
        Write-Host "  [2] BAIXAR DO GITHUB" -ForegroundColor Green
        Write-Host "  [0] VOLTAR" -ForegroundColor DarkGray
        Write-Host ""
        $key = [Console]::ReadKey($true).KeyChar.ToString()
        if ($key -eq "0") { return $null }
        if ($key -eq "1") {
            $selected = Select-ProjectFolder -Project $Project
            if ($selected) {
                if (Test-ProjectFolder -Path $selected) {
                    Save-ProjectPath -Project $Project -Path $selected
                    return $selected
                }
                Set-Notice "Pasta invalida: escolha a raiz que contem package.json." "Red"
            }
        }
        if ($key -eq "2") {
            $cloned = Clone-Project -Project $Project
            if ($cloned) {
                Save-ProjectPath -Project $Project -Path $cloned
                return $cloned
            }
        }
    }
}

function Get-ServerPidFile {
    param($Project)
    return Join-Path $script:StateRoot ($Project.id + ".server.pid")
}

function Get-ServerLogFile {
    param($Project)
    return Join-Path $script:LogsRoot ($Project.id + "-dev.log")
}

function Get-ServerProcess {
    param($Project)
    $pidFile = Get-ServerPidFile -Project $Project
    if (-not (Test-Path -LiteralPath $pidFile)) { return $null }
    try {
        $serverPid = [int](Get-Content -LiteralPath $pidFile -Raw).Trim()
        $process = Get-Process -Id $serverPid -ErrorAction Stop
        if ($process.HasExited) { throw "Processo encerrado." }
        return $process
    } catch {
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
        return $null
    }
}

function Get-DevUrl {
    param($Project)
    $log = Get-ServerLogFile -Project $Project
    if (Test-Path -LiteralPath $log) {
        $content = Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue
        $matches = [regex]::Matches($content, "https?://(?:localhost|127\.0\.0\.1):\d+(?:/[^\s]*)?")
        if ($matches.Count -gt 0) {
            return $matches[$matches.Count - 1].Value.TrimEnd("/", ".", ",", ")")
        }
    }
    if ($Project.defaultUrl) { return [string]$Project.defaultUrl }
    return "http://localhost:5173"
}

function Install-Dependencies {
    param([string]$Path)
    $packageFile = Join-Path $Path "package.json"
    if (-not (Test-Path -LiteralPath $packageFile)) {
        Set-Notice "Este projeto nao possui package.json." "Red"
        return $false
    }
    if (Test-Path -LiteralPath (Join-Path $Path "node_modules")) { return $true }
    if (-not (Test-App "npm")) {
        Set-Notice "Node.js/NPM nao instalado. Use [I] PREPARAR PC." "Red"
        return $false
    }
    Clear-Host
    $manager = Get-PackageManager -Path $Path
    Write-Host "Instalando dependencias com $manager..." -ForegroundColor Cyan
    Push-Location -LiteralPath $Path
    try {
        Invoke-PackageManager -Manager $manager -Arguments @("install")
        if ($LASTEXITCODE -ne 0) {
            Set-Notice "Falha ao instalar dependencias." "Red"
            Pause-Ayres
            return $false
        }
    } finally {
        Pop-Location
    }
    return $true
}

function Start-ProjectServer {
    param($Project, [string]$Path)
    if (Get-ServerProcess -Project $Project) {
        Set-Notice "Servidor local ja esta ativo." "Green"
        return $true
    }
    $scripts = @(Get-NpmScripts -Path $Path)
    if ($scripts -notcontains "dev") {
        Set-Notice "O projeto nao possui o comando npm run dev." "Red"
        return $false
    }
    if (-not (Install-Dependencies -Path $Path)) { return $false }

    $log = Get-ServerLogFile -Project $Project
    "AYRES DEV // iniciando servidor em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" |
        Set-Content -LiteralPath $log -Encoding UTF8
    $shell = Get-ShellExecutable
    $scriptPath = Join-Path $script:Root "AyresDev.ps1"
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Mode DevServer -ProjectPath "{1}" -LogPath "{2}"' -f `
        $scriptPath.Replace('"', '""'), $Path.Replace('"', '""'), $log.Replace('"', '""')
    try {
        $process = Start-Process $shell -ArgumentList $arguments -WindowStyle Hidden -PassThru
        $process.Id | Set-Content -LiteralPath (Get-ServerPidFile -Project $Project) -Encoding ASCII
        Start-Sleep -Milliseconds 700
        $process.Refresh()
        if ($process.HasExited) {
            Remove-Item -LiteralPath (Get-ServerPidFile -Project $Project) -Force -ErrorAction SilentlyContinue
            $tail = @(Get-LogTail -Project $Project | Select-Object -Last 1)
            Set-Notice ("Servidor encerrou ao iniciar. " + ($tail -join "")) "Red"
            return $false
        }
        Set-Notice "Servidor local iniciado. Aguardando ficar pronto..." "Green"
        return $true
    } catch {
        Set-Notice ("Falha ao iniciar servidor: " + $_.Exception.Message) "Red"
        return $false
    }
}

function Stop-ProjectServer {
    param($Project)
    $process = Get-ServerProcess -Project $Project
    if (-not $process) {
        Set-Notice "Servidor ja esta desligado." "DarkGray"
        return
    }
    try {
        & taskkill.exe /PID $process.Id /T /F 2>$null | Out-Null
        Remove-Item -LiteralPath (Get-ServerPidFile -Project $Project) -Force -ErrorAction SilentlyContinue
        Set-Notice "Servidor local encerrado." "Yellow"
    } catch {
        Set-Notice "Nao foi possivel encerrar o servidor." "Red"
    }
}

function Open-LocalProject {
    param($Project, [string]$Path)
    if (-not (Get-ServerProcess -Project $Project)) {
        if (-not (Start-ProjectServer -Project $Project -Path $Path)) { return }
        for ($attempt = 0; $attempt -lt 12; $attempt++) {
            if (-not (Get-ServerProcess -Project $Project)) {
                Set-Notice "Servidor encerrou antes de ficar pronto. Veja o log no painel." "Red"
                return
            }
            $logLines = @(Get-LogTail -Project $Project)
            if (($logLines -join " ") -match "https?://(?:localhost|127\.0\.0\.1):\d+") { break }
            Start-Sleep -Milliseconds 500
        }
    }
    Start-Process (Get-DevUrl -Project $Project)
    Set-Notice "Projeto aberto no navegador." "Green"
}

function New-VSCodeWorkspace {
    param($Project, [string]$Path)
    $manager = Get-PackageManager -Path $Path
    $scripts = @(Get-NpmScripts -Path $Path)
    $tasks = @()
    foreach ($name in @("dev", "lint", "test", "build")) {
        if ($scripts -contains $name) {
            $tasks += [ordered]@{
                label = "AYRES DEV: $($name.ToUpperInvariant())"
                type = "shell"
                command = if ($manager -like "corepack *") { "corepack" } else { $manager }
                args = if ($manager -like "corepack *") {
                    @(($manager -split " ")[1], "run", $name)
                } else {
                    @("run", $name)
                }
                options = @{ cwd = '${workspaceFolder}' }
                problemMatcher = @()
                presentation = @{
                    reveal = "always"
                    panel = "dedicated"
                    clear = $true
                }
            }
        }
    }
    $workspace = [ordered]@{
        folders = @(@{ path = $Path })
        settings = [ordered]@{
            "workbench.colorTheme" = "Default Dark Modern"
            "workbench.iconTheme" = "vs-seti"
            "terminal.integrated.fontFamily" = "Cascadia Code, Consolas"
            "terminal.integrated.cursorStyle" = "line"
            "editor.fontFamily" = "Cascadia Code, Consolas"
            "editor.fontLigatures" = $true
            "editor.formatOnSave" = $true
            "files.autoSave" = "afterDelay"
            "files.autoSaveDelay" = 850
            "chatgpt.openOnStartup" = $true
            "chatgpt.localeOverride" = "pt-BR"
        }
        extensions = @{
            recommendations = @(
                "openai.chatgpt",
                "dbaeumer.vscode-eslint",
                "esbenp.prettier-vscode"
            )
        }
        tasks = @{
            version = "2.0.0"
            tasks = $tasks
        }
    }
    $workspaceFile = Join-Path $script:WorkspacesRoot ($Project.id + ".code-workspace")
    $workspace | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $workspaceFile -Encoding UTF8
    return $workspaceFile
}

function Open-Workbench {
    param($Project, [string]$Path)
    if (-not (Test-App "code")) {
        Set-Notice "VS Code nao instalado. Use [I] PREPARAR PC." "Red"
        return
    }
    if (-not (Install-Dependencies -Path $Path)) { return }
    if (Test-App "git") {
        $changes = @(& git -C $Path status --porcelain 2>$null)
        if ($changes.Count -eq 0) {
            & git -C $Path pull --ff-only 2>$null | Out-Null
        }
    }
    $workspace = New-VSCodeWorkspace -Project $Project -Path $Path
    if (-not (Get-ServerProcess -Project $Project)) {
        [void](Start-ProjectServer -Project $Project -Path $Path)
    }
    & code -n $workspace
    Start-Sleep -Seconds 2
    Start-Process (Get-DevUrl -Project $Project)
    Set-Notice "Modo trabalho ativo: VS Code + localhost + painel ao vivo." "Green"
}

function Open-Codex {
    param($Project, [string]$Path)
    if (-not (Test-App "codex")) {
        Set-Notice "Codex nao instalado. Use [I] PREPARAR PC." "Red"
        return
    }
    $shell = Get-ShellExecutable
    $scriptPath = Join-Path $script:Root "AyresDev.ps1"
    $arguments = '-NoProfile -ExecutionPolicy Bypass -NoExit -File "{0}" -Mode Codex -ProjectPath "{1}"' -f `
        $scriptPath.Replace('"', '""'), $Path.Replace('"', '""')
    Start-Process $shell -ArgumentList $arguments
    Set-Notice "Codex aberto dentro do projeto." "Magenta"
}

function Open-ProjectTerminal {
    param([string]$Path)
    $shell = Get-ShellExecutable
    $escaped = $Path.Replace("'", "''")
    $command = "Set-Location -LiteralPath '$escaped'; `$Host.UI.RawUI.WindowTitle='AYRES DEV // TERMINAL'"
    Start-Process $shell -ArgumentList @("-NoExit", "-NoProfile", "-Command", $command)
    Set-Notice "Terminal livre aberto na pasta do projeto." "Cyan"
}

function Show-GitChanges {
    param([string]$Path)
    Clear-Host
    Write-Host ""
    Write-Host "  GIT // ALTERACOES REAIS" -ForegroundColor Cyan
    Write-Host ("  " + $Path) -ForegroundColor DarkGray
    Write-Host ""
    if (-not (Test-App "git")) {
        Write-Host "Git nao instalado." -ForegroundColor Red
        Pause-Ayres
        return
    }
    & git -C $Path status --short
    Write-Host ""
    & git -C $Path diff --stat
    Write-Host ""
    & git -C $Path diff --color=always
    Pause-Ayres
}

function Invoke-QualityGate {
    param([string]$Path)
    if (-not (Test-App "npm")) {
        Set-Notice "Node.js/NPM nao instalado." "Red"
        return $false
    }
    $scripts = @(Get-NpmScripts -Path $Path)
    $checks = @()
    if ($scripts -contains "lint") { $checks += "lint" }
    if ($scripts -contains "test") { $checks += "test" }
    if ($scripts -contains "build") { $checks += "build" }
    if ($checks.Count -eq 0) {
        Set-Notice "Projeto sem lint, test ou build. Nenhuma verificacao executada." "Yellow"
        return $true
    }
    Clear-Host
    Write-Host ""
    Write-Host "  QUALITY GATE // TESTES REAIS" -ForegroundColor Green
    foreach ($check in $checks) {
        Write-Host ""
        Write-Host "  > executando $check" -ForegroundColor Cyan
        if (-not (Invoke-PackageScript -Path $Path -ScriptName $check)) {
            Set-Notice "O comando $check falhou. Publicacao bloqueada." "Red"
            Pause-Ayres
            return $false
        }
    }
    Set-Notice "Testes e build concluidos com sucesso." "Green"
    Pause-Ayres
    return $true
}

function Update-Project {
    param([string]$Path)
    if (-not (Test-App "git")) {
        Set-Notice "Git nao instalado." "Red"
        return
    }
    $changes = @(& git -C $Path status --porcelain 2>$null)
    if ($changes.Count -gt 0) {
        Set-Notice "Atualizacao cancelada: existem mudancas locais." "Yellow"
        return
    }
    Clear-Host
    Write-Host "Atualizando sem apagar arquivos..." -ForegroundColor Cyan
    & git -C $Path pull --ff-only
    if ($LASTEXITCODE -eq 0) {
        Set-Notice "Projeto atualizado do GitHub." "Green"
    } else {
        Set-Notice "Falha ao atualizar. Veja a mensagem do Git." "Red"
        Pause-Ayres
    }
}

function Publish-Project {
    param($Project, [string]$Path)
    if (-not (Test-App "git")) {
        Set-Notice "Git nao instalado." "Red"
        return
    }
    $changes = @(& git -C $Path status --porcelain 2>$null)
    if ($changes.Count -eq 0) {
        Set-Notice "Nao existe alteracao para publicar." "DarkGray"
        return
    }
    if (-not (Invoke-QualityGate -Path $Path)) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  PUBLICACAO PROTEGIDA // $($Project.name)" -ForegroundColor Yellow
    Write-Host ""
    & git -C $Path status --short
    Write-Host ""
    & git -C $Path diff --stat
    Write-Host ""
    Write-Host "Nada sera enviado sem sua confirmacao." -ForegroundColor Yellow
    $confirm = Read-Host "Digite PUBLICAR"
    if ($confirm -cne "PUBLICAR") {
        Set-Notice "Publicacao cancelada. Nada foi enviado." "Green"
        return
    }
    $message = Read-Host "Resumo da mudanca"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "Atualizacao pelo Ayres Dev $script:Version"
    }
    & git -C $Path add -A
    & git -C $Path commit -m $message
    if ($LASTEXITCODE -ne 0) {
        Set-Notice "Commit falhou. Nenhum push foi feito." "Red"
        Pause-Ayres
        return
    }
    & git -C $Path push
    if ($LASTEXITCODE -ne 0) {
        $branch = (& git -C $Path branch --show-current).Trim()
        & git -C $Path push -u origin $branch
    }
    if ($LASTEXITCODE -eq 0) {
        Set-Notice "ALTERACOES PUBLICADAS COM SUCESSO." "Green"
    } else {
        Set-Notice "Push falhou. O commit continua salvo no PC." "Red"
        Pause-Ayres
    }
}

function Install-WithWinget {
    param([string]$Name, [string]$Id)
    if (-not (Test-App "winget")) {
        Write-Host "Winget nao disponivel neste Windows." -ForegroundColor Red
        return
    }
    Write-Host "Instalando $Name..." -ForegroundColor Cyan
    & winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = $machine + ";" + $user
}

function Show-Setup {
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  AYRES DEV // PREPARAR ESTE PC" -ForegroundColor Green
        Write-Host ""
        $items = @(
            @{ Key = "1"; Name = "Git"; Command = "git"; Id = "Git.Git" },
            @{ Key = "2"; Name = "Node.js LTS"; Command = "node"; Id = "OpenJS.NodeJS.LTS" },
            @{ Key = "3"; Name = "VS Code"; Command = "code"; Id = "Microsoft.VisualStudioCode" },
            @{ Key = "4"; Name = "GitHub CLI"; Command = "gh"; Id = "GitHub.cli" },
            @{ Key = "5"; Name = "Windows Terminal"; Command = "wt"; Id = "Microsoft.WindowsTerminal" }
        )
        foreach ($item in $items) {
            $state = if (Test-App $item.Command) { "OK" } else { "--" }
            $color = if ($state -eq "OK") { "Green" } else { "DarkYellow" }
            Write-Host ("  [$($item.Key)] " + $item.Name.PadRight(21) + " [$state]") -ForegroundColor $color
        }
        $codexState = if (Test-App "codex") { "OK" } else { "--" }
        Write-Host ("  [6] Codex CLI".PadRight(27) + "[$codexState]") -ForegroundColor Magenta
        Write-Host "  [7] Extensao Codex no VS Code" -ForegroundColor Magenta
        Write-Host "  [8] INSTALAR TUDO QUE FALTA" -ForegroundColor Cyan
        Write-Host "  [9] Login do GitHub" -ForegroundColor White
        Write-Host "  [0] VOLTAR" -ForegroundColor DarkGray
        Write-Host ""
        $key = [Console]::ReadKey($true).KeyChar.ToString()
        if ($key -eq "0") { return }
        $selected = $items | Where-Object { $_.Key -eq $key } | Select-Object -First 1
        if ($selected) {
            Install-WithWinget -Name $selected.Name -Id $selected.Id
            Refresh-Path
            Pause-Ayres
        }
        if ($key -eq "6") {
            if (Test-App "npm") {
                & npm install --global '@openai/codex'
                Refresh-Path
            } else {
                Write-Host "Instale Node.js primeiro." -ForegroundColor Red
            }
            Pause-Ayres
        }
        if ($key -eq "7") {
            if (Test-App "code") {
                & code --install-extension openai.chatgpt --force
            } else {
                Write-Host "Instale VS Code primeiro." -ForegroundColor Red
            }
            Pause-Ayres
        }
        if ($key -eq "8") {
            foreach ($item in $items) {
                if (-not (Test-App $item.Command)) {
                    Install-WithWinget -Name $item.Name -Id $item.Id
                    Refresh-Path
                }
            }
            if ((Test-App "npm") -and (-not (Test-App "codex"))) {
                & npm install --global '@openai/codex'
                Refresh-Path
            }
            if (Test-App "code") {
                & code --install-extension openai.chatgpt --force
            }
            Pause-Ayres
        }
        if ($key -eq "9") {
            if (Test-App "gh") {
                & gh auth login --web --git-protocol https
            } else {
                Write-Host "GitHub CLI nao instalado." -ForegroundColor Red
            }
            Pause-Ayres
        }
    }
}

function Get-GitInfo {
    param([string]$Path)
    $info = @{
        Branch = "sem git"
        Changes = 0
        LastCommit = "repositorio nao detectado"
        Files = @()
    }
    if (-not (Test-App "git")) { return $info }
    if (-not (Test-Path -LiteralPath (Join-Path $Path ".git"))) { return $info }
    try {
        $branch = (& git -C $Path branch --show-current 2>$null).Trim()
        $files = @(& git -C $Path status --short 2>$null)
        $last = (& git -C $Path log -1 --pretty=format:"%h  %s" 2>$null).Trim()
        if ($branch) { $info.Branch = $branch }
        $info.Changes = $files.Count
        if ($last) { $info.LastCommit = $last }
        $info.Files = $files
    } catch {}
    return $info
}

function Get-LogTail {
    param($Project)
    $log = Get-ServerLogFile -Project $Project
    if (-not (Test-Path -LiteralPath $log)) {
        return @("Nenhum processo local executado nesta sessao.")
    }
    try {
        $escape = [char]27
        return @(Get-Content -LiteralPath $log -Tail 6 | ForEach-Object {
            ($_ -replace ($escape + "\[[0-9;?]*[ -/]*[@-~]"), "").TrimEnd()
        })
    } catch {
        return @("Log indisponivel.")
    }
}

function Get-ToolState {
    param([string]$Command)
    if (Test-App $Command) { return "ONLINE" }
    return "SETUP"
}

function Test-LocalUrl {
    param([string]$Url)
    try {
        $uri = [Uri]$Url
        if ($uri.Host -notin @("localhost", "127.0.0.1", "::1")) { return $false }
        $port = if ($uri.IsDefaultPort) {
            if ($uri.Scheme -eq "https") { 443 } else { 80 }
        } else {
            $uri.Port
        }
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $connection = $client.BeginConnect($uri.Host, $port, $null, $null)
            return $connection.AsyncWaitHandle.WaitOne(120, $false) -and $client.Connected
        } finally {
            $client.Close()
        }
    } catch {
        return $false
    }
}

function Get-DashboardSignature {
    param($Project, [string]$Path)
    $git = Get-GitInfo -Path $Path
    $process = Get-ServerProcess -Project $Project
    $log = @(Get-LogTail -Project $Project)
    $url = Get-DevUrl -Project $Project
    $reachable = Test-LocalUrl -Url $url
    return @(
        $(if ($process) { $process.Id } else { 0 }),
        $reachable,
        $git.Branch,
        $git.Changes,
        ($git.Files -join "|"),
        $git.LastCommit,
        ($log -join "|"),
        $script:LastNotice
    ) -join "::"
}

function Write-State {
    param([string]$Label, [string]$Value, [string]$Color = "Gray")
    Write-Host ("  " + $Label.PadRight(18)) -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $Color
}

function Write-MaskedHeader {
    param([string]$Mode)
    Write-Host "  .============================================================================." -ForegroundColor DarkGreen
    Write-Host ("  | AYRES DEV " + $script:Version + " // " + $Mode.PadRight(54) + " |") -ForegroundColor Green
    Write-Host "  |                 .-''''-.       .-''''-.                                  |" -ForegroundColor DarkGreen
    Write-Host "  |                /  o  o  \_____/  o  o  \                                 |" -ForegroundColor Green
    Write-Host "  |                \       /  _  \       /                                  |" -ForegroundColor Green
    Write-Host "  |                 '-----/__/ \__\-----'                                   |" -ForegroundColor DarkGreen
    Write-Host "  |       MASKED OPERATOR // LOCAL CORE // SAFE GIT CONTROL                  |" -ForegroundColor DarkCyan
    Write-Host '  `============================================================================`' -ForegroundColor DarkGreen
}

function Show-Dashboard {
    param($Project, [string]$Path)
    $git = Get-GitInfo -Path $Path
    $server = Get-ServerProcess -Project $Project
    $url = Get-DevUrl -Project $Project
    $reachable = Test-LocalUrl -Url $url
    $serverText = if ($reachable -and $server) {
        "ONLINE  PID $($server.Id)"
    } elseif ($reachable) {
        "ONLINE  PORTA ATIVA"
    } elseif ($server) {
        "INICIANDO  PID $($server.Id)"
    } else {
        "OFFLINE"
    }
    $serverColor = if ($reachable) { "Green" } elseif ($server) { "Yellow" } else { "DarkYellow" }

    Clear-Host
    Write-Host ""
    Write-MaskedHeader -Mode "PROJECT OPERATIONS"
    Write-Host ""
    Write-Host "  [ 01 // TARGET IDENTITY ]" -ForegroundColor Magenta
    Write-Host ("  PROJECT ........ " + $Project.name.ToUpperInvariant()) -ForegroundColor White
    Write-Host ("  WORKSPACE ...... " + $Path) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [ 02 // LIVE TELEMETRY ]" -ForegroundColor Magenta
    Write-State "DEV SERVER" $serverText $serverColor
    Write-State "LOCAL URL" $url "Cyan"
    Write-State "GIT BRANCH" $git.Branch "Cyan"
    Write-State "CHANGED FILES" ([string]$git.Changes) $(if ($git.Changes -gt 0) { "Yellow" } else { "Green" })
    Write-State "LAST COMMIT" $git.LastCommit "DarkGray"
    Write-State "CODEX" (Get-ToolState "codex") $(if (Test-App "codex") { "Magenta" } else { "DarkYellow" })
    Write-State "NODE / GIT" ((Get-ToolState "node") + " / " + (Get-ToolState "git")) "Green"
    Write-Host ""
    Write-Host "  [ 03 // WORKTREE INTEL ]" -ForegroundColor Magenta
    if ($git.Files.Count -eq 0) {
        Write-Host "  workspace clean // nenhuma mudanca pendente" -ForegroundColor DarkGray
    } else {
        foreach ($file in @($git.Files | Select-Object -First 5)) {
            Write-Host ("  " + $file) -ForegroundColor Yellow
        }
        if ($git.Files.Count -gt 5) {
            Write-Host ("  ... +" + ($git.Files.Count - 5) + " arquivo(s)") -ForegroundColor DarkYellow
        }
    }
    Write-Host ""
    Write-Host "  [ 04 // REALTIME OUTPUT ]" -ForegroundColor Magenta
    foreach ($line in @(Get-LogTail -Project $Project)) {
        $visible = if ($line.Length -gt 94) { $line.Substring(0, 94) } else { $line }
        Write-Host ("  > " + $visible) -ForegroundColor DarkGreen
    }
    Write-Host ""
    Write-Host "  [ 05 // COMMAND MATRIX ]" -ForegroundColor Magenta
    Write-Host "  +-------------------+-------------------+-------------------+------------------+" -ForegroundColor DarkGreen
    Write-Host "  | [W] WORKBENCH     | [A] CODEX IA      | [O] ABRIR SITE    | [R] REINICIAR    |" -ForegroundColor Green
    Write-Host "  | [E] VS CODE       | [D] GIT DIFF      | [Q] TESTAR/BUILD  | [P] PUBLICAR     |" -ForegroundColor Cyan
    Write-Host "  | [T] TERMINAL      | [U] ATUALIZAR     | [S] PARAR SERVER | [I] PREPARAR PC  |" -ForegroundColor Gray
    Write-Host "  | [X] DIAGNOSTICO   | [L] LOLBAS AUDIT  | [K] TESTE CARGA   | [V] TROCAR ALVO |" -ForegroundColor DarkGray
    Write-Host "  | [0] SAIR          |                   |                   |                  |" -ForegroundColor DarkGray
    Write-Host "  +-------------------+-------------------+-------------------+------------------+" -ForegroundColor DarkGreen
    if ($script:LastNotice) {
        Write-Host ""
        Write-Host ("  >> " + $script:LastNotice) -ForegroundColor $script:LastNoticeColor
    }
    Write-Host ""
    Write-Host "  painel atualiza sozinho // pressione uma tecla" -ForegroundColor DarkGray
}

function Wait-DashboardKey {
    $until = (Get-Date).AddMilliseconds(1200)
    while ((Get-Date) -lt $until) {
        if ([Console]::KeyAvailable) {
            return [Console]::ReadKey($true).KeyChar.ToString().ToUpperInvariant()
        }
        Start-Sleep -Milliseconds 80
    }
    return $null
}

function Show-ProjectDashboard {
    param($Project, [string]$Path)
    $script:LastNotice = "Monitoramento em tempo real iniciado."
    $script:LastNoticeColor = "Green"
    $lastSignature = ""
    while ($true) {
        $signature = Get-DashboardSignature -Project $Project -Path $Path
        if ($signature -ne $lastSignature) {
            Show-Dashboard -Project $Project -Path $Path
            $lastSignature = $signature
        }
        $key = Wait-DashboardKey
        if (-not $key) { continue }
        switch ($key) {
            "W" { Open-Workbench -Project $Project -Path $Path }
            "A" { Open-Codex -Project $Project -Path $Path }
            "O" { Open-LocalProject -Project $Project -Path $Path }
            "R" {
                Stop-ProjectServer -Project $Project
                Start-Sleep -Milliseconds 400
                [void](Start-ProjectServer -Project $Project -Path $Path)
            }
            "E" {
                if (Test-App "code") {
                    $workspace = New-VSCodeWorkspace -Project $Project -Path $Path
                    & code -n $workspace
                    Set-Notice "Projeto aberto no VS Code." "Green"
                } else {
                    Set-Notice "VS Code nao instalado. Use [I]." "Red"
                }
            }
            "D" { Show-GitChanges -Path $Path }
            "Q" { [void](Invoke-QualityGate -Path $Path) }
            "P" { Publish-Project -Project $Project -Path $Path }
            "T" { Open-ProjectTerminal -Path $Path }
            "U" { Update-Project -Path $Path }
            "S" { Stop-ProjectServer -Project $Project }
            "I" { Show-Setup }
            "X" {
                Clear-Host
                [void](Invoke-SelfTest -TargetProjectPath $Path)
                Pause-Ayres
            }
            "L" {
                & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $script:LolbasAudit
            }
            "K" {
                & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $script:LoadTest -Url (Get-DevUrl -Project $Project)
            }
            "V" { return "SWITCH" }
            "0" { return "EXIT" }
        }
        $lastSignature = ""
    }
}

function Maximize-Console {
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class AyresWindow {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int command);
}
"@ -ErrorAction SilentlyContinue
        [AyresWindow]::ShowWindow([AyresWindow]::GetConsoleWindow(), 3) | Out-Null
    } catch {}
}

function Show-Boot {
    Clear-Host
    Write-Host ""
    Write-Host ("  AYRES DEV // LIVE CORE " + $script:Version) -ForegroundColor Green
    Write-Host "  conectando ferramentas reais..." -ForegroundColor DarkGray
    $bootItems = @(
        @{ Label = "projetos"; Command = $null },
        @{ Label = "git"; Command = "git" },
        @{ Label = "node"; Command = "node" },
        @{ Label = "vscode"; Command = "code" },
        @{ Label = "codex"; Command = "codex" },
        @{ Label = "monitor"; Command = $null }
    )
    foreach ($item in $bootItems) {
        $state = if ((-not $item.Command) -or (Test-App $item.Command)) { "ONLINE" } else { "SETUP" }
        $color = if ($state -eq "ONLINE") { "Green" } else { "DarkYellow" }
        Write-Host ("  [CORE] " + $item.Label.PadRight(16) + $state) -ForegroundColor $color
        Start-Sleep -Milliseconds 65
    }
    Start-Sleep -Milliseconds 250
}

function Show-ProjectSelector {
    while ($true) {
        $projects = @(Get-Projects)
        Clear-Host
        Write-Host ""
        Write-MaskedHeader -Mode "SELECT TARGET"
        Write-Host ""
        Write-Host "  [ AVAILABLE WORKSPACES ]" -ForegroundColor Magenta
        for ($index = 0; $index -lt $projects.Count; $index++) {
            $project = $projects[$index]
            Write-Host ("  +--[" + ($index + 1) + "]-- " + $project.name.ToUpperInvariant()) -ForegroundColor $project.color
            Write-Host ("  |       " + $project.description) -ForegroundColor DarkGray
            Write-Host "  |" -ForegroundColor DarkGreen
            Write-Host ""
        }
        Write-Host "  [ SYSTEM COMMANDS ]" -ForegroundColor Magenta
        Write-Host "  [I] PREPARAR PC   [N] IMPORTAR GITHUB   [X] DIAGNOSTICO   [0] SAIR" -ForegroundColor Green
        Write-Host ""
        $key = [Console]::ReadKey($true).KeyChar.ToString().ToUpperInvariant()
        if ($key -eq "0") { return $null }
        if ($key -eq "I") {
            Show-Setup
            continue
        }
        if ($key -eq "N") {
            $created = New-ProjectFromUrl
            if ($created) { return $created }
            continue
        }
        if ($key -eq "X") {
            Clear-Host
            [void](Invoke-SelfTest)
            Pause-Ayres
            continue
        }
        $number = 0
        if ([int]::TryParse($key, [ref]$number)) {
            if (($number -ge 1) -and ($number -le $projects.Count)) {
                return $projects[$number - 1]
            }
        }
    }
}

function Invoke-SelfTest {
    param([string]$TargetProjectPath = $ProjectPath)
    $failures = @()
    Write-Host "AYRES DEV $script:Version // DIAGNOSTICO" -ForegroundColor Cyan
    Write-Host ""

    try {
        $projects = @(Get-Projects)
        Write-Host ("[OK] Configuracao: " + $projects.Count + " projeto(s)") -ForegroundColor Green
    } catch {
        $failures += $_.Exception.Message
        Write-Host ("[ERRO] Configuracao: " + $_.Exception.Message) -ForegroundColor Red
    }

    foreach ($tool in @("git", "node", "npm", "code", "codex")) {
        if (Test-App $tool) {
            Write-Host ("[OK] " + $tool) -ForegroundColor Green
        } else {
            Write-Host ("[AVISO] " + $tool + " nao encontrado") -ForegroundColor Yellow
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($TargetProjectPath)) {
        if (Test-ProjectFolder -Path $TargetProjectPath) {
            $scripts = @(Get-NpmScripts -Path $TargetProjectPath)
            Write-Host ("[OK] Projeto valido: " + $TargetProjectPath) -ForegroundColor Green
            Write-Host ("[OK] Scripts: " + ($scripts -join ", ")) -ForegroundColor DarkCyan
        } else {
            $failures += "A pasta de teste nao contem um package.json valido."
            Write-Host "[ERRO] Projeto invalido ou sem package.json." -ForegroundColor Red
        }
    }

    Write-Host ""
    if ($failures.Count -gt 0) {
        Write-Host ("FALHOU // " + ($failures -join " | ")) -ForegroundColor Red
        return $false
    }
    Write-Host "DIAGNOSTICO CONCLUIDO // CORE FUNCIONAL" -ForegroundColor Green
    return $true
}

if ($Mode -eq "SelfTest") {
    Initialize-State
    if (Invoke-SelfTest) { exit 0 }
    exit 1
}

try {
    Initialize-State
    Maximize-Console
    $Host.UI.RawUI.WindowTitle = "AYRES DEV $script:Version // LIVE DEVELOPMENT CONSOLE"
    Show-Boot
    while ($true) {
        $project = Show-ProjectSelector
        if (-not $project) { break }
        $path = Resolve-ProjectPath -Project $project
        if (-not $path) { continue }
        $result = Show-ProjectDashboard -Project $project -Path $path
        if ($result -eq "EXIT") { break }
    }
} catch {
    Clear-Host
    Write-Host ""
    Write-Host "AYRES DEV encontrou um erro real:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Arquivo: $($_.InvocationInfo.ScriptName)" -ForegroundColor DarkGray
    Write-Host "Linha: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Pressione qualquer tecla para fechar." -ForegroundColor DarkGray
    [void][Console]::ReadKey($true)
}
