# Backup e restauração

Dono: DevOps (`time.yml`, `escrita.devops`). Origem: story 0-03; spec v1.2 §4.6, RNF-07,
RNF-14, P-17; ADR 0001, decisão 6.

## O que tem backup, e o que não tem

| Item | Como | Para onde |
|---|---|---|
| PostgreSQL do CRM | **pgBackRest 2.60.1**, completo diário + WAL contínuo, cifrado no cliente (`aes-256-cbc`) | o destino de `BACKUP_S3_*`, prefixos `pgbackrest/` (diários) e `pgbackrest-mensal/` (mensais) |
| Arquivos (bucket do Garage) | **rclone 1.76.0** de S3 para S3, diário, remote `crypt` (nomes e conteúdo cifrados), `--backup-dir` datado | o mesmo destino, prefixo `arquivos/` |
| Keycloak | **não é do CRM** (spec v1.2 §4.6): o Keycloak em `akpannel` é operado e copiado pela TI da Akeel | — |

O pgBackRest copia o **cluster** inteiro. No compose local o cluster tem também o banco
`keycloak` do Keycloak de teste, então ele vai junto e volta junto (é o que o
`testar-local.sh` confere). Em produção o cluster só tem o banco `crm`.

**Destino real: em aberto (P-17).** Será um S3 **com dados no Brasil** (RNF-14,
`decisoes/2026-11-24.md §12`). O R2 não serve (ADR 0001, Alternativas). Cifrar no
cliente não resolve residência. Até o destino existir, só há o teste local.

## As variáveis (o destino é só configuração)

O destino vem do **segredo do Docker `backup`**: um diretório, montado em
`/run/secrets/backup` no `postgres` e no `backup-arquivos`, com um arquivo por variável
(nome em minúsculas, valor sem quebra de linha). O compose acha o diretório em
`BACKUP_SEGREDOS` (ambiente ou `.env`).

| Arquivo | Variável | O que é |
|---|---|---|
| `backup_s3_endpoint` | `BACKUP_S3_ENDPOINT` | `https://host[:porta]`. Precisa ser https: o pgBackRest não fala S3 sem TLS |
| `backup_s3_region` | `BACKUP_S3_REGION` | região do bucket |
| `backup_s3_bucket` | `BACKUP_S3_BUCKET` | bucket de destino (o mesmo para banco e arquivos, em prefixos) |
| `backup_s3_uri_style` | `BACKUP_S3_URI_STYLE` | `path` ou `host` |
| `backup_s3_access_key` | `BACKUP_S3_ACCESS_KEY` | chave de acesso, com leitura, escrita e remoção **só** nesse bucket |
| `backup_s3_secret_key` | `BACKUP_S3_SECRET_KEY` | segredo da chave |
| `backup_cipher_pass` | `BACKUP_CIPHER_PASS` | senha da cifra (pgBackRest e rclone). **Perdeu, perdeu o backup**: guarde fora da VPS, com o Pedro |
| `backup_s3_ca_cert` | (opcional) | CA em PEM, só para destino com CA própria (o teste local usa) |

- **Sem destino, falha fechado.** Sem `BACKUP_SEGREDOS`, o compose usa
  `deploy/backup/sem-destino/`, que tem só o arquivo `SEM_DESTINO`. Nesse caso o
  `archive_command` **falha** (`crm-pgbackrest: sem destino de backup (SEM_DESTINO) fora do
  modo de desenvolvimento; WAL ... fica em pg_wal`): o PostgreSQL conta a falha em
  `pg_stat_archiver.failed_count`, guarda o WAL em `pg_wal` e tenta de novo. Nada se perde;
  o disco cresce. `backup.sh` e `restaurar.sh` recusam.
- **O descarte só existe no modo de desenvolvimento, e é explícito.** O WAL só é
  descartado (exit 0, com aviso no log `... BACKUP_MODO=desenvolvimento); WAL ... descartado`)
  quando as duas coisas valem juntas: o segredo tem `SEM_DESTINO` **e** o serviço
  `postgres` tem `BACKUP_MODO=desenvolvimento` no ambiente. O `compose.yaml` (o compose
  local) declara `BACKUP_MODO: ${BACKUP_MODO-desenvolvimento}`; o compose de produção não deve
  declarar `BACKUP_MODO`, e então lá um `.env` sem `BACKUP_SEGREDOS` falha fechado em vez de
  perder WAL em silêncio. Para ver a falha fechada localmente: `BACKUP_MODO= docker compose
  up -d --force-recreate --no-deps postgres` (o `testar-local.sh` faz isso, fase
  `[falha-fechada]`).
