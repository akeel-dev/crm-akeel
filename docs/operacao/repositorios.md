# Os repositórios do projeto

Dono: DevOps (`time.yml`, `escrita.devops`). Origem: story 0-01; ADR 0001, decisão 2;
`planning/decisoes/2026-11-24.md` §8 e §10.

## O que existe

| Pasta | O que é | Remoto |
|---|---|---|
| `.` (raiz) | método, spec, planning, docs, deploy, conflitos | a definir (GitHub privado, decisoes §10) |
| `backend/` | repositório git próprio: Java 25, Spring Boot, Maven (`./mvnw`) | a definir |
| `frontend/` | repositório git próprio: React, Vite, npm | a definir |

O raiz ignora as duas pastas (`/backend/` e `/frontend/` no `.gitignore` do raiz). Não
há submódulo: o raiz não registra qual versão do back combina com qual do front; quem
registra o par que sobe junto é o manifesto em `deploy/`.

## Como recriar as duas pastas

Sempre a partir da raiz do projeto.

### Hoje (sem remoto)

Não há de onde clonar. Se uma pasta sumiu e não há cópia, ela recomeça vazia:

```
git init -b main backend
git init -b main frontend
```

Depois disso, o primeiro commit de cada uma é o `.gitignore` do DevOps (story 0-01).
Trabalho que só existia na pasta perdida não volta: enquanto não houver remoto, a
cópia local é a única.

### Quando houver remoto

```
git clone <REMOTO_BACKEND: a definir> backend
git clone <REMOTO_FRONTEND: a definir> frontend
```

O endereço de cada remoto entra nesta página quando for criado (pendência da Onda 0).

## Como conferir

```
test -d backend/.git && test -d frontend/.git \
  && git check-ignore -q backend frontend \
  && test -z "$(git status --porcelain -- backend frontend)" \
  && git -C backend log --oneline -1 && git -C frontend log --oneline -1
```

## Segredo local

Os três `.gitignore` ignoram `*.secret`, `secrets/`, `.env` e `.env.*` (exceto
`.env.example`, que só leva nomes de variável, nunca valor). RF-SEC-03.
