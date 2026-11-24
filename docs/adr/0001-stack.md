# ADR 0001 — O CRM é um monólito modular Java 25 + Spring Boot 4 com SPA React, em dois repositórios, jobs no db-scheduler, arquivos por S3 (Garage na VPS) e backup sem provedor fixo

Dono: Arquiteto. Data: 2026-11-24 (revisão 2, pedida em `planning/decisoes/2026-11-24.md §7`). Estado: aceito pelo humano em 2026-11-24 (`planning/decisoes/2026-11-24.md §10`)

**O que mudou na revisão 2:** a avaliação do Cloudflare R2 (seção "Arquivos"), os
dois repositórios (decisão 2, que substitui o "um repositório só" da revisão 1), o
mecanismo de backup sem acoplamento (decisão 6), a regra "o caminho mais específico
vence" no bloco do `time.yml` e os comandos para dois repositórios.

**Emenda de 2026-11-24 (realm próprio, `planning/decisoes/2026-11-24.md §12`):** o CRM
não usa o realm `sed`. Muda só o nome do realm, na linha da D-07 e na nota de P-15;
a decisão (Keycloak, BFF, o CRM como fonte de verdade dos papéis) não muda.

**Acréscimo à emenda do realm, 2026-11-24 (realm real, `planning/decisoes/2026-11-24.md
§13` e §14; spec v1.2, §5.1 e §5.2):**
- **O realm real é `crm`, em `https://akpannel.akeel.com.br`, fora da VPS do CRM.**
  Issuer `https://akpannel.akeel.com.br/realms/crm`. O nome continua vindo de
  `KEYCLOAK_REALM` e a URL base de configuração; nada disso é literal no código.
- **O Keycloak não é mais operado pelo CRM.** A instância, o banco dela, o backup, a
  atualização de versão, o console de administração e a disponibilidade são da TI da
  Akeel. Consequências neste ADR:
  - **o `compose.yaml` de produção não sobe Keycloak.** O Keycloak continua só no
    `compose.yaml` local e no Testcontainers, com uma exportação de realm de teste;
  - **o backup da decisão 6 cobre só o PostgreSQL do CRM.** A linha "Keycloak: banco
    do Keycloak incluído na mesma política" da §4.6 da spec, e o "console de
    administração do Keycloak atrás do Cloudflare Access" da §4.5, descrevem algo que
    o CRM não opera mais (achado para o Orquestrador: a spec é do Pedro);
  - **a VPS fala com o Keycloak pela internet** (`api` → `akpannel.akeel.com.br`:
    discovery, JWKS, token endpoint, Admin API). Login e renovação de sessão passam a
    depender da disponibilidade de um serviço que não é nosso; o RTO da §4.6 não o
    cobre;
  - a versão `Keycloak 26.8.2` da tabela vale para o ambiente local e de teste. A
    versão do akpannel é da TI e não foi conferida: o realm de teste deve seguir a
    mesma série maior quando ela for informada.
- **O realm local de teste passa a se chamar `crm`** (era `crm-akeel`), igual ao real,
  com os clientes da §5.1 (`crm-bff` confidencial, `crm-web`, `crm-api`) e os grupos
  `/Perfis/*`. O teste de "nenhum nome de realm fixo no código" (0-09, critério 12)
  passa a procurar `"crm"` dentro de `/realms/`; um literal `"crm"` sozinho não é
  sinal (é o pacote base), então a checagem é por `/realms/` e pelo issuer.
- **A autorização do CRM não lê os claims `roles` e `groups`** (P-19, D-09). Regra e
  teste em "Guardado por", linhas "P-19".

**Emenda de 2026-11-24 (Node, versões gerenciadas, nota de ambiente;
`planning/decisoes/2026-11-24.md §16`, `reviews/0-14.md` N1, story 0-05):**
- **Node: a faixa do projeto é `^22.13 || ^24 || >=26`.** É a interseção do que o
  frontend exige (`vitest@5.1.1`: `^22.12 || ^24 || >=26`; `eslint@10.15.0`:
  `^22.13 || >=24`); exclui 23 e 25. A máquina de desenvolvimento usa o Node 24 LTS
  (v24.22.3, conferido com `node --version`). Substitui o "Node 26 LTS" da tabela e o
  regex do `pre_requisito` da proposta, que aceitava qualquer 22.x e o 23. O
  `engines` do `package.json` é do Dev.
- **A tabela de versões é registro do que foi verificado, não exigência.** No backend,
  valem as versões que o `spring-boot-dependencies` do Boot fixado gerencia; uma
  sobrescrita (`<flyway.version>`, `<jooq.version>` etc.) só entra com motivo escrito
  no `pom.xml` (correção de segurança ou defeito que nos atinge). Com o Boot 4.2.0, isso
  dá **Flyway 12.11.0 e jOOQ 3.21.9** (conferido no `spring-boot-dependencies-4.2.0.pom`,
  linhas `<flyway.version>` e `<jooq.version>`), que é o que o `backend/pom.xml` usa
  desde o commit `5b29975`. As 13.13.0 e 3.21.10 da tabela eram as últimas do Maven
  Central, não exigência. O que é exigência está em "Guardado por" (Java 25, Boot 4.2.x).
  Alternativa considerada: fixar as últimas do Central. Mais cara (sai da matriz que o
  Boot testa, Flyway com uma versão maior acima); o gatilho que a faria valer é um
  defeito ou CVE corrigido só na versão nova.
