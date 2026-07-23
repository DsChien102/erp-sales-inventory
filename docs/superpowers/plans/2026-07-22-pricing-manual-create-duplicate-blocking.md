# Pricing Manual Create Duplicate Blocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chặn tạo thủ công rule giá riêng trùng khoảng hiệu lực bằng `DUPLICATE_ACTIVE_RULE`, không tạo rule mới và không disable rule cũ.

**Architecture:** Application dùng create-context để chặn sớm trừ idempotent retry, còn RPC create vẫn là authoritative boundary và recheck duplicate dưới advisory lock. Fake và in-memory phải mô phỏng đúng lỗi; presentation giữ dữ liệu form và hiển thị thông báo chặn rõ ràng.

**Tech Stack:** Dart 3, Flutter Bloc, Supabase/PostgreSQL PL/pgSQL draft migrations, `package:test`, `flutter_test`.

## Global Constraints

- Chỉ đổi chính sách duplicate của tạo thủ công; update và reenable giữ nguyên.
- SQL chỉ sửa trong `supabase/migrations/_drafts/`; không tạo migration timestamp và không promote draft.
- Idempotent retry với cùng key/payload vẫn trả kết quả cũ dù create-context hiện có conflict.
- Mọi production change phải có test RED trước khi sửa và test GREEN sau khi sửa.
- Trước khi sửa symbol phải chạy GitNexus impact upstream; HIGH/CRITICAL phải báo người dùng trước.

---

### Task 1: Application contract và fake duplicate

**Files:**
- Modify: `modules/pricing/application/test/create_customer_price_rule_contract_test.dart`
- Modify: `modules/pricing/application/test/fake_pricing_module_test.dart`
- Modify: `modules/pricing/application/lib/src/customer_price_rule/commands/create_customer_price_rule/create_customer_price_rule_command_handler.dart`
- Modify: `modules/pricing/application/lib/src/testing/fake_pricing_module.dart`

**Interfaces:**
- Consumes: `CustomerPriceRuleCreateContext.hasConflictingRule`, `PricingBlockedCodes.duplicateActiveRule`.
- Produces: `CreateCustomerPriceRuleCommandHandler.handle(...)` và `FakePricingScenario.createRuleDuplicate` cùng trả `PricingBlockedException(DUPLICATE_ACTIVE_RULE)`.

- [ ] **Step 1: Đổi contract test sang hành vi bị chặn**

Thay test overlap của handler bằng:

```dart
test('blocks an overlapping active interval before create', () async {
  final gateway = _CommandGateway(_result());
  final handler = CreateCustomerPriceRuleCommandHandler(
    createContextPort: _ContextPort(
      _validContext().copyWith(conflictingRuleId: 'rule-existing'),
    ),
    commandGateway: gateway,
  );

  await expectLater(
    handler.handle(_command()),
    _throwsCode(PricingBlockedCodes.duplicateActiveRule),
  );
  expect(gateway.lastCandidate, isNull);
});
```

Đổi fake test thành:

```dart
test('createRuleDuplicate returns DUPLICATE_ACTIVE_RULE', () async {
  final module = FakePricingModule(
    scenario: FakePricingScenario.createRuleDuplicate,
  );

  await expectLater(
    module.executeCommandAsync(_command()),
    throwsA(
      isA<PricingBlockedException>().having(
        (error) => error.code,
        'code',
        PricingBlockedCodes.duplicateActiveRule,
      ),
    ),
  );
});
```

- [ ] **Step 2: Chạy RED application tests**

Run:

```bash
cd modules/pricing/application
dart test test/create_customer_price_rule_contract_test.dart test/fake_pricing_module_test.dart
```

Expected: hai test duplicate FAIL vì handler/fake vẫn trả success.

- [ ] **Step 3: Implement chặn sớm và fake lỗi**

Sau khi xác định `isIdempotentRetry`, thêm vào handler trước reference/floor validation:

```dart
if (!isIdempotentRetry && context.hasConflictingRule) {
  throw PricingBlockedException(
    PricingBlockedCodes.duplicateActiveRule,
    message: 'An active customer price rule already overlaps this period.',
    details: {
      if (context.conflictingRuleId != null)
        'conflictingRuleId': context.conflictingRuleId,
    },
  );
}
```

Đổi nhánh fake:

```dart
case FakePricingScenario.createRuleDuplicate:
  throw const PricingBlockedException(
    PricingBlockedCodes.duplicateActiveRule,
  );
```

- [ ] **Step 4: Chạy GREEN application tests**

Run lại lệnh Step 2. Expected: PASS, gồm test idempotent retry hiện hữu.

### Task 2: Authoritative SQL create không auto-disable

**Files:**
- Modify: `modules/pricing/infrastructure/test/pricing_sql_contract_test.dart`
- Modify: `supabase/migrations/_drafts/004_pricing_customer_price_rule_s1.sql`

