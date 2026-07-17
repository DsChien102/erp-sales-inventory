# TH-04 Pricing S3 Detail/Actions CONTRACT + BE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Freeze and implement the CONTRACT + BE lanes for TH-04 EP02 S3 so a tenant-scoped actor can read an authoritative customer price rule detail, current reference health, redacted floor comparison, source trace, version, and permission-aware lifecycle actions.

**Architecture:** Add one read-only CQRS query under the existing Pricing bounded context. The application handler validates shape and delegates to `IPricingReadGateway`; infrastructure binds tenant/access, calls `pricing.get_customer_price_rule_detail`, and maps the RPC response into the shared detail DTO. The RPC reads the Pricing-owned rule/snapshots and enriches current reference/price-band health only through the existing internal Partner/Catalog provider functions; it never joins provider-owned private tables and never mutates the rule.

**Tech Stack:** Dart 3, `vet45_shared_application`, `vet45_pricing_domain`, `vet45_pricing_application`, `vet45_pricing_infrastructure`, `vet45_generator`, GetIt, Supabase schema RPC, PostgreSQL draft SQL, `package:test`.

## Global Constraints

- Scope is S3 CONTRACT + BE only; do not add Pricing Presentation, ERP host DI, E2E, activity history payloads, mutations, outbox, integration events, or migration promotion.
- Read `AGENTS.md`, `.cursor/rules/vet45-architecture.mdc`, `docs/harness/PROGRESS.md`, the TH-04 agent ritual, §S3 of `07-api-contracts.md`, `US-03.md`, domain model, architecture flow, roadmap, and traceability before editing.
- Run GitNexus upstream impact before changing every existing Dart function/class/method. Warn and stop for user review if impact is HIGH or CRITICAL.
- Use `@RequiresTenant()` and `@RequiresPermission(PricingPermissions.viewCustomerPriceRule)`; tenant comes from `IExecutionContext`, and neither Dart RPC params nor SQL accept actor ID.
- Queries return application DTOs, never domain aggregates. Application must not import Supabase or infrastructure.
- Money is an integer minor-unit amount plus explicit three-letter currency. Calendar dates are UTC date-only values. Never use `double` for money.
- Write SQL only under `supabase/migrations/_drafts/`; do not create timestamped migrations, run `supabase db reset`, promote drafts, or claim drafts are applied.
- Do not read `partner.*` or `catalog.*` private tables from Pricing SQL. Call only `partner._get_customer_snapshot_for_pricing` and `catalog._get_product_price_band_snapshot_for_pricing`.
- Generated CQRS/access files are updated only by codegen.
- Do not embed activity rows in detail. The stable `history` action navigates to S10 when that slice exists.
- Preserve all unrelated worktree changes and stage only exact files owned by the current task.
- S3 CONTRACT/BE may move to `done` after Pricing-scoped gates pass. Workspace failures outside Pricing are recorded in `docs/harness/PROGRESS.md` as lane-external technical debt.

---

## Locked Contract Decisions

### Query

```dart
GetCustomerPriceRuleDetailQuery({
  String? id,
  String tenantId = '',
  required String ruleId,
  required DateTime businessDate,
})
```

- `tenantId` is replaced from execution context before access checks and dispatch.
- `ruleId` must be a canonical UUID string.
- `businessDate` is normalized with `DateTime.utc(year, month, day)`.
- RPC params are exactly `p_tenant_id`, `p_rule_id`, and `p_business_date`.

### Stable errors

```text
NO_PERMISSION
NOT_FOUND
VALIDATION_ERROR
SYSTEM_ERROR
```

Unknown, deleted, and cross-tenant rule IDs all return `NOT_FOUND`. A missing/inactive external customer or product/unit does not make the rule disappear; it returns a successful detail with reference-health issues.

### Stable actions

```text
edit
disable
reenable
history
```

| Persisted status | Permission-aware actions |
| --- | --- |
| `active` | `edit`, `disable`, `history` |
| `needs_review` | `edit`, `disable`, `history` |
| `disabled` | `edit`, `reenable`, `history` |
| `deleted` | invisible; RPC returns `NOT_FOUND` |

Derived `expired` and `not_yet_effective` do not change the action matrix. S5–S7 mutations remain authoritative for status, reference, version, and permission checks.

### Current-reference enrichment

- IDs and display labels remain Pricing-owned stored snapshots so archived references remain explainable.
- Partner/Catalog providers supply current health and current compatible list/floor prices.
- Provider `exists=false` or inactive state produces issue codes and stored price-band fallback where available.
- Provider execution failure produces `SYSTEM_ERROR`; it is not silently treated as a valid current check.
- Current below-floor state always exposes warning code `below_floor_price`. The floor amount is visible only when the actor has `PricingPermissions.overrideFloorPrice`.
- Detail live enrichment does not update persisted status, validation snapshot, version, activity, or S2 search projection.

### Stable reference issue codes

```text
customer_reference_inactive
customer_reference_missing
product_unit_reference_inactive
product_unit_reference_missing
price_band_currency_mismatch
price_band_minor_units_invalid
below_floor_price
```

### Source trace

- Basic `createdBy/createdAt/updatedBy/updatedAt` remains visible under view permission.
- Import/order trace identifiers are returned only when the actor has `PricingPermissions.viewCustomerPriceRuleHistory`.
- Without that permission, all trace identifiers are null and `sourceTrace.hidden == true`.
- S3 does not create import or memory persistence. Nullable trace fields freeze the future S8/S9 response shape.

---

## File Structure

Create:

- `modules/pricing/application/lib/src/customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query.dart`
- `modules/pricing/application/lib/src/customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query_validator.dart`
- `modules/pricing/application/lib/src/customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query_handler.dart`
- `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_derived_status.dart`
- `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_available_actions.dart`
- `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_reference_health_dto.dart`
- `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_source_trace_dto.dart`
- `modules/pricing/application/test/get_customer_price_rule_detail_contract_test.dart`
- `modules/pricing/infrastructure/lib/src/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper.dart`
- `modules/pricing/infrastructure/test/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper_test.dart`
- `supabase/migrations/_drafts/pricing_customer_price_rule_detail_s3.sql`

Modify:

- `modules/pricing/application/lib/application.dart`
- `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_detail_dto.dart`
- `modules/pricing/application/lib/src/customer_price_rule/queries/search_customer_price_rules/customer_price_rule_search_enums.dart`
- `modules/pricing/application/lib/src/customer_price_rule/queries/search_customer_price_rules/customer_price_rule_list_item_dto.dart`
- `modules/pricing/application/lib/src/ports/i_pricing_read_gateway.dart`
- `modules/pricing/application/lib/src/shared/pricing_blocked_codes.dart`
- `modules/pricing/application/lib/src/testing/fake_pricing_module.dart`
- `modules/pricing/application/test/create_customer_price_rule_contract_test.dart`
- `modules/pricing/application/test/fake_pricing_module_test.dart`
- `modules/pricing/application/test/search_customer_price_rules_contract_test.dart`
- `modules/pricing/infrastructure/lib/src/domain/customer_price_rule/pricing_rpc_mapper.dart`
- `modules/pricing/infrastructure/lib/src/domain/customer_price_rule/supabase_customer_price_rule_read_gateway.dart`
- `modules/pricing/infrastructure/lib/src/errors/pricing_error_mapper.dart`
- `modules/pricing/infrastructure/lib/src/configuration/processing/pricing_query_access_guard.dart`
- `modules/pricing/infrastructure/lib/src/configuration/pricing_startup.dart`
- `modules/pricing/infrastructure/lib/src/configuration/processing/generated/pricing_access_metadata.g.dart` via codegen
- `modules/pricing/infrastructure/lib/src/configuration/processing/generated/pricing_cqrs_registrar.g.dart` via codegen
- `modules/pricing/infrastructure/lib/src/configuration/processing/generated/pricing_module_manifest.g.dart` via codegen
- `modules/pricing/infrastructure/test/configuration/pricing_search_startup_test.dart`
- `modules/pricing/infrastructure/test/pricing_sql_contract_test.dart`
- `supabase/migrations/_drafts/pricing_customer_price_rule_s1.sql`
- `docs/themes/TH-04-pricing-promotions/Epic-02-customer-price-rules/US-03.md`
- `docs/themes/TH-04-pricing-promotions/harness/01-domain-model.md`
- `docs/themes/TH-04-pricing-promotions/harness/03-architecture-and-flows.md`
- `docs/themes/TH-04-pricing-promotions/harness/04-slice-roadmap.md`
- `docs/themes/TH-04-pricing-promotions/harness/05-traceability.md`
- `docs/themes/TH-04-pricing-promotions/harness/06-harness-notes.md`
- `docs/themes/TH-04-pricing-promotions/harness/07-api-contracts.md`
- `docs/harness/PROGRESS.md`

Do not change:

- `modules/pricing/domain/lib/src/customer_price_rule/customer_price_rule.dart` or aggregate behavior.
- Partner/Catalog private table schemas or their public client grants.
- `apps/erp/`, Pricing Presentation, integration events, worker wiring, or timestamped migrations.

---

### Task 1: Freeze Shared Detail Types and Fake Scenarios

**Files:**

- Create: `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_derived_status.dart`
- Create: `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_available_actions.dart`
- Create: `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_reference_health_dto.dart`
- Create: `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_source_trace_dto.dart`
- Modify: `modules/pricing/application/lib/src/customer_price_rule/shared/customer_price_rule_detail_dto.dart`
- Modify: `modules/pricing/application/lib/src/customer_price_rule/queries/search_customer_price_rules/customer_price_rule_search_enums.dart`
- Modify: `modules/pricing/application/lib/src/customer_price_rule/queries/search_customer_price_rules/customer_price_rule_list_item_dto.dart`
- Modify: `modules/pricing/application/lib/src/testing/fake_pricing_module.dart`
- Modify: `modules/pricing/application/lib/application.dart`
- Test: `modules/pricing/application/test/get_customer_price_rule_detail_contract_test.dart`
- Test: `modules/pricing/application/test/create_customer_price_rule_contract_test.dart`
- Test: `modules/pricing/application/test/fake_pricing_module_test.dart`
- Test: `modules/pricing/application/test/search_customer_price_rules_contract_test.dart`

**Interfaces:**

- Produces shared `CustomerPriceRuleDerivedStatus`, stable action constants, `CustomerPriceRuleReferenceHealthDto`, `CustomerPriceRuleSourceTraceDto`, and the final S3-compatible `CustomerPriceRuleDetailDto` shape.
- Preserves S1 create result and S2 list semantics while replacing detail string status/type/source fields with the typed enums already used by S2.

- [ ] **Step 1: Run GitNexus impact for existing public symbols**

Run upstream impact for:

```text
CustomerPriceRuleDetailDto
CustomerPriceRuleListItemDto
CustomerPriceRuleDerivedStatus
FakePricingScenario
FakePricingModule
```