- Com um diretório sem `SEM_DESTINO` e faltando qualquer arquivo, o `archive_command`
  também **falha**, do mesmo jeito. `failed_count` subindo e arquivos `.ready` em
  `pg_wal/archive_status` são o que o alerta de backup vai precisar olhar (RNF-12, fora da
  0-03).
- Nada de destino em arquivo versionado. O `deploy/postgres/pgbackrest.conf` tem só a
  política (retenção, cifra, prefixos). Quem guarda isso é o
  `sh deploy/backup/verificar-portabilidade.sh`, que está na `comandos.suite`.

## Agenda

| Quando | O quê | Comando |
|---|---|---|
| contínuo | WAL do PostgreSQL (o `archive_command`); `archive_timeout=300` fecha o segmento a cada 5 min no máximo | automático |
| todo dia, 03:00 (America/Sao_Paulo) | completo do banco no repo1 + cópia dos arquivos + retenção dos arquivos | `sh deploy/backup/backup.sh` |
| dia 1 do mês, 04:00 | completo do banco no repo2 (os 12 mensais) | `sh deploy/backup/backup.sh --mensal` |
| todo mês, numa data marcada | teste de restauração (abaixo) | `sh deploy/backup/restaurar.sh ...` |

- **RPO** (RNF-07, ≤ 15 min): banco, ≤ 5 min de WAL mais o tempo de envio. Arquivos,
  **até 24 h**: a spec pede "replicação diária" para eles (§4.6), e é isso que existe.
- **RTO** (≤ 4 h): o restore local de 44 MB levou cerca de 20 s. O tempo real depende do
  tamanho do banco e da banda até o destino: meça no primeiro teste mensal.
- **Quem dispara:** a VPS (timer do sistema chamando os comandos acima, ou um job do
  orquestrador de deploy). Isso não é regra de negócio, então não fere a §4.2. O
  agendamento na VPS e o alerta de falha ficam para quando a VPS existir (story 0-03,
  "Fora"). Os dois scripts saem diferente de 0 quando falham.

## Retenção (§4.6: 35 diários + 12 mensais)

- **Banco, repo1** (`pgbackrest/`): `repo1-retention-full-type=time`,
  `repo1-retention-full=35`. Mantém os completos dos últimos 35 dias e o WAL entre eles.
- **Banco, repo2** (`pgbackrest-mensal/`): `repo2-retention-full-type=count`,
  `repo2-retention-full=12`. O pgBackRest não tem retenção "por mês" num repositório só;
  por isso há um segundo repositório, no mesmo destino, recebendo um completo por mês.
  O WAL vai para os dois repositórios; no repo2 só fica o necessário para a consistência
  dos completos (e o PITR do mais recente, `repo2-retention-archive=1`).
- A limpeza do banco é o `expire` que o pgBackRest roda sozinho ao fim de cada backup.
- **Arquivos** (`arquivos/`, dentro do crypt):
  - `atual/` é o espelho do bucket na última cópia;
  - `versoes/AAAA-MM-DD/HHMMSSZ/` guarda o que aquela cópia **apagou ou sobrescreveu**
    no destino (o `--backup-dir`): nada some na hora;
  - `docker compose run --rm backup-arquivos reter` (o `backup.sh` já chama) apaga as
    pastas `versoes/AAAA-MM-DD` pela **data no nome**. Ficam as dos últimos 35 dias e,
    de cada um dos 12 meses anteriores, a primeira do mês. Para ver sem apagar:
    `docker compose run --rm backup-arquivos reter --simular`.
- Pedido de exclusão de titular contra a retenção: P-08, fora daqui.

## Como trocar de provedor

