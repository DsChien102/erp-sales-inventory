# IAM refactor — Bảng 2 `iam.tenant_legal_profiles` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mã số thuế chỉ lưu chữ số 10–13 ký tự (tự bỏ dấu `-`), onboarding không copy tỉnh/xã liên hệ sang hồ sơ pháp lý, và loại chủ thể onboarding lấy từ dropdown thay vì tự đoán — **sửa trực tiếp migration gốc**.

**Architecture:** Task 1 thêm CHECK MST vào `create table` gốc. Task 2 sửa định nghĩa cuối của `upsert_legal_profile` và `create_tenant_onboarding` (chữ ký mới 19 tham số, drop chữ ký cũ ngay tại file owner). Task 3–4 Dart: validator MST và truyền loại chủ thể qua onboarding.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`; Flutter `flutter_test` (apps admin/erp).

**Spec:** [02-tenant-legal-profiles.md](../specs/iam-schema-refactor/02-tenant-legal-profiles.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement** (README spec). Chạy sau plan [bảng 1](2026-09-17-iam-refactor-01-tenants.md) (thân `create_tenant_onboarding` đã sửa ở plan 1).
- MST lưu DB: `^[0-9]{10,13}$`, chung mọi loại chủ thể. Chuẩn hoá = bỏ mọi ký tự không phải số.
- Thông báo lỗi MST (UI): `Mã số thuế phải gồm 10–13 chữ số.`
- Loại chủ thể hợp lệ: `HOUSEHOLD_BUSINESS`, `ENTERPRISE`. Có tên pháp lý + MST mà thiếu/sai loại → lỗi (`ValidationException` ở command, `VALIDATION_ERROR` ở RPC).
- Onboarding ghi `tenant_legal_profiles.province_code/commune_code = null`.
- Chỉ `create_tenant_onboarding` đổi chữ ký (thêm tham số cuối `p_org_legal_entity_type text default null`); `upsert_legal_profile` giữ nguyên.
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Không `dart format` cả package; không đổi layout UI ngoài việc bỏ 1 item dropdown.
- Trước khi sửa hàm/class: `node .gitnexus/run.cjs impact "<symbol>" --direction upstream --repo .`; hàm SQL → `UNKNOWN`.
- Sửa **cả hai** app `apps/admin` và `apps/erp` ở các file trùng nhau.

## Khảo sát

| Đối tượng | File | Ghi chú |
|---|---|---|
| `create table iam.tenant_legal_profiles` chạy **đầu tiên** | `20260811006_iam_create_tenant_onboarding.sql` | Thêm CHECK ở đây (bản trong `20260811015` là `if not exists` → no-op; thêm cho đồng bộ) |
| `upsert_legal_profile` (định nghĩa cuối) | `20260826002_iam_tenant_audit_history_v2_payloads.sql` | |
| `create_tenant_onboarding` (định nghĩa cuối) | `20260916004_iam_patch_onboarding_default_store_scope.sql` | Các file trước tạo bản 18 tham số → phải `drop` trước khi tạo bản 19 tham số, tránh 2 overload |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260811006_iam_create_tenant_onboarding.sql`, `20260811015_iam_tenant_profile_legal.sql` | CHECK MST |
| Modify `supabase/migrations/20260826002_iam_tenant_audit_history_v2_payloads.sql` | `upsert_legal_profile` |
| Modify `supabase/migrations/20260916004_iam_patch_onboarding_default_store_scope.sql` | `create_tenant_onboarding` + drop/grant |
| Create `modules/iam/infrastructure/test/iam_refactor_02_legal_profiles_sql_contract_test.dart` | SQL contract test |
| Modify `modules/iam/domain/lib/src/tenant/rules/tax_code_format_rule.dart` + Create `modules/iam/domain/test/tax_code_format_rule_test.dart` | Rule |
| Modify `apps/{admin,erp}/lib/features/iam/presentation/organization_profile/bloc/organization_profile_cubit.dart`, `…/views/organization_legal_profile_form_page.dart` + test cubit | Validator |
| Modify onboarding Dart (command/validator/handler/port/stub/test/gateway/cubit/page/widget) | Loại chủ thể |

---

### Task 1: CHECK định dạng MST tại `create table` gốc