- **Nota de ambiente (máquina do Pedro):** o `~/.mavenrc` define
  `JAVA_HOME=/opt/homebrew/opt/openjdk@25/...` e vence o `JAVA_HOME` da linha de
  comando. A sabotagem do enforcer (provar que JDK 17 quebra o build) precisa de
  `MAVEN_SKIP_RC=true`. Rodado em 2026-11-24, em `backend/`:
  `JAVA_HOME=<jdk-17> ./mvnw -B validate` passa (o `.mavenrc` troca para o 25);
  `MAVEN_SKIP_RC=true JAVA_HOME=<jdk-17> ./mvnw -B validate` → `BUILD FAILURE`,
  `Rule 0: org.apache.maven.enforcer.rules.version.RequireJavaVersion failed`.

## Contexto

Projeto novo, sem código. A spec v1.1 já decidiu a stack; este ADR registra o que
ela decidiu, fecha as escolhas que ela deixou "para o início do projeto" e diz o
que isso implica para o time.

**Já decidido pela spec (não se reabre aqui):**

| D-xx | Decisão | Onde |
|---|---|---|
| D-03 | Java 25 + Spring Boot 4, **monólito modular**; um artefato, dois modos de execução (`api` e `worker`) | §2, §4.1, §4.2 |
| D-04 | React + TypeScript + Vite, SPA (TanStack Query/Router, Radix/shadcn, dnd-kit, react-hook-form + zod) | §2, §4.2 |
| D-05 | PostgreSQL 17 ou superior; busca em `pg_trgm` + `unaccent` + `tsvector` `portuguese`, sem Elasticsearch | §2, §4.2 |
| D-06 | VPS Hostinger no Brasil, atrás do Cloudflare (DNS, proxy, Tunnel, Access); tudo em Docker Compose | §2, §4.1, §4.5 |
| D-07 | Keycloak, realm `sed`, padrão BFF (tokens só no servidor, cookie `HttpOnly`); o CRM é a fonte de verdade de papéis (D-09). **Emenda 2026-11-24:** o realm é **próprio**, não o `sed` (`decisoes/2026-11-24.md §12`); o nome vem de `KEYCLOAK_REALM`, e o realm local de teste se chama `crm-akeel`. Isso contraria o texto da D-07 (e da §5.1): **o Pedro precisa atualizar a spec**. **Acréscimo 2026-11-24 (§13):** spec v1.2 atualizada; realm `crm` em `https://akpannel.akeel.com.br`, fora da VPS e operado pela TI; o realm local de teste passa a se chamar `crm` | §2, §5.1 |
| D-22 | warpdrive (MIT) é referência de modelo, regras e código de front reaproveitável (com aviso de copyright); **o backend dele não é usado** | §2, §3.1 |

E da §4.2, sem número D-xx mas escrito na spec: Spring Modulith (fronteiras e
registro de publicação de eventos), jOOQ como acesso a dados principal, Flyway,
springdoc/OpenAPI 3.1 com cliente TS gerado, SSE + `LISTEN/NOTIFY`, Gotenberg para
PDF, JUnit 5 + Testcontainers (PostgreSQL real, nunca banco em memória) +
ArchUnit/Modulith + Playwright.

**Residência de dados, como a spec escreve** (é o que limita a escolha de arquivos
e de backup):
- §1.4: "Dados hospedados na infraestrutura da Akeel, no Brasil."
- §4.2, linha "Arquivos": "Armazenamento compatível com S3 **na VPS** (ex.: Garage ou
  SeaweedFS), com backup fora da VPS".
- §4.6, PostgreSQL: "cópia fora da VPS em provedor com dados no Brasil".
- RNF-14: "Hospedados no Brasil (VPS e backups)".
- P-17: "Solução de armazenamento S3 na VPS e destino do backup externo (provedor
  com dados no Brasil)".

**Deixado em aberto pela spec:**
- Jobs: "JobRunr ou db-scheduler (decidir no início do projeto)", persistidos no
  PostgreSQL, **proibido** cron do sistema ou thread solta para regra de negócio (§4.2).
- Arquivos: a solução S3 na VPS e o destino do backup fora dela (P-17).

**Versões verificadas em 2026-11-24** (Maven Central `maven-metadata.xml`, Docker
Hub, API do Adoptium, releases no GitHub):

