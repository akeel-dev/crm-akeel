# Conflito — qa: `server.request.header.forwarded.strategy=native` não existe no Boot 4.2.0

Aberto por: qa. Data: 2026-11-24. Story: 0-09. Estado: aberto

## O que está em conflito

A story 0-09 (Objetivo; critério 15; passo 2 do Dev) e o ADR 0003, emenda §15 (item 1,
"Guardado por" e "Consequências"), mandam configurar
`server.request.header.forwarded.strategy=native`. No Spring Boot 4.2.0 essa propriedade
é do tipo `ForwardedHeaderStrategy`, cujos valores são `WEB_SERVER`, `FRAMEWORK` e `NONE`.
`native` era um valor da propriedade antiga, `server.forward-headers-strategy`
(depreciada na 4.2.0, remoção na 4.4.0). Com `native` na propriedade nova, a aplicação
**não sobe**. O Dev, seguindo a story ao pé da letra, trava na inicialização.

## Evidência

✅ execução, 2026-11-24, macOS, JDK 25, num protótipo descartável do QA no scratchpad (não no
repositório), com `server.request.header.forwarded.strategy: native` no `application.yml`:

```
Caused by: org.springframework.boot.context.properties.bind.BindException: Failed to bind properties under 'server.request.header.forwarded.strategy' to org.springframework.boot.web.server.autoconfigure.ForwardedHeaderStrategy
Caused by: java.lang.IllegalArgumentException: No enum constant org.springframework.boot.web.server.autoconfigure.ForwardedHeaderStrategy.native
```

✅ leitura, `javap` de `ForwardedHeaderStrategy` em `spring-boot-web-server-4.2.0.jar`:
constantes `WEB_SERVER`, `FRAMEWORK`, `NONE`. Metadados do mesmo jar: `server.forward-headers-strategy`
com `"deprecation": {"replacement": "server.request.header.forwarded.strategy", "since": "4.2.0"}`.

✅ execução: com `strategy: web-server`, o `ForwardedCallbackTest` passa no protótipo
(`redirect_uri=https://crm.akeel.com.br/login/oauth2/code/keycloak` atrás dos cabeçalhos;
`http://localhost:<porta>/…` sem eles); tirando a propriedade, ele fica vermelho.

⚠️ hipótese: `web-server` é o equivalente do antigo `native` (o servidor embutido trata os
cabeçalhos, o `RemoteIpValve` do Tomcat). O comportamento do teste confirma o efeito, não a
documentação.

## O que eu proponho

- Dev (0-09): usar `server.request.header.forwarded.strategy=web-server`. Os testes do QA
  conferem o comportamento (critério 15), não o nome do valor, então nada muda neles.
- Planejador: trocar `native` por `web-server` na story 0-09 (Objetivo, critério 15, passo 2,
  sabotagem "sem `server.request.header.forwarded.strategy`").
- Arquiteto: a mesma troca no ADR 0003, emenda §15 (item 1, tabela "Guardado por",
  "Consequências para o time").

## Resolução


## Resolução (Orquestrador, 2026-11-24)

Valor correto: `web-server` (Boot 4.2.0 aceita só `web-server`, `framework`, `none`). Story 0-09 corrigida pelo Planejador; ADR 0003 emendado pelo Arquiteto (`4e9c1f7`). Fechado.
