# T6-1a — Chuyển bảng tiền sang schema `receivable` Implementation Plan

> Phase: Theme 6 · Trạng thái: Plan ✅ (duyệt 2026-11-18) | Làm ✅ | Review ✅ R1
> Tài liệu liên quan: PLAN mục Theme 6 (T6-1a), [TH-06](../../../02-yeu-cau/TH-06-cong-no.md) 1.8 (Q12, Q13 R1), 3.2, 3.4, 3.6

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. (Dự án này: **người dùng tự code**, Claude review.)

**Goal:** Ba bảng tiền của đơn nằm ở schema `receivable`, ngày hẹn trả nằm ở quyết toán; mọi RPC TH-05 chạy như cũ, app không đổi.

**Architecture:** Một migration mới: tạo schema → `alter table … set schema` (dữ liệu, khoá, CHECK, index, RLS, quyền đi theo bảng) → thêm cột `payment_due_date` vào quyết toán và chép dữ liệu → tạo lại các hàm đang ghi tên bảng đầy đủ (thân hàm **sinh từ DB local** bằng `pg_get_functiondef` rồi đổi tên schema, cách 2 đã chọn 2026-11-18) + sửa tay 5 hàm R1 → sửa view `ai_read.don_ban` → xoá cột cũ.

**Tech Stack:** PostgreSQL (Supabase local), plpgsql, `psql`, `sed`.

**Spec:** TH-06 mục 3.6 + thiết kế duyệt trong chat 2026-11-18 (cách 2: sinh thân hàm từ DB).

## Global Constraints

- **Không** sửa migration cũ; **không** đổi tên bảng / cột; **không** chuyển RPC sang `receivable`; **không** sửa app (RPC trả `paymentDueDate` / `dueAt` cùng tên trường).
- Test SQL cũ: chỉ đổi `sales.<bảng tiền>` → `receivable.<bảng tiền>` và chỗ đọc ngày hẹn; **không sửa kỳ vọng**.
- Lệnh DB (`supabase db reset`, `psql`) **người dùng tự chạy local**, không chạy trên Dev.
- Ba bảng: `sales_order_settlements`, `sales_payment_transactions`, `settlement_obligation_adjustments`.
- `LOCAL_DB=postgresql://postgres:postgres@127.0.0.1:54322/postgres` (xem `supabase status`).

## Kết quả quét 2026-11-18 (khác spec)

- 13 migration dùng bảng tiền, đúng bảng 3.6. Không migration nào sau `20261122003` đụng tới.
- Các hàm dùng `set search_path = sales, …` nhưng **luôn ghi tên đầy đủ** `sales.<bảng>` (không có tham chiếu trần) → vẫn hỏng sau khi chuyển, phải tạo lại.
- AI: không phải `ai._warehouse` mà là **view `ai_read.don_ban`** (đọc `st.*` và `so.payment_due_date`). View tự theo bảng khi đổi schema, nhưng **chặn `drop column`** nếu chưa sửa.
- `precheck_sales_order_checkout` chỉ dùng **tham số** `p_payment_due_date` → không phải sửa R1.
- Test: **8 file** đọc bảng (`einvoice_th08` chỉ truyền tham số, không sửa). Đọc ngày hẹn từ đơn: chỉ `sales_th05` C08 (dòng 488) và C14 (dòng 599).
- `finalize_sales_order` có một chữ ký duy nhất (008 và 017 cùng tham số) → không có overload cũ.

## Review Focus

1. **Hàm plpgsql còn trỏ tên cũ** — plpgsql không kiểm thân lúc `create`, chỉ lỗi khi chạy. Chặn bằng test mới (Task 1) quét `pg_proc`.
2. **Chép ngày hẹn thiếu dòng** — đơn có `payment_due_date` mà quyết toán không nhận. Chặn bằng khối `do` kiểm đếm trong migration (Task 2 Bước 4).
3. **`confirm_return_exchange` có tham số tên `payment_due_date` trùng tên cột** — câu `update` mới phải viết đầy đủ `confirm_return_exchange.payment_due_date` và bí danh bảng, nếu không sẽ báo lỗi mơ hồ khi chạy. Chặn bằng `sales_th05` C14 (đổi/trả sinh nợ mới → ngày hẹn mới).
4. **Biên lai gốc / biên lai mới / tóm tắt thanh toán** — `dueAt` / `paymentDueDate` phải giữ đúng giá trị như trước (đọc từ quyết toán hiện tại; trước đây đơn cũng bị đổi/trả ghi đè nên hành vi như nhau). Chặn bằng test mới (Task 1) + kịch bản tay TH-05 9.3.
5. **Supabase trên mạng** — chưa mở `receivable` cho API thì T6-2 gọi `schema('receivable')` sẽ lỗi. T6-1a không gọi nên không vỡ; ghi vào mục 6.