| Item | Versão | Observação |
|---|---|---|
| Java | 25 | LTS mais recente segundo `api.adoptium.net` (`most_recent_lts: 25`) |
| Spring Boot | 4.2.0 | |
| Spring Modulith | 2.2.0 | o `spring-modulith-starter-core` 2.2.0 depende de `spring-boot-starter` 4.2.0 |
| jOOQ | 3.21.10 | última do Central; vale a 3.21.9 gerenciada pelo Boot 4.2.0 (emenda Node/versões) |
| Flyway | 13.13.0 | última do Central; vale a 12.11.0 gerenciada pelo Boot 4.2.0 (emenda Node/versões) |
| db-scheduler | 17.2.0 | Apache 2.0; tem `db-scheduler-spring-boot-4-starter` 17.2.0 |
| JobRunr | 9.0.5 | LGPL v3 + licença comercial; tem `jobrunr-spring-boot-4-starter` 9.0.5 |
| ArchUnit | 1.5.1 | |
| Testcontainers | 2.0.5 | |
| PostgreSQL | 18.7 (imagem `postgres:18`) | cumpre "17 ou superior" |
| Keycloak | 26.8.2 | |
| Garage | v2.5.0 (2026-10-24) | AGPL-3.0 |
| SeaweedFS | 4.55 (2026-11-23) | Apache 2.0 |
| pgBackRest | 2.60.1 (2026-11-16) | `api.github.com/repos/pgbackrest/pgbackrest/releases/latest` |
| restic | 0.20.0 (2026-11-19) | `api.github.com/repos/restic/restic/releases/latest` |
| Vite | 8.3.8 | exige Node `^20.19.0 \|\| >=22.12.0` |
| Node | faixa `^22.13 \|\| ^24 \|\| >=26`; máquina em 24 LTS (v24.22.3) | emenda Node/versões; era "26 LTS" |

**Achado de ambiente** (reconferido em 2026-11-24, revisão 2): a máquina do Pedro
continua só com o JDK 17 (`/usr/libexec/java_home -V` lista um único `17.0.12`),
Node v23.11.0, Docker com daemon de pé (`docker info` → exit 0), git 2.50.1, sem
Maven nem Gradle. Sem o JDK 25, a suíte é inexecutável. A instalação
(`brew install --cask temurin@25`) pede sudo e fica com o Pedro (§7).

## Arquivos: o Cloudflare R2 no lugar do Garage (avaliação pedida em §7)

Fontes lidas em 2026-11-24, na documentação oficial (versão `.md` de cada página):

| O que | O que a página diz | Fonte |
|---|---|---|
| Camada gratuita | Por mês: **10 GB-mês** de armazenamento, **1 milhão** de operações Classe A, **10 milhões** de Classe B; egress gratuito. Vale só para a classe Standard | developers.cloudflare.com/r2/pricing/ (modificada em 2026-10-30) |
| Acima dela | Standard: US$ 0,015/GB-mês; Classe A US$ 4,50/milhão; Classe B US$ 0,36/milhão; egress continua gratuito. Arredonda para cima (1,1 GB-mês cobra 2) | idem |
| O que é Classe A / B | A: `PutObject`, `CreateMultipartUpload`, `UploadPart`, `CompleteMultipartUpload`, `ListObjects`, `PutBucketCors`… B: `GetObject`, `HeadObject`… Grátis: `DeleteObject`, `AbortMultipartUpload` | idem |
| **Localização** | *Location hints* disponíveis: `wnam`, `enam`, `weur`, `eeur`, `apac`, `oc`. **Não há América do Sul.** O hint é "best effort and not a guarantee" | developers.cloudflare.com/r2/reference/data-location/ (modificada em 2026-08-19) |
| **Jurisdição** (a única garantia de residência) | Só `eu`, `fedramp` e `us`. **Não há Brasil.** A jurisdição não muda depois de criado o bucket | idem |
| URL pré-assinada | GET, PUT, HEAD, DELETE; validade de 1 s a 7 dias. **Só no domínio `<ACCOUNT_ID>.r2.cloudflarestorage.com`, não em domínio próprio.** Upload por `POST` de formulário não é suportado | developers.cloudflare.com/r2/api/s3/presigned-urls/ (modificada em 2026-11-12) |
| Multipart | `CreateMultipartUpload`, `UploadPart`, `CompleteMultipartUpload`, `AbortMultipartUpload`, `ListParts`, `ListMultipartUploads`: suportados | developers.cloudflare.com/r2/api/s3/api/ (modificada em 2026-11-10) |
| CORS | `PutBucketCors`/`GetBucketCors`/`DeleteBucketCors` suportados; a página de CORS cobre o caso "URL pré-assinada" | idem; developers.cloudflare.com/r2/buckets/cors/ |
| Fora do suporte | Versionamento (`PutBucketVersioning` ❌), Object Lock via S3 ❌ (existe "bucket lock" pela API própria da Cloudflare), região sempre `auto` | developers.cloudflare.com/r2/api/s3/api/; /r2/buckets/bucket-locks/ |

**Leitura:**

1. **Residência: o R2 contraria a spec.** Ele não tem jurisdição nem hint no Brasil
   ou na América do Sul; um bucket criado daqui cai na "região disponível mais
   próxima", que não é brasileira. Isso fere a §1.4, a linha "Arquivos" da §4.2
   ("na VPS"), a RNF-14 e a P-17, tanto para os arquivos quanto para o backup (a
   RNF-14 diz "VPS **e backups**"). Só o Pedro pode mudar a spec. Este ADR não a
   reabre; apresenta a escolha (pergunta 1, no fim).
