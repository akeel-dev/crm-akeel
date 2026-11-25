# Deploy: manifesto, script e workflow

Dono: DevOps (`time.yml`, `escrita.devops`). Origem: story 0-04; spec v1.2 §4.5, passos 4
e 5; ADR 0001, decisões 2 e 7; ADR 0003, emenda §15, itens 1, 3 e 4. Os arquivos de
`deploy/` e `.github/` não têm comentário (`decisoes/2026-11-24.md §17`): as explicações
ficam aqui.

**Estado em 2026-11-25:** o deploy existe como código e roda na **homologação local**. O
deploy real (VPS, Cloudflare Tunnel, segredos de produção) espera o Pedro
(`decisoes/2026-11-24.md §24`); a lista do que falta está no fim.

## Os arquivos

| Arquivo | O que é |
|---|---|
| `deploy/manifesto.env` | o par que sobe junto: `CRM_BACKEND_TAG` e `CRM_FRONTEND_TAG`. A tag é o hash completo do commit de cada repositório, o mesmo `github.sha` que o CI de cada um usa na imagem (`crm-backend:<sha>`, `crm-frontend:<sha>`) |
| `deploy/deploy.sh <ambiente>` | o deploy. Ambientes: `homologacao-local` e `producao` |
| `deploy/comum.sh` | funções do deploy: carrega manifesto e ambiente, monta o `docker compose` do ambiente |
| `deploy/imagens.sh` | constrói as duas imagens do manifesto a partir do commit fixado (`git archive <tag> \| docker build -`), não da pasta de trabalho. Pula a imagem que já existe |
| `deploy/contrato.sh [raiz]` | `cmp` dos dois `openapi.json`, o mesmo da `comandos.suite` |
| `deploy/aplicacao/compose.yaml` | os serviços da aplicação, iguais em todo ambiente: `migrate` e `aplicar-cors` (passos únicos, perfil `passos`), `api`, `worker`, `frontend`, `proxy` |
| `deploy/aplicacao/proxy.conf.template` | o proxy reverso (nginx). O `envsubst` da imagem troca `${CRM_ESQUEMA_PUBLICO}` na subida |
| `deploy/homologacao/ambiente.env`, `compose.yaml` | o ambiente `homologacao-local`: valores não secretos e a infraestrutura local (PostgreSQL, Keycloak de teste, Garage, Mailpit) |
| `deploy/homologacao/verificar.sh` | as checagens que o deploy local roda no fim (abaixo) |
| `deploy/homologacao/e2e.sh` | o e2e do frontend contra a homologação |
| `deploy/producao/ambiente.env`, `compose.yaml`, `garage.toml`, `postgres/10-banco.sh` | o ambiente `producao`: só o PostgreSQL do CRM (o Keycloak é o da TI) e o Garage, sem segredo legível por todos. **Nunca executado** |
| `.github/workflows/deploy.yml` | o workflow do raiz (passos 4 e 5) |
| `.github/actionlint.yaml` | declara o rótulo `crm-producao` do runner da VPS para o actionlint |

## O que o `deploy.sh` faz, nesta ordem

1. Carrega `deploy/manifesto.env` (ou o arquivo de `CRM_MANIFESTO`) e
   `deploy/<ambiente>/ambiente.env`. Para se a imagem de alguma tag não existir.
2. Sobe a infraestrutura do ambiente (`CRM_INFRA`) e espera `healthy`.
3. **Migração como etapa própria:** `docker compose run --rm migrate` (a imagem do backend
   com `CRM_MODE=migrate`, que roda o Flyway e sai com 0). Se sair diferente de 0, o script
   para aqui: nada foi trocado e as instâncias que estavam de pé continuam respondendo.
4. **CORS do bucket como etapa própria:** `docker compose run --rm aplicar-cors` (a imagem do
   backend com `--crm.storage.apply-cors`), com `CRM_STORAGE_CORS_ORIGINS` igual a
   `CRM_ORIGEM_PUBLICA`. Mesma regra: falhou, nada é trocado. É o que fecha o N1 de
   `reviews/0-13.md` (o backend só aplica o CORS quando alguém pede).
5. Troca `api` e `worker` (`up -d --wait --no-deps`), espera o health.
6. Troca `frontend` e `proxy`, espera o health.
7. Registra a hora de início e a imagem de cada contêiner.
8. Roda `CRM_VERIFICACAO`, se o ambiente tiver (a homologação local tem; produção não).

