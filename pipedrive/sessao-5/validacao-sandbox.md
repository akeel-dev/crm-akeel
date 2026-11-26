# Relatório de validação — Permissões, visibilidade e tempo real no Pipedrive

**Data dos testes:** 26/11/2026
**Ambiente:** conta sandbox de desenvolvedor (a sandbox da Akeel), separada da produção (a conta de produção da Akeel). Nada foi alterado na produção.
**Responsável pela execução:** Claude, operando dois perfis do Chrome em paralelo.

---

## 1. Objetivo

Validar, na prática, comportamentos do Pipedrive que a documentação oficial não responde ou deixa ambíguos, para orientar a configuração de permissões e visibilidade da conta de produção da Akeel.

Foram testados os itens que dependem de observar o sistema pela ótica de um segundo usuário:

| # | Pergunta |
|---|---|
| 3 | Um controle sem permissão some, fica desabilitado ou dá erro? |
| 4 | Uma permissão retirada vale na hora? |
| 7 | Chega notificação de um item que o usuário não pode ver? |
| 9 | Uma mudança aparece para o outro usuário sem recarregar a página? |

Os demais itens da lista original (1, 2, 5, 6 e 8) foram respondidos pela documentação oficial e estão resumidos na seção 5.

---

## 2. Ambiente e método

### Usuários

| Papel | Usuário | Permissões | Grupo de visibilidade |
|---|---|---|---|
| Administrador (U1) | U1 (conta técnica da Akeel) | Admin em tudo | Grupo padrão |
| Usuário de teste (U2) | U2 (colaborador da Akeel) | "Deals regular user" | Grupo padrão |

### Configuração inicial do U2 ("Deals regular user")

| Permissão | Estado original |
|---|---|
| Editar o dono de negócio de outros usuários | Permitido |
| Excluir negócios | Bloqueado |
| Converter negócios em leads | Permitido |
| Mesclar negócios | Bloqueado |
| Editar data de ganho/perda | Bloqueado |
| Arquivar negócios | Permitido |

### Objeto de teste

- Negócio **"TESTE 1 - Permissões"** (organização "Empresa Teste"), dono: administrador, funil padrão.

### Método

1. U1 e U2 logados ao mesmo tempo, cada um em um perfil do Chrome.
2. U1 faz uma alteração (permissão, visibilidade, valor, etapa ou menção).
3. U2 é observado **sem recarregar** a página e, quando relevante, **depois de recarregar**.
4. Quando o resultado é negativo, foi feito um **teste de controle** para confirmar que a funcionalidade existe nas condições normais.

### Limitações do ambiente

- A sandbox **não permite criar grupos de visibilidade personalizados** (recurso do plano Premium ou superior). Por isso, todos os testes de visibilidade usaram a opção do próprio negócio: "Visível para: Dono do item" ou "Todos os usuários".
- Cada cenário foi executado uma vez. Os tempos de atualização são aproximados (poucos segundos).

---

## 3. Resultados

### Item 3 — Controle sem permissão: some, desabilita ou dá erro?

**Resultado: o controle some.**

| Ação no menu "..." do negócio | Administrador | U2 (sem permissão) |
|---|---|---|
| Duplicar | Aparece | Aparece |
| Mesclar | Aparece | **Não aparece** |
| Exportar como XLSX | Aparece | Aparece |
| Converter em lead | Aparece | Aparece |
| Arquivar | Aparece | Aparece |
| Excluir | Aparece | **Não aparece** |

Na seção "Detalhes" do negócio, o U2 também vê uma mensagem pedindo que um usuário com acesso às configurações da conta preencha a seção, no lugar das opções de edição de campos.

**Implicação:** o usuário não recebe aviso de que uma ação existe e está bloqueada. Se um SDR disser "não tenho a opção de excluir", é permissão, não erro do sistema.

---

### Item 4 — Permissão retirada vale na hora?

**Resultado: vale na hora no servidor, mas a tela só se atualiza ao recarregar.**

Sequência executada:

