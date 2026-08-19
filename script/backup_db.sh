#!/bin/bash
# 本番PostgreSQLのダンプを手元へ保存する。
# Northflankが使えなくなっても復旧できるよう、ダンプはNorthflankの外へ置くこと。
#
#   DATABASE_URL="postgres://..." script/backup_db.sh
#
# 保存先は BACKUP_DIR で変更できる（既定: ~/basil-backups）。
# 古いダンプは KEEP_COUNT 世代だけ残す（既定: 12）。
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL を指定してください}"
backup_dir="${BACKUP_DIR:-$HOME/basil-backups}"
keep_count="${KEEP_COUNT:-12}"

mkdir -p "$backup_dir"
dump_path="$backup_dir/basil-$(date +%Y-%m-%d-%H%M).dump"

pg_dump "$DATABASE_URL" --format=custom --file="$dump_path"

# 中身が壊れていないか確認する。壊れたダンプを気づかず貯め続けないため。
if ! pg_restore --list "$dump_path" > /dev/null 2>&1; then
  echo "ダンプが読めません: $dump_path" >&2
  exit 1
fi

# 古い世代を消す。消すのは検証に成功したあとだけにする。
ls -1t "$backup_dir"/basil-*.dump | tail -n "+$((keep_count + 1))" | while IFS= read -r old_dump; do
  rm -- "$old_dump"
done

echo "$dump_path ($(du -h "$dump_path" | cut -f1))"
