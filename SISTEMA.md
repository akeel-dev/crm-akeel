# SISTEMA — crm-akeel

Dono: Arquiteto. Descreve **o que existe**, não o que vai existir.

Atualizado: 2026-11-25. Backend no commit `c07d095`, frontend no `63752e9`. A stack está em
`docs/adr/0001-stack.md`; os módulos, em `docs/arquitetura/modulos.md`; os atalhos e limites
declarados, em `docs/arquitetura/atalhos.md`.

## Medição

`comandos.arquitetura`, rodado em 2026-11-25 num clone do backend fixado em `c07d095`:

```
[ModularityTest] módulos detectados (2): identity, platform
Tests run: 2, Failures: 0  -- ModularityTest
Tests run: 2, Failures: 0  -- StorageConfigTest
Tests run: 10, Failures: 0 -- ArchitectureTest
Tests run: 14, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

## Backend

Spring Boot 4.2.0 (webmvc), Flyway e jOOQ do Boot, PostgreSQL, enforcer `requireJavaVersion
[25,)`. No classpath de produção também: Spring Security com OAuth2 client, Spring Session JDBC,
Actuator, `spring-boot-starter-mail`, db-scheduler 17.2.0 (`db-scheduler-spring-boot-4-starter`),
springdoc 3.1.0 (sem Swagger UI) e `spring-modulith-api`. Em teste: Spring Modulith 2.2.0,
ArchUnit 1.5.1, Testcontainers. Migrações: `V1__extensions`, `V2__spring_session`,
`V3__scheduled_tasks`, `V4__mail_delivery`.

Configuração: `application.yml` (Keycloak por `KEYCLOAK_*`, sessão de 8 h de inatividade e 30
dias absolutos, cookie `HttpOnly`/`Secure`/`SameSite=Lax`, Mailpit `localhost:1025`, intervalo de
e-mail `PT5M`, indicadores de saúde do db-scheduler e de e-mail desligados) e
`application-prod.yml` (relay `MAIL_HOST`/`MAIL_PORT`, padrão `smtp-relay.gmail.com:587`, STARTTLS
obrigatório, EHLO por `MAIL_EHLO_NAME`).

- **`identity`** (0-09): login BFF pelo Keycloak (Authorization Code), sessão no PostgreSQL,
  nenhum token no navegador, renovação do token (`TokenRefreshFilter`), idade absoluta da sessão,
  `GET /api/session`, logout por `end_session`, CSRF por cookie `XSRF-TOKEN`.
- **`platform`**, sem subpacote: `RunModes` (modos `api`, `worker`, `migrate`; desconhecido é
  recusado) e `RunModeConfig` (0-10).
- **`platform.jobs`** (0-10): fachada sobre o db-scheduler (`JobDefinition`, `JobScheduler`,
  `RetryPolicy`, `JobStatus`), novas tentativas, saúde do worker presa ao agendador. Exposta como
  `@NamedInterface("jobs")`.
- **`platform.mail`** (0-11): e-mail do sistema por fila (`SystemMail`, `QueuedSystemMail`),
  registro em `mail_delivery`, 5 novas tentativas, comando de verificação do relay. Usa
  `platform.jobs`.
- **`platform.openapi`** (0-08): contrato em `/v3/api-docs`, versionado em
  `backend/openapi/openapi.json` e copiado em `frontend/openapi/openapi.json` (`cmp` na suíte).

Nenhum módulo de negócio da spec §4.3 existe além de `identity`.

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

Fora do repositório e não operado pelo CRM: o Keycloak da TI em `https://akpannel.akeel.com.br`,
realm `crm`. Os segredos ficam fora do repositório.