1. U2 com o negócio aberto e as opções "Arquivar" e "Converter em lead" visíveis no menu.
2. U1 retirou essas duas permissões do conjunto "Deals regular user" e salvou.
3. **Sem recarregar**, U2 abriu o menu: as duas opções **continuavam aparecendo**.
4. U2 clicou em "Arquivar" e confirmou. O sistema **bloqueou** a ação com uma mensagem genérica: "Não foi possível arquivar o item. Algo deu errado, tente novamente."
5. **Depois de recarregar**, as opções "Arquivar" e "Converter em lead" **sumiram** do menu.

**Implicações:**
- A segurança não depende de recarregar: a ação é bloqueada imediatamente.
- A mensagem de erro não diz que o motivo é falta de permissão. Ao mudar permissões do time, avise para recarregarem a página e evite chamados de suporte por "erro".

---

### Item 7 — Chega notificação de um item invisível?

**Resultado: não chega, nem depois que o item volta a ficar visível.**

| Cenário | Visibilidade do negócio para o U2 | Ação do U1 | Notificação no U2 |
|---|---|---|---|
| Teste | Invisível ("Dono do item") | Nota com menção @U2 | **Nenhuma** |
| Depois do teste | Negócio voltou a ser visível | (nenhuma nova ação) | **Continuou sem notificação** |
| Controle | Visível ("Todos os usuários") | Nota com menção @U2 | **Recebida**: "U1 mencionou você em uma nota no negócio TESTE 1 - Permissões" |

Observação: ao mencionar o U2 num negócio que ele não vê, o Pipedrive **não avisou** o autor da nota de que a pessoa mencionada não tem acesso.

**Implicações:**
- Menções em negócios restritos são perdidas sem aviso para nenhum dos lados.
- Se um closer precisa chamar um SDR (ou vice-versa) num negócio restrito, o SDR precisa ser **seguidor** do negócio ou o negócio precisa estar visível para ele **antes** da menção.

---

### Item 9 — Mudança aparece para o outro usuário sem recarregar?

**Resultado: sim, em poucos segundos, tanto na página do negócio quanto no funil.**

| Tela aberta no U2 | Alteração feita pelo U1 | Atualizou sem recarregar? |
|---|---|---|
| Página do negócio | Valor de US$ 1.000 para US$ 2.500 | **Sim** |
| Funil (quadro kanban) | Etapa de "Qualified" para "Contact Made" e valor para US$ 4.000 | **Sim**: o card mudou de coluna e os totais das colunas foram recalculados |

**Exceção importante (achado extra, abaixo):** mudanças de **visibilidade** e **conteúdo novo em item que deixou de ser visível** não seguem essa regra.

---

## 4. Achados extras

### 4.1 Perda de visibilidade não fecha a tela aberta

Com a página do negócio aberta no U2, o U1 mudou o negócio para "Visível para: Dono do item".

- **Sem recarregar:** o U2 continuou vendo o negócio normalmente (título, valor, organização, histórico).
- A nota criada pelo U1 nesse intervalo **não apareceu** para o U2.
- **Depois de recarregar:** a tela mostrou "Este item não está visível para você".

**Implicação:** restringir um negócio não remove o acesso de quem já está com ele aberto até essa pessoa recarregar ou navegar. Para dados sensíveis, isso é uma janela de exposição curta, mas real.

### 4.2 O menu de visibilidade fica no cabeçalho do negócio

O botão ao lado de "Ganho/Perdido" abre as opções de visibilidade do item. Na sandbox (sem grupos personalizados), as opções são apenas "Dono do item" (dono e seguidores) e "Todos os usuários".

---

## 5. Itens respondidos pela documentação oficial