**Interfaces:**
- Consumes: bảng `pricing.customer_price_rules`, helper `pricing._raise_pricing_error`, advisory key hiện hữu.
- Produces: RPC `pricing.create_customer_price_rule` trả `DUPLICATE_ACTIVE_RULE` khi interval active giao nhau; helper auto-disable vẫn còn cho update/reenable.

- [ ] **Step 1: Viết SQL contract test cô lập thân create RPC**

Trong test S1, lấy substring từ `create or replace function pricing.create_customer_price_rule(` tới revoke tương ứng rồi assert:

```dart
expect(createFunction, contains("'DUPLICATE_ACTIVE_RULE'"));
expect(createFunction, contains("r.status = 'active'"));
expect(
  createFunction,
  contains(
    "r.effective_from <= coalesce(p_effective_to, 'infinity'::date)",
  ),
);
expect(
  createFunction,
  contains(
    "p_effective_from <= coalesce(r.effective_to, 'infinity'::date)",
  ),
);
expect(
  createFunction,
  isNot(
    contains(
      'perform pricing._auto_disable_overlapping_customer_price_rules(',
    ),
  ),
);
```

Đổi assertion cũ `createFunction isNot contains('v_conflicting_rule')` thành assertion cho duplicate variable/check mới.

- [ ] **Step 2: Chạy RED SQL contract**

Run:

```bash
cd modules/pricing/infrastructure
dart test test/pricing_sql_contract_test.dart
```

Expected: FAIL vì create RPC còn gọi `_auto_disable_overlapping_customer_price_rules`.

- [ ] **Step 3: Thay auto-disable bằng authoritative duplicate check**

Khai báo:

```sql
v_conflicting_rule_id uuid;
```

Ngay sau advisory lock theo rule key, thay lời gọi helper bằng:

```sql
select r.id
into v_conflicting_rule_id
from pricing.customer_price_rules r
where r.tenant_id = p_tenant_id
  and r.customer_id = p_customer_id
  and r.product_id = p_product_id
  and r.product_unit_id = p_product_unit_id
  and r.status = 'active'
  and r.effective_from <= coalesce(p_effective_to, 'infinity'::date)
  and p_effective_from <= coalesce(r.effective_to, 'infinity'::date)
limit 1
for update;

if v_conflicting_rule_id is not null then
  perform pricing._raise_pricing_error(
    'DUPLICATE_ACTIVE_RULE',
    'An active customer price rule already overlaps this period.',
    jsonb_build_object('conflictingRuleId', v_conflicting_rule_id)
  );
end if;
```

- [ ] **Step 4: Chạy GREEN SQL contract**

Run lại lệnh Step 2. Expected: PASS.

### Task 3: ERP in-memory giữ nguyên rule cũ

**Files:**
- Modify: `apps/erp/test/features/pricing/data/in_memory_pricing_module_test.dart`
- Modify: `apps/erp/lib/features/pricing/data/in_memory_pricing_module.dart`

**Interfaces:**
- Consumes: `_findOverlapping(...)` và `PricingBlockedCodes.duplicateActiveRule`.
- Produces: `_create(...)` ném blocked exception trước mọi mutation.

- [ ] **Step 1: Đổi test SG-03 sang invariant không mutation**

Test phải capture rule cũ, gọi create và assert:

```dart
await expectLater(
  module.executeCommandAsync(buildCommand()),
  throwsA(
    isA<PricingBlockedException>().having(
      (error) => error.code,
      'code',
      PricingBlockedCodes.duplicateActiveRule,
    ),
  ),
);

final oldDetail = await module.executeQueryAsync(
  GetCustomerPriceRuleDetailQuery(
    tenantId: 't1',
    ruleId: existing.id,
    businessDate: businessDate,
  ),
);
expect(oldDetail.persistedStatus, CustomerPriceRuleStatus.active);
expect(oldDetail.version, existing.version);
```

Đồng thời assert tổng số rule không tăng.

- [ ] **Step 2: Chạy RED in-memory test**

Run:

```bash
cd apps/erp
flutter test test/features/pricing/data/in_memory_pricing_module_test.dart
```

Expected: FAIL vì `_create` đang disable rule cũ rồi tạo rule mới.

- [ ] **Step 3: Implement blocked exception trước mutation**

Trong `_create`, thay `_disableInternal(...)` bằng:

```dart
if (duplicate != null) {
  throw PricingBlockedException(
    PricingBlockedCodes.duplicateActiveRule,
    details: {'conflictingRuleId': duplicate.id},
  );
}
```

Cập nhật comment đầu module chỉ mô tả create bị chặn; giữ mô tả update/reenable theo policy hiện tại.

- [ ] **Step 4: Chạy GREEN in-memory và regression reenable/import**

Run lại lệnh Step 2. Expected: PASS, gồm test SG-05 và import partial hiện hữu.

### Task 4: Presentation báo lỗi rõ và giữ form

