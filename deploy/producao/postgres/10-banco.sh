#!/bin/sh
set -eu

crm_pw=$(cat /run/secrets/crm_db_password)

psql -v ON_ERROR_STOP=1 -q --username "$POSTGRES_USER" --dbname postgres -v crm_pw="$crm_pw" <<'SQL'
CREATE ROLE crm LOGIN PASSWORD :'crm_pw';
CREATE DATABASE crm OWNER crm;
SQL