2. **Compatibilidade técnica: o R2 serve.** Pré-assinatura (usamos PUT e GET, não
   POST), multipart e CORS estão cobertos. O que muda no código é configuração:
   `region=auto` e o endpoint da conta; a CSP (RF-SEC-02) teria de liberar
   `https://*.r2.cloudflarestorage.com` em `connect-src`/`img-src`.
3. **Custo: não é o argumento.** Para ~50 usuários e anexos de até 25 MB (spec, tabela
   de anexos e RF-IMP-02), os 10 GB grátis cobrem o começo, e 100 GB custariam
   cerca de US$ 1,35/mês (90 GB × 0,015). O Garage usa o disco da VPS, que já é pago.
4. **Encaixe com D-06 (já estamos no Cloudflare): menor do que parece.** A URL
   pré-assinada do R2 só funciona no domínio `r2.cloudflarestorage.com`, então o
   navegador fala com o R2 **fora** da nossa zona: o Access e o WAF da zona não se
   aplicam a esse tráfego. O ganho real é operacional (sem disco nem processo na
   VPS, egress zero). Já o Garage atrás do Tunnel fica sob a nossa zona, com o
   limite de corpo de requisição do plano Free/Pro, **100 MB**
   (developers.cloudflare.com/workers/platform/limits/ e
   /cache/concepts/default-cache-behavior/, "Max upload size"): sobra para o limite
   de 25 MB da spec, e o multipart com partes menores que isso cobre arquivos maiores
   se um dia vierem.

**Recomendação:** manter o **Garage na VPS** como implementação, porque é o único dos
dois que cumpre a spec como ela está. O CRM fala **só S3**, e **só por
`platform.storage`**, com endpoint, região, bucket, estilo de URL (path ou
virtual-host) e credenciais vindos de configuração, sem valor padrão no código.
Assim, R2, Garage, SeaweedFS ou um S3 gerenciado no Brasil se trocam por
configuração, mais uma cópia dos objetos. Se o Pedro mudar a spec para aceitar
arquivos fora do Brasil, a troca para o R2 não exige ADR de código, só de
infraestrutura.

## Decisão

1. **Stack:** a da spec, nas versões da tabela acima (as linhas da mesma série
   menor podem subir de patch sem novo ADR).
2. **Dois repositórios git de produto, dentro deste projeto** (§7): `backend/`
   (Maven com wrapper `./mvnw`, `maven.compiler.release=25`) e `frontend/` (npm).
   Este repositório raiz guarda método, spec, planning, docs, deploy e conflitos.
   - **O raiz ignora as duas pastas** (`/backend/` e `/frontend/` no `.gitignore`
     da raiz, que é do DevOps). Submódulo foi considerado e recusado (ver
     Alternativas).
   - **O raiz não registra qual versão do back combina com qual do front; o
     `deploy/` registra.** O manifesto de deploy (DevOps) fixa a tag da imagem do
     backend e a do frontend que sobem juntas; é esse o registro que importa para
     produção. Como clonar as duas pastas fica em `docs/operacao/` (DevOps).
   - **Contrato OpenAPI entre os dois repositórios:** o backend gera e versiona
     `backend/openapi/openapi.json` (um teste do backend falha se o arquivo divergir
     do que o springdoc produz). O frontend versiona uma **cópia** em
     `frontend/openapi/openapi.json` e gera o cliente TS a partir dela, para que o
     CI do frontend rode sozinho. A `suite` do `time.yml` compara as duas (`cmp`):
     cópia velha fica vermelha no raiz.
3. **Pacote base** `br.com.akeel.crm`. Cada módulo da §4.3 é um pacote de topo
   (módulo do Spring Modulith). Infraestrutura sem regra de negócio (jobs,
   armazenamento, e-mail, outbox) fica em `br.com.akeel.crm.platform`, com um
   subpacote por adaptador.
4. **Jobs: db-scheduler.** Eventos de domínio seguem pelo registro de publicação do
   Spring Modulith (outbox, §4.4); o db-scheduler fica com o que é **por tempo**:
   lembretes, apodrecimento, resumo diário, purga da lixeira, novas tentativas de
   webhook, lotes da migração. Motivo: uma tabela no PostgreSQL que o Flyway
   controla, Apache 2.0 sem edição paga, tarefa nomeada por string (renomear uma
   classe não quebra o que já está agendado). No modo `api` o agendador não executa,
   só agenda; quem executa é o `worker`.
5. **Arquivos: S3 por `platform.storage`, com o Garage em nó único na VPS**
   (`replication_factor = 1`), pelo SDK S3 da AWS. Upload e download por URL
   pré-assinada (PUT/GET, nunca POST de formulário, que o R2 não aceita: assim
   nada no CRM prende a escolha). Configuração `crm.storage.endpoint`, `.region`,
   `.bucket`, `.path-style`, `.access-key`, `.secret-key`, todas obrigatórias, sem
   padrão. O Garage **não** tem versionamento de objeto nem política de bucket; o
   R2 também não tem versionamento. O CRM não depende de nenhum dos dois.
