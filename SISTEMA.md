# SISTEMA — crm-akeel

Dono: Arquiteto. Descreve **o que existe**, não o que vai existir.

Atualizado: 2026-11-25, portão da Onda 0. Backend no commit `46e767a`, frontend no `63752e9`. A stack está em
`docs/adr/0001-stack.md`; os módulos, em `docs/arquitetura/modulos.md`; os atalhos e limites
declarados, em `docs/arquitetura/atalhos.md`.

## Medição

`comandos.arquitetura`, rodado em 2026-11-25 num clone de diretório único do backend fixado em
`46e767a`:

```
[ModularityTest] módulos detectados (2): identity, platform
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in br.com.akeel.crm.architecture.ModularityTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in br.com.akeel.crm.architecture.StorageConfigTest
Tests run: 12, Failures: 0, Errors: 0, Skipped: 0 -- in br.com.akeel.crm.architecture.ArchitectureTest
Tests run: 16, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
exit=0
```

A suíte inteira em `46e767a` (backend 177/177, frontend 239/239, exit 0) foi medida pelo
Orquestrador (`planning/FILA.md`, "Em voo"), não por esta revisão.

## Backend

Spring Boot 4.2.0 (webmvc), Flyway e jOOQ do Boot, PostgreSQL, enforcer `requireJavaVersion
[25,)`. No classpath de produção também: Spring Security com OAuth2 client, Spring Session JDBC,
Actuator, `spring-boot-starter-mail`, db-scheduler 17.2.0 (`db-scheduler-spring-boot-4-starter`),
springdoc 3.1.0 (sem Swagger UI), `spring-modulith-api`, `spring-modulith-starter-jdbc` 2.2.0
(registro de publicação de eventos), `spring-boot-starter-validation` e o AWS SDK `s3` 2.59.9
(sem `netty-nio-client`, com `url-connection-client`). Em teste: ArchUnit 1.5.1, Testcontainers
(PostgreSQL, Keycloak, Garage `dxflrs/garage:v2.5.0`). Migrações: `V1__extensions`,
`V2__spring_session`, `V3__scheduled_tasks`, `V4__mail_delivery`, `V5__domain_events`
(`outbox_event` e `event_publication`).

Configuração: `application.yml` (Keycloak por `KEYCLOAK_*`, sessão de 8 h de inatividade e 30
dias absolutos, cookie `HttpOnly`/`Secure`/`SameSite=Lax`, Mailpit `localhost:1025`, intervalo de
e-mail `PT5M`, indicadores de saúde do db-scheduler e de e-mail desligados, agendador com
`polling-interval: 1s`, reentrega de eventos `PT1M` com idade mínima `PT5M`,
`republish-outstanding-events-on-restart: false`; o armazenamento `crm.storage.*` sem padrão para
endpoint, região, bucket e credenciais, a aplicação não sobe sem eles) e
`application-prod.yml` (relay `MAIL_HOST`/`MAIL_PORT`, padrão `smtp-relay.gmail.com:587`, STARTTLS
obrigatório, EHLO por `MAIL_EHLO_NAME`).

- **`identity`** (0-09): login BFF pelo Keycloak (Authorization Code), sessão no PostgreSQL,
  nenhum token no navegador, renovação do token (`TokenRefreshFilter`), idade absoluta da sessão,
  `GET /api/session`, logout por `end_session`, CSRF por cookie `XSRF-TOKEN`.
- **`platform`**, sem subpacote: `RunModes` (modos `api`, `worker`, `migrate`; desconhecido é
  recusado) e `RunModeConfig` (0-10).
- **`platform.jobs`** (0-10): fachada sobre o db-scheduler (`JobDefinition`, `JobScheduler`,
  `RetryPolicy`, `JobStatus`, e `RecurringJob` desde a 0-12), novas tentativas, saúde do worker
  presa ao agendador. O `worker` inicia o agendador com `ContextReadyStart`; o `api` não o inicia.
  Exposta como `@NamedInterface("jobs")`.
- **`platform.ids`** (0-11): `IdGenerator`, UUIDv7 gerado na aplicação. `@NamedInterface("ids")`.
- **`platform.mail`** (0-11): e-mail do sistema por fila (`SystemMail`, `QueuedSystemMail`),
  registro em `mail_delivery` com id v7, 5 novas tentativas, comando de verificação do relay. Usa
  `platform.jobs` e `platform.ids`. Sem `@NamedInterface`.