O `api` e o `worker` sobem com `SPRING_PROFILES_ACTIVE=prod` também na homologação: com
`prod`, eles recusam subir se houver migração pendente, e é por isso que a migração vem
antes.

### Segredos como segredos do Docker

Nenhum segredo vai para `environment:`. O compose monta cada arquivo de `CRM_SEGREDOS` em
`/run/secrets/` com o nome da propriedade, e o backend lê a pasta com
`SPRING_CONFIG_IMPORT=configtree:/run/secrets/`:

| Arquivo em `CRM_SEGREDOS` | Em `/run/secrets/` (vira a propriedade) |
|---|---|
| `crm_bff_client_secret` | `KEYCLOAK_CLIENT_SECRET` |
| `crm_db_password` | `spring.datasource.password` |
| `garage_s3_access_key_id` | `crm.storage.access-key` |
| `garage_s3_secret_access_key` | `crm.storage.secret-key` |

Na homologação local, `CRM_SEGREDOS=./local/secrets` (relativo a `deploy/`): os valores
falsos que `deploy/local/gerar-segredos.sh` gera, os mesmos do realm de teste. Em produção,
`/etc/crm-akeel/segredos` na VPS.

### O proxy

Um host, um proxy. Para a `api` vão só `/api/`, `/oauth2/authorization/`,
`/login/oauth2/code/` e `/logout` (exato); todo o resto vai para a SPA, inclusive `/api`,
`/oauth2/authorization` e `/login/oauth2/code` sem a barra final (sem as três linhas
exatas, o nginx responderia 301 para a versão com barra). Nenhum cabeçalho de CORS.

Para a `api`, o proxy repassa:

- `Host` original (`$http_host`): o Spring monta o `redirect_uri` com ele;
- `X-Forwarded-Proto` com `CRM_ESQUEMA_PUBLICO` do ambiente (`http` na homologação local,
  `https` em produção atrás do Tunnel);
- `X-Forwarded-Port` com a porta do `Host`, ou 443/80 conforme o esquema. Sem ele, o Tomcat
  (`RemoteIpValve`) troca a porta pela padrão do esquema e o `redirect_uri` perde o `:18080`.

O backend só aceita esses cabeçalhos de um proxy em rede privada
(`server.request.header.forwarded.strategy=web-server`, ADR 0003).

O nginx resolve `api` e `frontend` a cada 10 s (`resolver 127.0.0.11`), para seguir os
contêineres trocados. O `deploy.sh` passa um hash do template ao proxy
(`CRM_PROXY_CONFIGURACAO`): mudar a configuração do proxy faz o compose recriá-lo. Sem isso,
o arquivo mudava no disco e o proxy de pé continuava com o antigo (medido em 2026-11-25).

## Homologação local

### Rodar

Da raiz, com o Docker de pé e `deploy/local/secrets/` gerado
(`sh deploy/local/gerar-segredos.sh`):

```
sh deploy/imagens.sh                       # constrói as tags do manifesto, se faltarem
sh deploy/deploy.sh homologacao-local      # sobe, migra, troca e verifica
sh deploy/homologacao/e2e.sh               # e2e do frontend contra a homologação
```

O `e2e.sh` exige `frontend/` no commit do manifesto (`git -C frontend rev-parse HEAD` igual a
`CRM_FRONTEND_TAG`) e o `npm ci` feito nele. Ele roda
`E2E_BASE_URL=http://localhost:18080 KEYCLOAK_BASE_URL=http://keycloak.localhost:18180 npm run e2e`.

Para derrubar: `docker compose -p crm-akeel-homologacao down -v`.

### Endereços e convivência com o ambiente de desenvolvimento

É um projeto compose separado, `crm-akeel-homologacao`, com volumes próprios. Não usa
nenhuma porta do `compose.yaml` de desenvolvimento, e os dois sobem juntos.

| O quê | Endereço |
|---|---|
| SPA e BFF (o proxy) | `http://localhost:18080` |
| Keycloak de teste | `http://keycloak.localhost:18180` (console em `/admin/`) |
| Mailpit | `http://localhost:18025` |