---

## File Structure

| File | Hành động | Nội dung |
|---|---|---|
| `supabase/tests/receivable_t6_1a.sql` | tạo | test bảo vệ việc chuyển (Task 1) |
| `supabase/tests/{sales_th05,sales_stats,inventory_reports,inventory_purchase_forecast,inventory_issue_multi_line,inventory_sales_link,ai_read_views,ai_run_query}.sql` | sửa | đổi tên schema; C08/C14 đọc ngày hẹn từ quyết toán |
| `supabase/migrations/20261123001_receivable_move_money_tables.sql` | tạo | migration (Task 2) |
| `supabase/config.toml` | sửa | thêm `receivable` vào `schemas` (dòng 13) |
| `supabase/migrations/REGISTRY.yaml` | sửa (sinh lại) | chủ sở hữu các hàm vừa tạo lại |
| `docs/02-yeu-cau/TH-06-cong-no.md` | sửa | mục 3.6: `ai_read.don_ban`, `precheck` không R1, 8 test |
| `docs/refactor/PLAN.md` | sửa | dòng T6-1a |

---

### Task 1: Test đỏ — test mới + đổi test cũ

**Files:**
- Create: `supabase/tests/receivable_t6_1a.sql`
- Modify: 8 file test ở trên

**Interfaces:**
- Produces: tên đối tượng mà Task 2 phải tạo ra — schema `receivable`; `receivable.sales_order_settlements.payment_due_date date`; `sales.sales_orders` không còn `payment_due_date`.

- [ ] **Bước 1: Viết `receivable_t6_1a.sql`** theo khuôn `sales_th05.sql` (`begin; … rollback;`, lỗi = `raise exception 'FAIL: …'`, cuối `raise notice 'receivable_t6_1a: OK'`). Các ca:

```sql
-- M01 ba bảng ở receivable, không còn ở sales
--   to_regclass('receivable.sales_order_settlements') is not null (×3 bảng)
--   to_regclass('sales.sales_order_settlements') is null (×3 bảng)
-- M02 sales.sales_orders không còn cột payment_due_date;
--     receivable.sales_order_settlements có cột payment_due_date kiểu date
--   (information_schema.columns)
-- M03 không hàm nào còn trỏ tên cũ
--   select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
--   where n.nspname not in ('pg_catalog','information_schema')
--     and p.prosrc ~ 'sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)'
--   → phải = 0
-- M04 không hàm nào đọc ngày hẹn từ đơn
--   prosrc ~ '(v_order|so)\.payment_due_date' → phải = 0
-- M05 RLS vẫn bật trên 3 bảng ở receivable (pg_class.relrowsecurity)
-- M06 bán nợ có hẹn: dựng đơn bằng hàm giúp như sales_th05 (_th05_finalize… với p_due = hôm nay + 3)
--   → receivable.sales_order_settlements.payment_due_date = hôm nay + 3
--   → sales.get_sales_order_payment_summary(...)->>'dueAt' (hoặc khoá ngày hẹn hiện có) = to_char(hôm nay + 3,'YYYY-MM-DD')
--   → ai_read.don_ban.han_thanh_toan của đơn đó = hôm nay + 3 (đặt request.jwt.claims như ai_read_views.sql)
```

Hàm giúp dựng đơn: chép từ `sales_th05.sql` (dòng ~90–140) với tiền tố `_t61a_`; khoá JSON ngày hẹn lấy đúng tên đang trả trong RPC (`get_sales_order_payment_summary` dòng 423 của `20260830010`).

- [ ] **Bước 2: Sửa 8 file test cũ**

```bash
sed -E -i '' 's/sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)/receivable.\1/g' \
  supabase/tests/{sales_th05,sales_stats,inventory_reports,inventory_purchase_forecast,inventory_issue_multi_line,inventory_sales_link,ai_read_views,ai_run_query}.sql
```

