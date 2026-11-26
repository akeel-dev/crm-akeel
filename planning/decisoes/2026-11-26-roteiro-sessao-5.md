# Roteiro da sessão de estudo 5 do Pipedrive: usuários e permissões

Preparado pelo Orquestrador em 2026-11-26, para o Pedro (spec §14.2). Alimenta o módulo **USR** e a
**P-19**. Revisado duas vezes no mesmo dia:

1. com a pesquisa pública do Pedro (`pipedrive/sessao-5/pesquisa-publica.md`);
2. com a validação na sandbox, que **não é Premium** (`pipedrive/sessao-5/validacao-sandbox.md`,
   anonimizada).

O Pedro decidiu em 26/11 desconsiderar os termos de uso do Pipedrive para estes estudos.

## Onde estamos

| Parte | Estado |
|---|---|
| Lacunas que dependem de ver pela ótica do U2 (B3, B4, B7, B9) | **Feito** na sandbox, 26/11 |
| B1, B2, B5, B6 | **Respondido pela documentação** oficial |
| B8 e a matriz de grupos (pai, filho, irmão) | Não testado: a sandbox não tem grupos personalizados. **Opcional** (parte 2) |
| A. Inventário da conta real | **Falta** (parte 1) |
| C. Decisões do Pedro | **Falta** (parte 3) |

## O que a sandbox mostrou

| # | Pipedrive (medido) | Para o nosso CRM |
|---|---|---|
| B3 | Ação sem permissão **some** do menu | Igual: esconder |
| B4 | Permissão retirada bloqueia **na hora** no servidor; a tela só muda ao recarregar; o erro diz "algo deu errado" | **Melhoria candidata B-012** |
| B7 | Menção num item invisível não notifica, e o autor não é avisado | Igual em não notificar; **melhoria candidata B-013** |
| B9 | Mudança aparece para o outro em poucos segundos, no negócio e no quadro, com totais recalculados | Igual (fecha a Q-009) |
| 4.1 | Quem está com o negócio aberto continua vendo depois que ele fica restrito, até recarregar | **Melhoria candidata B-014** |
| B1 | (documentação) o dono **não** vê os próprios negócios num funil bloqueado para o grupo dele | Ver C4 |

---

## Parte 1: inventário da conta real (falta; uns 20 a 30 minutos)

**Regras:** só leitura. Não clique em Salvar em nenhuma tela. Se abrir uma tela de edição, saia pelo
X ou por Cancelar. **Não anote nomes de pessoas nem de clientes**: use G1, G2… para grupos, P1, P2…
para conjuntos de permissões e F1, F2… para funis. Os nomes dos menus abaixo podem variar um pouco
conforme o idioma e a versão; procure o equivalente.

**Quem faz:** um usuário com acesso às **configurações da conta** na produção. Sem esse acesso, as telas
de usuários, grupos e cobrança não aparecem.

### Passo 1.1: o plano (decide o tamanho do resto)

1. Clique na sua foto ou nas iniciais, no canto superior direito.
2. Abra **Cobrança** (ou "Billing"), depois **Gerenciar assinatura**.
3. Anote o nome do plano e o número de vagas pagas.

| Item | Valor |
|---|---|
| Plano | |
| Vagas pagas | |

- **Lite ou Growth** (ou os antigos Essential e Advanced): não existem grupos nem conjuntos personalizados.
  Os passos 1.3 e 1.4 ficam com uma linha cada (o grupo padrão e os conjuntos "admin" e "comum").
  "Visível para" tem só 2 opções. Isso também quer dizer que **a Akeel hoje não usa o modelo de 4 níveis**,
  e o nosso CRM vai ser mais rico que o atual; vale saber para o treinamento.
- **Premium ou Ultimate** (ou os antigos Professional, Power e Enterprise): faça todos os passos.

### Passo 1.2: os usuários

1. Na mesma área de configurações, abra **Gerenciar usuários**, aba **Usuários e acesso** (ou "Usuários").
2. Conte, sem anotar nomes:

| Item | Quantos |
|---|---|
| Usuários ativos | |
| Com acesso às configurações da conta | |
| Admins do app de negócios ("Deals admin") | |
| Convites pendentes (aba "Convidados") | |
| Desativados (aba "Desativados") | |

### Passo 1.3: os grupos de visibilidade (só Premium ou superior)

1. Em **Gerenciar usuários**, abra a aba **Grupos de visibilidade**.
2. Uma linha por grupo. O "pai" é o grupo logo acima na árvore.
3. Clique no grupo para ver as configurações dele **sem alterar nada**: o padrão de "Visível para" de
   cada tipo de item e os funis liberados.