**Por que `keycloak.localhost`:** o navegador, o Node do Playwright e a `api` dentro do
Docker precisam chamar o Keycloak pelo **mesmo** endereço, senão o issuer não bate. Dentro da
rede do compose, `keycloak.localhost` é apelido do serviço; no host, `*.localhost` resolve
para o loopback (Chromium e Node no macOS, conferido em 2026-11-25), e a porta 18180 está
publicada. O Keycloak escuta na 18180 também dentro do contêiner, para a URL ser idêntica.

### O que o `verificar.sh` confere (o deploy falha se algo quebrar)

| Rótulo | Checagem |
|---|---|
| `[8]` | `GET /api/session` → 401 JSON, igual à `api` direta; `GET /oauth2/authorization/keycloak` → 302 ao Keycloak local; `GET /login/oauth2/code/keycloak` e `POST /logout` → mesmo status da `api` direta, sem o `index.html`; `/`, `/qualquer/rota` e vizinhos dos prefixos (`/apix`, `/api`, `/logoutx`, `/actuator/health`...) → 200 com o `index.html`; nenhum `Set-Cookie` com `Domain`; nenhum `Access-Control-*` com `Origin` de fora (GET e pré-voo) |
| `[9]` | `Host: crm.akeel.com.br` no proxy de pé → `redirect_uri=http://crm.akeel.com.br/login/oauth2/code/keycloak`; e num proxy de sonda com `CRM_ESQUEMA_PUBLICO=https` (mesma configuração, sem porta publicada, removido no fim) → `https://crm.akeel.com.br/...` |
| `[10]` | `/run/secrets/KEYCLOAK_CLIENT_SECRET` existe na `api` e a variável não está no ambiente |
| `[11]` | o `worker` está no perfil `prod` com `MAIL_EHLO_NAME`; o comando de verificação de envio, dentro do contêiner do `worker`, sai 0 e a mensagem aparece no Mailpit |
| `[arquivos]` | pré-voo `PUT` no bucket com a origem pública → 200 com `PUT`; com outra origem → não 200 |

### E-mail na homologação (STARTTLS)

O `application-prod.yml` exige STARTTLS e o Mailpit sem certificado não o oferece. Só o
`deploy/homologacao/compose.yaml` desliga a exigência, no `worker`:
`SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_REQUIRED=false` (a chave pega pelo ambiente,
medido em 2026-11-25). O `application-prod.yml` e o `deploy/aplicacao/compose.yaml` não
mudam: em produção, o STARTTLS continua obrigatório.

## Mudar as tags do manifesto

1. O commit novo de cada repositório precisa estar no remoto (o workflow faz checkout por
   hash) e com o CI verde.
2. Troque o hash em `deploy/manifesto.env` (hash completo, 40 caracteres):
   `git -C backend rev-parse HEAD`, `git -C frontend rev-parse HEAD`.
3. Localmente: `sh deploy/imagens.sh`, `sh deploy/deploy.sh homologacao-local`, ponha
   `frontend/` no commit novo e rode `sh deploy/homologacao/e2e.sh`.
4. Commit no raiz só com o manifesto. Hoje o workflow roda à mão (Actions → deploy → Run
   workflow); depois da liberação, o push para `main` o dispara.

Para provar outro par sem mexer no manifesto: `CRM_MANIFESTO=<outro arquivo> sh deploy/deploy.sh homologacao-local`.

## O workflow do raiz (`.github/workflows/deploy.yml`)

Dispara **só à mão** (`workflow_dispatch`, decisão do Orquestrador em 2026-11-25 sobre
`decisoes/2026-11-24.md §24`): o raiz recebe push a todo momento (docs, fila), e sem o
segredo `CRM_PRODUTOS_LEITURA` e o runner da VPS cada push falharia na homologação e deixaria
a produção esperando um runner que não existe. Religar o `push: branches: [main]` é um passo
da liberação do deploy (pendências abaixo). Um deploy por vez
(`concurrency: deploy`, sem cancelar o que está rodando).

| Job | Onde | O que faz |
|---|---|---|
| `manifesto` | `ubuntu-24.04` | lê as duas tags do manifesto |
| `contrato` | `ubuntu-24.04` | checkout dos dois repositórios nas tags e `sh deploy/contrato.sh` (passo do contrato) |
| `homologacao` | `ubuntu-24.04` | checkout nas tags, `sh deploy/imagens.sh`, segredos falsos (`gerar-segredos.sh`), `sh deploy/deploy.sh homologacao-local`, Playwright e `sh deploy/homologacao/e2e.sh` (passo 4) |
| `producao` | runner próprio na VPS (`self-hosted`, `crm-producao`) | `environment: producao` (**aprovação manual**: os revisores ficam na configuração do ambiente no GitHub), checkout nas tags, `sh deploy/imagens.sh`, `sh deploy/deploy.sh producao` (passo 5) |

