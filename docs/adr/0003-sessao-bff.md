# ADR 0003 — A sessão da BFF, com os tokens, fica no PostgreSQL pelo Spring Session JDBC

Dono: Arquiteto. Data: 2026-11-24. Estado: aceito pelo humano em 2026-11-24 (planning/decisoes/2026-11-24.md §11); emendas de 2026-11-24 (§14, §15, a correção do valor de `forwarded.strategy` e o handler do CSRF, §22)

Responde a **Q-ARQ-2** da Onda 0 (trava a story 0-09).

**Emenda de 2026-11-24 (P-18, `planning/decisoes/2026-11-24.md §14`; spec v1.2, §5.1):**

1. **O BFF foi mantido.** O login usa o cliente **confidencial `crm-bff`**, que a TI
   ainda vai criar (Authorization Code + PKCE `S256`). O nome é provisório: o
   `client-id` vem de configuração (`KEYCLOAK_CLIENT_ID`) e o segredo do arquivo de
   segredos do Docker (RF-SEC-03); nenhum dos dois é literal no código. O `crm-web`
   público não é usado para login. Até a TI criar o cliente, a Onda 0 roda contra o
   realm de teste `crm`, que já traz um `crm-bff` confidencial.
2. **O access token dura 5 min; a renovação acontece no servidor**, nunca no navegador:
   - um `OAuth2AuthorizedClientManager` (`DefaultOAuth2AuthorizedClientManager`) com
     `OAuth2AuthorizedClientProviderBuilder.builder().authorizationCode().refreshToken()`,
     ligado ao `HttpSessionOAuth2AuthorizedClientRepository` da decisão 2. O provider
     de refresh renova quando faltar menos que o `clockSkew` (padrão 60 s) para o
     access token vencer, e o gerenciador grava o cliente renovado **na sessão**, ou
     seja, no banco: a outra instância já lê o token novo;
   - quem chama o gerenciador é um filtro do módulo `identity` em toda requisição
     autenticada a `/api/**`. Sem isso nada renova, porque a autenticação da sessão
     não expira junto com o access token;
   - **se o refresh falhar com `invalid_grant`** (usuário desativado, sessão encerrada
     no Keycloak, refresh token vencido), o handler padrão remove o cliente
     autorizado, e o filtro invalida a sessão e responde 401. Isso amarra a sessão do
     CRM à do Keycloak e faz valer a RF-IAM-04 ("encerra as sessões ativas");
   - o escopo continua `openid` (com `email` e `profile`), **sem `offline_access`**,
     que é um dos gatilhos de cifra abaixo.