6. **Backup: mecanismo neutro, destino por variável de ambiente** (§7: o destino
   está em aberto e não pode haver acoplamento forte).
   - **PostgreSQL (CRM; o do Keycloak saiu pela emenda de §13, é da TI): pgBackRest** com repositório `s3`
     (`repo1-s3-endpoint`, `repo1-s3-bucket`, `repo1-s3-region`,
     `repo1-s3-uri-style`, opções conferidas em pgbackrest.org/configuration.html
     em 2026-11-24), cifrado no cliente (`repo1-cipher-type=aes-256-cbc`), backup
     completo diário e WAL contínuo (RPO ≤ 15 min da §4.6). Retenção da §4.6
     (35 diários + 12 mensais) por `repo1-retention-*`.
   - **Arquivos: rclone de S3 para S3**, diário, com `--backup-dir` datado para que
     objeto apagado ou sobrescrito no primário vá para um prefixo do dia em vez de
     sumir; a retenção apaga os prefixos pela data no nome. Cifrado no cliente
     (remote `crypt` do rclone). O restic (S3 genérico, cifrado e com retenção
     pronta) é a alternativa se o DevOps preferir montar uma área de preparação no
     disco; os dois falam com qualquer S3.
   - **O destino é só configuração:** `BACKUP_S3_ENDPOINT`, `BACKUP_S3_REGION`,
     `BACKUP_S3_BUCKET`, `BACKUP_S3_URI_STYLE`, `BACKUP_S3_ACCESS_KEY`,
     `BACKUP_S3_SECRET_KEY`, `BACKUP_CIPHER_PASS`, vindos do arquivo de segredos do
     Docker (RF-SEC-03). Trocar de provedor é trocar essas variáveis e rodar um
     backup completo novo.
   - **Cifrar no cliente não resolve residência.** O destino ainda precisa ter dados
     no Brasil (RNF-14, P-17); o R2 não serve como destino pelo mesmo motivo da
     seção anterior.
   - Os detalhes (agenda, retenção por data, restauração mensal documentada) são do
     DevOps, em `deploy/backup/` e `docs/operacao/`.
7. **CI: um em cada repositório de produto, e o deploy no raiz.**
   - `backend/.github/workflows/` e `frontend/.github/workflows/`: passos 1 a 3 da
     §4.5 (build e testes, análise estática e de dependências, imagem), cada um com
     a própria suíte. O do backend precisa de Docker no runner (Testcontainers).
   - `.github/workflows/` do raiz: passos 4 e 5 (homologação + e2e, produção com
     aprovação manual e Flyway como etapa própria), lendo as tags fixadas no
     manifesto de `deploy/`, mais a comparação do contrato OpenAPI. Os testes e2e
     (Playwright) vivem no repositório do frontend (`frontend/e2e/`) e o workflow do
     raiz faz checkout dele na tag fixada. Isso exige o raiz num remoto (hoje
     `git remote -v` não lista nenhum): pergunta 3.

## Alternativas consideradas

| Alternativa | Por que não agora | Gatilho que a faria valer |
|---|---|---|
| **Cloudflare R2** (arquivos) | Cumpre o técnico (pré-assinatura PUT/GET, multipart, CORS) e é barato, mas não tem jurisdição nem hint no Brasil: contraria §1.4, §4.2, RNF-14 e P-17. A pré-assinatura só no domínio do R2 tira os arquivos da nossa zona do Cloudflare | O Pedro mudar a spec para aceitar arquivos fora do Brasil, **ou** a Cloudflare publicar jurisdição/hint no Brasil (conferir a página de data location). A troca é configuração de `platform.storage` + cópia dos objetos |
| **Cloudflare R2 como destino de backup** | A RNF-14 diz "VPS **e backups**" no Brasil | O mesmo gatilho acima; aí ele é só mais um valor de `BACKUP_S3_ENDPOINT` |
| **JobRunr** (jobs) | Painel pronto e API por lambda são confortáveis, mas o job serializado aponta para classe e método (refatorar quebra job enfileirado) e parte dos recursos fica na edição Pro paga (conferir a matriz antes de reabrir). Para ~50 usuários e jobs por tempo, é mais do que precisamos | Alguém fora do time técnico precisar ver e reprocessar jobs num painel, ou surgirem fluxos encadeados/lotes que o db-scheduler obrigue a montar à mão |
| `@Scheduled` + ShedLock (jobs, a mais barata) | A spec exige jobs persistidos no PostgreSQL e proíbe thread solta para regra de negócio (§4.2); isso não persiste nada | — (a spec fecha) |
| **SeaweedFS** (S3) | Apache 2.0 e mais recursos, mas mais peças (master, volume, filer, gateway S3) para operar numa VPS | Precisarmos de versionamento de objeto, ou de crescer para vários nós/discos com rebalanceamento |
| MinIO (S3) | O repositório comunitário foi arquivado: `github.com/minio/minio` está `archived: true` e o README diz "THIS REPOSITORY IS NO LONGER MAINTAINED", apontando para edições AIStor | — |
| Disco local da VPS atrás de uma interface de armazenamento (a mais barata) | A spec pede compatível com S3 (§4.2) e a URL pré-assinada tira o tráfego de arquivo do `api`. Fica como saída de emergência: como só `platform.storage` conhece o S3, trocar é local | P-07 apertar o prazo a ponto de o Garage atrasar a Onda 0 |
| Object storage S3 gerenciado **com dados no Brasil** | A spec quer o armazenamento na VPS | A Akeel aceitar arquivos fora da VPS (mas no Brasil); aí o mesmo provedor pode servir de destino de backup (P-17) |
| **Submódulos git** no raiz (repositórios) | Cada commit de produto pediria um segundo commit no raiz para mover o ponteiro; Devs em paralelo disputariam esse ponteiro; `git submodule update` esquecido deixa a pasta numa versão velha sem aviso. O que o submódulo daria (qual back combina com qual front) o manifesto de `deploy/` já dá, no lugar onde isso importa | Precisarmos reproduzir o par exato back+front de um commit do raiz fora do deploy (ex.: auditoria que exija isso) |
| **Um repositório só** (monorepo, revisão 1 deste ADR) | O Pedro decidiu separar (§7) | Os custos da separação (cópia do contrato, CI em três lugares, worktrees, pergunta 2) pesarem mais que o ganho. Fica registrado como a opção mais barata |
| Backup acoplado ao armazenamento (snapshot de diretório do Garage, replicação nativa de um provedor, `aws s3 sync`, `wrangler`) | Prende o backup à escolha do armazenamento ou do destino, o contrário do que §7 pede | — |
| Gradle em vez de Maven | Nenhuma vantagem que pague a diferença num projeto de um artefato | Build multi-projeto com muita lógica própria |

