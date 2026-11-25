# Story 0-13 — arquivos via platform.storage (evidência)

Transcrito pelo Orquestrador do relatório do QA (2026-11-25, macOS, JDK 25.0.5.1).

QA `d194a71` (sobre `4e0d7bb`): `platform/storage/ObjectStorageTest` (critérios 1–4),
`StorageConfigurationRequiredTest` (5), `StorageCredentialsTest` (7), `support/GarageTestServer`
(`dxflrs/garage:v2.5.0`), `config/application.yml` de teste e gêmeo plantado. Editou uma linha de
`RunModeSelectionTest` e `MailCheckCommandTest` (JVM filho sem test-classes precisa das propriedades).
No HEAD real o test-compile quebra até o Dev. ✅ Vermelho por asserção com stubs: 16 testes, 12 falhas.
✅ Verde com implementação descartável no clone: verify 168/0/0.

| # | Sabotagem (clone) | Resultado |
|---|---|---|
| S1 | PUT pré-assinado para outra chave | vermelho (GET 404) |
| S2 | validade ignorada | vermelho (URL expirada ainda 200) |
| S3 | parte fixa de 8 MiB | vermelho |
| S4 | `complete` sem efeito | vermelho (GET 404) |
| S5 | `abort` sem efeito | vermelho (PUT de parte depois do abort 200) |
| S6 | CORS `*` | vermelho |
| S6b | origem de fora somada | vermelho |
| S7 | CORS não aplicado | vermelho (pré-voo 403) |
| S8 | `region` com padrão silencioso | vermelho |
| S9 | `secret-key` com padrão no yml | vermelho (2 testes) |
| S10 | `AwsBasicCredentials.create` em `deals` | vermelho |

Conflito `conflitos/qa-0-13-cors.md`: o Garage põe `Access-Control-Allow-Origin: *` em respostas de erro;
resolvido pelo Orquestrador (o critério confere o pré-voo, como o navegador).

## Dev e Arquiteto (2026-11-25)

- Dev `5e501d7`: 16/16 nas três classes; verify 168/168 (remedido pelo Orquestrador: 168/168, 8:19 min).
- Arquiteto, critério 8, classes reais do AWS SDK 2.59.9, clone em `5e501d7` (✅ execução):

| Plantado | Resultado |
|---|---|
| `deals.SabS3` com `S3Client` | exit 1, `aws_sdk_only_in_platform_storage` |
| gêmeo em `platform.storage` | exit 0 |
| `deals.SabPresigner` com `S3Presigner` | exit 1, mesma regra |
| tipo público de `platform.openapi` usado por `deals` | exit 1, ModularityTest (não exposto) |
| `deals` usando `ObjectStorage` (controle) | exit 0 (`@NamedInterface("storage")`) |
