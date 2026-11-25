# Variáveis de ambiente do backend

Dono: DevOps (`time.yml`, `escrita.devops`). Origem: `reviews/0-09.md`, N4.

O que o backend lê **hoje** (conferido em 2026-11-24 contra
`backend/src/main/resources/application.yml`, `identity/SecurityConfig.java`,
`platform/RunModes.java` e `platform/RunModeConfig.java`). Quando o Dev acrescentar uma
leitura, esta tabela muda no mesmo despacho.

Nenhum valor abaixo é segredo real. Segredo só na shell (ou no gerenciador de segredos do
servidor), nunca em arquivo versionado, `.env` do repositório ou `application-*.yml`
(ADR 0003, emenda §15, item 4). Os valores locais saem de `deploy/local/secrets/`
(`docs/operacao/ambiente-local.md`).

## Identidade (Keycloak) e endereço público

| Variável | Obrigatória | Exemplo local | Onde é lida | Se faltar |
|---|---|---|---|---|
| `KEYCLOAK_BASE_URL` | sim | `http://localhost:8180` | `application.yml`, `issuer-uri: ${KEYCLOAK_BASE_URL}/realms/${KEYCLOAK_REALM}` | o placeholder não resolve e o contexto não sobe. Sem barra final: o `/realms/` já vem no `application.yml` |
| `KEYCLOAK_REALM` | sim | `crm` | `application.yml`, mesmo `issuer-uri` | idem. Com o issuer resolvido, o Keycloak precisa responder na subida (o Spring busca a descoberta OIDC do issuer) |
| `KEYCLOAK_CLIENT_ID` | sim | `crm-bff` (local) · `crm-bff-dev` (à mão contra o real) | `application.yml`, `registration.keycloak.client-id` | o placeholder não resolve e o contexto não sobe |
| `KEYCLOAK_CLIENT_SECRET` | sim, **segredo** | `"$(cat deploy/local/secrets/crm_bff_client_secret)"` | `application.yml`, `client-secret`; e `SecurityConfig`, `environment.getRequiredProperty("KEYCLOAK_CLIENT_SECRET")` | a subida falha (`getRequiredProperty` lança `IllegalStateException`), mesmo que o resto resolva |
| `CRM_PUBLIC_URL` | sim | `http://localhost:5173/` | `SecurityConfig`, `@Value("${CRM_PUBLIC_URL}")` | o placeholder não resolve e o contexto não sobe |

### `CRM_PUBLIC_URL` termina em `/`

É a origem que o navegador vê (a mesma da SPA, ADR 0003, emenda §15, item 3): local
`http://localhost:5173/`, produção `https://crm.akeel.com.br/`. O `SecurityConfig` usa o
valor em três lugares:

- depois do login: redireciona para `publicUrl`;
- login recusado: redireciona para `publicUrl + "acesso-recusado"`;
- depois do logout: é o `post_logout_redirect_uri` mandado ao Keycloak.

O endereço de recusa é concatenação simples. **Sem a barra final**, sai
`https://crm.akeel.com.bracesso-recusado` (`reviews/0-09.md`, N4; leitura do código, não
medido). O backend não valida a barra: quem configura confere. O valor com barra também
precisa estar entre os "Valid post logout redirect URIs" do cliente no Keycloak.

## Banco (PostgreSQL)

O `application.yml` não declara `spring.datasource`; o backend usa as propriedades padrão
do Spring Boot, que lê do ambiente pelos nomes abaixo (ligação relaxada). O banco serve
à aplicação, à sessão (`spring-session-jdbc`), ao Flyway e ao `db-scheduler`.

| Variável | Obrigatória | Exemplo local | Se faltar |
|---|---|---|---|
| `SPRING_DATASOURCE_URL` | sim | `jdbc:postgresql://localhost:5432/crm` | não há banco embutido no classpath: a subida falha ao configurar o `DataSource` (`'url' attribute is not specified`) |
| `SPRING_DATASOURCE_USERNAME` | sim | `crm` | o driver tenta sem usuário e a conexão é recusada |
| `SPRING_DATASOURCE_PASSWORD` | sim, **segredo** | `"$(cat deploy/local/secrets/crm_db_password)"` | a autenticação no PostgreSQL falha na subida (Flyway e sessão conectam logo) |

## Arquivos (S3, `platform.storage`)

Origem: story 0-13 (backend `5e501d7`), `reviews/0-13.md`, N2. Lidas por
`StorageProperties` (`@ConfigurationProperties("crm.storage")`, `@Validated`), pela
ligação relaxada do Spring: `CRM_STORAGE_PATH_STYLE` vira `crm.storage.path-style`. O
api **e** o worker leem as mesmas; nenhuma das seis primeiras tem padrão.

