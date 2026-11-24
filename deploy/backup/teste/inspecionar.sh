set -eu
b="destino:$BACKUP_S3_BUCKET"
lista=$(rclone lsf -R --files-only "$b")
total=$(printf '%s\n' "$lista" | grep -c . || true)
n_pg=$(printf '%s\n' "$lista" | grep -c '^pgbackrest/' || true)
n_pgm=$(printf '%s\n' "$lista" | grep -c '^pgbackrest-mensal/' || true)
n_arq=$(printf '%s\n' "$lista" | grep -c '^arquivos/' || true)
echo "inspecionar: $total objetos no destino: pgbackrest/=$n_pg pgbackrest-mensal/=$n_pgm arquivos/=$n_arq"
[ "$n_pg" -gt 0 ] || { echo "inspecionar: FALHOU sem objetos em pgbackrest/" >&2; exit 1; }
[ "$n_arq" -gt 0 ] || { echo "inspecionar: FALHOU sem objetos em arquivos/" >&2; exit 1; }
outros=$((total - n_pg - n_pgm - n_arq))
[ "$outros" -eq 0 ] || { echo "inspecionar: FALHOU $outros objeto(s) fora dos prefixos esperados" >&2; exit 1; }

for m in "$@"; do
  if printf '%s\n' "$lista" | grep -q -F "$m"; then
    echo "inspecionar: FALHOU o nome de um objeto contém o marcador $m" >&2; exit 1
  fi
done

salted=0; rclone_n=0; tmp=/tmp/obj
printf '%s\n' "$lista" | grep . > /tmp/lista
while IFS= read -r o; do
  rclone cat "$b/$o" > "$tmp"
  cab=$(head -c 8 "$tmp" | od -An -c | tr -d ' \n')
  case "$cab" in
    Salted__) salted=$((salted + 1)) ;;
    RCLONE\\0\\0) rclone_n=$((rclone_n + 1)) ;;
    *) echo "inspecionar: FALHOU objeto sem cabeçalho de cifra: $o (início: $cab)" >&2; exit 1 ;;
  esac
  for m in "$@"; do
    if grep -q -F "$m" "$tmp"; then
      echo "inspecionar: FALHOU o marcador $m aparece em claro em $o" >&2; exit 1
    fi
  done
done < /tmp/lista
echo "inspecionar: ok, $salted objeto(s) cifrados pelo pgBackRest (Salted__) e $rclone_n pelo rclone crypt (RCLONE); nenhum marcador em claro ($*)"
