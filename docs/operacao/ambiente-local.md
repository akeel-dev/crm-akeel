# O ambiente local

Dono: DevOps (`time.yml`, `escrita.devops`). Origem: story 0-02; spec v1.2 §4.5, §5.1,
§5.2; ADR 0001 (decisão 5 e nota do `compose.yaml`); ADR 0003, emenda §15.

`compose.yaml`, na raiz, sobe só a **infraestrutura**: PostgreSQL, Keycloak com o realm
de teste, Garage (S3) e Mailpit. O backend e o frontend **não** estão no compose: rodam
pelo `./mvnw` e pelo `npm` de cada repositório, apontando para estes serviços. Tudo aqui
usa dados fictícios.

## Primeira vez

Sempre a partir da raiz do projeto. Precisa de Docker, `openssl`, `curl` e `jq`.

```
sh deploy/local/gerar-segredos.sh      # cria .env e deploy/local/secrets/* (não sobrescreve)
docker compose up -d --wait            # sai com 0 quando todos estão healthy
sh deploy/local/verificar.sh           # confere os critérios 2 a 5 da story 0-02
```

O script gera um valor aleatório para cada nome de `deploy/local/segredos.example` e
copia `deploy/local/.env.example` para `.env`. Os dois destinos são ignorados pelo git
(`.env` e `secrets/` no `.gitignore`); `git status` não os lista. Nenhum valor de segredo
está no `compose.yaml` nem em `deploy/**`: o compose só referencia os arquivos como
segredos do Docker (RF-SEC-03).

## Serviços e portas

Todas as portas ficam presas a `127.0.0.1`. Os números vêm do `.env` (padrões abaixo).

| Serviço | Imagem | Porta no host | Para quê |
|---|---|---|---|
| `postgres` | `postgres:18.7` | `5432` (`POSTGRES_PORT`) | banco `crm` (dono `crm`) e banco `keycloak` (dono `keycloak`), separados |
| `keycloak` | `quay.io/keycloak/keycloak:26.8.2` | `8180` (`KEYCLOAK_PORT`) | realm de teste `${KEYCLOAK_REALM}` (`crm`), `start-dev`, banco no PostgreSQL |
| `garage` | `dxflrs/garage:v2.5.0` | `3900` (`GARAGE_S3_PORT`) | S3, região `garage`, endereço por caminho (path-style) |
| `garage-init` | `curlimages/curl:8.23.0` | — | cria layout, bucket `${S3_BUCKET}` e chave; fica parado e "healthy" |
| `mailpit` | `axllent/mailpit:v1.34.0` | SMTP `1025`, web e API `8025` | capturador de e-mail (RF-NOT-09); o realm manda e-mail para ele |

- Interface do Mailpit: `http://localhost:8025`.
- Console do Keycloak: `http://localhost:8180/admin/`, usuário `admin` (`KEYCLOAK_ADMIN_USER`),
  senha no arquivo `deploy/local/secrets/keycloak_admin_password`.
- Issuer local: `http://localhost:8180/realms/crm`.

## Segredos locais

Um arquivo por segredo em `deploy/local/secrets/` (diretório `700`). Os nomes:

| Arquivo | Usado por |
|---|---|
| `postgres_password` | superusuário `postgres` |
| `crm_db_password` | usuário `crm` do banco `crm` (o backend) |
| `keycloak_db_password` | usuário `keycloak` do banco `keycloak` |
| `keycloak_admin_password` | admin do console do Keycloak local |
| `crm_bff_client_secret` | segredo do cliente `crm-bff` do realm local |
| `crm_api_client_secret` | segredo do cliente `crm-api` do realm local |
| `test_user_password` | senha dos três usuários de teste |
| `garage_rpc_secret`, `garage_admin_token` | internos do Garage |
| `garage_s3_access_key_id`, `garage_s3_secret_access_key` | a chave S3 do CRM no bucket |

Para trocar um segredo: apague o arquivo, rode o script de novo e zere tudo (abaixo),
porque o banco e o realm guardam o valor antigo.

## O realm de teste

O nome vem de `KEYCLOAK_REALM` (`.env`; valor `crm`, o mesmo do real, spec §5.1). A
exportação é `deploy/keycloak/realm-crm-local.json`; o nome do realm, os segredos dos
clientes e a senha dos usuários entram nela por substituição `${VAR}` na importação.

| Cliente | Tipo | Notas |
|---|---|---|
| `crm-bff` | confidencial, Authorization Code + PKCE `S256` | redirect e post-logout só `http://localhost:*` (cobre `http://localhost:5173/login/oauth2/code/keycloak`); Backchannel e Front-channel logout URL vazias, como no real |
| `crm-api` | confidencial, só `client_credentials` | conta de serviço com `view-users`, `manage-users`, `query-users` e `query-groups` do `realm-management` |
| `crm-web` | público, PKCE `S256` | só paridade com o real; o CRM não faz login por ele (P-18) |