1. No provedor novo (com dados no Brasil): crie um bucket e uma chave só para ele.
2. Num diretório **fora do repositório** (ex.: `/srv/crm/segredos/backup-novo/`), crie os
   sete arquivos da tabela acima, com o diretório em **`711`** e os arquivos em **`644`**,
   dono o usuário do deploy (`chmod 711 dir && chmod 644 dir/*`). Gere uma senha de cifra
   nova; não reuse a do destino antigo. Por que `711`: o segredo com `file:` do compose é
   um bind mount, que no Linux mantém dono e modo do host, e o `archive_command` roda como
   `postgres` (uid 999 na imagem), que não é o dono. Ele precisa atravessar o diretório
   (`x`) e ler os arquivos (`r`). Com `700` ele não entra, não acha nem `SEM_DESTINO`, e
   o WAL acumula em `pg_wal`. `711` dá a travessia sem dar a listagem; os nomes já são
   públicos (a tabela acima), então o que protege os valores é a VPS não ter outro usuário
   de login além do deploy. O `testar-local.sh` usa os mesmos `711`/`644`. Medido num
   contêiner Linux com o diretório do uid 1000: em `700`, o uid 999 não vê `SEM_DESTINO`
   nem lê arquivo; em `711`, vê e lê, e a listagem continua negada.
3. Aponte `BACKUP_SEGREDOS` para esse diretório (no `.env` da VPS) e recrie o PostgreSQL:
   `docker compose up -d --wait postgres`. A partir daqui o WAL vai para o destino novo.
   Pare antes os serviços que usam o banco e suba-os depois: o Keycloak local ficou com
   conexão morta no pool e respondeu 500 quando o `postgres` foi recriado debaixo dele.
4. Rode `sh deploy/backup/backup.sh`. O `stanza-create` cria a stanza no destino novo e
   o completo sai em seguida. **Sem o completo, o destino novo não restaura nada.**
5. Faça um teste de restauração (roteiro abaixo) contra o destino novo e registre.
6. Mantenha o destino antigo até o novo ter 35 dias, ou até o Pedro decidir.

Nenhum arquivo do repositório muda. O `testar-local.sh` prova isso (crit. 5): roda o
ciclo inteiro em dois buckets, com duas chaves e duas senhas, trocando só
`BACKUP_SEGREDOS`.

## Restaurar

Sempre da raiz do projeto, com o mesmo `BACKUP_SEGREDOS` do backup.

```
sh deploy/backup/restaurar.sh                                  # banco até o último WAL + arquivos
sh deploy/backup/restaurar.sh --ate '2026-11-24 15:00:00-03'   # banco até um instante
sh deploy/backup/restaurar.sh --ponto NOME                     # até um pg_create_restore_point
sh deploy/backup/restaurar.sh --repo 2 --so-banco              # de um completo mensal
sh deploy/backup/restaurar.sh --so-arquivos --arquivos-de 2026-11-24/184715Z   # uma versão antiga
```

O que ele faz: para os serviços de `RESTAURAR_PARAR` (padrão vazio; em produção,
`RESTAURAR_PARAR="api worker"`; no compose local, `RESTAURAR_PARAR=keycloak`, porque o
Keycloak local usa o mesmo PostgreSQL. Em produção o Keycloak é da TI e não está no
compose) e o `postgres`; roda `pgbackrest restore --delta` num contêiner avulso
sobre o mesmo volume; sobe o `postgres`, espera a recuperação terminar e a promoção;
devolve os arquivos com `rclone copy` (copy, não sync: não apaga o que for mais novo no
bucket); sobe de novo o que parou. Cada restauração com alvo abre uma timeline nova; o
WAL seguinte continua indo para o mesmo destino.

## Restauração mensal (§4.6: "backup sem restauração testada não conta")

**Onde fica o registro:** um arquivo por mês, `docs/operacao/restauracoes/AAAA-MM.md`
(o DevOps cria a pasta no primeiro teste). Mês sem arquivo é mês sem backup válido.

**Roteiro** (num ambiente que **não** é a produção: a homologação, ou uma máquina com
o compose local; nunca restaure por cima do banco de produção para testar):

1. Anote data, máquina, quem fez e qual destino (o **nome** do provedor e do bucket;
   nunca chave nem senha).
2. Aponte `BACKUP_SEGREDOS` para uma cópia do segredo de produção em que a chave é
   **só de leitura** no bucket (crie essa chave uma vez no provedor). **Obrigatório:**
   depois da promoção, o PostgreSQL restaurado arquiva o WAL da timeline nova no mesmo
   destino; com a chave de produção, o teste gravaria uma timeline estranha no
   repositório de produção. Com a chave só de leitura, o `archive_command` falha, o WAL
   fica em `pg_wal` do ambiente de teste, e o destino não muda.
3. Suba um ambiente vazio (`docker compose down -v && docker compose up -d --wait`) e
   rode `sh deploy/backup/restaurar.sh`. Anote o tempo total (é o RTO medido) e o
   `info` do pgBackRest (qual completo foi usado, de quando).