## Guardado por

Os testes nascem na Onda 0; aqui só a proposta. Todos rodam em `comandos.arquitetura`
(exceto onde indicado).

| Decisão | Teste que fica vermelho |
|---|---|
| Monólito modular (D-03, §4.3) | `ModularityTest`: `ApplicationModules.of(CrmApplication.class).verify()` (ciclos e acesso a internos de outro módulo). A lista de módulos que ele imprime é a mesma do diagrama de módulos (conferência do Arquiteto) |
| Sem cron nem thread solta (§4.2) | `ArchitectureTest`: nenhum método com `@Scheduled`; nenhuma classe fora de `platform..` usa `java.util.Timer`, `java.util.concurrent.Executors` ou `new Thread` |
| db-scheduler isolado | `ArchitectureTest`: só `..platform.jobs..` depende de `com.github.kagkarlsson..` |
| S3 isolado (troca de provedor por configuração) | `ArchitectureTest`: só `..platform.storage..` depende de `software.amazon.awssdk..` |
| Nenhum provedor de S3 no código | `StorageConfigTest` (no pacote de arquitetura): nenhum arquivo em `backend/src/main/**` contém `r2.cloudflarestorage.com`, `amazonaws.com` nem outro host de provedor; `crm.storage.endpoint` não tem valor padrão |
| `platform.storage` funciona com um S3 que não é o da produção | Teste de integração (suíte, do QA) contra a imagem `dxflrs/garage` como contêiner genérico: pré-assina PUT e GET, faz multipart e confere o CORS |
| jOOQ como acesso principal (§4.2) | `ArchitectureTest`: `jakarta.persistence..` só é permitido em pacotes listados explicitamente (vazia no início); quem incluir abre a exceção no teste, com o motivo |
| Contrato OpenAPI igual nos dois repositórios | Na `suite`: `cmp backend/openapi/openapi.json frontend/openapi/openapi.json`. No backend, um teste compara o arquivo com o que o springdoc gera |
| Backup sem acoplamento (§7) | DevOps: `deploy/backup/verificar-portabilidade.sh`, na `suite`, falha se `deploy/backup/**` ou `compose.yaml` tiver host de provedor ou ferramenta de provedor (`wrangler`, `aws s3`, `b2`) ou destino fora de `BACKUP_S3_*`. Prova por presença, no CI do raiz: backup e restauração rodam também contra um Garage local, com os mesmos scripts |
| D-22 (backend do warpdrive não entra) | Sem asserção possível além da stack: o warpdrive é TypeScript e o backend é Java. O aviso de copyright do código de front copiado é verificação do Revisor |
| Java 25 / Spring Boot 4 | `maven-enforcer-plugin` com `requireJavaVersion [25,)` e o `parent` em `spring-boot-starter-parent` 4.2.x: o build falha antes dos testes |
| PostgreSQL 17+ (D-05) | Teste de integração (suíte, não arquitetura) que lê `server_version_num` do contêiner e exige `>= 170000` |
| **P-19** (D-09): só `identity` lê claims do token | `ArchitectureTest`: nenhuma classe fora de `br.com.akeel.crm.identity..` chama métodos de `org.springframework.security.oauth2.core.ClaimAccessor` (`getClaim*`, `getClaims`; cobre `Jwt`, `OidcIdToken`, `OidcUserInfo`), `OidcUser.getClaims/getIdToken/getUserInfo` nem `OAuth2AuthenticatedPrincipal.getAttribute(s)`; e nenhuma classe fora de `identity..` depende de `JwtGrantedAuthoritiesConverter` nem de `GrantedAuthoritiesMapper`. Gêmeo por presença: uma classe de fixture fora de `identity` que chama `jwt.getClaimAsStringList("roles")` é acusada |
| **P-19** dentro de `identity` | ArchUnit não vê o argumento `"roles"`, então dentro do módulo a garantia é de comportamento (QA, IAM): usuário com papel `vendedor` no CRM e token com `roles=[admin]` e `groups=[/Perfis/Administradores]` recebe 403 numa rota de administrador; o inverso (papel `admin` no CRM, token sem `roles`) recebe 200. Nasce na Onda 1, quando existirem `app_user` e papéis |