Expected: report direct callers/tests and no unreviewed HIGH/CRITICAL risk. If the result is HIGH or CRITICAL, show the blast radius to the user before editing.

- [ ] **Step 2: Write failing shared-contract and fake tests**

Create `get_customer_price_rule_detail_contract_test.dart` with fixed UUIDs and assertions equivalent to:

```dart
test('detail contract exposes typed status, health, trace, and actions', () {
  final detail = CustomerPriceRuleDetailDto(
    id: '00000000-0000-4000-8000-000000000001',
    customer: const CustomerRefDto(
      customerId: '00000000-0000-4000-8000-000000000002',
      displayName: 'Phòng khám A',
      status: 'active',
    ),
    productUnit: const ProductUnitRefDto(
      productId: '00000000-0000-4000-8000-000000000003',
      productName: 'Vaccine A',
      productUnitId: '00000000-0000-4000-8000-000000000004',
      unitName: 'Lọ',
      sellableStatus: 'active',
    ),
    price: const MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
    effectivePeriod: EffectivePeriodDto(
      effectiveFrom: DateTime.utc(2026, 7, 1),
    ),
    ruleType: CustomerPriceRuleType.specialPrice,
    sourceType: CustomerPriceRuleSourceType.manual,
    persistedStatus: CustomerPriceRuleStatus.active,
    derivedStatus: CustomerPriceRuleDerivedStatus.applying,
    validationOutcome: const RuleValidationOutcomeDto(
      outcome: 'warning',
      warningCodes: ['below_floor_price'],
      blockingCodes: [],
      floorPriceHidden: true,
    ),
    referenceHealth: const CustomerPriceRuleReferenceHealthDto(
      customerState: CustomerPriceRuleReferenceState.valid,
      productUnitState: CustomerPriceRuleReferenceState.valid,
      priceBandState: CustomerPriceRulePriceBandState.current,
      issueCodes: [],
      usedStoredPriceBandSnapshot: false,
    ),
    sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
    createdBy: '00000000-0000-4000-8000-000000000005',
    createdAt: DateTime.utc(2026, 7, 16),
    updatedBy: '00000000-0000-4000-8000-000000000005',
    updatedAt: DateTime.utc(2026, 7, 16),
    version: 1,
    availableActions: const [
      CustomerPriceRuleAvailableActions.edit,
      CustomerPriceRuleAvailableActions.disable,
      CustomerPriceRuleAvailableActions.history,
    ],
  );

  expect(detail.derivedStatus, CustomerPriceRuleDerivedStatus.applying);
  expect(detail.referenceHealth.priceBandState,
      CustomerPriceRulePriceBandState.current);
  expect(detail.sourceTrace.hidden, isFalse);
});
```

- [ ] **Step 3: Run the tests and confirm red**

Run:

```bash
melos exec --scope=vet45_pricing_application -- dart test test/get_customer_price_rule_detail_contract_test.dart test/fake_pricing_module_test.dart test/create_customer_price_rule_contract_test.dart test/search_customer_price_rules_contract_test.dart
```

Expected: compile failures for missing shared DTOs/actions and mismatched typed detail fields.

- [ ] **Step 4: Add the shared enum, action, health, and trace types**

Create the exact public types:

```dart
enum CustomerPriceRuleDerivedStatus {
  applying,
  notYetEffective,
  disabled,
  expired,
  needsReview,
}

abstract final class CustomerPriceRuleAvailableActions {
  static const edit = 'edit';
  static const disable = 'disable';
  static const reenable = 'reenable';
  static const history = 'history';
}

enum CustomerPriceRuleReferenceState { valid, inactive, missing }

enum CustomerPriceRulePriceBandState {
  current,
  currencyMismatch,
  invalidMinorUnits,
  unavailable,
}

final class CustomerPriceRuleReferenceHealthDto {
  const CustomerPriceRuleReferenceHealthDto({
    required this.customerState,
    required this.productUnitState,
    required this.priceBandState,
    required this.issueCodes,
    required this.usedStoredPriceBandSnapshot,
  });

  final CustomerPriceRuleReferenceState customerState;
  final CustomerPriceRuleReferenceState productUnitState;
  final CustomerPriceRulePriceBandState priceBandState;
  final List<String> issueCodes;
  final bool usedStoredPriceBandSnapshot;
}

final class CustomerPriceRuleSourceTraceDto {
  const CustomerPriceRuleSourceTraceDto({
    required this.hidden,
    this.sourceImportId,
    this.sourceImportRowId,
    this.sourceOrderId,
    this.sourceOrderLineId,
  });

  final bool hidden;
  final String? sourceImportId;
  final String? sourceImportRowId;
  final String? sourceOrderId;
  final String? sourceOrderLineId;
}
```

Move the derived-status enum out of the S2-only file. Keep `customer_price_rule_search_enums.dart` as a compatibility export plus `CustomerPriceRuleQuickFilter` so existing S2 imports continue compiling.

- [ ] **Step 5: Change `CustomerPriceRuleDetailDto` to the locked shape**

Use these field types:

```dart
final CustomerPriceRuleType ruleType;
final CustomerPriceRuleSourceType sourceType;
final CustomerPriceRuleStatus persistedStatus;
final CustomerPriceRuleDerivedStatus derivedStatus;
final CustomerPriceRuleReferenceHealthDto referenceHealth;
final CustomerPriceRuleSourceTraceDto sourceTrace;
final List<String> availableActions;
```

Keep existing identity, reference, price, period, note, validation, audit, and version fields. Update S1 fixtures to emit a valid snapshot-based health object and a non-hidden empty manual trace.