4. Confira e anote, com a saída dos comandos:
   - `SELECT max(<coluna de data>) FROM <tabela de movimento>` no banco `crm`: o dado
     mais novo restaurado (é o RPO medido) — a tabela certa entra quando o domínio
     existir;
   - contagem de linhas de 3 tabelas principais, contra a produção no mesmo dia;
   - 3 arquivos sorteados do bucket: abrem e têm o mesmo tamanho da produção;
   - uma restauração de `versoes/` de um dia da semana anterior.
5. Escreva `docs/operacao/restauracoes/AAAA-MM.md` com: data, máquina, destino, comandos,
   exit code de cada um, tempos, o que conferiu e o resultado. Se falhou, o que falhou e
   o conserto; um backup que não restaurou é incidente.
6. Derrube o ambiente do teste (`docker compose down -v`) e apague a cópia do segredo.

## Testar localmente (sem provedor real)

```
sh deploy/backup/verificar-portabilidade.sh
docker compose --profile backup-teste up -d --wait && sh deploy/backup/testar-local.sh
```

O perfil `backup-teste` sobe um segundo Garage (`garage-destino`) atrás de TLS
(`backup-destino`, Caddy com CA interna). O `testar-local.sh` primeiro prova a falha
fechada (sem destino e sem `BACKUP_MODO`, `failed_count` sobe e o WAL fica em `pg_wal`) e
o descarte do modo de desenvolvimento (o mesmo WAL some e `archived_count` sobe). Depois
cria dois buckets com chaves próprias, gera os segredos de teste em
`deploy/backup/secrets/` (ignorado pelo git), faz backup, confere que `archived_count`
subiu com destino, apaga os bancos `crm` e `keycloak` e um objeto, restaura, confere, e
apaga tudo o que criou no fim (passe ou falhe; se a falha deixar os bancos apagados,
ele mantém o destino e imprime o comando de restauração). No fim ele também **derruba o
perfil `backup-teste`** (remove os contêineres `garage-destino` e `backup-destino`; os
volumes ficam, para a CA do Caddy não mudar), então o `sh deploy/local/verificar.sh` da
0-02 volta a ficar verde sem passo à mão. Leva uns 4 minutos com o `up`.

Precisa do ambiente da story 0-02 de pé (`deploy/local/gerar-segredos.sh` já rodado):
o `garage-destino` reusa os segredos internos do Garage local.

## Por que está assim (o que não está escrito no código)

O código de `deploy/` não leva comentário (`decisoes/2026-11-24.md §17`); o porquê fica aqui.

- **Imagem do PostgreSQL.** O contexto de build é `./deploy`, para a imagem copiar
  `deploy/backup/destino.sh` e `pgbackrest.sh`. O `deploy/postgres/Dockerfile.dockerignore`
  deixa entrar no contexto só os três arquivos copiados: `deploy/local/secrets/` não vai
  para o builder.
- **`archive_command=crm-pgbackrest archive-push %p`** e **`archive_timeout=300`** estão no
  `command` do serviço `postgres` do compose: WAL contínuo, segmento fechado a cada 5 min
  no máximo (RPO ≤ 15 min).
- **`cmd=/usr/local/bin/crm-pgbackrest`** no `pgbackrest.conf`. Sem ele, o `restore`
  escreve um `restore_command` com o `pgbackrest` puro, que não recebe a stanza nem o
  destino (vêm do ambiente que o `crm-pgbackrest` monta), e a recuperação para em
  `archive-get command requires option: stanza`. Foi o que aconteceu na primeira
  restauração da 0-03.
- **`repo1-bundle=y`**: junta os arquivos pequenos do cluster em poucos objetos (no teste,
  um completo de 2074 arquivos e o WAL ficaram em 21 objetos no `pgbackrest/`).
- **Sem `--checksum` no rclone.** O remote `crypt` não tem hash. Com `--checksum`, o
  rclone compara só o tamanho, e um objeto sobrescrito com conteúdo do mesmo tamanho não
  é copiado nem vai para `versoes/`. O `testar-local.sh` pegou isso na 0-03. O padrão
  (tamanho + data de modificação) pega.
- **Senhas do crypt.** `password` é o `BACKUP_CIPHER_PASS`; `password2` (o sal) é um
  SHA-256 dele, para que a cifra dependa de um segredo só. As duas passam ao
  `rclone obscure` por stdin, nunca como argumento.
