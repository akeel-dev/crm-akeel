# Story 0-12 — eventos (evidência)

Transcrito pelo Orquestrador do relatório do QA (2026-11-25, macOS, JDK 25.0.5.1).

QA `5dc05e9` (sobre `d298567`): `platform/events/DomainEventOutboxTest` (12 testes), `RecordingConsumer`,
`FlakyConsumer`, `Delivery`. No HEAD real o test-compile quebra até o Dev (só símbolos do contrato).
✅ Vermelho por asserção num clone com stubs: 12 testes, 10 falhas. ✅ Verde com implementação de
referência (só no clone): 12/0.

| # | Sabotagem (clone) | Resultado |
|---|---|---|
| S01 | `REQUIRED` em vez de `MANDATORY` | 1 falha: não lança fora de transação |
| S02 | `REQUIRES_NEW` | 1 falha: linha sobrevive ao rollback |
| S03 | `publishEvent` também no api | 1 falha: `event_publication` antes do repasse |
| S04 | db-scheduler partindo no api | 1 falha: `relayed_at` sem worker |
| S05 | reentrega sem idade mínima | 1 falha: 2 tentativas antes da idade |
| S06 | repasse sem `relayed_at` | 1 falha: 3 publicações em vez de 1 |
| S07 | staleness no api | 1 falha |
| S08 | worker sem staleness | 1 falha |
| S09 | `republish-outstanding-events-on-restart=true` | 1 falha |
| S10 | `ImmediateStart` (repasse durante o refresh) | 1 falha: evento perdido |
| S11 | correlation descartado | 1 falha |
| S12 | id v4 | 1 falha: versão 7 esperada |
| S13 | `occurredAt` de `Instant.now()` | 1 falha |
| S14 | sem validação de `type` | 1 falha |
| S15 | repasse a cada 10 s | 1 falha: entrega > 5 s |
| S16 | correlation gerado constante | 1 falha |

Achados: A1 (staleness "zero" falha a subida no Modulith 2.2 — no api as propriedades ficam ausentes);
A2 (com `ImmediateStart` o repasse roda antes dos listeners e o evento some sem erro: usar `ContextReadyStart`);
A3 (um `Task` avulso faz o Spring descartar a `List<Task<?>>`); A4 (dois testes de interpretação mantidos
pelo Orquestrador: formato do `type` e entrega em até 5 s).

## Dev, Revisor e Arquiteto (2026-11-25)

- Dev `9126384`: verify 150/150. Revisor (`reviews/0-12.md`): critérios 1–6 passam; refez S01, S03, S05,
  S06 (variante), S07, S09, S10 (3×), S12 contra o código real — todas vermelhas. B1: faltavam as regras do critério 7.
- Remedição do Orquestrador sob carga ~9 (revisor rodando junto): 2 falhas de tempo; as duas passaram sozinhas
  (~60 s cada). Remedição limpa depois das regras: **152/152, 5:29 min**.
- Arquiteto `4e0d7bb` (backend) + `1a5c7bb` (ADR 0002): regras `only_platform_events_uses_the_application_event_publisher`
  e `domain_event_consumers_are_application_module_listeners`. ✅ Sabotagens em clone:

| # | Plantado | Resultado |
|---|---|---|
| (i) | `deals.SabPublisher` com `ApplicationEventPublisher.publishEvent` | exit 1, 3 violações |
| (i) var. | `ApplicationContext.publishEvent` em `deals` | exit 1, 1 violação |
| (i) gêmeo | mesma classe em `platform.events` | exit 0 |
| (ii) | `@EventListener on(DomainEvent)` em `deals` | exit 1 |
| (ii) var. | `@TransactionalEventListener` | exit 1 |
| (ii) gêmeo | `@ApplicationModuleListener` | exit 0 |

ADR 0002: N1 ordem `occurred_at, id` aceita; N2 a guarda do ContextReadyStart é probabilística (corrida na subida),
com gatilho para trocar por uma guarda sem tempo.
