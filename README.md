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

## Auditoria defensiva LOLBAS

A opcao `[7]` do menu principal e a tecla `[L]` dentro de um projeto executam
uma verificacao somente leitura dos processos ativos. Ela procura padroes
suspeitos no uso de ferramentas legitimas do Windows, mostra o motivo do alerta
e deixa a decisao com o usuario.

- nao executa comandos do catalogo LOLBAS;
- nao encerra processos;
- nao apaga nem altera arquivos;
- nao substitui o Microsoft Defender;
- usa o projeto LOLBAS apenas como referencia defensiva:
  https://github.com/LOLBAS-Project/LOLBAS

## Teste de carga autorizado

A opcao `[8]` aceita uma URL local ou publicada. Dentro de um projeto, pressione
`[K]` para testar o endereco do servidor configurado. O modulo exige confirmacao,
aceita cancelamento e apresenta requisicoes, sucesso, falhas, req/s e latencia.
Enderecos com IP e porta tambem sao aceitos, como `http://192.168.0.10:5173`.
Destinos publicos possuem limites menores que `localhost` para evitar sobrecarga
acidental. Use somente em sistemas proprios ou com autorizacao expressa.

A opcao `[9]` pede somente o IPv4 publico. Ela verifica automaticamente as
portas web 80 e 443, escolhe a que estiver acessivel e prepara o teste. Enderecos
locais/privados sao rejeitados. Execute em um computador conectado a outra
internet para o trafego realmente chegar de fora da rede do servidor. A
ferramenta nao abre portas nem altera o roteador ou o Firewall do Windows.