Grupos: `/Perfis/Administradores` (`admin`), `/Perfis/Gestores` (`gestor`),
`/Perfis/Vendedores` (`vendedor`), `/Perfis/Visualizadores` (`visualizador`) e
`/Equipes/Comercial`. Os papéis são compostos (um gestor recebe também `vendedor` e
`visualizador`). Os mapeadores dos clientes `crm-bff` e `crm-web` dão ao token os claims
`roles` e `groups` (caminho completo) e a audiência `crm-api` (ficam no cliente, não num
escopo próprio: um `clientScopes` na exportação faz o Keycloak deixar de criar os escopos
padrão, e o token perde `sub` e `preferred_username`); `preferred_username` é o e-mail (e-mail como nome de
usuário). Pela P-19, o CRM não usa `roles` nem `groups` para autorizar: existem para o
token local ter a forma do real. Nenhum provedor Google (é configuração da TI no real).

### Usuários de teste (fictícios)

Senha dos três: o conteúdo de `deploy/local/secrets/test_user_password`.

| Usuário (= e-mail) | E-mail verificado | Grupos | Caso |
|---|---|---|---|
| `ana.vendedora@akeel.com.br` | sim | `/Perfis/Vendedores`, `/Equipes/Comercial` | login normal |
| `bruno.naoverificado@akeel.com.br` | **não** | — | e-mail não verificado (0-09, 0-20) |
| `carla.externa@example.com` | sim | — | outro domínio (0-09, 0-20) |

## Rodar o backend e o frontend contra este ambiente

Exporte na shell (nunca em arquivo versionado). Os nomes das propriedades do lado do
backend são do Dev; os valores apontam para cá:

```
export KEYCLOAK_REALM=crm
export KEYCLOAK_BASE_URL=http://localhost:8180
export KEYCLOAK_CLIENT_ID=crm-bff
export KEYCLOAK_CLIENT_SECRET="$(cat deploy/local/secrets/crm_bff_client_secret)"
# banco: jdbc:postgresql://localhost:5432/crm, usuário crm
export CRM_DB_PASSWORD="$(cat deploy/local/secrets/crm_db_password)"
# arquivos: endpoint http://localhost:3900, região garage, bucket crm-arquivos, path-style
export CRM_STORAGE_ACCESS_KEY="$(cat deploy/local/secrets/garage_s3_access_key_id)"
export CRM_STORAGE_SECRET_KEY="$(cat deploy/local/secrets/garage_s3_secret_access_key)"
# e-mail: SMTP localhost:1025, sem autenticação

(cd backend && ./mvnw spring-boot:run)     # porta 8080
(cd frontend && npm ci && npm run dev)     # porta 5173
```

### Mesma origem: `http://localhost:5173`

A SPA e a BFF são vistas na **mesma origem**, `http://localhost:5173`, como em produção
são vistas em `https://crm.akeel.com.br` (ADR 0003, emenda §15, item 3). O proxy do Vite
(story 0-19) manda ao backend (`localhost:8080`) só `/api/`, `/oauth2/authorization/`,
`/login/oauth2/code/` e `/logout`, **mantendo o `Host`**; todo o resto é da SPA. Por isso
o callback do login é `http://localhost:5173/login/oauth2/code/keycloak`, e o login
começa em `http://localhost:5173/oauth2/authorization/keycloak`. Sem CORS e sem cookie
em outro host.

## Rodar à mão contra o Keycloak real

Só à mão, nunca em teste automatizado. Aponte para `https://akpannel.akeel.com.br`, realm
`crm`, com o cliente de desenvolvimento:

```
export KEYCLOAK_BASE_URL=https://akpannel.akeel.com.br
export KEYCLOAK_REALM=crm
export KEYCLOAK_CLIENT_ID=crm-bff-dev
read -rs KEYCLOAK_CLIENT_SECRET && export KEYCLOAK_CLIENT_SECRET   # cole o valor; não ecoa nem vai ao histórico
```

O segredo do `crm-bff-dev` fica **só na shell** como `KEYCLOAK_CLIENT_SECRET`: nunca em
arquivo versionado, nem `.env` no repositório, nem `application-*.yml` (ADR 0003, emenda
§15, item 4). O `crm-bff-dev` aceita `localhost:8080`, `5173` e `3000`.

**Nenhum teste automatizado usa o Keycloak real.** Os testes usam o Keycloak deste
compose ou o do Testcontainers, cada um com o próprio realm de teste e segredos falsos.

## Zerar tudo

```
docker compose down -v                  # para e apaga os volumes (banco, Garage)
docker compose up -d --wait             # recria do zero: realm, bancos, bucket e chave
sh deploy/local/verificar.sh
```

Para recomeçar também os segredos: `rm -r deploy/local/secrets .env` antes do
`gerar-segredos.sh`.

## Se algo não subir

- `docker compose ps -a` e `docker compose logs <serviço>`.
- `KEYCLOAK_REALM` ausente: o compose recusa subir; rode `gerar-segredos.sh`.
- Porta ocupada: troque o número no `.env`.