O único segredo do GitHub que o workflow lê é `secrets.CRM_PRODUTOS_LEITURA` (leitura dos
dois repositórios de produto, que são privados). Os segredos da aplicação em produção ficam
na VPS, em `/etc/crm-akeel/segredos`; o GitHub não os vê.

O workflow não foi executado no GitHub. Ele é conferido localmente pelo actionlint:

```
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest
```

## O que falta para o deploy real (pendências)

Nada disto é do DevOps sozinho: tudo espera a liberação do Pedro (`decisoes §24`).

- [ ] **Liberação do Pedro** para começar o deploy real.
- [ ] **Religar o gatilho `push`** em `.github/workflows/deploy.yml` (`on: push: branches: [main]`
      ao lado do `workflow_dispatch`), só depois do runner, do ambiente e do segredo abaixo.
- [ ] **VPS** de produção (e, se houver, a de homologação) com Docker e o compose v2.
- [ ] **Runner self-hosted** do GitHub na VPS, com o rótulo `crm-producao`, registrado no
      repositório `akeel-dev/crm-akeel`.
- [ ] **Ambiente `producao` no GitHub** com revisores obrigatórios (Settings → Environments).
      Sem isso, o job de produção roda sem aprovação: o YAML só nomeia o ambiente.
- [ ] **Segredo `CRM_PRODUTOS_LEITURA`** no repositório do raiz: token só de leitura dos dois
      repositórios de produto.
- [ ] **Segredos da aplicação na VPS**, em `/etc/crm-akeel/segredos/`, legíveis pelo uid
      10001 do backend: `crm_bff_client_secret` (o do `crm-bff` da TI), `crm_db_password`,
      `postgres_password`, `garage_rpc_secret`, `garage_admin_token`,
      `garage_s3_access_key_id`, `garage_s3_secret_access_key` e `backup` (o arquivo do
      destino de backup, `docs/operacao/backup.md`). Quem cria é o humano.
- [ ] **Cloudflare Tunnel** (D-06) do `cloudflared` na VPS para `http://127.0.0.1:8080` (o
      proxy), com o hostname `crm.akeel.com.br`; SPA e BFF fora do Access (spec §4.5).
- [ ] **Registro de imagens:** hoje a imagem é construída na própria máquina do deploy a
      partir do commit. Com um registro, `imagens.sh` vira `docker pull` das tags.
- [ ] **Teste de fumaça "Mesmo host em produção"** (ADR 0003, emenda §15) contra
      `https://crm.akeel.com.br`: as checagens `[8]` e `[9]` do `verificar.sh` são a versão
      local dele.
- [ ] **Envio pelo relay** do Google Workspace a partir do `worker` na VPS (§10.4) e
      `MAIL_EHLO_NAME` conferido: só dá para medir lá.
- [ ] **CRM_STORAGE_ENDPOINT público:** a URL pré-assinada aponta para o endpoint do S3; o
      navegador precisa alcançá-lo. Hoje `http://garage:3900` só existe dentro da rede do
      compose. Decisão de arquitetura antes do primeiro upload do navegador.

## Como isto foi provado (2026-11-25, `MacBook-Air-de-Maria.local`)

As saídas completas estão no relatório do DevOps da story 0-04. Resumo:

- `sh deploy/deploy.sh homologacao-local` do zero: exit 0, ordem no log
  migração ok → cors do bucket ok → api e worker de pé → frontend e proxy de pé, e as
  checagens `[8]`, `[9]`, `[10]`, `[11]` e `[arquivos]` verdes.
- `sh deploy/homologacao/e2e.sh`: 8 testes passaram.
- actionlint: exit 0.
- Sabotagens, todas em cópia de `deploy/` (nunca nos arquivos reais), cada uma com o deploy
  real rodado de novo depois: migração inválida numa tag de teste (o deploy para antes da
  troca e a `api` antiga continua respondendo); proxy sem `Host`; proxy sem
  `X-Forwarded-Proto`; `worker` sem o ajuste do STARTTLS; contratos diferentes.
