#!/bin/sh
set -eu

. "$(dirname "$0")/comum.sh"
crm_carregar "${1:?uso: sh deploy/deploy.sh <homologacao-local|producao>}"

crm_log "maquina $(hostname); manifesto $crm_manifesto"
crm_log "manifesto: backend crm-backend:$CRM_BACKEND_TAG, frontend crm-frontend:$CRM_FRONTEND_TAG"
docker image inspect "crm-backend:$CRM_BACKEND_TAG" "crm-frontend:$CRM_FRONTEND_TAG" >/dev/null \
  || crm_falha "imagem do manifesto ausente (sh deploy/imagens.sh)"

crm_log "infraestrutura: $CRM_INFRA"
crm_dc up -d --wait $CRM_INFRA

crm_log "migracao: inicio"
crm_dc run --rm --no-deps migrate || crm_falha "migracao: saiu diferente de 0; nenhuma instancia foi trocada"
crm_log "migracao: ok"

crm_log "cors do bucket: inicio ($CRM_ORIGEM_PUBLICA)"
crm_dc run --rm --no-deps aplicar-cors || crm_falha "cors do bucket: saiu diferente de 0; nenhuma instancia foi trocada"
crm_log "cors do bucket: ok"

crm_log "api e worker: trocando"
crm_dc up -d --wait --no-deps api worker
crm_log "api e worker: de pe"

crm_log "frontend e proxy: trocando"
crm_dc up -d --wait --no-deps frontend proxy
crm_log "frontend e proxy: de pe em $CRM_ORIGEM_PUBLICA"

for servico in api worker frontend proxy; do
  crm_log "inicio do conteiner $servico: $(docker inspect -f '{{.State.StartedAt}} {{.Config.Image}}' "$(crm_dc ps -q "$servico")")"
done

if [ -n "${CRM_VERIFICACAO:-}" ]; then
  crm_log "verificacao: $CRM_VERIFICACAO"
  sh "$crm_raiz/deploy/$CRM_VERIFICACAO" "$crm_ambiente"
fi

crm_log "deploy concluido"
