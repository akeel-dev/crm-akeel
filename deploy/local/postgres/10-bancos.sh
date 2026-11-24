#!/bin/sh
# Dono: DevOps (time.yml, escrita.devops). Story 0-02, critério 2.
# Roda uma vez, na primeira subida do volume (docker-entrypoint-initdb.d).
# Cria dois bancos separados, cada um com seu dono: o do CRM e o do Keycloak local
# (o Keycloak não usa H2). As senhas vêm dos segredos do Docker e não são impressas.
set -eu

crm_pw=$(cat /run/secrets/crm_db_password)
kc_pw=$(cat /run/secrets/keycloak_db_password)

psql -v ON_ERROR_STOP=1 -q --username "$POSTGRES_USER" --dbname postgres \
  -v crm_pw="$crm_pw" -v kc_pw="$kc_pw" <<'SQL'
CREATE ROLE crm LOGIN PASSWORD :'crm_pw';
CREATE DATABASE crm OWNER crm;
CREATE ROLE keycloak LOGIN PASSWORD :'kc_pw';
CREATE DATABASE keycloak OWNER keycloak;
SQL