- [ ] **Step 6: Reserve the four stable fake scenario identifiers**

Add enum values:

```dart
ruleDetailActive,
ruleDetailDisabled,
ruleDetailNotFound,
ruleDetailReferenceStale,
```

Do not add detail query dispatch in this task because the query type is produced by Task 2. Update every existing scenario switch so the new S3-only values remain exhaustive and throw `UnsupportedError` when used with an S1/S2 request.

- [ ] **Step 7: Export the new public contract and rerun tests**

Run:

```bash
melos exec --scope=vet45_pricing_application -- dart test test/get_customer_price_rule_detail_contract_test.dart test/fake_pricing_module_test.dart test/create_customer_price_rule_contract_test.dart test/search_customer_price_rules_contract_test.dart
```

Expected: all selected tests pass. The new scenario identifiers are frozen, while their detail dispatch behavior is added test-first in Task 2.

- [ ] **Step 8: Commit the shared contract checkpoint**

Before committing, run GitNexus `detect_changes` and confirm expected Pricing application symbols only. Then stage only Task 1 files and commit:

```bash
git commit -m "feat(pricing): freeze S3 detail contract"
```

---

### Task 2: Add Detail Query, Validator, Handler, Port, and Error Code

**Files:**

- Create: `modules/pricing/application/lib/src/customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query.dart`
- Create: `modules/pricing/application/lib/src/customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query_validator.dart`
- Create: `modules/pricing/application/lib/src/customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query_handler.dart`
- Modify: `modules/pricing/application/lib/src/ports/i_pricing_read_gateway.dart`
- Modify: `modules/pricing/application/lib/src/shared/pricing_blocked_codes.dart`
- Modify: `modules/pricing/application/lib/src/testing/fake_pricing_module.dart`
- Modify: `modules/pricing/application/lib/application.dart`
- Test: `modules/pricing/application/test/get_customer_price_rule_detail_contract_test.dart`
- Test: `modules/pricing/application/test/fake_pricing_module_test.dart`

**Interfaces:**

- Produces `GetCustomerPriceRuleDetailQuery`, `GetCustomerPriceRuleDetailQueryValidator`, `GetCustomerPriceRuleDetailQueryHandler`, `PricingBlockedCodes.notFound`, and `IPricingReadGateway.getCustomerPriceRuleDetail`.
- Consumes the shared detail DTO and fake scenarios from Task 1.

- [ ] **Step 1: Run GitNexus impact for the existing port and blocked-code class**

Run upstream impact for `IPricingReadGateway` and `PricingBlockedCodes`. Expected: Pricing application/infrastructure callers and low/medium risk; no unexplained module boundary impact.

- [ ] **Step 2: Add failing query/validator/handler tests**

Cover:

```text
normalizes businessDate to UTC calendar date
withExecutionContext replaces caller tenant and preserves query id/payload
accepts a valid canonical UUID
rejects blank tenantId
rejects blank ruleId
rejects malformed ruleId
handler validates then delegates the complete query
handler does not call gateway after validation failure
ruleDetailActive returns applying detail plus edit-disable-history
ruleDetailDisabled returns disabled detail plus edit-reenable-history
ruleDetailNotFound throws NOT_FOUND
ruleDetailReferenceStale preserves stored labels and redacts floor amount
```

Use a recording `IPricingReadGateway` fake and a fixed detail DTO. Assert the gateway receives the exact same effective query instance passed to the handler.

- [ ] **Step 3: Run the focused test and confirm red**

Run:

```bash
melos exec --scope=vet45_pricing_application -- dart test test/get_customer_price_rule_detail_contract_test.dart test/fake_pricing_module_test.dart
```

Expected: missing query, validator, handler, port method, and `NOT_FOUND` constant.

- [ ] **Step 4: Implement the query**

Use the existing S2 access pattern:

```dart
@RequiresPermission(PricingPermissions.viewCustomerPriceRule)
@RequiresTenant()
final class GetCustomerPriceRuleDetailQuery
    extends QueryBase<CustomerPriceRuleDetailDto>
    implements IQuery<CustomerPriceRuleDetailDto>, ITenantScopedCommand {
  GetCustomerPriceRuleDetailQuery({
    String? id,
    this.tenantId = '',
    required this.ruleId,
    required DateTime businessDate,
  }) : businessDate = DateTime.utc(
         businessDate.year,
         businessDate.month,
         businessDate.day,
       ),
       super(id);

  @override
  final String tenantId;
  final String ruleId;
  final DateTime businessDate;

  GetCustomerPriceRuleDetailQuery withExecutionContext({
    required String tenantId,
  }) => GetCustomerPriceRuleDetailQuery(
    id: id,
    tenantId: tenantId,
    ruleId: ruleId,
    businessDate: businessDate,
  );
}
```

- [ ] **Step 5: Implement validator, handler, port, and error constant**

Validator rules are exact:

```text
tenantId blank -> fieldErrors.tenantId = required
ruleId blank -> fieldErrors.ruleId = required
ruleId nonblank but not canonical UUID -> fieldErrors.ruleId = invalid
```

Throw `PricingBlockedException(PricingBlockedCodes.validationError, details: {'fieldErrors': fieldErrors})`.

Handler shape:

```dart
@QueryHandlerFor(GetCustomerPriceRuleDetailQuery)
final class GetCustomerPriceRuleDetailQueryHandler
    implements IQueryHandler<GetCustomerPriceRuleDetailQuery,
        CustomerPriceRuleDetailDto> {
  GetCustomerPriceRuleDetailQueryHandler({
    required IPricingReadGateway readGateway,
    required GetCustomerPriceRuleDetailQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final IPricingReadGateway _readGateway;
  final GetCustomerPriceRuleDetailQueryValidator _validator;

  @override
  Future<CustomerPriceRuleDetailDto> handle(
    GetCustomerPriceRuleDetailQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.getCustomerPriceRuleDetail(query);
  }
}
```