4. Nas colunas de padrão, escreva: **dono**, **grupo**, **grupo+sub** ou **empresa**.

| Grupo | Pai | Nº de usuários | Negócio | Lead | Pessoa | Organização | Produto | Funis liberados (F1, F2…) |
|---|---|---|---|---|---|---|---|---|
| Padrão | — | | | | | | | |
| G1 | | | | | | | | |
| G2 | | | | | | | | |

### Passo 1.4: os conjuntos de permissões

1. Em **Gerenciar usuários**, abra **Conjuntos de permissões**.
2. Para cada conjunto: "…" → **Editar**, olhe e saia **sem salvar**.
3. Marque **sim** ou **não**. Se o plano for de entrada, só existe a coluna "Comum".

| Permissão | Comum | P1 | P2 |
|---|---|---|---|
| Editar negócios de outros | | | |
| Excluir negócios | | | |
| Mudar o dono de negócios | | | |
| Mesclar negócios | | | |
| Editar a data de ganho ou perda | | | |
| Ver a quantidade e a soma no funil | | | |
| Ver dados de outros usuários | | | |
| Seguir outros usuários | | | |
| Ver os nomes de itens que não pode acessar | | | |
| Mudar a visibilidade de itens | | | |
| Estatísticas de outros e da empresa no Insights | | | |
| Exportar listas | | | |
| Edição em massa | | | |
| Excluir atividades | | | |
| Excluir pessoas e organizações | | | |

### Passo 1.5: a distribuição

Na aba **Usuários e acesso**, conte quantos usuários há em cada combinação:

| Grupo | Conjunto | Nº de usuários |
|---|---|---|
| | | |

### Passo 1.6: a visibilidade padrão na prática (sem salvar)

1. Abra um funil e clique em **+ Negócio**.
2. Veja o que vem marcado em **Visível para** e **feche sem salvar**.
3. Repita em **+ Pessoa** e **+ Organização**.

| Item novo | "Visível para" que vem marcado |
|---|---|
| Negócio | |
| Pessoa | |
| Organização | |

**Entrega:** cole as tabelas preenchidas neste arquivo, ou numa mensagem, e o Orquestrador guarda.

---

## Parte 2: a matriz de grupos (opcional; só com uma conta Premium de teste)

**Só vale se** você conseguir uma conta de teste **Premium ou superior** que não seja a produção (por
exemplo, um período de teste do Premium numa conta nova). Na produção não se testa nada. Se não houver
essa conta, **pule**: a documentação basta para o nosso desenho, e as decisões C4 e C10 não dependem
deste teste.

**Preparar (uns 15 minutos):**
1. Crie três grupos em árvore e um irmão: `[S5] Diretoria` → `[S5] Comercial` → `[S5] Time A`, e
   `[S5] Outro` ao lado de `[S5] Comercial`.
2. Deixe U1 (admin) em `[S5] Comercial` e U2 (comum) no grupo indicado em cada linha da tabela.
3. Com U1, crie 4 negócios `[S5] Dono`, `[S5] Grupo`, `[S5] Grupo+sub` e `[S5] Empresa`, cada um com o
   "Visível para" do nome. Ligue cada um a uma pessoa `[S5]` e coloque uma nota.

**Rodar (uns 30 minutos):** para cada linha, U1 move U2 de grupo; U2 recarrega e procura os 4
negócios no **quadro**, na **lista de negócios** e na **busca**. Anote **sim** ou **não**.

| Grupo de U2 | Dono | Grupo | Grupo+sub | Empresa |
|---|---|---|---|---|
| `[S5] Comercial` (o mesmo do dono) | | | | |
| `[S5] Diretoria` (pai) | | | | |
| `[S5] Time A` (filho) | | | | |
| `[S5] Outro` (irmão) | | | | |
| `[S5] Outro`, com U2 **seguidor** dos 4 | | | | |

**Mais três casos:**

| # | Como montar | O que anotar | Resultado |
|---|---|---|---|
| 2.1 | U1 bloqueia o funil para `[S5] Outro`, com U2 lá | O funil some do seletor de U2? Os negócios somem da busca? | |
| 2.2 | U1 cria um funil novo liberado, só com negócios "Dono" de U1 | Para U2 o funil aparece vazio ou some? (B8) | |
| 2.3 | U1 passa um negócio desse funil bloqueado para U2 | O Pipedrive deixa? U2 vê? (B1) | |

