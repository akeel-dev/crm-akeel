#!/bin/sh
set -eu

. "$(dirname "$0")/../comum.sh"
crm_carregar homologacao-local

atual=$(git -C "$crm_raiz/frontend" rev-parse HEAD)
[ "$atual" = "$CRM_FRONTEND_TAG" ] \
  || crm_falha "e2e: frontend/ esta em $atual e o manifesto fixa $CRM_FRONTEND_TAG; ponha o clone no commit do manifesto"

case "$CRM_SEGREDOS" in
  /*) segredos=$CRM_SEGREDOS ;;
  *) segredos=$crm_raiz/deploy/$CRM_SEGREDOS ;;
esac

crm_log "e2e: frontend@$CRM_FRONTEND_TAG contra $CRM_ORIGEM_PUBLICA"
cd "$crm_raiz/frontend"
E2E_BASE_URL=$CRM_ORIGEM_PUBLICA \
KEYCLOAK_BASE_URL=$KEYCLOAK_BASE_URL \
KEYCLOAK_REALM=$KEYCLOAK_REALM \
KEYCLOAK_CLIENT_ID=$KEYCLOAK_CLIENT_ID \
TEST_USER_PASSWORD=$(cat "$segredos/test_user_password") \
  npm run e2e
