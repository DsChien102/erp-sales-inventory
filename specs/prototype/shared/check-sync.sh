#!/usr/bin/env bash
# Báo nếu nền chung (shared/) lệch khỏi bản Theme 7 (đang FROZEN, chưa dùng nền chung).
# Dùng: bash specs/prototype/shared/check-sync.sh
cd "$(dirname "$0")/../../themes/theme-07/03.design/prototype/html/styles" || exit 1
rc=0
for f in tokens.css components.css; do
  if ! cmp -s "$f" "../../../../../../prototype/shared/$f"; then echo "LỆCH: shared/$f khác theme-07/styles/$f"; rc=1; fi
done
[ $rc -eq 0 ] && echo "shared/ khớp theme-07"
exit $rc