D-06 e D-07 são de infraestrutura e configuração: guardados pelo DevOps (deploy) e
pelos testes de IAM da Onda 0, não por teste de arquitetura.

**Por que a regra de P-19 é de dependência e não de texto:** quem lê `roles` precisa
de um acessor de claims; restringi-lo a `identity` deixa um só módulo a revisar. O
`access` (conjuntos de permissões e visibilidade) decide pelo banco, nunca pelo token.
Alternativa mais barata considerada: só o teste de comportamento, sem regra no
`ArchitectureTest`. Não basta, porque ele prova uma rota, não todas; a regra cobre
o resto do código pelo custo de uma asserção.

## Consequências para o time

**Proposta para o `time.yml`** (quem escreve é o Pedro). Os caminhos continuam
relativos à raiz deste projeto, mesmo dentro dos repositórios de produto.

```yaml
comandos:
  # Sem os dois clones, o JDK 25, o Node e o Docker, a suíte é inexecutável, não vermelha.
  pre_requisito: "test -d backend/.git && test -d frontend/.git && docker info >/dev/null 2>&1 && java -version 2>&1 | grep -q 'version \"25' && node --version | grep -qE '^v(22\\.(1[3-9]|[2-9][0-9])|24|2[6-9]|[3-9][0-9])\\.'"   # faixa ^22.13 || ^24 || >=26 (emenda Node/versões)
  # Roda a suíte de cada repositório, depois o que só o raiz enxerga (contrato e backup).
  suite: "(cd backend && ./mvnw -B verify) && (cd frontend && npm ci --no-audit --no-fund && npm test) && cmp backend/openapi/openapi.json frontend/openapi/openapi.json && sh deploy/backup/verificar-portabilidade.sh"
  suite_backend: "cd backend && ./mvnw -B verify"
  suite_frontend: "cd frontend && npm ci --no-audit --no-fund && npm test"
  teste_unico: "(cd backend && ./mvnw -B test -Dtest={classe} -Dsurefire.failIfNoSpecifiedTests=false)"
  teste_unico_frontend: "(cd frontend && npx vitest run {arquivo})"
  arquitetura: "(cd backend && ./mvnw -B test -Dtest='ModularityTest,ArchitectureTest,StorageConfigTest')"

# Regra de sobreposição (aceita pelo Pedro em decisoes/2026-11-24.md §7):
# quando dois caminhos casam com o mesmo arquivo, o mais específico vence.
escrita:
  arquiteto: [docs/adr/**, docs/arquitetura/**, SISTEMA.md,
              backend/src/test/java/br/com/akeel/crm/architecture/**]   # vence backend/src/test/** do QA
  qa: [backend/src/test/**, frontend/test/**, frontend/e2e/**]
  dev: [backend/src/main/**, backend/openapi/**, backend/pom.xml, backend/.mvn/**, backend/mvnw, backend/mvnw.cmd,
        frontend/src/**, frontend/public/**, frontend/openapi/**, frontend/index.html, frontend/package.json,
        frontend/package-lock.json, frontend/vite.config.ts, frontend/vitest.config.ts,
        frontend/tsconfig*.json, frontend/eslint.config.js, frontend/playwright.config.ts]
  devops: [deploy/**, docs/operacao/**, .github/**, .gitignore, compose.yaml,
           backend/.github/**, backend/Dockerfile, backend/.dockerignore, backend/.gitignore,
           frontend/.github/**, frontend/Dockerfile, frontend/.dockerignore, frontend/.gitignore]
```

Notas sobre a proposta:
- **`suite_backend`, `suite_frontend` e `teste_unico_frontend` são chaves novas.** O
  método só conhece `suite`, `teste_unico` e `arquitetura`; as novas servem para o
  despacho de uma story que toca um repositório só. Se o Pedro preferir não criar
  chaves, ficam como comentário, como na revisão 1.
- **A `suite` falha hoje e na primeira story da Onda 0**, até existirem os dois
  clones, o `openapi.json` dos dois lados e o script de portabilidade. Isso é
  "inexecutável" (o `pre_requisito` acusa a falta dos clones), não vermelho.
- **Testes de front fora de `frontend/src/`**, em `frontend/test/` (Vitest) e
  `frontend/e2e/` (Playwright), para que nenhum caminho tenha dois donos sem regra.
  Vitest não está na spec; é o executor natural do Vite e o proponho aqui.
- **Todos os testes do backend no Surefire** (sem divisão unitário/integração no
  Failsafe), para que `teste_unico` rode qualquer classe, inclusive as com
  Testcontainers. `verify` roda o enforcer e os testes.
- **Playwright fica fora da `suite`:** precisa da stack de pé. Roda no workflow de
  deploy do raiz (decisão 7).