- **`SEM_DESTINO`** é um arquivo vazio. Ter o arquivo já quer dizer "não há destino".
  Sozinho, ele faz o `archive_command` falhar; só com `BACKUP_MODO=desenvolvimento` no
  ambiente do `postgres` ele descarta. O padrão do compose é `${BACKUP_MODO-desenvolvimento}`
  (com `-`, não `:-`), para que `BACKUP_MODO=` vazio desligue o descarte.
- **O `verificar-portabilidade.sh` escreve os padrões com `[.]` e com as palavras
  partidas** (`'wr''angler'`). Assim o script não casa consigo mesmo e não precisa se
  excluir da busca: uma linha de provedor escondida nele também é recusada. Ele ignora
  pastas `secrets/` (segredos gerados, fora do git). Além de host de provedor, ferramenta
  de provedor e URL de domínio, ele recusa: destino de pgBackRest ou rclone que não venha
  de `BACKUP_S3_*`; **qualquer padrão** em `${BACKUP_S3_*}` ou `${BACKUP_CIPHER_*}`
  (`:-`, `-`, `:=`, `=`, `:+`, `+`; o `:?` passa); padrão com cara de host em qualquer
  `${VAR:-...}` (ex.: `${CRM_S3:-s3.empresa.com.br}`); valor literal atribuído a
  `BACKUP_S3_*`/`BACKUP_CIPHER_*` (só `BACKUP_S3_PORT=443` passa, o padrão do https); host
  literal sem esquema em variável com `ENDPOINT` ou `HOST` no nome; chave de remote rclone
  (`endpoint =`, `provider =`, `region =`, `access_key_id =` ...) em qualquer arquivo;
  `RCLONE_S3_*`, `RCLONE_B2_*` etc.; `provider` do rclone diferente de `Other`. Quando a
  regra é de valor de `BACKUP_*`, ele imprime só o nome, nunca o valor. Efeito colateral
  aceito: um `${VAR:-arquivo.txt}` no escopo é recusado (parece host). O que ele **não**
  pega: um destino que chegue de fora do escopo (outro diretório, variável vinda do
  ambiente da VPS) ou escrito de forma ofuscada (indireção por variável sem nome de
  `ENDPOINT`/`HOST`, por exemplo). É checagem de texto, não de execução.
- **Teste:** o `garage-destino` reusa o `garage_rpc_secret` e o `garage_admin_token` do
  Garage local (são dois clusters separados, que não se veem). O Caddy passa o
  cabeçalho `Host` intacto, porque a assinatura S3 depende dele.
- **Saídas do `testar-local.sh`:** `[falha-fechada]` (sem destino nem `BACKUP_MODO`:
  `failed_count` sobe, `.ready` em `pg_wal`), `[desenvolvimento]` (com `BACKUP_MODO`, o WAL
  pendente é descartado), `[arquivo]` (com destino, `archived_count` sobe), `[cifra]` (destino com `pgbackrest/` e `arquivos/`,
  tudo cifrado), `[restauracao]` (bancos e objeto de volta), `[versoes]` (versão anterior
  em `versoes/<dia>/`), `[troca]` (o mesmo ciclo noutro bucket com outra chave).

## Peças

| Arquivo | Papel |
|---|---|
| `deploy/postgres/Dockerfile` | `postgres:18.7` + `pgbackrest=2.60.1-1.pgdg13+1` + os scripts |
| `deploy/postgres/pgbackrest.conf` | a política (sem destino) |
| `deploy/backup/destino.sh` | o único lugar que lê o destino (o segredo `backup`) |
| `deploy/backup/pgbackrest.sh` | vira `crm-pgbackrest` na imagem: destino → `PGBACKREST_REPO*_*` |
| `deploy/backup/arquivos.sh` | rclone: `copiar`, `reter`, `restaurar`, `listar` |
| `deploy/backup/backup.sh`, `restaurar.sh` | os comandos de operação (host) |
| `deploy/backup/verificar-portabilidade.sh` | a checagem de acoplamento (suíte) |
| `deploy/backup/testar-local.sh`, `teste/` | o teste de ponta a ponta e o destino de teste |
| `deploy/backup/sem-destino/SEM_DESTINO` | o segredo padrão: "não há destino" (falha fechado; descarta só com `BACKUP_MODO=desenvolvimento`) |