Rồi sửa tay `sales_th05.sql` C08 (dòng 488) và C14 (dòng 599): `select payment_due_date into v_due from receivable.sales_order_settlements where sales_order_id = <đơn>` (giữ nguyên kỳ vọng và chữ `FAIL`).

- [ ] **Bước 3: Chạy cho đỏ** (người dùng chạy, DB đang ở bản trước migration)

```bash
psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/receivable_t6_1a.sql
psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/sales_th05.sql
```

Kỳ vọng: cả hai **lỗi** (`FAIL: M01…` / `relation "receivable.sales_order_settlements" does not exist`).

- [ ] **Bước 4:** Chưa commit; commit chung với Task 2 (test đỏ một mình làm hỏng nhánh).

---

### Task 2: Migration

**Files:**
- Create: `supabase/migrations/20261123001_receivable_move_money_tables.sql`
- Modify: `supabase/config.toml:13`

**Interfaces:**
- Consumes: tên đối tượng của Task 1.
- Produces: các hàm `sales.*` cùng chữ ký, cùng JSON trả về.

- [ ] **Bước 1: Impact (CLAUDE.md).** Chạy GitNexus `impact({target: "<tên>", direction: "upstream"})` cho `finalize_sales_order`, `confirm_return_exchange`, `get_sales_order_payment_summary`, `generate_sales_receipt`, `get_sales_order_original_receipt` (các hàm đổi hành vi). Nếu GitNexus không lập chỉ mục SQL thì ghi "không có trong chỉ mục" vào mục 7; báo nếu ra HIGH/CRITICAL.

- [ ] **Bước 2: Sinh thân hàm** (DB local đang ở bản trước migration, sau `supabase db reset`)

```bash
OUT=/tmp/t61a_functions.sql
psql "$LOCAL_DB" -X -At -v ON_ERROR_STOP=1 -o "$OUT" -c "
select string_agg(pg_get_functiondef(p.oid) || ';', E'\n\n' order by n.nspname, p.proname)
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog','information_schema')
  and p.prokind = 'f'
  and p.prosrc ~ 'sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)';"
sed -E -i '' 's/sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)/receivable.\1/g' "$OUT"

# danh sách hàm (để ghi Touches) và đối chiếu
psql "$LOCAL_DB" -X -At -c "
select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog','information_schema') and p.prokind = 'f'
  and p.prosrc ~ 'sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)'
order by 1;"
# hàm dùng payment_due_date mà KHÔNG nằm trong danh sách trên → kỳ vọng chỉ precheck_sales_order_checkout
psql "$LOCAL_DB" -X -At -c "
select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog','information_schema') and p.prokind = 'f'
  and p.prosrc ~ 'payment_due_date'
  and p.prosrc !~ 'sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)';"
```

Kỳ vọng: danh sách thứ nhất ~26 hàm, đều schema `sales`, có đủ 5 hàm R1 ở Bước 1; danh sách thứ hai chỉ `sales.precheck_sales_order_checkout(...)`. Khác thì dừng, báo Claude.

- [ ] **Bước 3: Viết migration** theo `_migration.template.sql` (header: `Kind: surgical`, `Intent: receivable_move_money_tables`, `Context: TH-06 3.6 / Q12 / Q13 R1`, `Touches:` = danh sách Bước 2, `Depends on: 20261122003_inventory_gross_profit_all_members`). Thứ tự khối (bắt buộc):

1. `create schema if not exists receivable;` `grant usage on schema receivable to authenticated, service_role;` (giống `20260830005` dòng 25).
2. `alter table sales.<bảng> set schema receivable;` ×3.
3. `alter table receivable.sales_order_settlements add column payment_due_date date;` rồi `update receivable.sales_order_settlements s set payment_due_date = o.payment_due_date from sales.sales_orders o where o.id = s.sales_order_id and o.tenant_id = s.tenant_id and o.payment_due_date is not null;`
4. Khối `do $$` kiểm chép: số đơn có `payment_due_date is not null` = số quyết toán có `payment_due_date is not null` và không đơn nào lệch ngày; sai thì `raise exception 'T6-1a: chép payment_due_date lệch …'`.
5. Dán nguyên `/tmp/t61a_functions.sql`, rồi sửa tay R1 (Bước 4).
6. `create or replace view ai_read.don_ban` — chép nguyên từ `20261122001` dòng 79–107, chỉ đổi: `st.payment_due_date as han_thanh_toan` và `left join receivable.sales_order_settlements st`. Giữ thứ tự / tên / kiểu cột (điều kiện của `create or replace view`).
7. `alter table sales.sales_orders drop column payment_due_date;` (sau 5 và 6; nếu báo phụ thuộc thì còn chỗ chưa sửa — **không** dùng `cascade`).