| Variável | Obrigatória | Exemplo local | Validação | Se faltar |
|---|---|---|---|---|
| `CRM_STORAGE_ENDPOINT` | sim | `http://localhost:3900` | `@NotNull URI` | a ligação de `crm.storage` falha e o contexto não sobe |
| `CRM_STORAGE_REGION` | sim | `garage` | `@NotBlank` | idem |
| `CRM_STORAGE_BUCKET` | sim | `crm-arquivos` (`S3_BUCKET` do `.env`) | `@NotBlank` | idem |
| `CRM_STORAGE_PATH_STYLE` | sim | `true` (Garage) | `@NotNull Boolean` | idem |
| `CRM_STORAGE_ACCESS_KEY` | sim, **segredo** | `"$(cat deploy/local/secrets/garage_s3_access_key_id)"` | `@NotBlank` | idem |
| `CRM_STORAGE_SECRET_KEY` | sim, **segredo** | `"$(cat deploy/local/secrets/garage_s3_secret_access_key)"` | `@NotBlank` | idem |
| `CRM_STORAGE_CORS_ORIGINS` | não (no deploy: sim) | `http://localhost:5173` (lista separada por vírgula) | nenhuma | lista vazia. Só é lida pelo comando `--crm.storage.apply-cors` (backend `46e767a`), que aplica o CORS no bucket e sai; a subida normal do api e do worker não toca no CORS. O deploy roda esse comando como passo único, antes de trocar as instâncias, com a origem pública (`docs/operacao/deploy.md`) |
| `CRM_STORAGE_MULTIPART_PART_SIZE` | não | `5MB` | **nenhuma** | vale `5MB`. Não baixar: `0B` sobe e estoura no primeiro multipart, e o S3 exige 5 MiB por parte exceto a última (`reviews/0-13.md`, N3) |

Não existe `CRM_DB_PASSWORD`: para o banco valem os `SPRING_DATASOURCE_*` acima.

## Modo de execução (opcionais)

| Variável | Obrigatória | Exemplo | Efeito / se faltar |
|---|---|---|---|
| `CRM_MODE` (ou `--crm.mode=`) | não (na VPS: `worker` no contêiner do worker, `migrate` no de migração) | `migrate` · `worker` | `migrate`: só roda o Flyway e sai (`RunModes`). `worker`: só `/actuator/health` responde, o resto `404` (`RunModeConfig`); é o único modo que envia e-mail (o api só enfileira). Ausente: modo api |
| `HOSTNAME` | não (definida pelo Docker) | id do contêiner | `application.yml`, `db-scheduler.scheduler-name: ${HOSTNAME:crm}`: é o nome do nó no agendador. O Docker define sozinho em cada contêiner. **Fora do Docker** (ou se alguém a sobrescrever com o mesmo valor), todos os nós viram `crm` e o agendador não distingue quem pegou cada execução. Não definir à mão no compose |
| `SPRING_PROFILES_ACTIVE` | não (produção: `prod`) | `prod` | com `prod`, o api e o worker recusam subir se houver migração pendente. Ausente: o Flyway migra na subida |

## E-mail do sistema (perfil `prod`)

Origem: `reviews/0-11.md`, N3. Lidas só em `application-prod.yml` (§10.4: relay do
Google Workspace, sem autenticação, STARTTLS obrigatório). Fora do perfil `prod`, o
`application.yml` fixa `localhost:1025` (o Mailpit do `compose.yaml`) e nenhuma destas
variáveis é lida. Só o `worker` abre conexão SMTP (RF-SEC-06); no api elas são
inofensivas, mas a mesma lista serve aos dois contêineres.

| Variável | Obrigatória | Padrão / exemplo | Onde é lida | Se faltar |
|---|---|---|---|---|
| `MAIL_HOST` | não | `smtp-relay.gmail.com` | `spring.mail.host: ${MAIL_HOST:smtp-relay.gmail.com}` | vale o padrão, que é o da §10.4 |
| `MAIL_PORT` | não | `587` | `spring.mail.port: ${MAIL_PORT:587}` | vale o padrão (STARTTLS exigido: `starttls.required: true`) |
| `MAIL_EHLO_NAME` | **sim, na VPS** | o nome de domínio público do servidor (§10.4: nome de domínio, **não** o nome do contêiner) | `spring.mail.properties.mail.smtp.localhost: ${MAIL_EHLO_NAME}` | **a aplicação sobe normalmente** e o EHLO sai com o texto literal `${MAIL_EHLO_NAME}` (medido pelo Revisor, `reviews/0-11.md`, sonda P1). O relay tende a recusar; a falha só aparece no envio, depois de 6 tentativas (~25 min), com a mensagem em FAILED. Conferir com o comando de verificação abaixo depois de cada mudança |

Não há validação na subida: quem configura confere `MAIL_EHLO_NAME` no ambiente do
`worker` antes de subir (`docker compose config` mostra o valor resolvido; não é segredo).

### Comando de verificação de e-mail

Enfileira um e-mail de teste (modelo `delivery-check`) pela fila real e sai quando a
mensagem deixa de estar pendente: código `0` se entregue, `1` se FAILED
(`MailConfig.deliveryCheck`). Exige `crm.mode=worker`; em outro modo a subida falha com
`IllegalStateException`.