3. **A decisão sobre a cifra dos tokens não muda** (decisão 6 e o quadro "Decidido
   pelo Pedro"): o refresh token na sessão continua inútil sem o segredo do `crm-bff`.
   Trocar o cliente não aciona nenhum gatilho.

**Premissas sobre o realm, que a TI configura e o CRM não controla** (confirmadas pela
TI em 2026-11-24, §15: Idle 8 h, Max 30 dias, Revoke Refresh Token desligado; ⚠️ informado,
não conferível daqui, porque o discovery não expõe esses valores):
- **SSO Session Idle ≥ 8 h e SSO Session Max ≥ 30 dias** no realm `crm`. O refresh
  token do Keycloak vence com a sessão SSO; com o padrão do Keycloak (30 min de
  inatividade), o CRM deslogaria após 30 min parado, não 8 h. A ociosidade real da
  sessão é o menor dos dois valores.
- **"Revoke Refresh Token" desligado** (padrão do Keycloak). Ligado, duas requisições
  simultâneas da mesma sessão renovariam com o mesmo refresh token e a segunda
  derrubaria a sessão. Se a TI precisar ligá-lo, a renovação passa a ser serializada
  por sessão (custo: um lock por id de sessão no `identity`).

**Guardado por** (acréscimo à tabela abaixo; teste de integração do QA, em
`comandos.suite`, com Keycloak de Testcontainers e o realm de teste `crm`, dois
contextos `api`; o tempo é avançado por um `Clock` injetado no provider de refresh,
não por espera):

| Regra | Teste que fica vermelho |
|---|---|
| Renovação no servidor, gravada na sessão | Sessão criada em A; relógio além do `expiresAt` do access token; `GET /api/session` em B → 200, e o cliente autorizado lido da sessão tem access token **diferente** do original e `expiresAt` no futuro. Sabotagem: tirar `.refreshToken()` do builder (ou o filtro) deixa vermelho |
| Falha do refresh derruba a sessão | Usuário desativado (ou sessão encerrada) pela Admin API do Keycloak de teste; relógio além do vencimento; a próxima requisição → 401 e a linha some de `SPRING_SESSION`. Gêmeo por presença: sem desativar, 200 |
| Nenhum token no navegador durante a renovação | O inspetor do critério 2 da 0-09 aplicado às respostas da renovação acusa zero `access_token`/`refresh_token`/JWT |
| `client-id` de configuração | Contexto sobe com `KEYCLOAK_CLIENT_ID=crm-bff` e o login passa; com outro valor, falha. `backend/src/main/**` não contém o literal `"crm-bff"` |

**Emenda de 2026-11-24 (Keycloak entregue pela TI, `planning/decisoes/2026-11-24.md §15`):**

A TI criou o `crm-bff` (confidencial, PKCE `S256`, redirect
`https://crm.akeel.com.br/login/oauth2/code/keycloak`) e o `crm-bff-dev` (qualquer caminho em
`localhost:8080`, `5173` e `3000`), no Keycloak 26.8.2. O Pedro disse que a configuração
do realm é ponto de partida: o time pode pedir mudanças. Evidência conferida em 2026-11-24:

| Fato | Evidência |
|---|---|
| O redirect padrão do login é `{baseUrl}/login/oauth2/code/{registrationId}`; o endpoint de redirecionamento é `/login/oauth2/code/*` | docs.spring.io/spring-security/reference/servlet/oauth2/login/core.html e …/login/advanced.html (Spring Security 7.2.0) |
| O início do login é `/oauth2/authorization/{registrationId}` (`OAuth2AuthorizationRequestRedirectFilter.DEFAULT_AUTHORIZATION_REQUEST_BASE_URI`) | …/login/advanced.html (7.2.0) |
| **OIDC Back-Channel Logout existe:** `.oidcLogout(o -> o.backChannel(...))` abre `POST /logout/connect/back-channel/{registrationId}`, valida assinatura e claims do `logout_token` e encerra a sessão do `sid` (ou todas as do `sub`) | …/login/logout.html (7.2.0), "OpenID Connect 1.0 Back-Channel Logout" |
| O vínculo `sid` → sessão do cliente fica num `OidcSessionRegistry`, **em memória por padrão** (`InMemoryOidcSessionRegistry` em `OidcSessionRegistryAuthenticationStrategy`) | idem, "Customizing the OIDC Provider Session Registry"; código de `OAuth2LoginConfigurer` na tag `7.2.0` |
| Para encerrar, o handler faz uma **chamada HTTP interna** a `logoutUri` (padrão `{baseUrl}/logout/connect/back-channel/{registrationId}`) com o cookie `JSESSIONID=<id cru da sessão>` | `OidcBackChannelLogoutHandler.java`, tag `7.2.0` (`eachLogout`, `computeLogoutEndpoint`) |
| O cookie do Spring Session se chama `SESSION` e leva o id **em Base64** (`useBase64Encoding = true`) | `DefaultCookieSerializer.java`, spring-session tag `4.2.0`, linha 84; a doc do Spring Security manda trocar o nome para `SESSION`, mas não fala do Base64 |
| O realm anuncia `backchannel_logout_supported: true` e `backchannel_logout_session_supported: true`; issuer `https://akpannel.akeel.com.br/realms/crm` | `GET https://akpannel.akeel.com.br/realms/crm/.well-known/openid-configuration`, executado em 2026-11-24 |
| O `OidcClientInitiatedLogoutSuccessHandler` redireciona ao `end_session` por `GET` (o `id_token_hint` vai na URL); com `FormPostRedirectStrategy`, vai por `POST` de formulário | …/login/logout.html (7.2.0) |
| No Boot 4.2, os cabeçalhos `X-Forwarded-*` só valem com `server.request.header.forwarded.strategy` (sem valor, é deduzido da plataforma de nuvem; numa VPS, nenhuma) | docs.spring.io/spring-boot/appendix/application-properties/index.html (4.2.0) |
| Para SPA, o Spring Security 7.2 tem `csrf.spa()` (token em cookie legível + tratamento do BREACH) | docs.spring.io/spring-security/reference/servlet/exploits/csrf.html (7.2.0), "Single-Page Applications" |

1. **O callback fica `/login/oauth2/code/keycloak`.** É o padrão do Spring com o
   `registrationId` **`keycloak`** (`spring.security.oauth2.client.registration.keycloak.*`),
   sem `redirect-uri` customizado. O `registrationId` é o nome do provedor, não o
   `client_id`: o mesmo caminho serve ao `crm-bff` e ao `crm-bff-dev`, e trocar de cliente
   não muda a URL cadastrada. O `redirect_uri` é montado com `{baseUrl}`, então, atrás do
   Tunnel e do proxy reverso, a `api` precisa ver o host e o esquema originais:
   `server.request.header.forwarded.strategy=web-server` (corrigido em 2026-11-24; ver a emenda
   logo abaixo), e o proxy repassa `Host` e
   `X-Forwarded-Proto: https`. Sem isso, o Spring monta `http://…` e o Keycloak devolve 400.
   **Pedido à TI:** cadastrar também `https://crm.akeel.com.br/` (exato, sem curinga), que é o
   `redirect_uri` do convite e o `post_logout_redirect_uri` do logout. Hoje só o callback está
   cadastrado, e um redirect fora da lista devolve 400.
2. **Back-channel logout: existe no Spring, mas não liga na v1. A TI deixa a "Backchannel
   logout URL" (e a de front-channel) do `crm-bff` vazia.** Motivo: ligado com os padrões, ele
   **falha em silêncio** no nosso desenho, por três razões conferidas acima:
   - o registro `sid` → sessão fica na memória de uma instância, e com duas `api` o
     `logout_token` cai na outra (e todo deploy o apaga);
   - a chamada interna manda `JSESSIONID=<id cru>`, e o nosso cookie é `SESSION` em Base64;
   - com `{baseUrl}`, a chamada interna sairia pela internet e voltaria pelo Cloudflare.

   O que a spec exige já está coberto sem ele:
   - **RF-IAM-04** (desativar no CRM "encerra as sessões ativas") parte do CRM, que apaga as
     próprias sessões (`FindByIndexNameSessionRepository.findByPrincipalName`, com o nome do
     principal = `sub`, o padrão para OIDC) e encerra as do Keycloak pela Admin API. Fica
     para a Onda 1;
   - uma sessão encerrada **no Keycloak** (pelo console da TI, por usuário desativado lá, por
     expiração) derruba a do CRM na primeira requisição a `/api/**` depois que o access token
     vence: o refresh falha com `invalid_grant` (emenda P-18, item 2). A janela é **≤ 5 min**,
     a vida do access token.

   **Se o gatilho vier** (ver alternativas): caminho
   `https://crm.akeel.com.br/logout/connect/back-channel/keycloak`; `oidcLogout().backChannel()`
   com um `OidcSessionRegistry` em tabela do PostgreSQL (uma classe + migração),
   `setSessionCookieName("SESSION")`, cookie do Spring Session sem Base64
   (`DefaultCookieSerializerCustomizer`) ou handler próprio que apaga a linha de
   `SPRING_SESSION` direto, e `logoutUri` apontando para a própria instância
   (`http://localhost:8080/…`), não para `{baseUrl}`. Efeito na sessão JDBC: a linha da sessão
   do `sid` some de `SPRING_SESSION`, e o cookie passa a dar 401 em qualquer instância.
   **Alcance pelo Cloudflare:** o Keycloak chama o endpoint de fora, sem navegador, como os
   webhooks da §4.5. Ele chega se o caminho não estiver atrás do Cloudflare Access (o Keycloak
   não manda o token de serviço do Access) nem de desafio de bot. A spec já põe a SPA e a API
   fora do Access (§4.5, "Endpoints públicos").
3. **A SPA e a BFF ficam no mesmo host, `crm.akeel.com.br`, atrás do mesmo proxy.** O proxy
   manda para a `api` só `/api/`, `/oauth2/authorization/`, `/login/oauth2/code/` e `/logout`;
   o resto vai para os estáticos da SPA (a SPA não usa esses prefixos como rota). Motivos:
   - **cookie:** a sessão fica *host-only* (sem `Domain`), não vaza para outros hosts de
     `akeel.com.br` (o `akpannel` inclusive), e o `SameSite=Lax` não depende de nenhuma
     regra de site;
   - **CSRF:** o cookie do token (modo simples, não `csrf.spa()`: ver a emenda do handler do CSRF, §22) é lido pela SPA no mesmo host. Com
     subdomínios, ele precisaria de `Domain=.akeel.com.br`, legível e gravável por qualquer
     subdomínio;
   - **CORS:** nenhum. Com subdomínios, toda escrita (JSON com cabeçalho CSRF) faria preflight,
     com `Allow-Credentials` e uma lista de origens para manter;
   - **D-06:** um hostname, uma regra de ingresso no Tunnel, um conjunto de regras de WAF;
   - já é o que o convite (`redirect_uri=https://crm.akeel.com.br/`), o callback cadastrado e o
     proxy do Vite da 0-19 (crit. 8, mesma origem em dev) supõem.
4. **Desenvolvimento usa o `crm-bff-dev`.** `KEYCLOAK_CLIENT_ID=crm-bff-dev`, e o segredo vem
   da variável de ambiente **`KEYCLOAK_CLIENT_SECRET`**
   (`spring.security.oauth2.client.registration.keycloak.client-secret=${KEYCLOAK_CLIENT_SECRET}`,
   sem valor padrão), exportada na shell de quem desenvolve, **nunca** de arquivo versionado
   (nem `.env` no repositório, nem `application-*.yml`). Em produção, o mesmo nome chega pelo
   arquivo de segredos do Docker (RF-SEC-03; ex.: `spring.config.import=configtree:/run/secrets/`
   com o arquivo `KEYCLOAK_CLIENT_SECRET`), com o `crm-bff`. O callback de dev é
   `http://localhost:5173/login/oauth2/code/keycloak`, pelo proxy do Vite, que mantém o `Host`.
   O teste usa o realm de teste do Testcontainers, com segredo próprio e falso.
5. **Exceção do `id_token_hint`, aceita pelo Pedro (§15).** O único token que passa pelo
   navegador é o ID token, no `Location` do redirecionamento ao `end_session` (0-09, crit. 2),
   emitido **depois** de a sessão do servidor ser invalidada. Por que se aceita:
   - ele não abre nada no CRM. A BFF não aceita Bearer (0-09, crit. 6), e a futura API
     pública exige `aud` com `crm-api`, que um ID token do `crm-bff` não tem;
   - sem ele, o Keycloak pede confirmação de logout.

   O que fica exposto: nome e e-mail do usuário (claims do ID token) numa URL, que pode cair
   no histórico do navegador e em log de acesso. A alternativa mais barata, se isso incomodar,
   está nas alternativas abaixo.

**Emenda de 2026-11-24 (valor de `forwarded.strategy`; `conflitos/qa-0-09-forwarded-strategy.md`):**

O item 1 da emenda §15 mandava `server.request.header.forwarded.strategy=native`. No Boot
4.2.0 esse valor não existe e a aplicação não sobe (`No enum constant
…ForwardedHeaderStrategy.native`, execução do QA no conflito). `native` era valor da
propriedade antiga `server.forward-headers-strategy`. **O valor certo é `web-server`.**

| Fato | Evidência |
|---|---|
| A propriedade nova é do tipo `ForwardedHeaderStrategy`, com as constantes `WEB_SERVER`, `FRAMEWORK` e `NONE` | ✅ leitura: `javap` de `org.springframework.boot.web.server.autoconfigure.ForwardedHeaderStrategy`, `spring-boot-web-server-4.2.0.jar` |
| `server.forward-headers-strategy` está depreciada desde a 4.2.0, com remoção na 4.4.0, e aponta para `server.request.header.forwarded.strategy` | ✅ leitura: `META-INF/spring-configuration-metadata.json` do mesmo jar |
| O antigo `NATIVE` equivale a `WEB_SERVER`: `ForwardedHeaderStrategy.adaptDeprecated` mapeia `NATIVE → WEB_SERVER`, `FRAMEWORK → FRAMEWORK`, `NONE → NONE` | ✅ leitura: `javap -c` de `adaptDeprecated` e do `$SwitchMap` em `ForwardedHeaderStrategy$1`, mesmo jar |
| Com `web-server`, o servidor embutido (Tomcat, via `spring-boot-starter-webmvc`) trata os cabeçalhos no `RemoteIpValve`, que só confia em quem casa com `server.tomcat.remoteip.internal-proxies` | ✅ leitura: metadados de `spring-boot-tomcat-4.2.0.jar` (`internal-proxies`, `trusted-proxies`, `protocol-header`) |

**Por que `web-server` e não `framework`:**

- É a tradução exata do que o ADR decidiu (`native`), confirmada no fonte. Não é decisão nova.
- **Confiança no remetente.** O `RemoteIpValve` só aplica `X-Forwarded-*` quando a conexão vem
  de um proxy interno (`internal-proxies`; o padrão do Tomcat cobre as faixas privadas e o
  loopback, onde ficam o proxy e o `cloudflared` na VPS). O `ForwardedHeaderFilter` do
  `framework` aplica os cabeçalhos de **qualquer** remetente. A tabela "Guardado por" já diz
  "vindos de IP de proxy confiável"; com `framework`, um cliente que chegasse direto à `api`
  forjaria host e esquema do `redirect_uri` e o IP de origem.
- **Alcance.** No servidor, o esquema e o IP corrigidos valem para tudo que vem depois
  (`request.isSecure()`, log de acesso do Tomcat, cookie `Secure`). O filtro só corrige o que
  passa por ele, e depende de ficar antes do filtro do Spring Security.

Alternativa mais barata considerada: deixar a propriedade sem valor. Não serve: sem valor, a
estratégia é deduzida da plataforma de nuvem, e numa VPS não há nenhuma (fato da tabela da
§15). O teste de sabotagem do callback já cobre esse caso.

O que muda: a troca de `native` por `web-server` no item 1 da §15 e nas consequências para o
Dev. Os testes do QA conferem o comportamento (callback com o host público), não o nome do
valor, e não mudam. A story 0-09 cita `native` em quatro lugares; a troca lá é do Planejador.

**Alternativas desta emenda:**

| Alternativa | Por que não agora | Gatilho que a faria valer |
|---|---|---|
| **Back-channel logout ligado** (registro em tabela, cookie sem Base64, `logoutUri` local; o desenho do item 2) | Uma classe, uma tabela e três armadilhas silenciosas, para encurtar uma janela que já é ≤ 5 min; a spec não pede propagação imediata de logout feito fora do CRM | A Akeel exigir que uma sessão encerrada **no Keycloak** derrube o CRM na hora; a TI subir a vida do access token (a janela cresce junto); ou outro aplicativo no realm `crm` com SSO compartilhado |
| Back-channel com os padrões do Spring (sem registro em tabela) | Passa num teste de uma instância e falha em produção (duas `api`, deploy, cookie em Base64) | — (nunca: é a armadilha) |
| SPA e BFF em subdomínios (`crm.` e `api.crm.`) | CORS com credenciais, cookie de CSRF com `Domain` largo, dois hostnames no Tunnel, sem ganho para ~50 usuários | A SPA sair da VPS (ex.: CDN/Pages) e o proxy único deixar de existir |
| `id_token_hint` por `POST` (`FormPostRedirectStrategy`) | Tira o token da URL (histórico, logs), mas ele continua no corpo HTML; muda o inspetor do crit. 2 da 0-09 | Achado de pentest/ASVS (RF-SEC-07) ou log de proxy/Cloudflare guardando a query string |
| Logout sem `id_token_hint` (só `client_id` + `post_logout_redirect_uri`) | O Keycloak mostra uma tela "deseja sair?" | O mesmo gatilho acima, se o POST não bastar |

**Guardado por** (acréscimo à tabela da decisão; QA, em `comandos.suite`, salvo onde dito):

| Regra | Teste que fica vermelho |
|---|---|
| Callback `/login/oauth2/code/keycloak` com o host público | `GET /oauth2/authorization/keycloak` com `X-Forwarded-Proto: https` e `X-Forwarded-Host: crm.akeel.com.br` vindos de IP de proxy confiável → o `Location` tem `redirect_uri=https://crm.akeel.com.br/login/oauth2/code/keycloak`. Sabotagem: sem `server.request.header.forwarded.strategy`, sai `http://` e fica vermelho |
| Sessão encerrada no Keycloak derruba a do CRM em ≤ 5 min | Sessão do usuário encerrada pela Admin API do Keycloak de teste (`POST /users/{id}/logout`); **antes** de o access token vencer, `GET /api/session` → 200 (a janela existe, e o teste a enxerga); relógio além do vencimento → 401 e a linha some de `SPRING_SESSION` |
| Back-channel não ligado pela metade | `ArchitectureTest` (`comandos.arquitetura`, quando nascer na Onda 0): nenhuma classe de `br.com.akeel.crm..` chama `OidcLogoutConfigurer.backChannel` nem depende de `OidcBackChannelLogoutHandler` ou `OidcSessionRegistry`. Gêmeo por presença: uma fixture que chama `.backChannel(...)` é acusada. Substituir esta emenda retira a regra |
| Segredo só de ambiente | Contexto sem `KEYCLOAK_CLIENT_SECRET` não sobe (sem valor padrão); `backend/src/main/**` e `backend/src/main/resources/**` não têm `client-secret:` com valor literal. Gêmeo: um `client-secret: abc` plantado é acusado |
| Mesmo host em produção | DevOps, teste de fumaça em homologação: `GET https://<host>/oauth2/authorization/keycloak` responde 302 ao `akpannel` com `redirect_uri` no mesmo host; `GET https://<host>/` devolve o `index.html` da SPA |

**Emenda de 2026-11-24 (handler do CSRF; `planning/decisoes/2026-11-24.md §22`; `reviews/0-19.md`, N2):**

O item 3 da emenda §14 diz "o cookie do token (`csrf.spa()`)". **Não é o que roda.** O backend
(commit `ad9b009`) usa o modo simples, e o Pedro aceitou assim na §22:

| Fato | Evidência |
|---|---|
| Repositório: `CookieCsrfTokenRepository.withHttpOnlyFalse()` (cookie `XSRF-TOKEN` legível pela SPA; cabeçalho `X-XSRF-TOKEN`) | ✅ leitura: `backend/src/main/java/br/com/akeel/crm/identity/SecurityConfig.java`, linhas 85 a 87 |
| Handler: `CsrfTokenRequestAttributeHandler` simples, com `setCsrfRequestAttributeName(null)` (o token é carregado em toda requisição, e o cookie sai sem esperar alguém ler o atributo); **sem** `XorCsrfTokenRequestAttributeHandler` nem `csrf.spa()` | ✅ leitura: mesmo arquivo, linhas 66, 67 e 87 |
| O sair é `POST /logout` de formulário com o token **cru** no campo `_csrf` (0-19, crit. 5). Com `csrf.spa()`, parâmetro de formulário passa pelo handler XOR, e o token cru daria 403 | ⚠️ inferido do código do Spring Security (`SpaCsrfTokenRequestHandler.resolveCsrfTokenValue`: cabeçalho → simples, senão → XOR), `reviews/0-19.md` N2; não rodado. Quem prova o sair contra o backend real é a 0-20 |

**Risco aceito (§22):** sem a máscara XOR, o valor do token é o mesmo em toda resposta, e o
BREACH (compressão + texto escolhido refletido no mesmo corpo) poderia extraí-lo. Aceito porque
o token **nunca vai em HTML nem em corpo de resposta**: só no cookie e no cabeçalho/campo que a
SPA envia. O `SameSite=Lax` da sessão é uma segunda barreira.

**Não "alinhar" o backend ao texto antigo:** trocar para `csrf.spa()` quebra o sair sem que
nenhum teste do front acuse (o front testa contra dublê). Quem trocar o handler troca junto o
`_csrf` do formulário de sair.

**Gatilho para rever** (passar para `csrf.spa()` ou XOR, e mandar o `_csrf` mascarado ou sair
por `fetch` com cabeçalho): o token passar a ir em HTML ou em qualquer corpo de resposta (ex.:
página renderizada no servidor, endpoint que devolve o token); ou achado de pentest/ASVS
(RF-SEC-07) sobre CSRF/BREACH.

Alternativa mais barata considerada: nenhuma; o modo simples já é o mais barato, e a cara
(`spa()`) só vale com o gatilho acima.

## Contexto

D-07 e §5.1: BFF com Authorization Code + PKCE, tokens **só no servidor**, cookie
`HttpOnly`/`Secure`/`SameSite=Lax`, CSRF, sessão inativa 8 h e absoluta 30 dias. §4.5
passo 5 e RNF-13: deploy por troca de instâncias, "sem parada perceptível". RF-SEC-03:
segredos em arquivo de segredos do Docker. RF-SEC-04 exige cifra no banco para tokens
**de terceiros** (WhatsApp, Google), não para os do Keycloak. A infraestrutura da spec
(§4.1) não tem Redis.

Sessão em memória: todo deploy desloga todo mundo, e um login iniciado numa instância
falha se o callback cair em outra (o pedido de autorização, com `state` e o
`code_verifier` do PKCE, fica na `HttpSession`:
`HttpSessionOAuth2AuthorizationRequestRepository`, padrão do Spring Security,
docs.spring.io/spring-security/reference/servlet/oauth2/client/authorization-grants.html).

**Duas armadilhas conferidas** (2026-11-24):

| Fato | Evidência |
|---|---|
| Spring Boot 4.2 autoconfigura sessão em JDBC com `spring-boot-starter-session-jdbc`; propriedades `spring.session.jdbc.*` (tabela padrão `SPRING_SESSION`, limpeza `cleanup-cron` padrão `0 * * * * *`, `initialize-schema` padrão `embedded`, ou seja, **não** cria a tabela no PostgreSQL) e `spring.session.timeout` | docs.spring.io/spring-boot/reference/web/spring-session.html; docs.spring.io/spring-boot/appendix/application-properties/index.html (versão estável 4.2.0) |
| **Os tokens não ficam na sessão por padrão.** O Boot registra um `OAuth2AuthorizedClientRepository` que usa um `OAuth2AuthorizedClientService`, cujo padrão é `InMemoryOAuth2AuthorizedClientService`: com Spring Session, o usuário continuaria logado na outra instância, mas sem os tokens | docs.spring.io/spring-security/reference/servlet/oauth2/client/core.html (Spring Security 7.2.0), seção `OAuth2AuthorizedClientRepository / OAuth2AuthorizedClientService` |

## Decisão

1. **Spring Session JDBC no mesmo PostgreSQL do CRM** (`spring-boot-starter-session-jdbc`).
   As tabelas `SPRING_SESSION` e `SPRING_SESSION_ATTRIBUTES` nascem por migração Flyway
   (o script PostgreSQL do próprio `spring-session-jdbc`), não pelo `initialize-schema`.
2. **Os tokens moram na sessão:** um bean `HttpSessionOAuth2AuthorizedClientRepository`
   substitui o repositório padrão. Assim tokens, `SecurityContext` e pedido de
   autorização ficam num só lugar, que some no logout e na expiração.
3. **Tempos:** `spring.session.timeout=8h` (inatividade). A idade absoluta (30 dias)
   é conferida pela aplicação contra o `CREATION_TIME` da sessão, que está no banco e
   vale em qualquer instância. Os dois configuráveis (§5.1, "ajustável").
4. **Cookie:** o do Spring Session, com `HttpOnly`, `Secure` e `SameSite=Lax`
   (`server.servlet.session.cookie.*`). A troca do id da sessão no login (fixação de
   sessão) é a do Spring Security.
5. **Limpeza de expiradas:** a do próprio Spring Session (`cleanup-cron`, um `DELETE`
   por minuto em cada `api`, idempotente). É infraestrutura, não regra de negócio, então
   não fere a §4.2.
6. **Proteção dos tokens em repouso: sem cifra de aplicação na v1.** O que protege:
   - **o refresh token não vale sozinho:** o CRM é cliente confidencial, e no token
     endpoint cliente confidencial tem de se autenticar (RFC 6749 §6). O segredo do
     cliente está no arquivo de segredos do Docker (RF-SEC-03), **não no banco**;
   - access token de vida curta (o do realm);
   - quem lê `SPRING_SESSION` já tem o `SESSION_ID` em claro, que é a própria
     credencial do cookie: cifrar os tokens não fecha esse acesso. A defesa real é o
     acesso ao banco (só o papel da aplicação) e o backup cifrado (pgBackRest
     `aes-256-cbc`, ADR 0001 decisão 6);
   - sessão apagada no logout e na expiração.

> **Decidido pelo Pedro** (2026-11-24, `planning/decisoes/2026-11-24.md` §11): os
> tokens do Keycloak ficam na sessão **sem cifra de aplicação**.
>
> **Motivo:** a RF-SEC-04 só exige cifra no banco para tokens **de terceiros**
> (WhatsApp, Google), não para os do Keycloak; e quem lê a tabela `SPRING_SESSION` já
> tem o `SESSION_ID` em claro, que é a própria credencial do cookie, então cifrar os
> tokens não fecha esse acesso.
>
> **Gatilhos que obrigam a cifrar** (alternativa "Cifrar os atributos da sessão",
> abaixo): a sessão passar a guardar token que vale sem o segredo do cliente (ex.:
> **token do Google**, que cai na RF-SEC-04); pedir `offline_access`; alguém além da
> aplicação ganhar leitura do banco (ex.: **réplica de BI**); ou **achado de
> pentest/ASVS** (RF-SEC-07, RNF-09). Qualquer um deles reabre esta decisão.

## Alternativas consideradas

| Alternativa | Por que não agora | Gatilho que a faria valer |
|---|---|---|
| **Sessão em memória** (a mais barata) | Fere a RNF-13: todo deploy desloga todos, e login com callback em outra instância falha | — (a spec fecha) |
| **Redis** (`spring-boot-starter-session-data-redis`) | Infraestrutura nova (contêiner, backup, monitoramento) para ~50 usuários; o PostgreSQL já está lá e já tem backup | Medição mostrar a sessão pesando no PostgreSQL (latência da RNF-02) |
| **Cifrar os atributos da sessão** (AES-256-GCM num `ConversionService` do `JdbcIndexedSessionRepository`, chave em segredo do Docker com id de versão para rotação) | Custo de uma classe, uma chave e o roteiro de rotação, para proteger um refresh token que sem o segredo do cliente não serve; não protege o `SESSION_ID` | A sessão passar a guardar token que vale sem o segredo do cliente (ex.: token do Google, que cai na RF-SEC-04), `offline_access`, alguém além da aplicação ganhar leitura do banco (réplica de BI), ou achado de pentest/ASVS (RF-SEC-07, RNF-09) |
| **`JdbcOAuth2AuthorizedClientService`** (tokens na tabela `oauth2_authorized_client`, sessão à parte) | Duas tabelas para o mesmo ciclo de vida; o token sobreviveria ao logout se ninguém o apagasse | Precisarmos dos tokens fora de uma sessão de navegador (job agindo em nome do usuário) |
| **Sessão sem estado em cookie cifrado** | O cookie passaria do limite de ~4 KB com id, access e refresh token; revogar sessão vira lista negra; fora do que o Spring Session oferece | — |
| Limpeza de sessões por tarefa do db-scheduler no `worker` | Mais código que a limpeza embutida, para o mesmo `DELETE` | O `DELETE` por minuto aparecer na carga do banco |

## Guardado por

Todos no teste de integração da 0-09 (QA), em `comandos.suite`, com Keycloak e
PostgreSQL de Testcontainers e **dois contextos `api`** contra o mesmo banco:

| Regra | Teste que fica vermelho |
|---|---|
| Sessão no banco, não em memória | Sessão criada na instância A é reconhecida pela B (`GET /api/session` → 200) |
| Pedido de autorização no banco | Login iniciado em A, callback recebido em B → sessão autenticada |
| **Tokens na sessão, não no `InMemoryOAuth2AuthorizedClientService`** | Em B, o `OAuth2AuthorizedClientRepository` carrega o cliente autorizado da sessão criada em A (não nulo, com access token). Sabotagem registrada: voltar ao repositório padrão deixa este teste vermelho |
| Logout vale para todas as instâncias | Logout em B; o mesmo cookie em A → 401 |
| Idade absoluta | Sessão com `CREATION_TIME` além do limite configurado, usada em B → 401 |

Não há regra de dependência a declarar no `ArchitectureTest`: o repositório padrão nasce
da autoconfiguração, sem import no nosso código, então só o teste de comportamento o pega.

## Consequências para o time

- Nenhuma mudança em `time.yml`.
- **0-09 muda** (critério 8 e sabotagens): ver o retorno ao Orquestrador.
- Dev: `spring-boot-starter-session-jdbc`, migração Flyway com o esquema do Spring
  Session, bean `HttpSessionOAuth2AuthorizedClientRepository`, filtro da idade absoluta.
- DevOps: nada novo. A sessão entra no backup do PostgreSQL; restaurar um backup traz
  sessões que ainda estejam no prazo (aceitável; quem quiser derrubar todas apaga as
  linhas de `SPRING_SESSION`).
- Os atributos são serializados em Java. Uma atualização do Spring Security pode
  tornar sessões antigas ilegíveis; não conferi como o Spring Session reage (relogar
  é aceitável, erro 500 não). Verificar na primeira atualização de versão menor.
- **Emenda §15:**
  - Nenhuma mudança em `time.yml`.
  - Dev (0-09): `registrationId` `keycloak`, `server.request.header.forwarded.strategy=web-server`,
    `client-secret` de `${KEYCLOAK_CLIENT_SECRET}` e nada de `oidcLogout().backChannel()`.
  - DevOps: um host só (`crm.akeel.com.br`); o proxy roteia os quatro prefixos da BFF e
    repassa `Host` e `X-Forwarded-Proto`; o segredo `KEYCLOAK_CLIENT_SECRET` como segredo
    do Docker.
  - QA (0-09): os quatro testes de comportamento da tabela da emenda.
  - Arquiteto: a regra do `ArchitectureTest` quando ele nascer.
  - Onda 1 (RF-IAM-04): encerrar sessões por `findByPrincipalName(sub)` e pela Admin API.
  - Quem fizer o SSE (§4.2): uma conexão SSE aberta não passa pelo filtro de renovação a
    cada evento. Ela precisa fechar quando a sessão some ou quando o access token vence,
    senão escapa da janela de 5 min e do logout.