**Ao terminar:** exclua os negócios, as pessoas e os grupos `[S5]`, e devolva U2 ao grupo padrão.

---

## Parte 3: as suas decisões (falta; uns 20 minutos)

Responda "aceito" ou dê a sua escolha em cada linha. A parte 1 não muda nenhuma delas, exceto se o plano
da produção for de entrada; aí só muda o que vale treinar o time.

### 3.1 Comportamento

| # | Ponto | Pipedrive | Nossa spec hoje | Recomendação | Sua decisão |
|---|---|---|---|---|---|
| C1 | Seguir um **usuário** (ver todos os itens dele) | existe, com permissão própria | não existe | Fora da v1: abre visibilidade por uma porta lateral | |
| C2 | Padrão de "Visível para" | por grupo e por tipo de item | um padrão da empresa | Manter o da empresa na v1 | |
| C3 | Nota ou atividade ligada a vários itens | exige ver **todos** os ligados | herda do item | Adotar a regra do Pipedrive (mais segura) | |
| C4 | Dono num funil bloqueado para o grupo dele | o dono deixa de ver | ambíguo | **Impedir a situação:** não deixar atribuir dono sem acesso ao funil; ao bloquear um funil para um grupo com donos lá dentro, avisar o admin e listar os negócios afetados | |
| C5 | Permissões ausentes da §5.5 | mudar a visibilidade, ver nomes de ocultos, ver totais do funil, editar data de ganho ou perda | ausentes | Incluir as quatro | |
| C6 | Dois admins (de negócios e global) | existem | um admin | Um admin só | |
| C7 | Conjunto padrão do usuário comum | "Deals regular user": muda dono de outros, não exclui, não mescla | Vendedor (§5.5) | Restritivo: edita só os próprios, não exclui, não exporta, **não muda dono de outros** | |
| C8 | Item ligado oculto | nome ou "oculto", conforme uma permissão | — | Mostrar "Item restrito" com "Pedir acesso"; texto nosso | |
| C9 | Notificação de item invisível | não chega | — | Igual: nunca notificar nem mostrar prévia | |
| C10 | Funil sem acesso / sem negócio visível | some / (esperado) vazio | — | Sem acesso: some. Com acesso e nada visível: vazio | |
| C11 | Ação sem permissão | o controle some | — | Igual: esconder | |
| C12 | Reativar um usuário | o que não foi transferido volta; automações ficam desligadas | — | Igual, com um aviso ao admin listando as automações que ficaram desligadas | |

### 3.2 Melhorias candidatas (viram B-012 a B-014 no Apêndice B se você aprovar)

| # | Problema no Pipedrive (medido na sandbox) | Como o nosso CRM resolve | Sua decisão |
|---|---|---|---|
| B-012 | Permissão retirada: a tela continua mostrando a ação, e o erro diz "algo deu errado" | O erro diz que falta permissão, e a tela se atualiza sozinha quando o conjunto do usuário muda | |
| B-013 | Menção a quem não vê o item se perde sem aviso para ninguém | Ao mencionar, o autor é avisado de que a pessoa não vê o item e pode torná-la seguidora | |
| B-014 | Quem está com um item aberto continua vendo depois que ele fica restrito | O tempo real avisa a tela, que fecha o item; nenhuma leitura nova passa, porque o backend confere a cada pedido | |

### 3.3 P-19: os 4 perfis do Keycloak

A §5.5 não tem conjunto para Visualizador.

| Perfil | Conjunto no CRM | Recomendação | Sua decisão |
|---|---|---|---|
| `/Perfis/Administradores` | Administrador | Tudo | |
| `/Perfis/Gestores` | Gestor | Vendas com escopo de grupo, relatórios de outros, metas, desconto | |
| `/Perfis/Vendedores` | Vendedor | Igual a C7 | |
| `/Perfis/Visualizadores` | **Visualizador (novo)** | Só ver o que a visibilidade deixa; nada de criar, editar, excluir ou exportar | |

E mais duas:
- Um conjunto personalizado fica no perfil do conjunto de origem, porque o perfil só autentica (D-09).
- O admin escolhe o grupo de visibilidade no convite, sem padrão por perfil.

---

## Depois

- Corrigir o e-mail do admin da sandbox para `.com.br` (os e-mails do Pipedrive não chegam).
- Com as partes 1 e 3 respondidas, o Orquestrador leva tudo para a spec: §5.4, §5.5, §9.1, Apêndice B e
  P-19. Q-006 e Q-009 são fechadas em `pipedrive/questions.md`. Só então o Planejador fatia o USR.
