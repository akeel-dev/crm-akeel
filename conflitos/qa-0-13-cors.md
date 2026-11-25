# Conflito — QA: o Garage v2.5.0 põe `Access-Control-Allow-Origin: *` em toda resposta de erro, inclusive no pré-voo recusado

Aberto por: QA. Data: 2026-11-25. Story: 0-13 (critério 4). Estado: aberto

## O que está em conflito

O critério 4 diz: "só a permitida recebe os cabeçalhos de CORS". O Garage v2.5.0 **suporta**
CORS por bucket pela API S3 (`PutBucketCors`): com a regra aplicada, a origem configurada
recebe `200` com `Access-Control-Allow-Origin: <a origem>` e `Access-Control-Allow-Methods`.
Mas a origem não configurada recebe `403` **com** `Access-Control-Allow-Origin: *`, porque o
Garage acrescenta esse cabeçalho a toda resposta de erro (também a um GET anônimo). Lido ao
pé da letra, o critério nunca fecha com o Garage, por nada que o CRM faça.

O navegador recusa esse pré-voo mesmo assim: o Fetch exige status "ok" (200 a 299) na
resposta do pré-voo, e a de fora recebe `403` e nenhum `Access-Control-Allow-Methods`.

## Evidência

Medido em 2026-11-25, macOS, `dxflrs/garage:v2.5.0`, num clone com uma implementação
descartável (AWS SDK 2.59.9, `putBucketCors` com as origens de `crm.storage.cors-origins`):

- pré-voo `OPTIONS` (Origin `https://intruso.example.test`, `Access-Control-Request-Method: PUT`)
  depois da regra aplicada: `status 403, headers {access-control-allow-origin=[*],
  content-length=[231], content-type=[application/xml]}`;
- o mesmo da origem configurada `http://localhost:5173`: `200`, `access-control-allow-origin`
  igual à origem, `access-control-allow-methods=[GET, PUT, HEAD]`;
- `curl -i` num Garage limpo, GET anônimo em `/qualquer/obj`: `403 Forbidden`,
  `access-control-allow-origin: *` (o cabeçalho vem em qualquer erro);
- antes da regra, a origem configurada também recebe `403` com `access-control-allow-origin: *`.

## O que eu fiz no teste (sem apagar o critério)

`ObjectStorageTest.theBucketCorsAppliedByTheCrmAnswersThePreflightOnlyForTheConfiguredOrigins`
confere o que o navegador confere:

- antes de o CRM aplicar o CORS, o pré-voo da origem configurada **não** é concedido;
- depois, cada origem configurada recebe status 2xx, `Access-Control-Allow-Origin` igual à
  origem e `Access-Control-Allow-Methods` com `PUT`;
- a origem de fora **não** é concedida (não é 2xx com origem e `PUT`), **não** recebe
  `Access-Control-Allow-Methods` e **não** recebe `Access-Control-Allow-Origin` igual a ela.
  O `*` no `403` é aceito, e é este o ponto que peço para o dono do critério confirmar.

As sabotagens S6 (`AllowedOrigins "*"`), S6b (origem de fora acrescentada às de configuração)
e S7 (CORS não aplicado) deixam o teste vermelho (relatório do QA da 0-13).

## O que eu proponho

Que o Planejador (dono da story) e o Revisor aceitem a leitura "só a permitida recebe um
pré-voo **concedido**", que é o que protege o navegador, ou digam outra. Se a leitura literal
for mantida, o critério depende de o Garage deixar de mandar `*` nos erros, e isso não está
ao alcance do CRM.


## Resolução (Orquestrador, 2026-11-25)

Aceita a leitura do QA: o critério de CORS confere o que o navegador confere (pré-voo concedido só às origens configuradas, com a própria origem em `Allow-Origin` e com `Allow-Methods`). O `*` que o Garage v2.5.0 põe nas respostas de erro (403) não concede acesso, porque o pré-voo de uma origem de fora não recebe `Allow-Methods`. O Revisor da 0-13 confere. Estado: resolvido.
