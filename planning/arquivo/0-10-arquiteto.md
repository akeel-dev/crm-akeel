# Story 0-10 — critério 10 (Arquiteto), evidência

Transcrito pelo Orquestrador do relatório do Arquiteto (2026-11-24, macOS, JDK 25.0.5.1),
clone do backend em `ffa2bf5`. Comando: `./mvnw -B test -Dtest='ModularityTest,ArchitectureTest,StorageConfigTest'`.

| Rodada | Exit | Resultado |
|---|---|---|
| Base | 0 | ✅ 13/0 |
| `deals.SabDbScheduler` com `com.github.kagkarlsson.scheduler.Scheduler` real | 1 | ✅ `db_scheduler_only_in_platform_jobs` violada (1 vez) |
| Gêmeo: mesma classe em `platform.jobs` | 0 | ✅ 13/0 |
| Removida | 0 | ✅ 13/0 |
| `deals.SabMisc` com `@Scheduled` e `Executors.newFixedThreadPool` | 1 | ✅ 2 falhas (meta-anotado e thread solta) |
| `deals.DealReminders` usando `JobDefinition`/`JobScheduler` | 1 | ✅ ModularityTest: "depends on non-exposed type … within module 'platform'" |
| Com `@NamedInterface("jobs")` em `platform/jobs/package-info.java` + `spring-modulith-api` | 0 | ✅ 13/0; `platform.openapi` continua fechado |

Correção para a 0-11 (Dev): `package-info.java` com `@org.springframework.modulith.NamedInterface("jobs")`
em `platform.jobs`, e `org.springframework.modulith:spring-modulith-api` no pom (versão do BOM 2.2.0).
