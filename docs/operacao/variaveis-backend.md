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

Atenção: o bloco "Rodar o backend e o frontend contra este ambiente" de
`ambiente-local.md` exporta `CRM_DB_PASSWORD`, `CRM_STORAGE_ACCESS_KEY` e
`CRM_STORAGE_SECRET_KEY`. **Nenhum dos três é lido pelo backend hoje** (grep em
`backend/src/main` sem ocorrência). Para o banco valem os `SPRING_DATASOURCE_*` acima.

## Modo de execução (opcionais)

| Variável | Obrigatória | Exemplo | Efeito / se faltar |
|---|---|---|---|
| `CRM_MODE` (ou `--crm.mode=`) | não | `migrate` · `worker` | `migrate`: só roda o Flyway e sai (`RunModes`). `worker`: só `/actuator/health` responde, o resto `404` (`RunModeConfig`). Ausente: modo api |
| `SPRING_PROFILES_ACTIVE` | não (produção: `prod`) | `prod` | com `prod`, o api e o worker recusam subir se houver migração pendente. Ausente: o Flyway migra na subida |

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
(cd backend && ./mvnw spring-boot:run)     # porta 8080
```

## Como esta lista foi conferida

- ✅ leitura: `application.yml` (quatro placeholders `KEYCLOAK_*`, sem `spring.datasource`),
  `SecurityConfig` (`@Value("${CRM_PUBLIC_URL}")`, `getRequiredProperty("KEYCLOAK_CLIENT_SECRET")`,
  `publicUrl + "acesso-recusado"`), `RunModes` e `RunModeConfig` (`crm.mode`, perfil `prod`).
- ✅ execução: `grep -rniE 'datasource|CRM_DB|CRM_STORAGE|getRequiredProperty' backend/src/main`
  só acha o `DataSourceAutoConfiguration` de `RunModes` e o `getRequiredProperty` do `SecurityConfig`.
- ⚠️ não medido: as mensagens exatas de falha de cada ausência (o backend não foi subido
  sem cada variável).
