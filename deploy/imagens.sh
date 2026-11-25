#!/bin/sh
set -eu

raiz=$(cd "$(dirname "$0")/.." && pwd)
manifesto=${CRM_MANIFESTO:-$raiz/deploy/manifesto.env}
. "$manifesto"

construir() {
  repositorio=$1
  imagem=$2
  tag=$3
  if docker image inspect "$imagem:$tag" >/dev/null 2>&1; then
    echo "imagens: $imagem:$tag ja existe"
    return
  fi
  git -C "$raiz/$repositorio" cat-file -e "$tag^{commit}" || { echo "imagens: $repositorio nao tem o commit $tag" >&2; exit 1; }
  echo "imagens: construindo $imagem:$tag a partir de $repositorio@$tag"
  git -C "$raiz/$repositorio" archive --format=tar "$tag" | docker build -q -t "$imagem:$tag" -
}

construir backend crm-backend "${CRM_BACKEND_TAG:?}"
construir frontend crm-frontend "${CRM_FRONTEND_TAG:?}"