Port method:

```dart
Future<CustomerPriceRuleDetailDto> getCustomerPriceRuleDetail(
  GetCustomerPriceRuleDetailQuery query,
);
```

Add `static const notFound = 'NOT_FOUND';` to `PricingBlockedCodes` and export all new public files through `application.dart`.

Extend `FakePricingModule.executeQueryAsync` with `GetCustomerPriceRuleDetailQuery` dispatch. The not-found scenario throws:

```dart
const PricingBlockedException(PricingBlockedCodes.notFound)
```

The stale-reference scenario keeps stored labels, sets reference states to inactive/missing, includes stable issue codes, and never exposes a floor amount when `floorPriceHidden` is true.

- [ ] **Step 6: Run all Pricing application tests**

Run:

```bash
melos exec --scope=vet45_pricing_application -- dart test
```

Expected: all application tests pass, including the four S3 fake scenarios.

- [ ] **Step 7: Commit the application use case**

Run GitNexus `detect_changes`, stage only Task 2 files, and commit:

```bash
git commit -m "feat(pricing): add customer price rule detail query"
```

---

### Task 3: Add Detail RPC Mapper and Read Gateway Method

**Files:**

- Create: `modules/pricing/infrastructure/lib/src/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper.dart`
- Modify: `modules/pricing/infrastructure/lib/src/domain/customer_price_rule/pricing_rpc_mapper.dart`
- Modify: `modules/pricing/infrastructure/lib/src/domain/customer_price_rule/supabase_customer_price_rule_read_gateway.dart`
- Modify: `modules/pricing/infrastructure/lib/src/errors/pricing_error_mapper.dart`
- Test: `modules/pricing/infrastructure/test/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper_test.dart`
- Test: `modules/pricing/infrastructure/test/domain/customer_price_rule/pricing_rpc_mapper_test.dart`

**Interfaces:**

- Produces `CustomerPriceRuleDetailRpcMapper.params`, `CustomerPriceRuleDetailRpcMapper.detailFromJson`, and the gateway method that calls `get_customer_price_rule_detail`.
- Reuses the same detail decoder from S1 create-result mapping so S1 and S3 cannot diverge on enum, money, redaction, audit, or version semantics.

- [ ] **Step 1: Run GitNexus impact for existing mapper/gateway/error symbols**

Run upstream impact for:

```text
PricingRpcMapper
PricingRpcMapper.createResultFromJson
SupabaseCustomerPriceRuleReadGateway
mapPricingRpcError
```

Expected: only Pricing create/search/detail paths. Stop for user review on HIGH/CRITICAL risk.

- [ ] **Step 2: Write failing mapper and gateway tests**

Cover exact params:

```dart
expect(CustomerPriceRuleDetailRpcMapper.params(query), {
  'p_tenant_id': 'tenant-1',
  'p_rule_id': '00000000-0000-4000-8000-000000000001',
  'p_business_date': '2026-07-16',
});
```

Assert params do not contain `p_actor_id`.

Add response tests for:

```text
active/applying typed detail with edit-disable-history
disabled detail with edit-reenable-history
expired and not_yet_effective derived wires
current list/floor integer money
hidden floor with null amount and below-floor warning
stale customer/product health with stored snapshot fallback
hidden source trace with all identifiers null
visible import/order source trace
timestamps normalized to UTC and version > 0
```

Add negative tests for fractional money, unknown enum/action/health wire, invalid date/timestamp, non-positive version, hidden floor leak, hidden source-trace leak, RPC technical error, and malformed response. Every negative response maps to `SYSTEM_ERROR` except a valid RPC `NOT_FOUND` envelope, which remains `NOT_FOUND`.

- [ ] **Step 3: Run tests and confirm red**

Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart test test/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper_test.dart test/domain/customer_price_rule/pricing_rpc_mapper_test.dart
```

Expected: missing mapper/gateway implementation and unmapped `NOT_FOUND`.

- [ ] **Step 4: Implement exact wire mapping**

Map wires as follows:

```text
rule_type: special_price | remembered_price
source_type: manual | excel_import | sales_order | migration
persisted_status: active | disabled | needs_review
derived_status: applying | not_yet_effective | disabled | expired | needs_review
reference state: valid | inactive | missing
price band state: current | currency_mismatch | invalid_minor_units | unavailable
actions: edit | disable | reenable | history
```

Reject `deleted` in a successful detail response because the public RPC must map it to `NOT_FOUND`.

Enforce:

```text
money.amount_minor is int
currency_code is a nonblank string
effective dates match YYYY-MM-DD and are real dates
created_at/updated_at parse as instants
version is int > 0
floor_price_hidden=true implies floor_price=null
source_trace.hidden=true implies every trace ID is null
```

- [ ] **Step 5: Delegate S1 create mapping to the shared detail decoder**

Change `PricingRpcMapper.createResultFromJson` so its `rule` field is decoded by `CustomerPriceRuleDetailRpcMapper.detailFromJson`. Keep create warnings decoding in `PricingRpcMapper`; do not change create params or create-context mapping.

- [ ] **Step 6: Implement the gateway method and error mapping**

Call:

```dart
final json = await _rpcClient.callMap(
  'get_customer_price_rule_detail',
  params: CustomerPriceRuleDetailRpcMapper.params(query),
);
return CustomerPriceRuleDetailRpcMapper.detailFromJson(json);
```

Use the existing exception boundary. Add `PricingBlockedCodes.notFound` to `_stableCode` in `pricing_error_mapper.dart`; raw technical messages remain hidden.

- [ ] **Step 7: Run focused and full infrastructure tests**

Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart test test/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper_test.dart test/domain/customer_price_rule/pricing_rpc_mapper_test.dart
melos exec --scope=vet45_pricing_infrastructure -- dart test
```