```
java -jar crm.jar --spring.profiles.active=prod --crm.mode=worker \
  --crm.mail.check-to=<e-mail> --server.port=0
```

Cuidados (`reviews/0-11.md`, N4):

- **É um segundo worker completo**: sobe o Tomcat, inicia o agendador e também executa
  as outras tarefas vencidas da fila (seguro no db-scheduler, mas é carga extra). Ele
  precisa das mesmas variáveis do worker (banco, Keycloak, `MAIL_*`).
- **Porta da saúde**: rodando no mesmo contêiner do `worker` (`docker compose exec`), a
  porta do health já está ocupada. Use `--server.port=0` (porta livre aleatória) ou rode
  num contêiner à parte (`docker compose run --rm` com o mesmo serviço).
- **Duração com o relay recusando**: não há prazo próprio. Com `crm.mail.retry-interval`
  padrão (`PT5M`) são 6 tentativas com 5 min entre elas, então leva **cerca de 25 min**
  para sair `1`. Com o relay aceitando, sai em segundos. Não encurtar com
  `--crm.mail.retry-interval`: este processo também reexecuta falhas de outras mensagens
  da fila, que passariam a usar o intervalo curto (leitura de `MailConfig`, não medido).
- Local, contra o Mailpit: o mesmo comando sem `--spring.profiles.active=prod`; a
  mensagem aparece em `http://localhost:8025`.
- Nunca apontar `check-to` para um destinatário real fora da equipe; o teste do relay de
  produção é do humano (credencial de produção não é do DevOps).

## Bloco local completo

```
export KEYCLOAK_BASE_URL=http://localhost:8180
export KEYCLOAK_REALM=crm
export KEYCLOAK_CLIENT_ID=crm-bff
export KEYCLOAK_CLIENT_SECRET="$(cat deploy/local/secrets/crm_bff_client_secret)"
export CRM_PUBLIC_URL=http://localhost:5173/
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/crm
export SPRING_DATASOURCE_USERNAME=crm
export SPRING_DATASOURCE_PASSWORD="$(cat deploy/local/secrets/crm_db_password)"
export CRM_STORAGE_ENDPOINT=http://localhost:3900
export CRM_STORAGE_REGION=garage
export CRM_STORAGE_BUCKET=crm-arquivos
export CRM_STORAGE_PATH_STYLE=true
export CRM_STORAGE_ACCESS_KEY="$(cat deploy/local/secrets/garage_s3_access_key_id)"
export CRM_STORAGE_SECRET_KEY="$(cat deploy/local/secrets/garage_s3_secret_access_key)"
(cd backend && ./mvnw spring-boot:run)     # porta 8080
```

## Como esta lista foi conferida

- ✅ leitura: `application.yml` (quatro placeholders `KEYCLOAK_*`, sem `spring.datasource`),
  `SecurityConfig` (`@Value("${CRM_PUBLIC_URL}")`, `getRequiredProperty("KEYCLOAK_CLIENT_SECRET")`,
  `publicUrl + "acesso-recusado"`), `RunModes` e `RunModeConfig` (`crm.mode`, perfil `prod`).
- ✅ execução (2026-11-24, antes da 0-13): `grep -rniE 'datasource|CRM_DB|CRM_STORAGE|getRequiredProperty' backend/src/main`
  só acha o `DataSourceAutoConfiguration` de `RunModes` e o `getRequiredProperty` do `SecurityConfig`.
- ✅ leitura (2026-11-25): `application-prod.yml` (`MAIL_HOST`, `MAIL_PORT`,
  `MAIL_EHLO_NAME` sem padrão), `application.yml` (`${HOSTNAME:crm}`,
  `crm.mail.retry-interval: PT5M`, mail local `localhost:1025`), `MailConfig`
  (`MAX_RETRIES = 5`, `deliveryCheck` exige `worker`, sai 0/1).
- ⚠️ não medido aqui: o EHLO literal `${MAIL_EHLO_NAME}` foi medido pelo Revisor (sonda P1
  de `reviews/0-11.md`), não por mim; os ~25 min são cálculo (6 tentativas, 5 min), não
  cronometrados; o relay real não foi usado.
- ✅ leitura (2026-11-25): `StorageProperties` no backend `5e501d7` (seis campos validados
  sem padrão, `multipartPartSize` com `@DefaultValue("5MB")`, `corsOrigins` com lista
  vazia); `grep applyBucketCors backend/src/main/java` só acha a declaração e a implementação.
- ✅ execução (2026-11-25): o "Bloco local completo" acima, num clone do backend fixado em
  `5e501d7`, contra o compose de pé: `/actuator/health` respondeu `200` (registro em
  `ambiente-local.md`, "Como este roteiro foi provado").
- ⚠️ não medido: as mensagens exatas de falha de cada ausência (o backend não foi subido
  sem cada variável).
