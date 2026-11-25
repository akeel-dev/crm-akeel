crm_raiz=$(cd "$(dirname "$0")" && while [ ! -f deploy/manifesto.env ] && [ "$(pwd)" != / ]; do cd ..; done && pwd)

crm_log() {
  printf '%s deploy[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${crm_ambiente:-?}" "$*"
}

crm_falha() {
  crm_log "FALHOU: $*" >&2
  exit 1
}

crm_carregar() {
  crm_ambiente=$1
  case "$crm_ambiente" in
    homologacao-local) crm_dir=homologacao ;;
    producao) crm_dir=producao ;;
    *) echo "ambiente desconhecido: $crm_ambiente (use homologacao-local ou producao)" >&2; exit 2 ;;
  esac
  crm_manifesto=${CRM_MANIFESTO:-$crm_raiz/deploy/manifesto.env}
  crm_ambiente_env=$crm_raiz/deploy/$crm_dir/ambiente.env
  [ -f "$crm_manifesto" ] || crm_falha "manifesto ausente: $crm_manifesto"
  set -a
  . "$crm_manifesto"
  . "$crm_ambiente_env"
  set +a
  : "${CRM_BACKEND_TAG:?manifesto sem CRM_BACKEND_TAG}" "${CRM_FRONTEND_TAG:?manifesto sem CRM_FRONTEND_TAG}"
  crm_rede=${CRM_PROJETO}_default
  CRM_PROXY_CONFIGURACAO=$(cksum < "$crm_raiz/deploy/aplicacao/proxy.conf.template" | cut -d ' ' -f 1)
  export CRM_PROXY_CONFIGURACAO
}

crm_dc() {
  docker compose -p "$CRM_PROJETO" --project-directory "$crm_raiz/deploy" \
    --env-file "$crm_manifesto" --env-file "$crm_ambiente_env" \
    -f "$crm_raiz/deploy/aplicacao/compose.yaml" -f "$crm_raiz/deploy/$crm_dir/compose.yaml" "$@"
}