Expected: all existing infrastructure tests pass before Task 4 adds new startup expectations.

- [ ] **Step 8: Commit the mapper/gateway checkpoint**

Run GitNexus `detect_changes`, stage only Task 3 files, and commit:

```bash
git commit -m "feat(pricing): map S3 detail RPC"
```

---

### Task 4: Bind Detail Access, Register Handler, and Regenerate CQRS Metadata

**Files:**

- Modify: `modules/pricing/infrastructure/lib/src/configuration/processing/pricing_query_access_guard.dart`
- Modify: `modules/pricing/infrastructure/lib/src/configuration/pricing_startup.dart`
- Modify: `modules/pricing/infrastructure/test/configuration/pricing_search_startup_test.dart`
- Generate: `modules/pricing/infrastructure/lib/src/configuration/processing/generated/pricing_access_metadata.g.dart`
- Generate: `modules/pricing/infrastructure/lib/src/configuration/processing/generated/pricing_cqrs_registrar.g.dart`
- Generate: `modules/pricing/infrastructure/lib/src/configuration/processing/generated/pricing_module_manifest.g.dart`

**Interfaces:**

- Produces execution-context tenant binding, pre-RPC permission/tenant checks, validator registration, and generated handler/access registration for `GetCustomerPriceRuleDetailQuery`.
- Consumes the query, validator, handler, and read gateway from Tasks 2–3.

- [ ] **Step 1: Run GitNexus impact for access/startup symbols**

Run upstream impact for `PricingQueryAccessGuard`, `PricingQueryAccessGuard.bindAndAuthorize`, and `PricingStartup`. Report any HIGH/CRITICAL risk before editing.

- [ ] **Step 2: Add failing startup/access tests**

Add tests that:

```text
replace caller tenant with context tenant before detail RPC
send UTC business date and no actor param
require pricing.customer_price_rule.view before RPC
check tenant access before RPC
map missing execution context to NO_PERMISSION
do not call RPC after permission or tenant denial
register GetCustomerPriceRuleDetailQueryValidator
register generated metadata with view permission and requiresTenant=true
execute the generated detail handler through PricingModule and QueryBus
```

- [ ] **Step 3: Run startup tests and confirm red**

Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart test test/configuration/pricing_search_startup_test.dart
```

Expected: detail query is not context-bound and handler/validator metadata is not registered.

- [ ] **Step 4: Extend the access guard and startup registration**

Add a switch arm:

```dart
GetCustomerPriceRuleDetailQuery detail =>
  detail.withExecutionContext(tenantId: tenantId) as IQuery<TResult>,
```

Register a factory:

```dart
container.registerFactory<GetCustomerPriceRuleDetailQueryValidator>(
  GetCustomerPriceRuleDetailQueryValidator.new,
);
```

Do not add hand-written QueryBus registration.

- [ ] **Step 5: Run Pricing-scoped codegen**

Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart run build_runner clean
melos exec --scope=vet45_pricing_infrastructure -- dart run build_runner build --delete-conflicting-outputs
```

Expected generated output includes the S3 handler constructor dependencies, view permission metadata, tenant requirement, and module manifest entry. Do not edit generated files manually.

- [ ] **Step 6: Run startup and application tests**

Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart test test/configuration/pricing_search_startup_test.dart
melos exec --scope=vet45_pricing_application -- dart test
```

Expected: all pass.

- [ ] **Step 7: Commit access/codegen wiring**

Run GitNexus `detect_changes`, stage Task 4 source/tests/generated outputs only, and commit:

```bash
git commit -m "feat(pricing): wire S3 detail query access"
```

---

### Task 5: Draft the Authoritative Detail RPC with Live Provider Enrichment

**Files:**

- Create: `supabase/migrations/_drafts/pricing_customer_price_rule_detail_s3.sql`
- Modify: `supabase/migrations/_drafts/pricing_customer_price_rule_s1.sql`
- Modify: `modules/pricing/infrastructure/test/pricing_sql_contract_test.dart`

**Interfaces:**

- Produces `pricing.get_customer_price_rule_detail(uuid, uuid, date) returns jsonb`.
- Consumes the S1 Pricing table/snapshots/error helper and the Partner/Catalog internal provider functions.
- Keeps the S1 create RPC response compatible with the expanded shared detail decoder.

- [ ] **Step 1: Record SQL symbol impact status**

Run GitNexus upstream impact for `_customer_price_rule_result` and `create_customer_price_rule`. If SQL functions are not indexed, record risk as UNKNOWN and rely on exact SQL contract tests plus the direct S1 caller audit before editing. No Dart symbol may be changed under an UNKNOWN SQL result without its own Dart impact check.

- [ ] **Step 2: Write failing SQL contract tests**

Add tests that read the draft files and assert:

```text
exact function signature get_customer_price_rule_detail(uuid, uuid, date)
auth.uid() and pricing.customer_price_rule.view checks
tenant_id predicate and status <> deleted
NOT_FOUND through pricing._raise_pricing_error
no p_actor_id
calls both internal provider functions
no FROM/JOIN partner.* or catalog.* private tables
derived precedence disabled -> needs_review -> expired -> not_yet_effective -> applying
inclusive effective boundaries
stable reference-health issue codes
current compatible list/floor comparison
stored snapshot fallback flag when provider reference is unavailable
floor warning survives redaction
trace IDs require view_history
action checks use update/disable/reenable/view_history permissions
public/anon revoke and authenticated/service_role grant
no activity-table read and no insert/update/delete
```

Also assert `_customer_price_rule_result` contains the newly required `reference_health` and `source_trace` objects so S1 create results remain decodable.

- [ ] **Step 3: Run SQL contract tests and confirm red**

Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart test test/pricing_sql_contract_test.dart
```