| # | Pergunta | Resposta | Fonte |
|---|---|---|---|
| 1 | O dono de um negócio ainda o vê quando o funil está bloqueado para o grupo dele? | **Não.** O funil fica totalmente oculto para o grupo, inclusive os negócios do próprio dono. Existe o filtro "Dono está restrito do funil" para localizar esses casos, mas ele não torna os negócios visíveis. Usuários com permissão de admin de negócios ou de configurações da conta continuam vendo todos os funis. | [Pipeline visibility](https://support.pipedrive.com/en/article/pipeline-visibility) · [Visibility groups](https://support.pipedrive.com/en/article/visibility-groups) |
| 2 | Como aparece uma nota ligada a um item que o usuário não vê? | **Parcial.** A visibilidade de notas e atividades depende do acesso a todos os itens vinculados (pessoa, negócio e organização). O teste 4.1 confirmou que uma nota num negócio invisível não aparece. | [FAQ: permissions and visibility](https://intercom.help/pipedrive/en/articles/10633271-faq-permissions-and-visibility) |
| 5 | A transferência ao desativar um usuário pode ir para destinos diferentes por tipo de item? | Na desativação, o Pipedrive lista os itens do usuário e permite transferir a propriedade. Automações são transferidas para outro administrador global. Para separar por tipo, use depois **Configurações > Uso > Limpeza de dados**, filtrando negócios, pessoas e organizações separadamente. | [Data of deleted/deactivated user](https://support.pipedrive.com/en/article/data-deleted-deactivated-user) · [Deactivated users' data](https://support.pipedrive.com/en/article/deactivated-users-data) |
| 6 | O que volta ao reativar o usuário? | O que **não** foi transferido continua no nome dele e volta junto. Automações de um dono desativado são desativadas; não há confirmação de que religam sozinhas na reativação. | [Deactivate or reactivate a user](https://support.pipedrive.com/en/article/how-can-i-deactivate-or-reactivate-a-user) |
| 8 | Um funil sem negócio visível aparece vazio ou some? | Se o funil está **bloqueado** para o grupo, ele **some**. Se o funil está liberado e só os negócios estão ocultos, a expectativa é aparecer com colunas vazias. **Não testado** por falta de grupos personalizados na sandbox. | [Visibility groups](https://support.pipedrive.com/en/article/visibility-groups) |

---

## 6. Requisitos e recomendações para a produção

1. **Comunicar mudanças de permissão.** Ao alterar permissões do time, pedir que todos recarreguem o Pipedrive. O bloqueio vale na hora, mas a tela engana até recarregar (item 4).
2. **Tratar "Algo deu errado" como possível falta de permissão.** Incluir isso no material de treinamento do time antes de abrir chamado.
3. **Seguidores antes de menções.** Em negócios com visibilidade restrita, adicionar como seguidor quem precisa ser mencionado (item 7).
4. **Restrição de dados sensíveis.** Ao restringir um negócio, considerar que quem já está com ele aberto continua vendo até recarregar (achado 4.1).
5. **Desativação de usuários.** Antes de desativar alguém do time (ex.: SDR que saiu), transferir a propriedade dos itens e das automações; depois, conferir a Limpeza de dados (item 5).
6. **Bloqueio de funis por grupo exige plano Premium ou superior.** Confirmar o plano da produção antes de desenhar uma separação por funil entre pré-vendas e closers (itens 1 e 8).

---

## 7. Pendências

| Item | Situação | O que falta |
|---|---|---|
| 8 | Respondido em parte pela documentação | Testar numa conta com grupos de visibilidade personalizados (produção ou teste do plano Ultimate) |
| 6 | Respondido em parte | Testar se automações religam ao reativar um usuário |
| Admin da sandbox | E-mail cadastrado com o domínio errado (`.com.vr`) | Corrigir para `.com.br`, senão os e-mails do Pipedrive não chegam |

---

## 8. Estado final da sandbox

- Permissões do "Deals regular user" **restauradas** ao original (Arquivar e Converter em lead permitidos; Excluir, Mesclar e Editar data de ganho/perda bloqueados).
- Negócio "TESTE 1 - Permissões": visível para todos os usuários, na etapa "Contact Made", valor US$ 4.000, com 2 notas de teste.
- Usuário U2 ativo, ocupando 1 dos 4 assentos.