- **Uma story que toca os dois lados vira dois commits, um em cada repositório.** A
  story cita os dois; o Revisor recebe os dois diffs; a consolidação por
  `cherry-pick` (TIME.md §4.5) acontece em cada repositório, e a suíte é remedida
  nos dois `main`.
- **`pre_requisito` rodado em 2026-11-24 (revisão 2), parte a parte:** clones
  ausentes (`backend/` e `frontend/` não existem), `docker=0`, `java=1` (17.0.12),
  `node=0` (v23.11.0).
- O `compose.yaml` da raiz sobe PostgreSQL, Keycloak (só local, realm de teste `crm`; emenda de §13), Garage, Gotenberg e Mailpit
  para o ambiente local, e o Garage de teste do backup (DevOps).
- O Garage não tem módulo pronto no Testcontainers: o teste de `platform.storage`
  sobe `dxflrs/garage` como contêiner genérico e roda `layout assign`/`key
  create`/`bucket create` no início. Custo pequeno, da Onda 0.

**Pendências da spec que tocam a stack:**
- **P-15 (realm `sed` compartilhado).** Não muda a stack nem os comandos. Muda quem
  opera o Keycloak: se o realm é compartilhado, provavelmente a instância não é
  nossa, e o `compose.yaml` só sobe Keycloak para desenvolvimento, com uma
  exportação de realm `sed` de teste. Como o CRM é a fonte de verdade dos papéis
  (D-09), não dependemos de papéis do realm. Até P-15 fechar, a Onda 0 escreve IAM
  contra um realm local.
  **Emenda 2026-11-24:** P-15 respondida em `decisoes/2026-11-24.md §12`: o realm é
  próprio do CRM, com nome real ainda a definir pelo Pedro. Até lá o nome vem de
  `KEYCLOAK_REALM` (sem valor fixo no código), e o realm local de teste, exportado
  para o `compose.yaml`, se chama `crm-akeel`. Como a D-07 da spec ainda diz `sed`,
  o Pedro precisa atualizá-la (e a §5.1). O texto acima fica como registro do que
  se supunha antes da resposta.
  **Acréscimo 2026-11-24 (`decisoes/2026-11-24.md §13`):** a P-15 fechou de vez. O
  realm é `crm`, em `https://akpannel.akeel.com.br`, operado pela TI; a suposição
  acima ("a instância provavelmente não é nossa") se confirmou. O `compose.yaml`
  sobe Keycloak só no ambiente local, com o realm de teste `crm` (não mais
  `crm-akeel`); o de produção não sobe Keycloak.
- **P-07 (fim do Pipedrive).** Não muda a stack. Foi por ela que escolhi as opções
  de menor configuração (db-scheduler, Garage em nó único) e deixei a saída de disco
  local registrada acima.
- **P-17** fica meio fechada: a solução S3 é proposta aqui e o mecanismo de backup
  também; o **destino** do backup (provedor S3 com dados no Brasil) continua com o
  time técnico e a TI da Akeel, e entra só como valor de `BACKUP_S3_*`.

## Perguntas para o Pedro

1. **[Respondida: Garage na VPS, spec intacta, `decisoes/2026-11-24.md §9`]** **R2 x spec.** O R2 não guarda dados no Brasil (só jurisdições `eu`, `fedramp`,
   `us`; hints sem América do Sul). Duas saídas: (a) manter a spec e o Garage na
   VPS (**recomendo**); (b) o Pedro muda a §1.4, a §4.2, a RNF-14 e a P-17 para
   aceitar arquivos (e backups?) fora do Brasil, e aí o R2 entra por configuração.
   A escolha também é da Akeel, porque toca LGPD.
2. **[Respondida: saída (b), paralelo só entre backend e frontend e em série dentro de cada repositório, `decisoes/2026-11-24.md §10`]** **Repositórios separados e worktrees (problema sério).** O TIME.md §4.4 manda cada
   Dev em paralelo num worktree. Um worktree do **raiz** não contém `backend/` nem
   `frontend/` (são repositórios ignorados), então o worktree automático dos agentes
   (`.claude/worktrees/`) chega sem código. Saídas: (a) os worktrees são criados
   dentro do repositório de produto (`git -C backend worktree add …`), e o
   Orquestrador traduz os caminhos de `escrita` para o worktree; (b) Devs em paralelo
   só em repositórios diferentes (um no back, um no front), e em série dentro de cada
   um; (c) voltar ao monorepo. **Recomendo (b) na Onda 0** (pouco paralelismo, zero
   ferramenta nova) e medir antes de montar (a). Confirmar também a leitura do §7:
   dois repositórios git nas subpastas, o raiz ignorando as duas.
3. **[Respondida: GitHub privado, deploy no `.github/` do raiz, `decisoes/2026-11-24.md §10`]** **Onde fica o raiz.** O deploy (passos 4 e 5 da §4.5) fica no `.github/` do raiz,
   que hoje não tem remoto. Ele vai para um repositório privado no GitHub, como o
   kit (P-03)? Se não, o workflow de deploy passa para o repositório do backend.
4. **Destino do backup.** Continua aberto (§7). O mecanismo aceita qualquer S3; a
   spec exige que o provedor tenha dados no Brasil.