**Files:**
- Create: `modules/iam/infrastructure/test/iam_refactor_02_legal_profiles_sql_contract_test.dart`
- Modify: `supabase/migrations/20260811006_iam_create_tenant_onboarding.sql`
- Modify: `supabase/migrations/20260811015_iam_tenant_profile_legal.sql`

**Interfaces:**
- Produces: constraint `tenant_legal_profiles_tax_code_format_chk`; helper test `_readMigration`, `_lastFunctionBlock`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 2 `iam.tenant_legal_profiles`
/// (docs/superpowers/specs/iam-schema-refactor/02-tenant-legal-profiles.md).
void main() {
  group('legal profile DDL', () {
    test('both create table statements carry the 10-13 digit tax code check', () {
      for (final file in const [
        '20260811006_iam_create_tenant_onboarding.sql',
        '20260811015_iam_tenant_profile_legal.sql',
      ]) {
        final sql = _readMigration(file);
        final start = sql.indexOf('create table if not exists iam.tenant_legal_profiles (');
        final table = sql.substring(start, sql.indexOf('\n);', start));
        expect(
          table,
          contains("constraint tenant_legal_profiles_tax_code_format_chk\n    check (tax_code ~ '^[0-9]{10,13}\$')"),
          reason: file,
        );
      }
    });
  });
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

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_02_legal_profiles_sql_contract_test.dart`
Expected: FAIL.

- [ ] **Step 3: Sửa 2 câu `create table iam.tenant_legal_profiles`**

Trong **cả** `20260811006_…` và `20260811015_…`, thay:
```sql
  constraint tenant_legal_profiles_entity_type_chk
    check (legal_entity_type in ('HOUSEHOLD_BUSINESS', 'ENTERPRISE'))
);
```
bằng:
```sql
  constraint tenant_legal_profiles_entity_type_chk
    check (legal_entity_type in ('HOUSEHOLD_BUSINESS', 'ENTERPRISE')),
  constraint tenant_legal_profiles_tax_code_format_chk
    check (tax_code ~ '^[0-9]{10,13}$')
);
```

- [ ] **Step 4: Chạy test, xác nhận pass.**

- [ ] **Step 5: Dừng — tóm tắt.** Đề xuất commit: `feat(iam): enforce digits-only 10-13 tax code on legal profiles`.

---

### Task 2: `upsert_legal_profile` + `create_tenant_onboarding` (file owner)

**Files:**
- Modify: test file
- Modify: `supabase/migrations/20260826002_iam_tenant_audit_history_v2_payloads.sql`
- Modify: `supabase/migrations/20260916004_iam_patch_onboarding_default_store_scope.sql`

**Interfaces:**
- Produces:
  - `iam.upsert_legal_profile(uuid, text, text, text, text, text, text, int, boolean)` — chuẩn hoá MST; sai định dạng → `VALIDATION_ERROR`.
  - `iam.create_tenant_onboarding(uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text, text)` — tham số cuối `p_org_legal_entity_type text default null`; bản 18 tham số bị drop.

- [ ] **Step 1: Thêm test (fail)**

```dart
  group('legal profile rpcs (final definitions)', () {
    final upsertSql = _readMigration('20260826002_iam_tenant_audit_history_v2_payloads.sql');
    final onboardingSql = _readMigration('20260916004_iam_patch_onboarding_default_store_scope.sql');

    test('upsert normalizes tax code and validates format', () {
      final body = _lastFunctionBlock(upsertSql, 'iam.upsert_legal_profile');
      expect(body, contains(r"v_tax_code text := regexp_replace(coalesce(p_tax_code, ''), '\D', '', 'g');"));
      expect(body, contains(r"if v_tax_code !~ '^[0-9]{10,13}$' then"));
      expect(body, contains('where lp.tax_code = v_tax_code'));
      expect(body, contains('    v_tax_code,\n'));
      expect(body, isNot(contains('    p_tax_code,\n')));
    });

    test('onboarding drops 18-arg signature before creating 19-arg and grants it', () {
      final drop = onboardingSql.indexOf(
        'drop function if exists iam.create_tenant_onboarding(\n'
        '  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text\n'
        ');',
      );
      final create = onboardingSql.indexOf('create or replace function iam.create_tenant_onboarding(');
      expect(drop, isNonNegative);
      expect(create, greaterThan(drop));
      expect(
        onboardingSql,
        contains(
          'grant execute on function iam.create_tenant_onboarding(\n'
          '  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text, text\n'
          ') to authenticated;',
        ),
      );
    });

    test('onboarding takes legal entity type, normalizes tax code, nulls legal province/commune', () {
      final body = _lastFunctionBlock(onboardingSql, 'iam.create_tenant_onboarding');
      expect(body, contains('p_org_legal_entity_type text default null'));
      expect(body, contains("not in ('HOUSEHOLD_BUSINESS', 'ENTERPRISE')"));
      expect(body, isNot(contains("then 'HOUSEHOLD_BUSINESS'")));
      expect(body, contains(r"nullif(regexp_replace(coalesce(p_org_tax_code, ''), '\D', '', 'g'), '')"));
      expect(body, contains('      v_org_registered_address_text,\n      null,\n      null,'));
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail.**

- [ ] **Step 3: `upsert_legal_profile`** (`20260826002_…`, định nghĩa cuối)

1. `declare`: sau `  v_audit_before jsonb;` thêm `  v_tax_code text := regexp_replace(coalesce(p_tax_code, ''), '\D', '', 'g');`
2. Ngay sau khối
```sql
  if not iam.has_permission(p_tenant_id, 'tenant.legal_profile.update') then
    raise exception 'PERMISSION_DENIED';
  end if;
```
thêm:
```sql

  if v_tax_code !~ '^[0-9]{10,13}$' then
    raise exception 'VALIDATION_ERROR';
  end if;
```
3. `  where lp.tax_code = p_tax_code` → `  where lp.tax_code = v_tax_code`
4. Trong `values (` của insert: `    p_tax_code,` → `    v_tax_code,`

- [ ] **Step 4: `create_tenant_onboarding`** (`20260916004_…`)

1. Ngay trước `create or replace function iam.create_tenant_onboarding(` thêm:
```sql
drop function if exists iam.create_tenant_onboarding(
  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text
);

```
2. Tham số cuối: `  p_org_registered_address_text text default null\n)` → `  p_org_registered_address_text text default null,\n  p_org_legal_entity_type text default null\n)`
3. `declare`: thay `  v_org_tax_code text := nullif(trim(coalesce(p_org_tax_code, '')), '');` bằng:
```sql
  v_org_tax_code text := nullif(regexp_replace(coalesce(p_org_tax_code, ''), '\D', '', 'g'), '');
  v_org_legal_entity_type text := nullif(upper(trim(coalesce(p_org_legal_entity_type, ''))), '');
```
4. Ngay sau khối `if p_org_name is null or trim(p_org_name) = '' then raise exception 'organization name required'; end if;` thêm:
```sql

  if v_org_legal_name is not null and v_org_tax_code is not null then
    if v_org_legal_entity_type is null
       or v_org_legal_entity_type not in ('HOUSEHOLD_BUSINESS', 'ENTERPRISE') then
      raise exception 'VALIDATION_ERROR';
    end if;
    if v_org_tax_code !~ '^[0-9]{10,13}$' then
      raise exception 'VALIDATION_ERROR';
    end if;
  end if;
```
5. Trong `insert into iam.tenant_legal_profiles … values (`, thay:
```sql
      v_tenant_id,
      case
        when length(regexp_replace(v_org_tax_code, '\D', '', 'g')) = 12
          then 'HOUSEHOLD_BUSINESS'
        else 'ENTERPRISE'
      end,
      v_org_legal_name,
      v_org_tax_code,
      v_org_registered_address_text,
      nullif(trim(coalesce(p_org_province_code, '')), ''),
      nullif(trim(coalesce(p_org_commune_code, '')), ''),
      v_now, v_now
```
bằng:
```sql
      v_tenant_id,
      v_org_legal_entity_type,
      v_org_legal_name,
      v_org_tax_code,
      v_org_registered_address_text,
      null,
      null,
      v_now, v_now
```
6. Cuối file, thay 2 khối `revoke`/`grant` dùng chữ ký 18 kiểu bằng chữ ký 19 kiểu (thêm một `text` cuối):
```sql
revoke all on function iam.create_tenant_onboarding(
  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text, text
) from public, anon;
grant execute on function iam.create_tenant_onboarding(
  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text, text
) to authenticated;
```

- [ ] **Step 5: Chạy test, xác nhận pass.**

- [ ] **Step 6: Policy + test cũ**

Run: `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
Run: `cd modules/iam/infrastructure && dart test test/iam_create_tenant_onboarding_new_owner_sql_contract_test.dart test/supabase_platform_admin_gateway_onboarding_test.dart` → nếu assertion cũ kiểm tra bản 18 tham số / tự đoán loại chủ thể thì cập nhật theo nội dung mới.

- [ ] **Step 7: Dừng — tóm tắt.** Lưu ý: sau reset, app admin cũ (chưa có Task 4) onboarding có MST sẽ lỗi `VALIDATION_ERROR` → build app cùng Task 4. Đề xuất commit: `feat(iam): normalize tax code and take onboarding legal entity type`.

---

### Task 3: Dart — validator MST 10–13 chữ số, tự bỏ dấu

**Files:**
- Modify: `modules/iam/domain/lib/src/tenant/rules/tax_code_format_rule.dart`
- Create: `modules/iam/domain/test/tax_code_format_rule_test.dart`
- Modify: `apps/admin/lib/features/iam/presentation/organization_profile/bloc/organization_profile_cubit.dart`
- Modify: `apps/erp/lib/features/iam/presentation/organization_profile/bloc/organization_profile_cubit.dart`
- Modify: `apps/admin/lib/features/iam/presentation/organization_profile/views/organization_legal_profile_form_page.dart`
- Modify: `apps/erp/lib/features/iam/presentation/organization_profile/views/organization_legal_profile_form_page.dart`
- Test: `apps/admin/test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart`
- Test: `apps/erp/test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart`

**Interfaces:**
- Produces: `TaxCodeFormatRule.normalize(String raw) → String` (static); constructor giữ nguyên; `isBroken()` = độ dài sau chuẩn hoá ngoài 10–13; `message` = `'Mã số thuế phải gồm 10–13 chữ số.'`.

- [ ] **Step 1: Test domain rule (fail)**

Tạo `modules/iam/domain/test/tax_code_format_rule_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:vet45_iam_domain/domain.dart';

void main() {
  group('TaxCodeFormatRule', () {
    bool broken(String taxCode, [LegalEntityType type = LegalEntityType.enterprise]) =>
        TaxCodeFormatRule(entityType: type, taxCode: taxCode).isBroken();

    test('normalize strips every non-digit', () {
      expect(TaxCodeFormatRule.normalize(' 0101234567-001 '), '0101234567001');
    });

    test('accepts 10 to 13 digits for any entity type', () {
      expect(broken('0101234567'), isFalse);
      expect(broken('01012345678'), isFalse);
      expect(broken('010123456789', LegalEntityType.enterprise), isFalse);
      expect(broken('0101234567001', LegalEntityType.householdBusiness), isFalse);
    });

    test('accepts dashed input after normalization', () {
      expect(broken('0101234567-001'), isFalse);
    });

    test('rejects fewer than 10 or more than 13 digits', () {
      expect(broken('123456789'), isTrue);
      expect(broken('01012345670011'), isTrue);
      expect(broken('---'), isTrue);
    });
  });
}
```

(`TaxCodeFormatRule` đã được export trong `modules/iam/domain/lib/domain.dart`.)

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/iam/domain && dart test test/tax_code_format_rule_test.dart`
Expected: FAIL — `normalize` không tồn tại / độ dài 13 bị coi là sai.

- [ ] **Step 3: Sửa rule**

Thay toàn bộ `modules/iam/domain/lib/src/tenant/rules/tax_code_format_rule.dart`:

```dart
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../legal_entity_type.dart';

/// Tax code must be 10–13 digits after stripping non-digit characters,
/// for every legal entity type (IAM refactor bảng 2 ④).
final class TaxCodeFormatRule implements IBusinessRule {
  TaxCodeFormatRule({
    required this.entityType,
    required String taxCode,
  }) : _taxCode = normalize(taxCode);

  static const int minLength = 10;
  static const int maxLength = 13;

  /// Removes every non-digit character (`0101234567-001` → `0101234567001`).
  static String normalize(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  final LegalEntityType entityType;
  final String _taxCode;

  @override
  bool isBroken() =>
      _taxCode.length < minLength || _taxCode.length > maxLength;

  @override
  String get message => 'Mã số thuế phải gồm 10–13 chữ số.';
}
```

- [ ] **Step 4: Chạy test, xác nhận pass** — Expected: PASS (4 test).

- [ ] **Step 5: Test cubit (fail) — admin**

Trong `apps/admin/test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart`, thêm trước `}` cuối `main()`:

```dart
  test('upsertLegal strips dashes and sends digits-only 13-digit tax code', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.legalUpsertOk),
    );
    final cubit = buildCubit(module);
    await cubit.load();

    await cubit.upsertLegal(
      const LegalProfileFormInput(
        legalEntityType: 'ENTERPRISE',
        legalName: 'Chi nhanh',
        taxCode: '0101234567-001',
      ),
      allowDuplicateTaxCode: false,
    );

    final command = module.commandsOf<UpsertLegalProfileCommand>().single;
    expect(command.taxCode, '0101234567001');
    await cubit.close();
  });

  test('upsertLegal rejects tax code outside 10-13 digits', () async {
    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.legalUpsertOk),
    );
    final cubit = buildCubit(module);
    await cubit.load();

    final ok = await cubit.upsertLegal(
      const LegalProfileFormInput(
        legalEntityType: 'HOUSEHOLD_BUSINESS',
        legalName: 'Ho kinh doanh',
        taxCode: '12345-6789',
      ),
      allowDuplicateTaxCode: false,
    );

    expect(ok, isFalse);
    expect(module.commandsOf<UpsertLegalProfileCommand>(), isEmpty);
    expect(cubit.state.failure?.code, IamBlockedCodes.validationError);
    expect(cubit.state.failure?.message, 'Mã số thuế phải gồm 10–13 chữ số.');
    await cubit.close();
  });
```

Nếu `LegalProfileFormInput` yêu cầu thêm tham số bắt buộc, bổ sung như `legalInput` ở đầu file.

- [ ] **Step 6: Chạy test, xác nhận fail**

Run: `cd apps/admin && flutter test test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart`
Expected: 2 test mới FAIL.

- [ ] **Step 7: Sửa cubit — admin**

Trong `apps/admin/lib/features/iam/presentation/organization_profile/bloc/organization_profile_cubit.dart`:

1. Trong `_validateLegalInput`, thay:
```dart
    final digits = input.taxCode.replaceAll(RegExp(r'\D'), '');
    final expected = switch (type) {
      LegalEntityType.enterprise => 10,
      LegalEntityType.householdBusiness => 12,
    };
    if (digits.length != expected || digits != input.taxCode.trim()) {
      return IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: type == LegalEntityType.enterprise
            ? 'Mã số thuế doanh nghiệp phải đúng 10 chữ số.'
            : 'Mã số thuế hộ kinh doanh phải đúng 12 chữ số.',
      );
    }
```
bằng:
```dart
    final taxRule = TaxCodeFormatRule(entityType: type, taxCode: input.taxCode);
    if (taxRule.isBroken()) {
      return IamUiFailure(
        code: IamBlockedCodes.validationError,
        message: taxRule.message,
      );
    }
```
2. Trong `upsertLegal`: `          taxCode: input.taxCode.trim(),` → `          taxCode: TaxCodeFormatRule.normalize(input.taxCode),`

- [ ] **Step 8: Sửa form page — admin**

Trong `apps/admin/lib/features/iam/presentation/organization_profile/views/organization_legal_profile_form_page.dart`, thay:
```dart
    } else if (type != null) {
      final expected = switch (type) {
        LegalEntityType.enterprise => 10,
        LegalEntityType.householdBusiness => 12,
      };
      if (tax.length != expected || !RegExp(r'^\d+$').hasMatch(tax)) {
        _taxCodeError = type == LegalEntityType.enterprise
            ? 'Mã số thuế doanh nghiệp phải đúng 10 chữ số.'
            : 'Mã số thuế hộ kinh doanh phải đúng 12 chữ số.';
        ok = false;
      } else {
        _taxCodeError = null;
      }
    } else {
```
bằng:
```dart
    } else if (type != null) {
      final taxRule = TaxCodeFormatRule(entityType: type, taxCode: tax);
      if (taxRule.isBroken()) {
        _taxCodeError = taxRule.message;
        ok = false;
      } else {
        _taxCodeError = null;
      }
    } else {
```
Nếu thiếu import `package:vet45_iam_domain/domain.dart` thì thêm.

- [ ] **Step 9: Chạy test admin, xác nhận pass**

Run: `cd apps/admin && flutter test test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart test/features/iam/presentation_module/widgets/organization_legal_profile_form_page_test.dart`
Expected: PASS.

- [ ] **Step 10: Lặp lại Step 5, 7, 8 cho ERP** (thay `apps/admin` bằng `apps/erp`)

Run: `cd apps/erp && flutter test test/features/iam/presentation_module/organization_profile/organization_profile_cubit_test.dart test/features/iam/presentation_module/widgets/organization_legal_profile_form_page_test.dart`
Expected: PASS.

- [ ] **Step 11: Dừng — tóm tắt.** Đề xuất commit: `feat(iam): accept 10-13 digit tax codes and strip dashes`.

---

### Task 4: Dart — onboarding truyền loại chủ thể

**Files:**
- Modify: `modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command.dart`
- Modify: `modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command_validator.dart`
- Modify: `modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command_handler.dart`
- Modify: `modules/iam/application/lib/src/ports/i_platform_admin_gateway.dart`
- Modify: `modules/iam/application/test/support/stub_platform_admin_gateway.dart`
- Modify: `modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`
- Modify: `modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart`
- Modify: `modules/iam/infrastructure/test/supabase_platform_admin_gateway_onboarding_test.dart`
- Modify: `apps/admin/lib/features/organizations/presentation/bloc/platform_onboarding_cubit.dart`
- Modify: `apps/admin/lib/features/organizations/presentation/pages/platform_onboarding_page.dart`
- Modify: `apps/admin/lib/features/iam/presentation/widgets/platform_onboarding_step_organization.dart`
- Modify: `docs/superpowers/specs/iam-schema-refactor/README.md`

**Interfaces:**
- Consumes: RPC tham số `p_org_legal_entity_type` (Task 2).
- Produces: `CreateTenantOnboardingCommand.legalEntityType` (`String?`); `IPlatformAdminGateway.createTenantOnboarding({…, String? legalEntityType, …})`; `PlatformOnboardingCubit.submit({…, String? legalEntityType})`.

- [ ] **Step 1: Test application (fail)**

Trong `modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`:
1. `_IdempotentPlatformGateway`: thêm field `String? lastLegalEntityType;` (cạnh `lastTaxCode`), tham số `String? legalEntityType,` vào override `createTenantOnboarding` (sau `String? taxCode,`), dòng `lastLegalEntityType = legalEntityType;` (sau `lastTaxCode = taxCode;`).
2. Test `'passes optional organization profile and legal fields to gateway'`: thêm `legalEntityType: 'ENTERPRISE',` (sau `taxCode: '0123456789',`) và `expect(gateway.lastLegalEntityType, 'ENTERPRISE');` cuối test.
3. Thêm sau test `'validator rejects empty org name'`:

```dart
    test('validator requires legal entity type when legal name and tax code given', () async {
      expect(
        () => CreateTenantOnboardingCommandValidator().validate(
          CreateTenantOnboardingCommand(
            owner: OnboardingOwnerInput.existing('u-1'),
            organizationName: 'Store',
            legalName: 'Store Legal Co',
            taxCode: '0123456789',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validator rejects unknown legal entity type', () async {
      expect(
        () => CreateTenantOnboardingCommandValidator().validate(
          CreateTenantOnboardingCommand(
            owner: OnboardingOwnerInput.existing('u-1'),
            organizationName: 'Store',
            legalName: 'Store Legal Co',
            taxCode: '0123456789',
            legalEntityType: 'VETERINARY_CLINIC',
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
```

`modules/iam/application/test/support/stub_platform_admin_gateway.dart`: thêm `String? legalEntityType,` sau `String? taxCode,` trong `createTenantOnboarding`.

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/iam/application && dart test test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`
Expected: FAIL biên dịch.

- [ ] **Step 3: Command, port, handler, validator**

`create_tenant_onboarding_command.dart`: thêm `this.legalEntityType,` sau `this.taxCode,` và field (sau `final String? taxCode;`):
```dart
  /// `HOUSEHOLD_BUSINESS` | `ENTERPRISE`; required when legal name + tax code given.
  final String? legalEntityType;
```

`i_platform_admin_gateway.dart`: thêm `String? legalEntityType,` sau `String? taxCode,` trong `createTenantOnboarding`.

`create_tenant_onboarding_command_handler.dart`: trong **cả hai** lời gọi `_platformGateway.createTenantOnboarding(`, thêm `legalEntityType: command.legalEntityType,` sau `taxCode: command.taxCode,`.

`create_tenant_onboarding_command_validator.dart`: thêm import `package:vet45_iam_domain/domain.dart`; ngay sau khối kiểm tra `idempotencyKey`:

```dart
    final hasLegal = (command.legalName ?? '').trim().isNotEmpty &&
        (command.taxCode ?? '').trim().isNotEmpty;
    if (hasLegal) {
      final type = LegalEntityTypeCodes.fromCode(command.legalEntityType);
      if (type == null) {
        throw ValidationException('Legal entity type is required');
      }
      if (TaxCodeFormatRule(entityType: type, taxCode: command.taxCode!)
          .isBroken()) {
        throw ValidationException('Tax code must be 10-13 digits');
      }
    }
```

- [ ] **Step 4: Chạy test application, xác nhận pass**

Run: `cd modules/iam/application && dart test test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart test/sign_in_command_handler_test.dart`
Expected: PASS.

- [ ] **Step 5: Gateway Supabase (test fail → pass)**

`modules/iam/infrastructure/test/supabase_platform_admin_gateway_onboarding_test.dart`: thêm `expect(params?['p_org_legal_entity_type'], 'ENTERPRISE');` sau assert `p_org_tax_code`, và `legalEntityType: 'ENTERPRISE',` sau `taxCode: '0123456789',` trong lời gọi. Run → FAIL.

`supabase_platform_admin_gateway.dart`: thêm `String? legalEntityType,` sau `String? taxCode,` trong chữ ký `createTenantOnboarding`, và `'p_org_legal_entity_type': legalEntityType,` sau `'p_org_tax_code': taxCode,`. Run lại → PASS.

- [ ] **Step 6: Admin app — cubit, page, widget**

`platform_onboarding_cubit.dart` (`submit`): thêm `String? legalEntityType,` sau `String? taxCode,` và `legalEntityType: legalEntityType,` sau `taxCode: taxCode,` trong `CreateTenantOnboardingCommand(`.

`platform_onboarding_page.dart` (lời gọi `.submit(`): thêm sau dòng `taxCode: …,`:
```dart
      legalEntityType: _selectedEntityType,
```

`platform_onboarding_step_organization.dart`:
1. Trong `displayTextForValue`, xoá dòng `              'VETERINARY_CLINIC' => 'Phòng khám thú y',`
2. Trong `VComboboxList(children: const [ … ])`, xoá item:
```dart
                      VComboboxItem<String>(
                        value: 'VETERINARY_CLINIC',
                        searchText: 'Phòng khám thú y',
                        child: Text('Phòng khám thú y'),
                      ),
```

- [ ] **Step 7: Chạy test admin onboarding**

Run: `cd apps/admin && flutter test test/features/users/presentation/pages/platform_onboarding_page_test.dart`
Expected: PASS.

Run: `grep -rn "VETERINARY_CLINIC" apps modules --include='*.dart' | grep -v /build/`
Expected: không còn kết quả.

- [ ] **Step 8: Cập nhật tiến độ spec**

Dòng bảng 2 trong README spec:
```markdown
| 2 | `iam.tenant_legal_profiles` | ✅ Đã chốt · 📝 Plan: [2026-09-17-iam-refactor-02-tenant-legal-profiles](../../plans/2026-09-17-iam-refactor-02-tenant-legal-profiles.md) · 🧪 Đã sửa migration gốc, chờ reset | [02-tenant-legal-profiles.md](02-tenant-legal-profiles.md) |
```

- [ ] **Step 9: Dừng — user reset + smoke test**

Sau `supabase db reset` + build admin:
```sql
select pg_get_function_identity_arguments(p.oid)
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'iam' and p.proname = 'create_tenant_onboarding';
```
Expected: đúng **1** dòng, kết thúc bằng `p_org_legal_entity_type text`.

Smoke test: onboarding chọn "Doanh nghiệp", MST `0101234567-001` → DB lưu `0101234567001`, tỉnh/xã pháp lý `null`; nhập MST + tên pháp lý không chọn loại → báo lỗi; dropdown không còn "Phòng khám thú y". Màn hồ sơ pháp lý (admin + ERP): MST có dấu `-` được chấp nhận và lưu dạng chữ số.
Đề xuất commit: `feat(iam): pass legal entity type through tenant onboarding`.