**Files:**
- Modify: `modules/pricing/presentation/lib/src/cubit/price_rule_form_cubit.dart`
- Modify: `modules/pricing/presentation/lib/src/widgets/price_rule_warning_banner.dart`
- Create: `modules/pricing/presentation/test/price_rule_warning_banner_test.dart`
- Modify: `apps/erp/lib/features/pricing/presentation/pages/pricing_form_page.dart`
- Modify: `apps/erp/test/features/pricing/presentation/pages/pricing_form_e2e_test.dart`

**Interfaces:**
- Consumes: `PriceRuleFormError.code == PricingBlockedCodes.duplicateActiveRule`.
- Produces: toast actionable, form vẫn là `PriceRuleFormEditing` với payload cũ sau lỗi.

- [ ] **Step 1: Viết widget/E2E tests RED**

Widget test render `PriceRuleDuplicateBanner` và expect:

```dart
expect(find.textContaining('không thể lưu'), findsOneWidget);
expect(find.textContaining('ghi đè'), findsNothing);
```

E2E dùng `FakePricingScenario.createRuleDuplicate`, điền form, submit rồi expect:

```dart
expect(
  find.text(
    'Đã tồn tại giá riêng đang hoạt động trùng thời gian. '
    'Vui lòng điều chỉnh khoảng hiệu lực hoặc chọn đối tượng khác.',
  ),
  findsOneWidget,
);
expect(findByWgtKey('wgt_e02_u04_fr01_01'), findsOneWidget);
final state = cubit.state as PriceRuleFormEditing;
expect(state.customerId, 'customer-1');
expect(state.productUnitId, 'unit-1');
expect(state.rulePriceMinor, 150000);
```

- [ ] **Step 2: Chạy RED presentation tests**

Run:

```bash
cd modules/pricing/presentation
flutter test test/price_rule_warning_banner_test.dart
cd ../../../apps/erp
flutter test test/features/pricing/presentation/pages/pricing_form_e2e_test.dart
```

Expected: banner test FAIL vì còn copy ghi đè; E2E FAIL vì fake hiện chưa/hoặc page chưa có thông báo mới.

- [ ] **Step 3: Cập nhật comments và error copy**

- Đổi comment cubit thành create duplicate bị authoritative backend chặn.
- Đổi banner message thành:

```dart
'Đã có giá riêng cho khách hàng, sản phẩm, đơn vị trong khoảng thời gian. '
'Không thể lưu rule mới; vui lòng điều chỉnh khoảng hiệu lực hoặc đối tượng áp dụng.'
```

- Map page error thành:

```dart
PricingBlockedCodes.duplicateActiveRule =>
  'Đã tồn tại giá riêng đang hoạt động trùng thời gian. '
  'Vui lòng điều chỉnh khoảng hiệu lực hoặc chọn đối tượng khác.',
```

Không reset state trong `_handleBlocked`; flow hiện hữu `Error` rồi `Editing.copyWith(isSubmitting: false)` được giữ nguyên.

- [ ] **Step 4: Chạy GREEN presentation tests**

Run lại hai lệnh Step 2. Expected: PASS.

### Task 5: Đồng bộ contract docs và verification

**Files:**
- Modify: `docs/themes/TH-04-pricing-promotions/Epic-02-customer-price-rules/US-04.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/07-api-contracts.md`

**Interfaces:**
- Produces: một policy thống nhất: manual create duplicate là blocked/no mutation; update/reenable không bị thay đổi bởi plan này.

- [ ] **Step 1: Đồng bộ docs**

- US-04 AC-02 đổi từ auto-disable thành `DUPLICATE_ACTIVE_RULE`, không mutation.
- API contract scenario `create_rule_duplicate` đổi success/auto-disable thành blocked error.
- Authoritative create flow ghi rõ recheck dưới advisory lock và giữ rule cũ.

- [ ] **Step 2: Format và chạy focused suites**

Run:

```bash
dart format modules/pricing/application modules/pricing/presentation apps/erp/lib/features/pricing/data apps/erp/test/features/pricing
cd modules/pricing/application && dart test
cd ../infrastructure && dart test test/pricing_sql_contract_test.dart test/sql/pricing_customer_price_rule_lifecycle_br070809_contract_test.dart
cd ../../presentation && flutter test
cd ../../../apps/erp && flutter test test/features/pricing/data/in_memory_pricing_module_test.dart test/features/pricing/presentation/pages/pricing_form_e2e_test.dart
```

Expected: tất cả PASS.

- [ ] **Step 3: Analyze và harness**

Run:

```bash
cd modules/pricing/application && dart analyze
cd ../infrastructure && dart analyze
cd ../../presentation && flutter analyze
cd ../../../apps/erp && flutter analyze lib/features/pricing test/features/pricing
cd ../.. && bash scripts/ci/verify_harness.sh
git diff --check
```

Expected: Pricing scopes không có error; harness chỉ có thể còn baseline ngoài Pricing đã được ghi nhận.

- [ ] **Step 4: Phân tích scope cuối**

Chạy GitNexus `detect_changes(scope: all)`, review changed symbols/processes và xác nhận task-specific diff không chạm timestamp migrations hay policy update/reenable/import ngoài regression tests.
