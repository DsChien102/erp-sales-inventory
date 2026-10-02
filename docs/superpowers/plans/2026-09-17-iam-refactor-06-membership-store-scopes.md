# IAM refactor — Bảng 6 `iam.membership_store_scopes` (xoá bảng) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ `iam.membership_store_scopes`; mọi kiểm tra quyền theo cửa hàng (IAM, Sales, Catalog, Pricing) đi qua `iam.can_access_store(tenant, store, user)` — **sửa trực tiếp migration gốc**.

**Architecture:** Task 1 xoá DDL bảng/policy/grant tại `20260830001`, thêm helper `can_access_store` ngay sau `iam.stores`, xoá `_ensure_membership_default_store_scope` và vòng backfill scope. Task 2 sửa 6 hàm IAM (file owner). Task 3 sửa 20 hàm Sales; Task 4 sửa 4 hàm Catalog + 2 hàm Pricing (file owner). Task 5 cập nhật SQL contract test cũ + kiểm chứng. Không đổi chữ ký RPC/output; không đổi Dart.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [06-membership-store-scopes.md](../specs/iam-schema-refactor/06-membership-store-scopes.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Chạy sau plan [3](2026-09-17-iam-refactor-03-memberships.md), [4](2026-09-17-iam-refactor-04-tenant-invitations.md) (cần `memberships.is_active`; văn bản "trước" đã gồm thay đổi plan 1–4).
- Helper (tên, chữ ký cố định): `iam.can_access_store(p_tenant_id uuid, p_store_id uuid, p_user_id uuid) returns boolean` — true ⇔ store thuộc tenant, `status = 'active'`, và `p_user_id` là member `is_active` của tenant. `language sql stable security definer`; revoke `public, anon, authenticated`.
- Quy tắc viết lại (giữ biểu thức tenant/store/actor cũ, giữ mã lỗi/message):

  | Cũ | Mới |
  |---|---|
  | `if not exists ( select 1 from iam.membership_store_scopes scope [join iam.stores store on …] where scope.tenant_id = T and scope.user_id = A and scope.store_id = S [and store…] ) then` | `if not iam.can_access_store(T, S, A) then` |
  | `and exists ( select 1 from iam.membership_store_scopes scope where scope.tenant_id = T and scope.user_id = A and scope.store_id = S )` | `and iam.can_access_store(T, S, A)` |

- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên>" --direction upstream --repo .` (hàm SQL → `UNKNOWN`).

## Khảo sát

**Câu lệnh chạy trực tiếp / đối tượng phải xoá hoặc sửa:**

| File | Nội dung |
|---|---|
| `20260830001_iam_active_store_context_group_a.sql` | `create table iam.membership_store_scopes`, index `membership_store_scopes_one_default`, `enable row level security`, policy `membership_store_scopes_self_read`, `revoke all on iam.membership_store_scopes`, `grant select on iam.stores, iam.membership_store_scopes` |
| `20260916001_iam_ensure_default_store_scope_helpers.sql` | hàm `_ensure_membership_default_store_scope` + `revoke`; header `-- Touches:` |
| `20260916003_iam_backfill_default_store_scopes.sql` | vòng lặp thứ hai trong khối `DO` (đọc bảng scope, gọi helper bị xoá); header |

**Định nghĩa cuối cần sửa:**

| Hàm | File owner | Việc |
|---|---|---|
| `iam.get_session_context`, `iam.bootstrap_owner` | `20260914001_iam_get_session_context_multi_tenant.sql` | chọn cửa hàng qua helper; bỏ insert scope |
| `iam.create_tenant_onboarding` | `20260916004_iam_patch_onboarding_default_store_scope.sql` | bỏ `perform _ensure_membership_default_store_scope` |
| `iam.create_tenant_invitation` | `20260916005_iam_patch_invitation_membership_store_scope.sql` | bỏ `perform …` |
| `iam.accept_invitation` | `20260916006_iam_patch_accept_invitation_default_store_scope.sql` | bỏ 2 `perform …` |
| `iam.activate_tenant` | `20260916007_iam_patch_activate_tenant_default_store_scope.sql` | bỏ tra owner + `perform …` |
| `sales._assert_sales_actor` | `20260830006_sales_shared_rpc_helpers.sql` | helper |
| `sales.get_sales_order`, `get_sales_order_payment_summary`, `get_order_integration_status`, `list_sales_orders`, `search_sales_orders`, `get_sales_order_detail`, `get_sales_order_settlement`, `get_sales_order_payment_transactions`, `get_sales_order_timeline`, `get_sales_order_return_summary`, `get_sales_receipt`, `record_sales_receipt_activity` | `20260830010_sales_inquiry_receipt_rpcs.sql` | helper |
| `sales.get_available_post_sale_actions`, `precheck_sales_order_cancellation`, `get_sales_order_cancellation` | `20260830011_sales_adjustment_cancellation_rpcs.sql` | helper |
| `sales.precheck_return_exchange`, `get_returnable_order_lines`, `_get_return_exchange_context`, `get_return_exchange_detail` | `20260830012_sales_return_exchange_session_rpcs.sql` | helper |
| `catalog.search_sellable_products`, `resolve_sellable_barcode`, `list_sellable_product_units` | `20260830002_catalog_sales_sellable_lookup_group_a.sql` | helper |
| `catalog.resolve_sellable_products` | `20260831001_catalog_sellable_lookup_by_ids.sql` | helper |
| `pricing.preview_sales_working_state_pricing`, `pricing.evaluate_sales_manual_price` | `20260830003_pricing_sales_working_state_preview_group_a.sql` | helper |

Bản plpgsql cũ của `get_session_context` / `bootstrap_owner(text)` trong `20260830001` đọc bảng scope nhưng bị ghi đè/drop sau → để nguyên.

**SQL contract test cũ assert `membership_store_scopes`** (sửa ở Task 5): `modules/sales/infrastructure/test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart`, `…/sales_order/sales_post_sale_actions_group_f_sql_contract_test.dart`, `…/sales_order/sales_inquiry_group_f_sql_contract_test.dart`, `…/sales_order/sales_read_group_e_sql_contract_test.dart`, `modules/catalog/infrastructure/test/catalog_sales_sellable_lookup_sql_contract_test.dart`, `modules/catalog/infrastructure/test/catalog_sellable_lookup_by_ids_sql_contract_test.dart`, `modules/pricing/infrastructure/test/sql/pricing_sales_working_state_preview_contract_test.dart`, `modules/iam/infrastructure/test/sql/iam_membership_store_scope_lifecycle_sql_contract_test.dart` (test hàm bị xoá).

## File Structure

| File | Thay đổi |
|---|---|
| Modify migration theo Khảo sát | Sửa tại chỗ |
| Create `modules/iam/infrastructure/test/iam_refactor_06_store_scopes_sql_contract_test.dart` | SQL contract test |
| Modify / Delete test cũ (danh sách trên) | Cập nhật assertion |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

Chạy test: `cd modules/iam/infrastructure && dart test test/iam_refactor_06_store_scopes_sql_contract_test.dart`

---

### Task 1: Xoá bảng + helper cũ, thêm `can_access_store`

**Files:**
- Create: test file
- Modify: `20260830001_iam_active_store_context_group_a.sql`, `20260916001_iam_ensure_default_store_scope_helpers.sql`, `20260916003_iam_backfill_default_store_scopes.sql`

**Interfaces:**
- Produces: `iam.can_access_store(uuid, uuid, uuid) → boolean`; test helper `_readMigration`, `_lastFunctionBlock`, `_expectUsesStoreAccess`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 6: remove membership_store_scopes
/// (docs/superpowers/specs/iam-schema-refactor/06-membership-store-scopes.md).
void main() {
  group('store scope DDL removed; can_access_store added', () {
    final activeStore = _readMigration('20260830001_iam_active_store_context_group_a.sql');

    test('no scope table, index, policy or grant is created', () {
      expect(activeStore, isNot(contains('create table if not exists iam.membership_store_scopes')));
      expect(activeStore, isNot(contains('membership_store_scopes_one_default')));
      expect(activeStore, isNot(contains('create policy membership_store_scopes_self_read')));
      expect(activeStore, contains('grant select on iam.stores to authenticated;'));
    });

    test('can_access_store checks active store and active member, not exposed', () {
      final body = _lastFunctionBlock(activeStore, 'iam.can_access_store');
      expect(body, contains("s.status = 'active'"));
      expect(body, contains('m.is_active'));
      expect(activeStore.indexOf('create or replace function iam.can_access_store('),
          greaterThan(activeStore.indexOf('create table if not exists iam.stores (')));
      expect(activeStore, contains('revoke all on function iam.can_access_store(uuid, uuid, uuid) from public, anon, authenticated;'));
    });

    test('legacy scope helper and backfill loop removed', () {
      final helpers = _readMigration('20260916001_iam_ensure_default_store_scope_helpers.sql');
      expect(helpers, isNot(contains('_ensure_membership_default_store_scope')));
      final backfill = _readMigration('20260916003_iam_backfill_default_store_scopes.sql');
      expect(backfill, isNot(contains('membership_store_scopes')));
      expect(backfill, isNot(contains('_ensure_membership_default_store_scope')));
    });
  });
}

void _expectUsesStoreAccess(Map<String, String> ownerByFunction) {
  for (final entry in ownerByFunction.entries) {
    final body = _lastFunctionBlock(_readMigration(entry.value), entry.key);
    expect(body, isNot(contains('membership_store_scopes')), reason: entry.key);
    expect(body, contains('iam.can_access_store('), reason: entry.key);
  }
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `20260830001_iam_active_store_context_group_a.sql`**

1. Xoá khối:
```sql
create table if not exists iam.membership_store_scopes (
  tenant_id uuid not null references iam.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid not null,
  is_default boolean not null default false,
  primary key (tenant_id, user_id, store_id),
  foreign key (tenant_id, user_id)
    references iam.memberships(tenant_id, user_id) on delete cascade,
  foreign key (tenant_id, store_id)
    references iam.stores(tenant_id, id) on delete cascade
);

create unique index if not exists membership_store_scopes_one_default
  on iam.membership_store_scopes (tenant_id, user_id)
  where is_default;
```
2. Xoá dòng `alter table iam.membership_store_scopes enable row level security;`
3. Thay khối policy scope:
```sql
drop policy if exists membership_store_scopes_self_read on iam.membership_store_scopes;
create policy membership_store_scopes_self_read on iam.membership_store_scopes
  for select
  to authenticated
  using (
    user_id = auth.uid()
    and exists (
      select 1
      from iam.memberships m
      where m.tenant_id = membership_store_scopes.tenant_id
        and m.user_id = auth.uid()
    )
  );
```
bằng:
```sql
-- Single-store era: store access = active store of tenant + active membership.
-- Multi-store later: reintroduce scopes and change only this helper.
create or replace function iam.can_access_store(
  p_tenant_id uuid,
  p_store_id uuid,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = iam, pg_temp
as $$
  select exists (
    select 1
    from iam.stores s
    join iam.memberships m
      on m.tenant_id = s.tenant_id
    where s.tenant_id = p_tenant_id
      and s.id = p_store_id
      and s.status = 'active'
      and m.user_id = p_user_id
      and m.is_active
  );
$$;

revoke all on function iam.can_access_store(uuid, uuid, uuid) from public, anon, authenticated;
```
4. Thay:
```sql
revoke all on iam.stores from public, anon;
revoke all on iam.membership_store_scopes from public, anon;
grant select on iam.stores, iam.membership_store_scopes to authenticated;
```
bằng:
```sql
revoke all on iam.stores from public, anon;
grant select on iam.stores to authenticated;
```

- [ ] **Step 4: `20260916001_iam_ensure_default_store_scope_helpers.sql`**
1. Xoá toàn bộ hàm `create or replace function iam._ensure_membership_default_store_scope(` … `$$;`.
2. Xoá dòng `revoke all on function iam._ensure_membership_default_store_scope(uuid, uuid) from public, anon;`
3. Header: `-- Touches: iam._ensure_tenant_default_store, iam._ensure_membership_default_store_scope` → `-- Touches: iam._ensure_tenant_default_store`

- [ ] **Step 5: `20260916003_iam_backfill_default_store_scopes.sql`**
1. Trong khối `DO`, xoá vòng lặp thứ hai (từ `  for v_tenant_id, v_user_id in` tới `  end loop;` ngay trước `end;`) và dòng khai báo `  v_user_id uuid;`.
2. Header: `-- Title: IAM backfill default store + membership scopes` → `-- Title: IAM backfill default store`; `-- Touches: iam.stores, iam.membership_store_scopes` → `-- Touches: iam.stores`.

- [ ] **Step 6: Chạy test, xác nhận pass.**

- [ ] **Step 7: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): replace membership_store_scopes with can_access_store`.

---

### Task 2: 6 hàm IAM (file owner)

**Files:**
- Modify: test file + `20260914001_…`, `20260916004_…`, `20260916005_…`, `20260916006_…`, `20260916007_…`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('iam functions no longer touch store scopes', () {
    const owners = {
      'iam.get_session_context': '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.bootstrap_owner': '20260914001_iam_get_session_context_multi_tenant.sql',
      'iam.create_tenant_onboarding': '20260916004_iam_patch_onboarding_default_store_scope.sql',
      'iam.create_tenant_invitation': '20260916005_iam_patch_invitation_membership_store_scope.sql',
      'iam.accept_invitation': '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
      'iam.activate_tenant': '20260916007_iam_patch_activate_tenant_default_store_scope.sql',
    };

    test('no scope table or legacy helper', () {
      for (final entry in owners.entries) {
        final body = _lastFunctionBlock(_readMigration(entry.value), entry.key);
        expect(body, isNot(contains('membership_store_scopes')), reason: entry.key);
        expect(body, isNot(contains('_ensure_membership_default_store_scope')), reason: entry.key);
      }
    });

    test('session context resolves active store through helper', () {
      expect(
        _lastFunctionBlock(_readMigration(owners['iam.get_session_context']!), 'iam.get_session_context'),
        contains('iam.can_access_store(v_tenant_id, v_active_store_id, v_user_id)'),
      );
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `get_session_context`** (`20260914001_…`)

Thay đoạn từ `  select array_agg(scope.store_id)` (khối đầu) tới hết `  v_active_store_id := v_store_ids[1];`:
```sql
  select array_agg(scope.store_id)
  into v_store_ids
  from iam.membership_store_scopes scope
  join iam.stores store on store.id = scope.store_id
    and store.tenant_id = scope.tenant_id
  where scope.tenant_id = v_tenant_id
    and scope.user_id = v_user_id
    and scope.is_default
    and store.status = 'active';

  if coalesce(cardinality(v_store_ids), 0) = 0
    and v_role = 'store_owner' then
    perform iam.bootstrap_owner(v_tenant_id, 'My Store');

    select array_agg(scope.store_id)
    into v_store_ids
    from iam.membership_store_scopes scope
    join iam.stores store on store.id = scope.store_id
      and store.tenant_id = scope.tenant_id
    where scope.tenant_id = v_tenant_id
      and scope.user_id = v_user_id
      and scope.is_default
      and store.status = 'active';
  end if;

  if coalesce(cardinality(v_store_ids), 0) <> 1 then
    raise exception using errcode = 'P0001',
      message = '{"code":"CONTEXT_INVALID","message":"Exactly one active default store is required.","details":{}}';
  end if;

  v_active_store_id := v_store_ids[1];
```
bằng:
```sql
  -- Single-store era: the tenant's active store (default first) is the active store.
  select store.id
  into v_active_store_id
  from iam.stores store
  where store.tenant_id = v_tenant_id
    and store.status = 'active'
  order by (store.code = 'default') desc, store.created_at, store.id
  limit 1;

  if v_active_store_id is null
    and v_role = 'store_owner' then
    perform iam.bootstrap_owner(v_tenant_id, 'My Store');

    select store.id
    into v_active_store_id
    from iam.stores store
    where store.tenant_id = v_tenant_id
      and store.status = 'active'
    order by (store.code = 'default') desc, store.created_at, store.id
    limit 1;
  end if;

  if v_active_store_id is null
    or not iam.can_access_store(v_tenant_id, v_active_store_id, v_user_id) then
    raise exception using errcode = 'P0001',
      message = '{"code":"CONTEXT_INVALID","message":"Exactly one active default store is required.","details":{}}';
  end if;
```
Xoá khai báo `  v_store_ids uuid[];`.

- [ ] **Step 4: `bootstrap_owner`** (`20260914001_…`) — xoá khối:
```sql
  insert into iam.membership_store_scopes (
    tenant_id,
    user_id,
    store_id,
    is_default
  ) values (
    p_tenant_id,
    v_user_id,
    v_store_id,
    true
  )
  on conflict (tenant_id, user_id, store_id) do update
  set is_default = true;
```

- [ ] **Step 5: Bỏ lời gọi helper cũ**
- `create_tenant_onboarding` (`20260916004_…`): xoá `  perform iam._ensure_membership_default_store_scope(v_tenant_id, v_owner_user_id);`
- `create_tenant_invitation` (`20260916005_…`): xoá `  perform iam._ensure_membership_default_store_scope(p_tenant_id, v_invitee_user_id);`
- `accept_invitation` (`20260916006_…`): xoá **cả 2** dòng `perform iam._ensure_membership_default_store_scope(…);`
- `activate_tenant` (`20260916007_…`): xoá khối
```sql
  select m.user_id
  into v_owner_user_id
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and (m.is_owner is true or m.role = 'store_owner')
    and m.is_active
  order by m.created_at
  limit 1;

  if v_owner_user_id is not null then
    perform iam._ensure_membership_default_store_scope(p_tenant_id, v_owner_user_id);
  end if;
```
và dòng khai báo `  v_owner_user_id uuid;` (giữ `perform iam._ensure_tenant_default_store(p_tenant_id);`).

- [ ] **Step 6: Chạy test, xác nhận pass.**

- [ ] **Step 7: Dừng — tóm tắt.** Đề xuất commit: `refactor(iam): session context and flows stop writing store scopes`.

---

### Task 3: 20 hàm Sales (file owner)

**Files:**
- Modify: test file + `20260830006_sales_shared_rpc_helpers.sql`, `20260830010_sales_inquiry_receipt_rpcs.sql`, `20260830011_sales_adjustment_cancellation_rpcs.sql`, `20260830012_sales_return_exchange_session_rpcs.sql`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('sales store access', () {
    const f06 = '20260830006_sales_shared_rpc_helpers.sql';
    const f10 = '20260830010_sales_inquiry_receipt_rpcs.sql';
    const f11 = '20260830011_sales_adjustment_cancellation_rpcs.sql';
    const f12 = '20260830012_sales_return_exchange_session_rpcs.sql';

    test('20 functions use can_access_store', () => _expectUsesStoreAccess(const {
          'sales._assert_sales_actor': f06,
          'sales.get_sales_order': f10,
          'sales.get_sales_order_payment_summary': f10,
          'sales.get_order_integration_status': f10,
          'sales.list_sales_orders': f10,
          'sales.search_sales_orders': f10,
          'sales.get_sales_order_detail': f10,
          'sales.get_sales_order_settlement': f10,
          'sales.get_sales_order_payment_transactions': f10,
          'sales.get_sales_order_timeline': f10,
          'sales.get_sales_order_return_summary': f10,
          'sales.get_sales_receipt': f10,
          'sales.record_sales_receipt_activity': f10,
          'sales.get_available_post_sale_actions': f11,
          'sales.precheck_sales_order_cancellation': f11,
          'sales.get_sales_order_cancellation': f11,
          'sales.precheck_return_exchange': f12,
          'sales.get_returnable_order_lines': f12,
          'sales._get_return_exchange_context': f12,
          'sales.get_return_exchange_detail': f12,
        }));

    test('assert actor keeps DATA_SCOPE_DENIED', () {
      final body = _lastFunctionBlock(_readMigration(f06), 'sales._assert_sales_actor');
      expect(body, contains('if not iam.can_access_store(p_tenant_id, p_store_id, p_actor_id) then'));
      expect(body, contains("'DATA_SCOPE_DENIED'"));
    });

    test('list/search keep per-order store filter', () {
      final sql = _readMigration(f10);
      expect(_lastFunctionBlock(sql, 'sales.list_sales_orders'),
          contains('and iam.can_access_store(list_sales_orders.tenant_id, o.store_id, list_sales_orders.actor_id)'));
      expect(_lastFunctionBlock(sql, 'sales.search_sales_orders'),
          contains('and iam.can_access_store(search_sales_orders.tenant_id, o.store_id, search_sales_orders.actor_id)'));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: Viết lại khối scope trong 20 hàm** (định nghĩa cuối trong 4 file). Ba dạng:

(a) `_assert_sales_actor` — thay:
```sql
  if not exists (
    select 1
    from iam.membership_store_scopes scope
    join iam.stores store
      on store.id = scope.store_id
     and store.tenant_id = scope.tenant_id
    where scope.tenant_id = p_tenant_id
      and scope.user_id = p_actor_id
      and scope.store_id = p_store_id
      and store.status = 'active'
  ) then
```
bằng `  if not iam.can_access_store(p_tenant_id, p_store_id, p_actor_id) then`

(b) Kiểm tra theo đơn — dạng:
```sql
  if not exists (
    select 1 from iam.membership_store_scopes scope
    where scope.tenant_id = <T>
      and scope.user_id = <A>
      and scope.store_id = <S>
  ) then
```
→ `  if not iam.can_access_store(<T>, <S>, <A>) then` (vd `get_sales_order`: `iam.can_access_store(p_tenant_id, v_order.store_id, p_actor_id)`; `precheck_return_exchange`: `iam.can_access_store(precheck_return_exchange.tenant_id, v_order.store_id, precheck_return_exchange.actor_id)`).

(c) Lọc danh sách (`list_sales_orders`, `search_sales_orders`) — thay:
```sql
        and exists (
          select 1
          from iam.membership_store_scopes scope
          where scope.tenant_id = list_sales_orders.tenant_id
            and scope.user_id = list_sales_orders.actor_id
            and scope.store_id = o.store_id
        )
```
bằng `        and iam.can_access_store(list_sales_orders.tenant_id, o.store_id, list_sales_orders.actor_id)` (tương tự `search_sales_orders.*`).

Khối khác dạng: lấy `<T>` từ `scope.tenant_id = …`, `<A>` từ `scope.user_id = …`, `<S>` từ `scope.store_id = …`; bỏ phần `join iam.stores` / `store.status`.

- [ ] **Step 4: Chạy test, xác nhận pass.**

- [ ] **Step 5: Dừng — tóm tắt.** Đề xuất commit: `refactor(sales): check store access through iam.can_access_store`.

---

### Task 4: Catalog + Pricing (file owner)

**Files:**
- Modify: test file + `20260830002_catalog_sales_sellable_lookup_group_a.sql`, `20260831001_catalog_sellable_lookup_by_ids.sql`, `20260830003_pricing_sales_working_state_preview_group_a.sql`

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('catalog/pricing store access', () {
    test('6 functions use can_access_store', () => _expectUsesStoreAccess(const {
          'catalog.search_sellable_products': '20260830002_catalog_sales_sellable_lookup_group_a.sql',
          'catalog.resolve_sellable_barcode': '20260830002_catalog_sales_sellable_lookup_group_a.sql',
          'catalog.list_sellable_product_units': '20260830002_catalog_sales_sellable_lookup_group_a.sql',
          'catalog.resolve_sellable_products': '20260831001_catalog_sellable_lookup_by_ids.sql',
          'pricing.preview_sales_working_state_pricing': '20260830003_pricing_sales_working_state_preview_group_a.sql',
          'pricing.evaluate_sales_manual_price': '20260830003_pricing_sales_working_state_preview_group_a.sql',
        }));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: Catalog (4 hàm)** — thay khối
```sql
  if not exists (
    select 1
    from iam.membership_store_scopes scope
    join iam.stores store
      on store.id = scope.store_id
     and store.tenant_id = scope.tenant_id
    where scope.tenant_id = p_tenant_id
      and scope.user_id = auth.uid()
      and scope.store_id = p_store_id
      and store.tenant_id = p_tenant_id
      and store.status = 'active'
  ) then
```
bằng `  if not iam.can_access_store(p_tenant_id, p_store_id, auth.uid()) then` (giữ `raise exception 'store access denied';`). Nếu khối không có dòng `and store.tenant_id = p_tenant_id`, áp cùng quy tắc.

- [ ] **Step 4: Pricing (2 hàm)** — thay khối `if not exists ( select 1 from iam.membership_store_scopes scope join iam.stores store … where scope.tenant_id = p_tenant_id and scope.user_id = v_actor_id and scope.store_id = p_store_id and store.status = 'active' ) then` bằng `  if not iam.can_access_store(p_tenant_id, p_store_id, v_actor_id) then`.

- [ ] **Step 5: Chạy test, xác nhận pass.**

- [ ] **Step 6: Dừng — tóm tắt.** Đề xuất commit: `refactor(catalog,pricing): check store access through iam.can_access_store`.

---

### Task 5: Cập nhật test cũ + kiểm chứng

- [ ] **Step 1: Sửa SQL contract test cũ**
- Trong `sales_shared_rpc_helpers_sql_contract_test.dart`, `sales_post_sale_actions_group_f_sql_contract_test.dart`, `sales_inquiry_group_f_sql_contract_test.dart`, `sales_read_group_e_sql_contract_test.dart`, `catalog_sales_sellable_lookup_sql_contract_test.dart`, `catalog_sellable_lookup_by_ids_sql_contract_test.dart`, `pricing_sales_working_state_preview_contract_test.dart`: đổi assertion `contains('membership_store_scopes')` / `contains('iam.membership_store_scopes')` thành `contains('iam.can_access_store(')`.
- Xoá file `modules/iam/infrastructure/test/sql/iam_membership_store_scope_lifecycle_sql_contract_test.dart` (kiểm tra hàm `_ensure_membership_default_store_scope` đã bị xoá).

- [ ] **Step 2: Grep** — `grep -rn "membership_store_scopes\|_ensure_membership_default_store_scope" supabase/migrations/*.sql`
Expected: chỉ còn trong thân hàm plpgsql **bản cũ** ở `20260830001` (`get_session_context`, `bootstrap_owner(text)`); không còn câu lệnh chạy trực tiếp.

- [ ] **Step 3: Chạy test**
- `cd modules/iam/infrastructure && dart test test/iam_refactor_06_store_scopes_sql_contract_test.dart test/iam_refactor_03_memberships_sql_contract_test.dart`
- `cd modules/sales/infrastructure && dart test test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart test/domain/sales_order`
- `cd modules/catalog/infrastructure && dart test test/catalog_sales_sellable_lookup_sql_contract_test.dart test/catalog_sellable_lookup_by_ids_sql_contract_test.dart`
- `cd modules/pricing/infrastructure && dart test test/sql/pricing_sales_working_state_preview_contract_test.dart`

Expected: PASS (ngoài baseline fail sẵn).

- [ ] **Step 4: Policy** — `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` rồi `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK; `REGISTRY.yaml` có `can_access_store: 20260830001_iam_active_store_context_group_a.sql`, không còn `_ensure_membership_default_store_scope`.

- [ ] **Step 5: Tiến độ spec** — dòng bảng 6 README: `… · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 6: Dừng — user reset + smoke test**

Sau `supabase db reset`:
```sql
select to_regclass('iam.membership_store_scopes');   -- null
```
Smoke test ERP: owner + staff đăng nhập vào được cửa hàng; tìm/quét sản phẩm bán; giá tạm tính + chỉnh giá tay; tạo đơn, danh sách/chi tiết đơn, thanh toán, hoá đơn; huỷ đơn; đổi trả. Staff tạm ngưng → bị từ chối truy cập cửa hàng. Onboarding owner mới + mời staff email mới → thành công.
Đề xuất commit: `test: update store access contract tests after removing membership_store_scopes`.