Expected: missing S3 draft/signature and missing expanded S1 detail fields.

- [ ] **Step 4: Add the S3 draft header and RPC signature**

Use:

```sql
-- Title: Pricing S3 customer price rule detail
-- Kind: patch
-- Intent: pricing_customer_price_rule_detail_s3
-- Context: TH-04 EP02 S3 CONTRACT + BE
-- Touches: get_customer_price_rule_detail
-- Safety: draft only; do not apply or promote without explicit migration review
-- Depends on: pricing_customer_price_rule_s1.sql, partner_pricing_customer_snapshot.sql, catalog_pricing_price_band_snapshot.sql

create or replace function pricing.get_customer_price_rule_detail(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_business_date date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
```

- [ ] **Step 5: Implement auth, validation, invisibility, and provider reads**

The function must:

```text
read actor only from auth.uid()
require non-null tenant/rule/businessDate
require pricing.customer_price_rule.view
select exactly one non-deleted rule by tenant_id + id
raise NOT_FOUND if no visible row
call Partner customer snapshot provider
call Catalog product/unit price-band snapshot provider
```

Provider `exists=false` is a valid stale-reference result. Provider execution exceptions are not swallowed; the RPC boundary maps them to `SYSTEM_ERROR`.

- [ ] **Step 6: Implement derived status and reference health**

Use exact precedence:

```sql
case
  when r.status = 'disabled' then 'disabled'
  when r.status = 'needs_review'
    or r.review_status in ('blocked', 'needs_review')
    or jsonb_array_length(r.blocking_codes) > 0 then 'needs_review'
  when r.effective_to is not null
    and r.effective_to < p_business_date then 'expired'
  when r.effective_from > p_business_date then 'not_yet_effective'
  else 'applying'
end
```

Build `reference_health` from provider `exists`, customer role/status, product sellability, currency compatibility, and `minor_units_valid`. Keep stored customer/product labels in the main references.

- [ ] **Step 7: Implement price-band fallback and floor redaction**

Rules:

```text
use current provider list/floor only when product/unit exists, minor units are valid, and currency matches rule currency
otherwise use stored list/floor snapshots and set used_stored_price_band_snapshot=true
append below_floor_price when rule price is lower than the selected floor
floor visibility is iam.has_permission(tenant, override_floor_price)
floor_price_hidden=true when a selected floor exists but actor cannot view it
never expose floor amount while hidden
```

Do not change persisted warning/blocking codes or version.

- [ ] **Step 8: Implement action and trace redaction matrices**

Actions are appended only when both status and permission permit them. `history` requires `view_history`. Source trace identifiers also require `view_history`; otherwise emit null IDs plus `hidden=true`.

S3 does not add source columns or import/memory tables. Emit current available trace data from existing persistence and null for identifiers not yet owned by S3.

- [ ] **Step 9: Expand the S1 create-result helper**

Add `reference_health` and `source_trace` to `_customer_price_rule_result`. For a just-committed S1 manual rule:

```text
customerState=valid
productUnitState=valid
priceBandState=current when stored check is compatible, otherwise unavailable
usedStoredPriceBandSnapshot=false
source trace IDs=null
sourceTrace.hidden=false
```

Align S1 detail enum wires with S2/S3 and replace the old `view` action with the stable lifecycle action names. Do not alter create validation, idempotency, floor commit policy, activity write, or provider recheck behavior.

- [ ] **Step 10: Lock grants and rerun SQL/infrastructure tests**

Add exact revoke/grant statements for the three-argument signature. Run:

```bash
melos exec --scope=vet45_pricing_infrastructure -- dart test test/pricing_sql_contract_test.dart
melos exec --scope=vet45_pricing_infrastructure -- dart test
```

Expected: all SQL contract and infrastructure tests pass. Do not run a live reset/apply command.

- [ ] **Step 11: Commit the draft SQL checkpoint**

Run GitNexus `detect_changes`, stage only the S3 draft, S1 draft adjustment, and SQL tests, then commit:

```bash
git commit -m "feat(pricing): draft S3 detail RPC"
```

---

### Task 6: Reconcile Harness Contracts and Mark Lane Completion

**Files:**

