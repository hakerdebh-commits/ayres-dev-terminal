# AYRES DEV TERMINAL

Terminal PowerShell para projetos, Codex, Git, servidor local, testes e publicacao segura no GitHub.

## Como usar

1. Clone ou atualize este repositorio.
2. Clique duas vezes em `Abrir-AyresDev.bat`.
3. Escolha o projeto no painel.

O pacote inclui Painel Ayres e Site Adriana em `projetos.json`.

A publicacao executa verificacoes e exige a confirmacao `PUBLICAR`.

## Personalizacao do PowerShell

O menu inclui uma adaptacao segura da ideia do projeto `hakernet`:

- instala uma tela inicial AYRES no perfil do usuario;
- nao exige administrador;
- cria backup antes de alterar um perfil existente;
- pode ser removida pelo proprio menu;
- nao inclui ferramentas de invasao ou coleta de credenciais.

O menu principal tambem possui a opcao `[6]`, que abre um PowerShell livre
diretamente na pasta do AYRES DEV para executar Git, Codex e manutencoes locais.

## Painel grafico PowerShell

`Abrir-AyresDev.bat` inicia um painel WPF portatil com visual neon, chuva de
codigo e acesso direto a projetos, Codex, PowerShell, VS Code e GitHub.
O painel continua sendo executado por PowerShell e nao instala um aplicativo.
