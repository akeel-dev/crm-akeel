#!/bin/sh
set -eu

raiz=$(cd "$(dirname "$0")/../.." && pwd)
cd "$raiz"

alvo=""; repo=""; banco=1; arquivos=1; arquivos_de=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ponto) alvo="--type=name --target=$2 --target-action=promote"; shift ;;
    --ate) alvo="--type=time --target=$2 --target-action=promote"; shift ;;
    --repo) repo="--repo=$2"; shift ;;
    --so-banco) arquivos=0 ;;
    --so-arquivos) banco=0 ;;
    --arquivos-de) arquivos_de="$2"; shift ;;
    *) echo "uso: restaurar.sh [--ponto NOME | --ate INSTANTE] [--repo N] [--so-banco|--so-arquivos] [--arquivos-de DIA/HORA]" >&2; exit 2 ;;
  esac
  shift
done
parar=${RESTAURAR_PARAR-keycloak}

echo "restaurar.sh: início $(date -u +%Y-%m-%dT%H:%M:%SZ) em $(hostname -s)"

if [ "$banco" = 1 ]; then
  echo "restaurar.sh: parando: $parar postgres"
  docker compose stop $parar postgres
  docker compose --progress quiet run --rm --no-deps -T -u postgres --entrypoint crm-pgbackrest postgres \
    $repo --delta $alvo restore
  docker compose up -d --wait --no-deps postgres
  i=0
  until [ "$(docker compose exec -T postgres psql -U postgres -tAc 'select pg_is_in_recovery()' 2>/dev/null)" = f ]; do
    i=$((i + 1)); [ "$i" -le 120 ] || { echo "restaurar.sh: o PostgreSQL não saiu da recuperação em 120 s" >&2; exit 1; }
    sleep 1
  done
  echo "restaurar.sh: PostgreSQL restaurado e promovido (timeline $(docker compose exec -T postgres psql -U postgres -tAc 'select timeline_id from pg_control_checkpoint()' | tr -d ' '))"
fi

if [ "$arquivos" = 1 ]; then
  if [ -n "$arquivos_de" ]; then
    docker compose --progress quiet run --rm -T backup-arquivos restaurar --de "$arquivos_de"
  else
    docker compose --progress quiet run --rm -T backup-arquivos restaurar
  fi
fi

if [ "$banco" = 1 ] && [ -n "$parar" ]; then
  docker compose up -d --wait $parar
fi
echo "restaurar.sh: fim $(date -u +%Y-%m-%dT%H:%M:%SZ)"
