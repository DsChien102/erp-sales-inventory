#!/usr/bin/env bash
# Kiểm DB local sau mỗi plan có SQL (quy ước G5, chốt 2026-11-11).
#
#   1. supabase db reset --local         dựng lại DB sạch từ migration (bắt lỗi thứ tự migration)
#   2. plpgsql_check mọi hàm plpgsql      bắt tên bảng / cột / kiểu sai mà không cần chạy hàm
#   3. chạy supabase/tests/*.sql          test nghiệp vụ; tệp xanh khi psql thoát 0
#
# Dùng:
#   tools/db_check.sh                     chạy đủ 3 bước, mọi tệp test
#   tools/db_check.sh --no-reset          bỏ bước 1 (DB đã reset)
#   tools/db_check.sh inventory           chỉ chạy tệp test có tên chứa "inventory"
#   tools/db_check.sh --no-reset inventory_goods_receipts
#
# Cần: Docker đang chạy, `supabase start` đã bật. Không cần cài psql (dùng psql trong container).
# Nợ đã biết: tools/db_check_known.txt — lỗi có trong đó hiện ⚠️, không làm đỏ.
# Thoát mã 1 nếu có lỗi MỚI ở bất kỳ bước nào.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RESET=1
FILTER=""
for arg in "$@"; do
  case "$arg" in
    --no-reset) RESET=0 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) FILTER="$arg" ;;
  esac
done

PROJECT_ID="$(sed -n 's/^project_id *= *"\(.*\)"/\1/p' supabase/config.toml | head -1)"
CONTAINER="supabase_db_${PROJECT_ID}"

if [ -t 1 ]; then RED=$'\e[31m'; GREEN=$'\e[32m'; BOLD=$'\e[1m'; RESET_C=$'\e[0m'; else RED=""; GREEN=""; BOLD=""; RESET_C=""; fi
YELLOW=""; [ -t 1 ] && YELLOW=$'\e[33m'
ok()   { printf '%s✅ %s%s\n' "$GREEN" "$1" "$RESET_C"; }
warn() { printf '%s⚠️  %s%s\n' "$YELLOW" "$1" "$RESET_C"; }

KNOWN_FILE="tools/db_check_known.txt"
# known <loại> <khoá>: có trong danh sách nợ đã biết? (bỏ dòng trống / chú thích)
known() { [ -f "$KNOWN_FILE" ] && grep -v '^#' "$KNOWN_FILE" | grep -qxF "$1"$'\t'"$2"; }
fail() { printf '%s❌ %s%s\n' "$RED" "$1" "$RESET_C"; }

psql_db() { docker exec -i "$CONTAINER" psql -U postgres -d postgres -v ON_ERROR_STOP=1 "$@"; }

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  fail "Không thấy container $CONTAINER — mở Docker Desktop rồi chạy: supabase start"
  exit 1
fi

FAILED=0

# 1. Reset ------------------------------------------------------------------
if [ "$RESET" = 1 ]; then
  printf '%s[1/3] supabase db reset --local%s\n' "$BOLD" "$RESET_C"
  LOG="$(mktemp)"
  if (yes || true) | supabase db reset --local >"$LOG" 2>&1; then
    ok "migration lên đủ"
  else
    fail "db reset lỗi:"
    grep -iE "error|failed" "$LOG" | head -20
    rm -f "$LOG"
    exit 1
  fi
  rm -f "$LOG"
else
  printf '%s[1/3] bỏ qua reset (--no-reset)%s\n' "$BOLD" "$RESET_C"
fi