- **`platform.events`** (0-12, ADR 0002): `DomainEvents.publish` grava o envelope (id v7, `type`
  `entidade.ação`, `occurred_at` UTC, `actor`, `entity_type`/`entity_id`, `payload`
  `current`/`changes`, `correlation_id`) na `outbox_event`, na transação de quem chama
  (`MANDATORY`). No `worker`, a tarefa recorrente de repasse (a cada 1 s) lê
  `relayed_at is null order by occurred_at, id … for update skip locked`, publica no
  `ApplicationEventPublisher` e marca `relayed_at`; o registro do Spring Modulith
  (`event_publication`) entrega a cada `@ApplicationModuleListener` pelo menos uma vez, sem
  ordem garantida. Outra tarefa reentrega as falhas. Staleness `PT10M` só no `worker`
  (`WorkerEventStaleness`, por `spring.factories`). O `api` só grava. Sem `AbandonPolicy` e sem
  purga. Usa `platform.jobs` e `platform.ids`. **Sem `@NamedInterface`:** um módulo de domínio
  que use `DomainEvents` ou `DomainEvent` deixa o `ModularityTest` vermelho (medido; ver
  `docs/arquitetura/modulos.md`).
- **`platform.storage`** (0-13): `ObjectStorage`/`S3ObjectStorage`, URL pré-assinada de `PUT` e
  `GET` (nunca `POST`), multipart com partes pré-assinadas (parte mínima de 5 MiB, recusada na
  subida abaixo disso), CORS do bucket só pelo comando `--crm.storage.apply-cors` (aplica e
  termina; falha citando endpoint e bucket). Qualquer S3 por configuração, credenciais estáticas
  só de configuração externa. A URL assinada usa o mesmo endpoint do cliente interno.
  `@NamedInterface("storage")`.
- **`platform.openapi`** (0-08): contrato em `/v3/api-docs`, versionado em
  `backend/openapi/openapi.json` e copiado em `frontend/openapi/openapi.json` (`cmp` na suíte).

Nenhum módulo de negócio da spec §4.3 existe além de `identity`. Nenhum código publica nem
consome evento de domínio, nem usa `platform.storage`, fora dos testes.

## Frontend

React com Vite, TypeScript, Vitest e Playwright.

- Design system (0-17): tokens, `Button`, `TextField`, `Dialog`, `Toast`, `Wordmark`, Inter
  self-hosted, em `src/design/`.
- Formatos (0-16): data, hora e BRL no fuso explícito, só em `src/format/`; textos em
  `src/i18n/` (pt-BR).
- Cliente da API (0-18): `src/api/`, tipos gerados do contrato pelo openapi-typescript.
- Sessão (0-19): `src/session/`, login, rota lembrada, sair por formulário com `_csrf`.
- E2E (0-20): `e2e/session.spec.ts` contra o Keycloak local, por `npm run e2e`, fora de
  `comandos.suite`.

## Raiz e ambiente

- Ambiente local (0-02): `compose.yaml` com PostgreSQL, Keycloak (realm `crm`), Garage e Mailpit;
  conferência em `deploy/local/verificar.sh`.
- Backup (0-03, fechada): PostgreSQL (pgBackRest) e arquivos (rclone) cifrados em
  `deploy/backup/`, destino só por `BACKUP_S3_*`, falha fechado sem destino, guarda em
  `verificar-portabilidade.sh`.
- CI dos dois repositórios (0-07, 0-15), verde no GitHub segundo `planning/FILA.md`; não
  conferido daqui.
- Deploy como código e homologação local (0-04, `docs/operacao/deploy.md`):
  `deploy/manifesto.env` fixa o par de commits (backend `46e767a`, frontend `63752e9`, conferido
  por `reviews/0-04.md`); `deploy/deploy.sh <ambiente>` sobe a infraestrutura, roda a migração e o
  `aplicar-cors` como passos únicos (falhou, nada é trocado), troca `api` e `worker`, depois
  `frontend` e o proxy nginx (quatro prefixos para o BFF, o resto é SPA, mesma origem). A
  homologação local (`crm-akeel-homologacao`, `http://localhost:18080`) roda em perfil `prod` e é
  conferida por `deploy/homologacao/verificar.sh` (12 `ok`) e `e2e.sh` (8 testes), medidos pelo
  Revisor em 2026-11-25. Produção (`deploy/producao/**`) **nunca executada**; o workflow
  `.github/workflows/deploy.yml` só dispara à mão (§28). Limites conhecidos: a troca para a
  aplicação por ≈ 11 s; o backup não alcança o projeto de produção; a URL pré-assinada aponta para
  o Garage interno; produção reconstrói as imagens (`decisoes §29`, `docs/arquitetura/atalhos.md`).

Fora do repositório e não operado pelo CRM: o Keycloak da TI em `https://akpannel.akeel.com.br`,
realm `crm`. Os segredos ficam fora do repositório.
