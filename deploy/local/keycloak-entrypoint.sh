#!/bin/bash
# Dono: DevOps (time.yml, escrita.devops). Story 0-02, critérios 3 e 6.
# O Keycloak não lê *_FILE. Este invólucro passa os segredos do Docker para as
# variáveis que o kc.sh e a importação do realm usam (substituição ${VAR} em
# deploy/keycloak/realm-crm-local.json) e depois entrega o processo ao kc.sh.
set -euo pipefail

export KC_DB_PASSWORD="$(< /run/secrets/keycloak_db_password)"
export KC_BOOTSTRAP_ADMIN_PASSWORD="$(< /run/secrets/keycloak_admin_password)"
export CRM_BFF_CLIENT_SECRET="$(< /run/secrets/crm_bff_client_secret)"
export CRM_API_CLIENT_SECRET="$(< /run/secrets/crm_api_client_secret)"
export CRM_TEST_USER_PASSWORD="$(< /run/secrets/test_user_password)"

exec /opt/keycloak/bin/kc.sh "$@"