# 2. plpgsql_check ------------------------------------------------------------
printf '%s[2/3] plpgsql_check (schema của app)%s\n' "$BOLD" "$RESET_C"
# Chạy trong giao dịch rồi rollback ⇒ không để lại extension trong DB.
CHECK_OUT="$(psql_db -At -F $'\t' <<'SQL' 2>&1
begin;
create extension if not exists plpgsql_check;
with fns as (
  select p.oid, n.nspname, p.proname,
         case when p.prorettype = 'trigger'::regtype
              then (select t.tgrelid from pg_trigger t where t.tgfoid = p.oid limit 1)
              else 0::oid end as relid,
         p.prorettype = 'trigger'::regtype as is_trigger
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  join pg_language l on l.oid = p.prolang and l.lanname = 'plpgsql'
  left join pg_depend d on d.objid = p.oid and d.deptype = 'e'
  where d.objid is null
    and n.nspname not in ('pg_catalog', 'information_schema', 'auth', 'storage', 'extensions',
                          'graphql', 'graphql_public', 'realtime', 'vault', 'pgsodium',
                          'pgsodium_masks', 'supabase_functions', 'supabase_migrations',
                          'net', 'pgbouncer', 'cron', '_realtime', '_analytics')
    and n.nspname not like 'pg_temp%' and n.nspname not like 'pg_toast%'
)
select f.nspname || '.' || f.proname, (c).lineno, (c).message
from fns f,
     lateral plpgsql_check_function_tb(f.oid, coalesce(f.relid, 0)) c
where (c).level = 'error'
  and not (f.is_trigger and f.relid is null)
order by 1, 2;
rollback;
SQL
)"
CHECK_STATUS=$?
if [ "$CHECK_STATUS" -ne 0 ] || printf '%s\n' "$CHECK_OUT" | grep -q '^ERROR'; then
  fail "plpgsql_check không chạy được:"
  printf '%s\n' "$CHECK_OUT" | grep -E '^(ERROR|DETAIL|HINT)' | head -5 | sed 's/^/    /'
  FAILED=1
else
  CHECK_ERRORS="$(printf '%s\n' "$CHECK_OUT" | grep -vE '^(BEGIN|CREATE EXTENSION|ROLLBACK)?$')"
  NEW=0; OLD=0
  while IFS=$'\t' read -r fn line msg; do
    [ -z "$fn" ] && continue
    if known plpgsql "$fn"$'\t'"$msg"; then
      warn "nợ đã biết: $fn:$line — $msg"; OLD=$((OLD + 1))
    else
      fail "$fn:$line — $msg"; NEW=$((NEW + 1))
    fi
  done <<< "$CHECK_ERRORS"
  if [ "$NEW" = 0 ]; then
    if [ "$OLD" = 0 ]; then ok "không có lỗi tên bảng / cột / kiểu"; else ok "không có lỗi tên bảng / cột / kiểu mới ($OLD nợ đã biết)"; fi
  else
    FAILED=1
  fi
fi

# 3. Test SQL ----------------------------------------------------------------
printf '%s[3/3] supabase/tests/*.sql%s\n' "$BOLD" "$RESET_C"
shopt -s nullglob
TESTS=(supabase/tests/*.sql)
RAN=0
for f in "${TESTS[@]}"; do
  name="$(basename "$f" .sql)"
  if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then continue; fi
  RAN=$((RAN + 1))
  OUT="$(psql_db < "$f" 2>&1)"
  if [ $? -eq 0 ]; then
    last="$(printf '%s\n' "$OUT" | grep -E '^NOTICE' | tail -1 | sed 's/^NOTICE: *//')"
    ok "$name${last:+ — $last}"
  elif known test "$name"; then
    warn "$name — nợ đã biết: $(printf '%s\n' "$OUT" | grep -m1 '^ERROR' | sed 's/^ERROR: *//')"
  else
    fail "$name"
    printf '%s\n' "$OUT" | grep -E '^(ERROR|DETAIL|HINT|CONTEXT)' | head -6 | sed 's/^/    /'
    FAILED=1
  fi
done
[ "$RAN" = 0 ] && fail "không có tệp test khớp \"$FILTER\"" && FAILED=1

echo
if [ "$FAILED" = 0 ]; then ok "DB check đạt"; else fail "DB check có lỗi"; fi
exit "$FAILED"
