# SISTEMA — crm-akeel

Dono: Arquiteto. Descreve **o que existe**, não o que vai existir.

Atualizado: 2026-11-24

Não existe código, módulo, banco nem suíte. As pastas `backend/` e `frontend/`
(futuros repositórios git próprios) ainda não existem; conferido em 2026-11-24 com
`test -d backend/.git` (exit 1). A stack proposta está em `docs/adr/0001-stack.md`
(aceito em 2026-11-24, revisão 2, com a emenda do realm); ela vira descrição
aqui quando a Onda 0 a construir. Reconferido em 2026-11-24, depois da spec v1.2:
`backend/.git` e `frontend/.git` continuam sem existir (exit 1), e não há
`compose.yaml`.

Fora deste repositório, e não operado pelo CRM: o Keycloak 26.8.2 da TI em
`https://akpannel.akeel.com.br`, realm `crm`. Conferido em 2026-11-24 pelo discovery
público: issuer `https://akpannel.akeel.com.br/realms/crm`. Os clientes `crm-bff` e
`crm-bff-dev` existem segundo a TI (§15), mas não foram conferidos daqui (pedem segredo).
Os segredos ficam fora do repositório.
