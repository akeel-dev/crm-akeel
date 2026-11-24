# Conflito — dev: o contrato marca o cookie XSRF-TOKEN do POST /logout como obrigatório

Aberto por: dev. Data: 2026-11-24. Despacho: sincronizar o contrato do frontend com o commit 59c1156 do backend. Estado: aberto

## O que está em conflito

O commit 59c1156 do backend declara, em `SecurityConfig.java:108`,
`new CookieParameter().name("XSRF-TOKEN").required(true)`. O openapi-typescript transforma
isso em `parameters.cookie: { "XSRF-TOKEN": string }` obrigatório, e o openapi-fetch passa a
exigir o segundo argumento em `client.POST('/logout', ...)`.

O teste do QA `frontend/test/api-client.test.tsx:77` chama `await client.POST('/logout');`
sem argumento (o cookie vai pelo navegador, com `credentials: 'include'`). Com o contrato
novo, o `tsc --noEmit` do `npm test` falha antes do vitest rodar.

O despacho pede ajuste mínimo em `frontend/src/`, mas o erro está no teste, que o Dev não
pode editar, e não há ajuste honesto em `src/` que o resolva: a única saída por `src/` seria
afrouxar o tipo do cliente devolvido por `createApiClient`, o que tapa o sintoma e esconde o
contrato.

## Evidência

✅ execução, 2026-11-24, macOS, em `frontend/` depois de `npm run copy:api` e `npm ci`:

```
> npm run generate:api && tsc --noEmit && vitest run
🚀 openapi/openapi.json → src/api/schema.ts [22ms]
test/api-client.test.tsx(77,18): error TS2554: Expected 2 arguments, but got 1.
```

O teste de contrato do backend (`SessionContractTest.theVersionedContractNamesTheCsrfCookieHeaderAndFormFieldOfTheLogout`,
commit 66218ed) confere só `in` e `name` do cookie; não exige `required: true`.

## Proposta

Causa no backend: trocar `required(true)` por `required(false)` no `CookieParameter` do
`XSRF-TOKEN` (o cookie é posto pelo navegador, não pelo chamador; o header já é
`required(false)`) e regenerar `backend/openapi/openapi.json`. Depois, refazer este
despacho. Hipótese não executada: não rodei o tsc com o cookie opcional.

Alternativa: o QA muda o teste para passar o cookie, se o time quiser o contrato com o
cookie obrigatório. Decide o Orquestrador.

## Resolução (Orquestrador, 2026-11-24)

O cookie `XSRF-TOKEN` fica `required: false` no contrato do `POST /logout`: quem o envia é o navegador, não o código do cliente, e o cabeçalho já é opcional. Correção no backend (Dev da 0-09) depois do commit do QA da 0-10; depois, a cópia do frontend é refeita.