- Modify: `docs/themes/TH-04-pricing-promotions/Epic-02-customer-price-rules/US-03.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/01-domain-model.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/05-traceability.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/06-harness-notes.md`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/07-api-contracts.md`
- Modify: `docs/harness/PROGRESS.md`

**Interfaces:**

- Freezes §S3 as the source of truth for FE and future S5–S7 mutation flows.
- Records lane-scoped completion only after Task 7 verification succeeds.

- [ ] **Step 1: Update §S3 contract details**

Document:

```text
context-derived tenant
ruleId/businessDate inputs
typed enum wires
reference-health fields/states/issues
source-trace redaction
stable action matrix
NOT_FOUND invisibility
floor warning/redaction
exact RPC params and no actor param
four fake scenarios
```

- [ ] **Step 2: Reconcile US-03 and architecture semantics**

State explicitly:

```text
S3 returns no recent activity rows; history is a capability/navigation action for S10
S2 list uses stored validation snapshots
S3 detail uses read-time Partner/Catalog provider enrichment
live reference health does not mutate persisted rule status or list projection
stored labels remain visible for archived references
```

- [ ] **Step 3: Update domain model and harness notes**

Add detail projection/reference-health semantics without changing aggregate state or domain events. Record that provider missing references are warnings, while provider technical failures are `SYSTEM_ERROR`.

- [ ] **Step 4: Defer lane status edits until verification**

Before Task 7 passes, leave S3 CONTRACT and BE unchanged. After focused gates pass, change only:

```text
S3 CONTRACT -> done
S3 BE -> done
```

Keep FE and E2E unchanged. Update traceability rows and add Pricing S3 progress evidence plus workspace technical debt.

---

### Task 7: Run Focused and Workspace Verification, Review Diff, and Finalize Status

**Files:**

- Verify all files listed in Tasks 1–6.
- Modify lane/progress documents from Task 6 only after focused gates are green.

**Interfaces:**

- Produces completion evidence for S3 CONTRACT + BE and a GitNexus low/understood-risk diff report.

- [ ] **Step 1: Format only Pricing Dart files changed by S3**

Run `dart format` with the explicit changed application/infrastructure source and test paths. Do not format unrelated packages.

- [ ] **Step 2: Run Pricing package tests**

Run:

```bash
melos exec --scope=vet45_pricing_domain -- dart test
melos exec --scope=vet45_pricing_application -- dart test
melos exec --scope=vet45_pricing_infrastructure -- dart test
```

Expected: all tests pass; record exact counts in `docs/harness/PROGRESS.md`.

- [ ] **Step 3: Run Pricing analyzers**

Run:

```bash
melos exec --scope=vet45_pricing_domain -- dart analyze
melos exec --scope=vet45_pricing_application -- dart analyze
melos exec --scope=vet45_pricing_infrastructure -- dart analyze
```

Expected: `No issues found!` for all three packages.

- [ ] **Step 4: Verify codegen freshness and focused guards**

Run:

```bash
melos run codegen
bash scripts/ci/guard_layer_imports.sh
bash scripts/ci/guard_infra_dart_only.sh
bash scripts/ci/guard_application_use_case_layout.sh
bash scripts/ci/guard_application_dto_colocation.sh
bash scripts/ci/guard_theme_structure.sh
bash scripts/ci/guard_docs_reference.sh
bash scripts/ci/guard_theme_traceability.sh
```

Expected: all focused guards pass and codegen produces no unexpected manual diff.

- [ ] **Step 5: Run workspace baseline without broadening the lane gate**

Run:

```bash
melos bootstrap
melos run analyze --no-select
melos run test --no-select
bash scripts/ci/verify_harness.sh
```

Record failures outside Pricing as technical debt with package/file names. Any Pricing failure or S3-owned guard failure blocks S3 completion.

- [ ] **Step 6: Mark S3 lane status after focused success**

Change S3 CONTRACT and BE to `done` in roadmap and traceability, keep FE/E2E unchanged, and add a Phase 2.4 Pricing S3 entry in `docs/harness/PROGRESS.md` with focused test/analyze/codegen evidence and workspace baseline debt.

- [ ] **Step 7: Run final diff hygiene**

Run:

```bash
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors; only intended S3/docs files plus clearly identified pre-existing user changes.

- [ ] **Step 8: Run final GitNexus change detection**

Run `detect_changes({scope: "compare", base_ref: "main"})` or the available repo-local equivalent. Review changed symbols, affected processes, and risk. Do not commit if GitNexus is unavailable or if unexplained HIGH/CRITICAL impact remains.

- [ ] **Step 9: Perform final self-review**

Verify:

```text
no direct Partner/Catalog private-table access
no actor RPC parameter
no floor/source-trace leak
no activity history embedded
no mutation/domain-event/outbox work
no generated file edited manually
no timestamped migration
S1 create and S2 search tests remain green
S3 FE/E2E unchanged
```

- [ ] **Step 10: Create the final implementation commit if authorized**

Stage only remaining S3/docs files and commit:

```bash
git commit -m "docs(pricing): complete S3 contract and backend lane"
```

If the implementation workflow is configured for one squashed commit, omit intermediate commits and use:

```bash
git commit -m "feat(pricing): implement S3 customer price rule detail"
```

---

## Definition of Done

- `GetCustomerPriceRuleDetailQuery`, validator, handler, DTO extensions, port, and fake scenarios are exported from Pricing application.
- Tenant is context-bound; generated view/tenant metadata and pre-RPC guard are active.
- Detail mapper/gateway enforce exact params, enum/date/money/version parsing, and sensitive-data leak rejection.
- Draft RPC enforces access/invisibility, derives status by business date, enriches through provider functions, redacts floor/source trace, and derives lifecycle actions.
- No S3 mutation, activity append, domain event, outbox, Presentation, ERP DI, E2E, live DB reset, or migration promotion exists.
- Pricing domain/application/infrastructure tests and analyzers pass.
- Relevant architecture/layout/docs/traceability guards pass.
- Workspace-external failures are recorded separately and do not mask a Pricing-owned failure.
- S3 CONTRACT + BE are `done`; FE/E2E remain unchanged.
- Final GitNexus `detect_changes` shows only expected impact and no unexplained HIGH/CRITICAL risk.