- [ ] **Bước 4: Sửa tay R1 trong khối 5**

| Hàm | Sửa |
|---|---|
| `sales.finalize_sales_order` | `insert into sales.sales_orders(…)`: bỏ cột `payment_due_date` và giá trị `p_payment_due_date` tương ứng. `insert into receivable.sales_order_settlements(…)`: thêm cột `payment_due_date` = `p_payment_due_date`. Phần kiểm tham số và `'paymentDueDate', p_payment_due_date` giữ nguyên |
| `sales.confirm_return_exchange` | `update sales.sales_orders`: bỏ dòng `payment_due_date = case … end` (giữ `version`, `updated_at`). Thêm ngay sau: `update receivable.sales_order_settlements s set payment_due_date = confirm_return_exchange.payment_due_date, updated_at = now() where v_collect_debt > 0 and s.sales_order_id = v_order.id and s.tenant_id = v_order.tenant_id;` — **không** tăng `version` của quyết toán (`_apply_settlement_obligation_adjustment` / `_recompute_sales_settlement` lo việc đó) |
| `sales.get_sales_order_payment_summary` | `v_order.payment_due_date` → `v_settlement.payment_due_date` (biến đã có) |
| `sales.generate_sales_receipt` | như trên (`v_settlement` đã có) |
| `sales.get_sales_order_original_receipt` | thêm biến `v_due_date date;` + `select s.payment_due_date into v_due_date from receivable.sales_order_settlements s where s.sales_order_id = v_order.id and s.tenant_id = v_order.tenant_id;`; `v_order.payment_due_date` → `v_due_date` |

Sau đó: `grep -nE "(v_order|so)\.payment_due_date|sales_orders[^;]*payment_due_date" <migration>` → không còn dòng nào ngoài chữ ký tham số / chú thích.

- [ ] **Bước 5: `config.toml`** — thêm `"receivable"` vào `schemas` (dòng 13), sau `"sales"`.

- [ ] **Bước 6: Chạy cho xanh** (người dùng chạy)

```bash
supabase db reset
for f in supabase/tests/*.sql; do psql "$LOCAL_DB" -X -q -v ON_ERROR_STOP=1 -f "$f" >/dev/null 2>/tmp/t61a_err.txt \
  && echo "OK   $f" || { echo "FAIL $f"; head -3 /tmp/t61a_err.txt; }; done
```

Kỳ vọng: `db reset` không lỗi; **mọi** file `OK` (gồm `receivable_t6_1a.sql`, `einvoice_th08.sql` không sửa). So với `docs/refactor/TEST-BASELINE.md`: không lỗi thêm.

- [ ] **Bước 7: Commit**

```bash
git add supabase/migrations/20261123001_receivable_move_money_tables.sql supabase/config.toml supabase/tests/
git commit -m "feat(receivable): T6-1a chuyển bảng tiền sang schema receivable, ngày hẹn vào quyết toán"
```

---

### Task 3: Registry, tài liệu, chạy tay

**Files:** `supabase/migrations/REGISTRY.yaml`, `docs/02-yeu-cau/TH-06-cong-no.md`, `docs/refactor/PLAN.md`

