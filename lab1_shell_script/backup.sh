#!/usr/bin/env bash
# backup.sh безопасное создание tar.gz бэкапа каталога.
# Использование:
#   ./backup.sh SOURCE_DIR [DEST_DIR=/backup]
# Примеры:
#   ./backup.sh /var/www
#   ./backup.sh /etc /mnt/backups

set -Eeuo pipefail
IFS=$'\n\t'

PROG="${0##*/}"

usage() {
  cat <<EOF
Usage: $PROG SOURCE_DIR [DEST_DIR=/backup]

Create a compressed tar.gz backup of SOURCE_DIR into DEST_DIR (default: /backup).
Archive name: <basename(SOURCE_DIR)>-YYYY-MM-DD_HH-MM-SS.tar.gz

Examples:
  $PROG /var/www
  $PROG /etc /mnt/backups
EOF
}

log() { printf '[%(%F %T)T] %s\n' -1 "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }
die() { err "$@"; exit 1; }

# Помощь по -h/--help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Обязателен хотя бы один аргумент (SOURCE_DIR)
if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

src="$1"
dest="${2:-/backup}"

# Проверка наличия readlink (для безопасного получения абсолютных путей)
command -v readlink >/dev/null 2>&1 || die "Utility 'readlink' not found in PATH."

# Абсолютные пути (нормализованные)
src_abs="$(readlink -f -- "$src")"       || die "Cannot resolve path: $src"
dest_abs="$(readlink -f -- "$dest" 2>/dev/null || true)"

# Если каталога назначения ещё нет создадим (потом снова нормализуем)
if [[ -z "$dest_abs" || ! -d "$dest_abs" ]]; then
  log "Destination does not exist; creating: $dest"
  mkdir -p -- "$dest"                     || die "Failed to create destination: $dest"
  dest_abs="$(readlink -f -- "$dest")"    || die "Cannot resolve destination path: $dest"
fi

# Валидации директорий
[[ -d "$src_abs"  ]] || die "Source directory does not exist: $src_abs"
[[ -d "$dest_abs" ]] || die "Destination directory does not exist: $dest_abs"
[[ -w "$dest_abs" ]] || die "Destination is not writable: $dest_abs"

# Если каталог назначения лежит внутри исходного исключим его из архива (чтобы не заархивировать сам себя)
exclude_arg=()
case "$dest_abs" in
  "$src_abs"|"$src_abs"/*)
    log "Destination is inside source; will exclude: $dest_abs"
    exclude_arg=(--exclude="$dest_abs")
    ;;
esac

base="$(basename -- "$src_abs")"
ts="$(date +%F_%H-%M-%S)"                          # YYYY-MM-DD_HH-MM-SS
archive="$dest_abs/${base}-${ts}.tar.gz"
tmp_archive="${archive}.part"                      # Временный файл (на случай прерывания)

# На любой аварийный выход удалить .part (безопасность от «битых» архивов)
cleanup() {
  [[ -f "$tmp_archive" ]] && rm -f -- "$tmp_archive" || true
}
trap cleanup ERR INT TERM

log "Creating archive: $archive"

# Собираем архив:
#  -C <parent>   — переключаемся в родительский каталог, чтобы в архив попал каталог base без абсолютных путей.
#  "${exclude_arg[@]}" — опционально исключаем каталог назначения, если он лежит внутри исходного.
parent="$(dirname -- "$src_abs")"
if tar -C "$parent" -czf "$tmp_archive" "${exclude_arg[@]}" -- "$base"; then
  :
else
  die "tar failed to create archive."
fi

# Проверка целостности архива (gzip -t возвращает 0, если всё ок)
if command -v gzip >/dev/null 2>&1; then
  gzip -t -- "$tmp_archive" || die "Archive integrity check failed."
fi

# «Атомарное» переименование: готовый .part становится финальным архивом
mv -f -- "$tmp_archive" "$archive"

# Информационный вывод: размер и SHA256 (если доступно)
size_h="$(du -h --apparent-size -- "$archive" | awk '{print $1}')"
if command -v sha256sum >/dev/null 2>&1; then
  sum="$(sha256sum -- "$archive" | awk '{print $1}')"
  log "SHA256: $sum"
fi
log "Size: ${size_h:-unknown}"
log "Backup completed successfully."
log "Archive: $archive"