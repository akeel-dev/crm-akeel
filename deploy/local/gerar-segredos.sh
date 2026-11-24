#!/bin/sh
# Dono: DevOps (time.yml, escrita.devops). Story 0-02, critério 6 (RF-SEC-03).
#
# Primeira execução do ambiente local:
#   - copia deploy/local/.env.example para .env na raiz, se ainda não existir;
#   - gera, para cada nome de deploy/local/segredos.example, um arquivo
#     deploy/local/secrets/<nome> com valor aleatório, se ainda não existir.
# Nunca imprime valor. Nunca sobrescreve: para trocar um segredo, apague o arquivo e
# zere os volumes (docker compose down -v), porque o banco guarda a senha antiga.
set -eu

raiz=$(cd "$(dirname "$0")/../.." && pwd)
dir="$raiz/deploy/local/secrets"

command -v openssl >/dev/null 2>&1 || { echo "falta o openssl" >&2; exit 1; }

if [ ! -f "$raiz/.env" ]; then
  cp "$raiz/deploy/local/.env.example" "$raiz/.env"
  echo "criado: .env (a partir de deploy/local/.env.example)"
else
  echo "mantido: .env"
fi

umask 077
mkdir -p "$dir"
chmod 700 "$dir"

grep -v '^[[:space:]]*#' "$raiz/deploy/local/segredos.example" | grep '=' | cut -d= -f1 |
while read -r nome; do
  arq="$dir/$nome"
  if [ -s "$arq" ]; then
    echo "mantido: deploy/local/secrets/$nome"
    continue
  fi
  case "$nome" in
    # Garage: rpc_secret é 32 bytes em hex; a chave S3 importada tem o formato
    # GK + 24 hex (id) e 64 hex (segredo).
    garage_rpc_secret|garage_s3_secret_access_key) valor=$(openssl rand -hex 32) ;;
    garage_s3_access_key_id) valor="GK$(openssl rand -hex 12)" ;;
    *) valor=$(openssl rand -hex 24) ;;
  esac
  printf '%s' "$valor" > "$arq"
  # 644 dentro de um diretório 700: o host só deixa o dono entrar, e o contêiner,
  # que lê com outro uid (postgres, keycloak, curl_user), consegue ler.
  chmod 644 "$arq"
  echo "gerado: deploy/local/secrets/$nome"
done