- [ ] **Bước 1:** `melos run migrate:seed-registry -- --write`; `git diff supabase/migrations/REGISTRY.yaml` chỉ đổi chủ sở hữu các hàm trong `Touches` sang `20261123001_…` (thêm cả khối `receivable:` nếu công cụ sinh).
- [ ] **Bước 2: TH-06 3.6** — bảng hàm: dòng `20261122001` đổi thành "view `ai_read.don_ban` [R1]"; bỏ [R1] ở `precheck_sales_order_checkout` (chỉ tham số); mục 4: "8 test" (bỏ `einvoice_th08`, chỉ truyền tham số); ghi `search_path` thật là `sales, …` nhưng hàm luôn ghi tên đầy đủ.
- [ ] **Bước 3: Chạy tay** kịch bản TH-05 9.3 trên app (iPhone hoặc web): bán nợ có hẹn → chi tiết đơn hiện ngày hẹn → thu một phần → in phiếu (ngày hẹn đúng) → đổi/trả phát sinh nợ thêm với hẹn mới → chi tiết đơn hiện hẹn mới → huỷ một đơn khác. Hỏi "Hỏi VET45": "đơn nào còn nợ, hạn khi nào?" ra đúng hạn.
- [ ] **Bước 4:** `detect_changes()` GitNexus (CLAUDE.md) → chỉ đụng các ký hiệu trong `Touches`.
- [ ] **Bước 5:** PLAN.md dòng T6-1a: Làm ✅; commit `docs(refactor): T6-1a registry + sửa TH-06 3.6`.

---

## 5. Kiểm tra

- [ ] `supabase db reset` chạy hết migration
- [ ] Mọi `supabase/tests/*.sql` OK, kỳ vọng test cũ không đổi
- [ ] `receivable_t6_1a.sql` M01–M06 OK
- [ ] Kịch bản tay TH-05 9.3 + câu hỏi AI về hạn nợ
- [ ] `flutter analyze` không cần (không sửa Dart)

## 6. Rủi ro / lưu ý

- **Deploy Supabase trên mạng:** chạy migration xong vào Dashboard → Project Settings → API → *Exposed schemas* thêm `receivable` (chỉ cần trước T6-2; ghi luôn để không quên).
- `pg_get_functiondef` bỏ chú thích ngoài thân và in theo định dạng Postgres (`SET search_path TO …`, `$function$`) — chấp nhận (cách 2). Chú thích **trong** thân hàm vẫn giữ.
- `create or replace function` giữ quyền `grant execute` đã cấp; không cần cấp lại.
- `alter table … set schema` giữ quyền bảng (`select` của `authenticated`), RLS, khoá ngoại sang `sales.sales_orders`.
- Không dùng `drop … cascade` ở khối 7: lỗi phụ thuộc là tín hiệu còn chỗ chưa sửa.
- `/tmp/t61a_functions.sql` chỉ dùng một lần, không commit.

## 7. Review

### R1
- Ngày, commit được review: 2026-11-18, `d13372e93` (migration + test), `26a4ef78b` (registry + TH-06 3.6)
- Kết quả: ✅ đạt
- Kiểm:
  - Migration tạo lại 25 hàm (đúng bảng 3.6, trừ `precheck_sales_order_checkout` chỉ dùng tham số); không còn `sales.<bảng tiền>`; thứ tự khối đúng plan, có kiểm đếm sau khi chép ngày hẹn, `drop column` không `cascade`.
  - R1: `finalize_sales_order` ghi ngày hẹn vào quyết toán; `confirm_return_exchange` cập nhật quyết toán với `confirm_return_exchange.payment_due_date` + bí danh `s`, chỉ khi `v_collect_debt > 0` (như cũ); ba RPC biên lai / tóm tắt đọc từ quyết toán, trường JSON giữ tên.
  - `ai_read.don_ban` giữ thứ tự / tên cột, chỉ đổi nguồn ngày hẹn.
  - Test: 8 file đổi tên schema, kỳ vọng giữ; C08 / C14 đọc từ quyết toán; `receivable_t6_1a.sql` M01–M06.
  - `tools/db_check.sh` (người dùng chạy): migration lên đủ; `plpgsql_check` không lỗi mới (2 nợ đã biết); mọi test xanh, gồm `receivable_t6_1a: OK`, `sales_th05: OK` (3 ⚠️ là nợ đã biết: `catalog_th02`, `einvoice_th08`, `pricing_th04`).
  - GitNexus `detect-changes`: rủi ro thấp, 0 luồng (không lập chỉ mục SQL).
- Góp ý (không chặn):
  1. Sinh lại `REGISTRY.yaml` kéo theo ~57 dòng sắp xếp / bổ sung ở theme khác — vô hại, chỉ làm commit to.
  2. M04 chỉ bắt `v_order.` / `so.payment_due_date`; `plpgsql_check` của `db_check.sh` là lớp chặn chính.
  3. Kịch bản tay TH-05 9.3 + câu hỏi hạn nợ ở "Hỏi VET45": người dùng tự xác nhận.
