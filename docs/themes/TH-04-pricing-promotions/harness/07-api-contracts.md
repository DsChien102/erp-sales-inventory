# TH-04 EP02 — API contracts (FE ↔ BE)

Source of truth giữa presentation và application cho EP02. Types sẽ sống trong `modules/pricing/application/`; facade mục tiêu `IPricingModule`.

> **DOC_AHEAD_OF_CODE (2026-08-04):** Product Theme-4 + docs này chốt policy **overwrite-confirm** (`OVERWRITE_REQUIRED` / `acknowledgeOverwrite` → soft-delete overlapping actives). Implementation Dart/SQL hiện tại có thể vẫn trả `DUPLICATE_ACTIVE_RULE` blocked và/hoặc `MANUAL_RULE_PROTECTED`. Fake scenario ids cũ giữ annotated `deprecated` đến catch-up slice. Không implement code trong PR docs-only.

**S1/S2 baseline 2026-07-16:** CONTRACT + BE cho create/list đã freeze. SQL vẫn là draft, chưa promote/apply; FE và E2E chưa triển khai.

**S3 baseline 2026-07-16:** CONTRACT + BE cho detail/actions đã được freeze với live Partner/Catalog reference-health enrichment, redacted floor/source-trace, và permission-aware lifecycle actions. Detail SQL vẫn là draft, chưa promote/apply; FE và E2E chưa triển khai.

**S5 baseline 2026-07-16:** CONTRACT + BE cho update rule đã freeze — command/handler/advisory context port và cả hai RPC draft (`get_customer_price_rule_update_context`, `update_customer_price_rule`) đã implement với 8 fake scenario. Update SQL vẫn là draft, chưa promote/apply; FE và E2E chưa triển khai.

## Access & tenancy

- Tenant/actor lấy từ `IExecutionContext`, không nhận tenant ID tin cậy từ UI payload.
- Commands/queries dùng `@RequiresTenant()` và `@RequiresPermission(PricingPermissions.*)` theo IAM golden pattern.
- Cross-tenant/not-visible IDs map thành `NOT_FOUND`.
- Amounts là integer minor units + currency code.

## Error envelope

| Code | Meaning | UI guidance |
| ---- | ------- | ----------- |
| `NO_PERMISSION` | Actor thiếu quyền | Access state/toast; không retry tự động |
| `NOT_FOUND` | Rule/batch không tồn tại hoặc không visible | Not-found state |
| `VALIDATION_ERROR` | Field/value/date invalid | Field errors |
| `INVALID_STATUS` | Action không hợp lifecycle | Refresh current state |
| `OVERWRITE_REQUIRED` | Active interval overlaps another active rule for the same key; user must confirm ghi đè | Keep form/batch; show overwrite dialog with overlapping rule refs; retry with `acknowledgeOverwrite=true` |
| `DUPLICATE_ACTIVE_RULE` | **Deprecated (DOC_AHEAD_OF_CODE)** — legacy blocked duplicate. Map to `OVERWRITE_REQUIRED` in catch-up slice | Treat as overwrite prompt until code lands |
| `AMBIGUOUS_OVERLAPPING_RULES` | Blank-`rule_id` `upsert` giao với nhiều active rule cùng customer/product/product-unit | Blocking row error; `skip`; không mutation (hoặc require explicit `rule_id`) |
| `BELOW_FLOOR_BLOCKED` | Floor policy chặn | Explain policy/override eligibility |
| `REFERENCE_INVALID` | Customer/product/unit không hợp lệ | Reselect or row error |
| `AMBIGUOUS_PRODUCT_UNIT` | Import không resolve được unique/default unit | Row error |
| `STATE_CHANGED` | Expected version/precheck stale | Reload and review |
| `IDEMPOTENCY_CONFLICT` | Same key, different payload | Stop retry; investigate caller |
| `SYSTEM_ERROR` | Technical failure | Retry/support path |

## Shared DTOs

| DTO | Required fields |
| --- | --------------- |
| `MoneyDto` | `amountMinor`, `currencyCode` |
| `EffectivePeriodDto` | `effectiveFrom`, `effectiveTo?` |
| `CustomerRefDto` | `customerId`, `displayName`, `status` |
| `ProductUnitRefDto` | `productId`, `productName`, `productUnitId`, `unitName`, `sellableStatus`, `productReferenceId?`, `sku?` |
| `RuleIssueDto` | stable `code`, optional `field`, structured `details` |
| `RuleValidationOutcomeDto` | outcome, warning codes, blocking codes, listPrice?, floorPrice?, floorPriceHidden |
| `CustomerPriceRuleListItemDto` | id, customer/product/unit refs, price, type, source, persisted/derived status, effectivity, updatedAt |
| `CustomerPriceRuleDetailDto` | ID/refs, price, period, typed type/source/status, note, validation outcome, `referenceHealth`, `sourceTrace`, audit metadata, version, availableActions |
| `CustomerPriceRuleReferenceHealthDto` | customer/productUnit/priceBand states, issueCodes, usedStoredPriceBandSnapshot |
| `CustomerPriceRuleSourceTraceDto` | hidden, optional import/order/memory request identifiers |
| `CursorPageDto<T>` | items, nextCursor?, hasMore |

## Command/query catalog

| ID | Symbol | Type | Permission | US |
| -- | ------ | ---- | ---------- | -- |
| QRY-01 | `SearchCustomerPriceRulesQuery` | Query | view | US-01 |
| QRY-02 | `GetCustomerPriceRuleDetailQuery` | Query | view | US-03 |
| CMD-01 | `CreateCustomerPriceRuleCommand` | Command | create | US-04 |
| CMD-02 | `UpdateCustomerPriceRuleCommand` | Command | update | US-06 |
| CMD-03 | `DisableCustomerPriceRuleCommand` | Command | disable | US-07 |
| QRY-03 | `PrecheckCustomerPriceRuleReenableQuery` | Query | reenable | US-08 |
| CMD-04 | `ReenableCustomerPriceRuleCommand` | Command | reenable | US-08 |
| CMD-05 | `StartCustomerPriceRuleImportCommand` | Command | import | US-05 |
| QRY-04 | `GetCustomerPriceRuleImportQuery` | Query | import | US-05 |
| CMD-06 | `ConfirmCustomerPriceRuleImportCommand` | Command | import | US-05 |
| CMD-07 | `CancelCustomerPriceRuleImportCommand` | Command | import | US-05 |
| CMD-08 | `SaveRememberedPriceFromOrderCommand` | Command | save_memory | US-09 |
| QRY-05 | `GetCustomerPriceRuleHistoryQuery` | Query | view_history | US-10 |

---

## §S1 — US-04 Create manual rule

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `CreateCustomerPriceRuleCommand` | context-derived tenantId/actorId; customerId, productId, productUnitId, rulePriceMinor, currencyCode, effectiveFrom, effectiveTo?, note?, acknowledgeFloorWarning, acknowledgeOverwrite?, idempotencyKey | `CreateCustomerPriceRuleResult(rule, warnings)` | `NO_PERMISSION`, `VALIDATION_ERROR`, `OVERWRITE_REQUIRED`, `BELOW_FLOOR_BLOCKED`, `REFERENCE_INVALID`, `IDEMPOTENCY_CONFLICT`, `SYSTEM_ERROR` |

`tenantId` và `actorId` được command executor điền từ `IExecutionContext`; form không được cung cấp và mutation RPC luôn lấy actor từ `auth.uid()`. Command có `@RequiresTenant()` và `@RequiresPermission(PricingPermissions.createCustomerPriceRule)`. Date được chuẩn hóa thành calendar date UTC; money luôn là integer minor units.

Server assigns type=`special_price`, source=`manual`, status=`active`, version=`1` và authoritative validation outcome. Policy S1 cố định là `block_with_override`: dưới floor chỉ commit khi đã acknowledge và actor có `pricing.customer_price_rule.override_floor_price`. Không có floor thì outcome `notChecked`; floor bị redact nếu actor không có override permission.

`PricingBlockedException` luôn mang stable `code` + structured `details`; client không phân nhánh theo message.

### RPC target

| Use case | RPC | Status |
| -------- | --- | ------ |
| Load create context/precheck | `pricing.get_customer_price_rule_create_context` | draft / UX advisory |
| Create rule atomically | `pricing.create_customer_price_rule` | draft / authoritative commit |
| Partner customer provider | `partner._get_customer_snapshot_for_pricing` | internal draft; no client execute |
| Catalog price-band provider | `catalog._get_product_price_band_snapshot_for_pricing` | internal draft; no client execute |

Mutation rechecks tenant/create permission, references, closed-interval overlap, and floor policy under advisory locks. Nếu gặp active overlap cùng key và `acknowledgeOverwrite` chưa true → trả `OVERWRITE_REQUIRED` (warning envelope / structured details với overlapping rule ids), không tạo rule mới. Khi `acknowledgeOverwrite=true`: soft-delete overlapping actives, tạo rule mới, ghi activity create + soft-delete/overwrite. `(tenant_id, idempotency_key)` là unique: same normalized payload returns the original result trước overlap recheck, different payload returns `IDEMPOTENCY_CONFLICT`.

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `create_rule_ok` | valid unique candidate | active detail DTO |
| `create_rule_overwrite_required` | overlapping key, no acknowledge | `OVERWRITE_REQUIRED`; no mutation |
| `create_rule_overwrite_confirmed` | overlapping key + acknowledgeOverwrite | soft-delete old + create new |
| `create_rule_duplicate` | **deprecated** alias of overwrite_required | `DUPLICATE_ACTIVE_RULE` (legacy code path) |
| `create_rule_floor_warning` | warn policy | result + warning |
| `create_rule_floor_blocked` | block/no override | `BELOW_FLOOR_BLOCKED` |
| `create_rule_reference_invalid` | stale customer/unit | `REFERENCE_INVALID` |
| `create_rule_idempotent_retry` | same key + same normalized payload | original result/no duplicate activity |
| `create_rule_idempotency_conflict` | same key + different normalized payload | `IDEMPOTENCY_CONFLICT` |

## §S2 — US-01 Search/list

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `SearchCustomerPriceRulesQuery` | context-derived tenantId; q?, quickFilter, statuses, sources, customerId?, productId?, businessDate, cursor?, limit | `CustomerPriceRuleSearchResultDto(page, availableActions)` | `NO_PERMISSION`, `VALIDATION_ERROR`, `SYSTEM_ERROR` |

`quickFilter` wire values là `all`, `applying`, `below_floor`. Derived-status wire values là `applying`, `not_yet_effective`, `disabled`, `expired`, `needs_review`; source wire values là `manual`, `excel_import`, `sales_order`, `migration`. `limit` mặc định 20 và hợp lệ trong khoảng 1–100. `q` được trim, blank thành null và tối đa 120 ký tự. `businessDate` là calendar date UTC.

Search dùng Pricing-owned snapshots cho customer/product identity (name/UUID/reference/SKU). **Giá hiện tại (`list_price`)** trên list ưu tiên Catalog-live price band (cùng tiêu chí `current` như detail S3), fallback `list_price_snapshot_minor` khi band không current. Customer code deferred vì Partner chưa sở hữu field này. Không có custom effectivity hoặc updated-date range trong V1. Tất cả filter kết hợp bằng AND; deleted luôn bị loại (`status <> 'deleted'` và `deleted_at is null`).

Derived-status precedence: persisted `disabled` → `disabled`; persisted/review blocking hoặc blocking codes → `needs_review`; `effective_to < businessDate` → `expired`; `effective_from > businessDate` → `not_yet_effective`; còn lại → `applying`. Effective boundaries là inclusive.

Cursor opaque, server seek theo `updated_at DESC, id DESC`; Dart không parse cursor. `below_floor` quick-filter vẫn phản ánh validation **snapshot** gần nhất (warning code / floor snapshot), không recompute từ Catalog-live. List không trả floor amount; chỉ trả warning codes và `floorPriceHidden` (true khi floor live/snapshot có giá trị).

Draft SQL: `005_pricing_customer_price_rule_search_s2.sql`, patch list-price live `015_pricing_customer_price_rule_search_list_price_live.sql`.

Screen actions có stable values `create_manual` và `import`, lần lượt phụ thuộc quyền create/import. Tenant được bind từ `IExecutionContext`; query guard và RPC đều recheck quyền view/tenant. RPC không nhận actor ID.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Search/list | `pricing.search_customer_price_rules` | draft / identity snapshot + Catalog-live `list_price` (015) |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `search_rules_default` | no filters | mixed source/status page, gồm future rule và below-floor warning |
| `search_rules_empty` | empty tenant | empty page |
| `search_rules_no_result` | unmatched q | empty page with active filters |
| `search_rules_error` | gateway failure | `SYSTEM_ERROR` |

## §S3 — US-03 Detail

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `GetCustomerPriceRuleDetailQuery` | context-derived `tenantId`; required `ruleId` (canonical UUID), `businessDate` (UTC calendar date) | `CustomerPriceRuleDetailDto` | `NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`, `SYSTEM_ERROR` |

`tenantId` được thay từ `IExecutionContext` trước access check/dispatch. RPC params đúng là `p_tenant_id`, `p_rule_id`, `p_business_date` — **không** có `p_actor_id`; actor chỉ lấy từ `auth.uid()`.

Query có `@RequiresTenant()` và `@RequiresPermission(PricingPermissions.viewCustomerPriceRule)`.

#### Typed wires

| Field | Wires |
| ----- | ----- |
| `ruleType` | `special_price` \| `remembered_price` |
| `sourceType` | `manual` \| `excel_import` \| `sales_order` \| `migration` |
| `persistedStatus` | `active` \| `disabled` \| `needs_review` (deleted → `NOT_FOUND`) |
| `derivedStatus` | `applying` \| `not_yet_effective` \| `disabled` \| `expired` \| `needs_review` |
| `availableActions` | `edit` \| `disable` \| `reenable` \| `history` |

Derived precedence (business date inclusive): `disabled` → `needs_review` → `expired` → `not_yet_effective` → `applying`. Derived `expired`/`not_yet_effective` không đổi action matrix.

#### Permission-aware actions

| Persisted status | Actions (nếu có permission) |
| --- | --- |
| `active` / `needs_review` | `edit`, `disable`, `history` |
| `disabled` | `edit`, `reenable`, `history` |
| `deleted` | invisible → `NOT_FOUND` |

#### Reference health (live Partner/Catalog enrichment)

- IDs/labels hiển thị vẫn là Pricing-owned stored snapshots (archived references vẫn explainable).
- Live health/list/floor đến từ `partner._get_customer_snapshot_for_pricing` và `catalog._get_product_price_band_snapshot_for_pricing` — không join provider private tables.
- Provider `exists=false`/inactive → issue codes + stored price-band fallback khi cần; provider technical failure → `SYSTEM_ERROR`.
- Live enrichment **không** mutate persisted status, validation snapshot, version, hay activity. List search (`015`) cũng enrich `list_price` Catalog-live độc lập; detail không ghi đè projection đã lưu trên rule.

Issue codes ổn định: `customer_reference_inactive`, `customer_reference_missing`, `product_unit_reference_inactive`, `product_unit_reference_missing`, `price_band_currency_mismatch`, `price_band_minor_units_invalid`, `below_floor_price`.

Below-floor luôn expose warning `below_floor_price`. Floor amount chỉ hiện khi actor có `PricingPermissions.overrideFloorPrice`; ngược lại `floorPriceHidden=true` và `floorPrice=null`.

#### Source trace

- `createdBy`/`createdAt`/`updatedBy`/`updatedAt` luôn visible với view permission.
- Import/order identifiers chỉ trả khi có `PricingPermissions.viewCustomerPriceRuleHistory`; không có thì mọi ID = null và `sourceTrace.hidden == true`.
- S3 **không** embed activity rows; action `history` điều hướng S10.

#### Shared DTO extensions

`CustomerPriceRuleDetailDto` gồm typed enums + `referenceHealth` + `sourceTrace` + `availableActions` + `version`.

### RPC target

| Use case | RPC | Status |
| -------- | --- | ------ |
| Rule detail | `pricing.get_customer_price_rule_detail(uuid, uuid, date)` | draft / `_drafts/006_pricing_customer_price_rule_detail_s3.sql` |

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `rule_detail_active` | active ID | applying detail + edit/disable/history |
| `rule_detail_disabled` | disabled ID | disabled detail + edit/reenable/history |
| `rule_detail_not_found` | invisible/deleted/cross-tenant ID | `NOT_FOUND` |
| `rule_detail_reference_stale` | archived product/customer | stored labels + health issues + redacted floor |
## §S4 — US-02 Choose add method

No server command/RPC. FE derives visible routes from capabilities and destinations recheck access. Fake test cases: both actions, create-only, import-only, neither, dismiss/no mutation.

## §S5 — US-06 Update rule

**S5 baseline 2026-07-16:** CONTRACT + BE for update are frozen. `UpdateCustomerPriceRuleCommand`, its handler, the advisory update-context port, and both RPC drafts are implemented and tested; SQL remains draft-only, unapplied. FE and E2E are untouched.

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `UpdateCustomerPriceRuleCommand` | context-derived `tenantId`/`actorId`; required `ruleId` (canonical UUID), `expectedVersion`, `rulePriceMinor`, `effectiveFrom`; optional `effectiveTo`, `note`; required `acknowledgeFloorWarning`; optional `acknowledgeOverwrite` | `CustomerPriceRuleDetailDto` (direct result, no wrapper) | `NO_PERMISSION`, `VALIDATION_ERROR`, `STATE_CHANGED`, `INVALID_STATUS`, `OVERWRITE_REQUIRED`, `BELOW_FLOOR_BLOCKED`, `REFERENCE_INVALID`, `NOT_FOUND`, `SYSTEM_ERROR` |

`tenantId`/`actorId` are replaced by `withExecutionContext(...)` after dispatch, never trusted from caller input. Command carries `@RequiresTenant()` and `@RequiresPermission(PricingPermissions.updateCustomerPriceRule)`. Money stays integer minor units (`rulePriceMinor`); dates are calendar dates UTC. **No** `currencyCode`, customer/product/unit identity, `ruleType`, or `sourceType` field exists on this command — currency and identity/source are immutable via update and are always read from the reconstituted current rule, never from client input.

`PricingBlockedException` always carries a stable `code` + structured `details`; `STATE_CHANGED` includes `expectedVersion`/`currentVersion`, `INVALID_STATUS` includes the rule's current `status`.

### RPC target

| Use case | RPC | Status |
| -------- | --- | ------ |
| Load update context/precheck | `pricing.get_customer_price_rule_update_context` | draft / UX advisory |
| Update rule atomically | `pricing.update_customer_price_rule` | draft / authoritative commit |
| Partner customer provider | `partner._get_customer_snapshot_for_pricing` | internal draft; no client execute |
| Catalog price-band provider | `catalog._get_product_price_band_snapshot_for_pricing` | internal draft; no client execute |

**Advisory RPC params (exact, in order):** `p_tenant_id uuid`, `p_rule_id uuid`, `p_expected_version integer`, `p_rule_price_minor bigint`, `p_effective_from date`, `p_effective_to date`. Read-only/`stable`; recomputes the same precheck the authoritative RPC will run (permission, payload shape, version, status, references, floor, advisory duplicate) but **never authorizes commit** — the authoritative RPC always re-derives and re-checks everything itself under a row lock.

**Authoritative RPC params (exact, in order):** `p_tenant_id uuid`, `p_rule_id uuid`, `p_expected_version integer`, `p_rule_price_minor bigint`, `p_effective_from date`, `p_effective_to date`, `p_note text`, `p_acknowledge_floor_warning boolean`. Neither RPC has a `p_actor_id` parameter; actor identity is always `auth.uid()`.

Authoritative flow (**target docs / DOC_AHEAD_OF_CODE**): `select ... for update` row lock → `NOT_FOUND` / `STATE_CHANGED` / `INVALID_STATUS` checks → no-op short-circuit → revalidate references + floor → advisory-lock + overlap check excluding current rule → if overlap and `acknowledgeOverwrite` not true → `OVERWRITE_REQUIRED` (no write) → if acknowledged → soft-delete overlapping actives + update (`version + 1`) + `'updated'` activity (+ overwrite/soft-delete activities). Legacy code may still auto-disable overlapping rules — treat as drift until catch-up.

### Fake scenarios (all eight `FakePricingScenario.updateRule*` variants)

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `updateRuleOk` | current version + changed price | detail with `version = expectedVersion + 1` |
| `updateRuleNoop` | no actual change vs. current snapshot | current detail, `version` unchanged (no new activity) |
| `updateRuleStateChanged` | stale `expectedVersion` | `STATE_CHANGED` |
| `updateRuleDuplicate` | **deprecated** | legacy auto-disable success |
| `updateRuleOverwriteRequired` | new interval overlaps another active rule | `OVERWRITE_REQUIRED`; no mutation |
| `updateRuleOverwriteConfirmed` | overlap + acknowledgeOverwrite | soft-delete overlapping + updated detail |
| `updateRuleFloorWarning` | below floor, acknowledged + override permission | detail with `warningCodes: ['below_floor_price']`, `priceCheckStatus: overrideAllowed` |
| `updateRuleFloorBlocked` | below floor, missing acknowledgement or override permission | `BELOW_FLOOR_BLOCKED` |
| `updateRuleReferenceInvalid` | archived/inactive customer or product unit | `REFERENCE_INVALID` |
| `updateRuleDisabled` | update against a `disabled` rule | updated detail, `persistedStatus` stays `disabled` |

Immutable via this command: tenant, customer, product, product unit, `ruleType`, `sourceType`, and source trace (import/order identifiers). Only price, effective dates, and note are mutable inputs.

## §S6 — US-07 Disable rule

**S6 baseline 2026-07-16:** CONTRACT + BE for disable are complete under lane-scoped completion (command, validator, detail lifecycle fields, six-fake matrix, domain transition, handler/gateway, startup/codegen, RPC draft). SQL remains draft-only, unapplied. FE and E2E remain `todo`.

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `DisableCustomerPriceRuleCommand` | context-derived `tenantId`/`actorId`; required `ruleId` (canonical UUID), `expectedVersion`; optional `reason` (trim, blank→null, max 500 chars) | `CustomerPriceRuleDetailDto` (direct result, no wrapper) with `persistedStatus`/`derivedStatus` = `disabled`, lifecycle audit fields set on real transition | `NO_PERMISSION`, `VALIDATION_ERROR`, `NOT_FOUND`, `STATE_CHANGED`, `INVALID_STATUS`, `SYSTEM_ERROR` |

Exact constructor fields:

```dart
DisableCustomerPriceRuleCommand({
  String? id,
  String tenantId = '',
  String actorId = '',
  required String ruleId,
  required int expectedVersion,
  String? reason,
})
```

`tenantId`/`actorId` are replaced by `withExecutionContext(...)` after dispatch, never trusted from caller input. Command carries `@RequiresTenant()` and `@RequiresPermission(PricingPermissions.disableCustomerPriceRule)`.

Detail DTO lifecycle fields (nullable; remain null until a rule has been disabled):

```dart
final DateTime? disabledAt;
final String? disabledBy;
final String? disabledReason;
```

A disabled RPC payload must contain `disabled_at` and `disabled_by`; malformed payloads map to `SYSTEM_ERROR` at the gateway boundary. Real transition bumps `version = previous + 1` and sets audit metadata; `availableActions` includes `reenable` when permission allows.

`PricingBlockedException` always carries a stable `code` + structured `details`.

### Authoritative ordering

```text
permission/context
→ payload validation
→ SELECT ... FOR UPDATE scoped by tenant and non-deleted state
→ NOT_FOUND
→ already disabled: return current detail, no write/activity/version check
→ expected version check
→ allowed status check (active or needs_review)
→ status/audit/version update
→ one disabled activity
→ current disabled detail
```

The already-disabled branch runs **before** the version check. A retry with the original `expectedVersion` returns current state without changing the original disable reason, actor, time, version, or activity count.

### RPC target

| Use case | RPC | Status |
| -------- | --- | ------ |
| Disable rule atomically | `pricing.disable_customer_price_rule` | draft (`pricing_customer_price_rule_disable_s6.sql`; unapplied) |

**Authoritative RPC params (exact, in order):** `p_tenant_id uuid`, `p_rule_id uuid`, `p_expected_version integer`, `p_reason text default null`. No `p_actor_id` — actor identity is always `auth.uid()`. Returns `jsonb`.

No Partner/Catalog provider call, floor check, duplicate check, advisory context RPC, outbox event, or order snapshot write belongs in S6.

### Fake scenarios (all six `FakePricingScenario.disableRule*` variants)

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `disableRuleOk` | active/current + optional reason | disabled detail, `version = expectedVersion + 1`, normalized `disabledReason`, audit set |
| `disableRuleAlreadyDisabled` | retry against already-disabled | current disabled detail; original `disabledReason` preserved |
| `disableRuleStateChanged` | stale `expectedVersion` (active/needs_review) | `STATE_CHANGED` |
| `disableRuleDenied` | missing permission | `NO_PERMISSION` |
| `disableRuleNotFound` | missing/deleted/invisible/cross-tenant | `NOT_FOUND` |
| `disableRuleInvalidStatus` | persisted status outside allowed set | `INVALID_STATUS` |

### Stable errors

| Condition | Code |
| --------- | ---- |
| Missing permission/context | `NO_PERMISSION` |
| Invalid UUID/version/reason length (>500) | `VALIDATION_ERROR` |
| Missing, deleted, invisible, or cross-tenant rule | `NOT_FOUND` |
| Active/needs-review version mismatch | `STATE_CHANGED` |
| Persisted status outside `active`, `needs_review`, `disabled` (+ deleted → `NOT_FOUND`) | `INVALID_STATUS` |
| Malformed RPC/error envelope or technical failure | `SYSTEM_ERROR` |

## §S7 — US-08 Reenable rule

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `PrecheckCustomerPriceRuleReenableQuery` | ruleId, expectedVersion, businessDate | `CustomerPriceRuleReenablePrecheckDto` | permission, not found, invalid status, state changed |
| `ReenableCustomerPriceRuleCommand` | ruleId, expectedVersion, businessDate, precheckToken?, acknowledgeFloorWarning, acknowledgeOverwrite? | active `CustomerPriceRuleDetailDto` | floor, reference, state changed, invalid status, `OVERWRITE_REQUIRED` |

`businessDate` is normalized to a UTC calendar date in both query and command. `precheckToken` when present must be exactly 64 lowercase hexadecimal characters. A supplied stale token returns `STATE_CHANGED` before newly discovered business-validation errors. Token absence never skips authoritative commit-time validation.

Precheck token is advisory/staleness evidence: a stateless HMAC-SHA-256 fingerprint over canonical live context. The HMAC key is read server-side from Supabase Vault secret `pricing_reenable_fingerprint_hmac_v1`; it is never returned to clients or stored with the token. RPC always runs authoritative checks again.

### Outcome mapping

| Condition | Precheck outcome/code | Commit error when current |
| --- | --- | --- |
| Clean | `valid` | success |
| Below floor + override permission | `warning / below_floor_price` | success only when acknowledged |
| Invalid customer | `blocked / customer_reference_invalid` | `REFERENCE_INVALID` |
| Invalid product/unit | `blocked / product_unit_reference_invalid` | `REFERENCE_INVALID` |
| Currency mismatch | `blocked / currency_mismatch` | `REFERENCE_INVALID` |
| Active overlap | `warning / duplicate_rule_overwrite_required` | `OVERWRITE_REQUIRED` unless `acknowledgeOverwrite`; then soft-delete overlapping + success |
| Expired effective period | `blocked / effective_period_expired` | `INVALID_STATUS`, reason `effectivePeriodExpired` |
| Below floor without override | `blocked / override_permission_required` | `BELOW_FLOOR_BLOCKED` |

### RPC targets

| Use case | RPC | Params (order) | Status |
| -------- | --- | -------------- | ------ |
| Precheck | `pricing.precheck_customer_price_rule_reenable` | p_tenant_id, p_rule_id, p_expected_version, p_business_date | drafted / unapplied |
| Reenable | `pricing.reenable_customer_price_rule` | p_tenant_id, p_rule_id, p_expected_version, p_business_date, p_precheck_token, p_acknowledge_floor_warning | drafted / unapplied |

Actor derives from `auth.uid()`; no `p_actor_id`.
Promotion/deployment must provision a non-blank Vault secret named `pricing_reenable_fingerprint_hmac_v1`; a missing secret fails closed with `SYSTEM_ERROR`.

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `reenablePrecheckValid` | clean disabled rule | valid outcome + 64-char token |
| `reenablePrecheckWarning` | below floor warn | warning / below_floor_price |
| `reenablePrecheckBlockedDuplicate` | **deprecated** | legacy: treated as valid + auto-disable |
| `reenablePrecheckOverwriteRequired` | active overlap | warning / duplicate_rule_overwrite_required |
| `reenablePrecheckBlockedExpired` | expired effective period | blocked / effective_period_expired |
| `reenablePrecheckBlockedReference` | invalid customer | blocked / customer_reference_invalid |
| `reenablePrecheckDenied` | missing permission | `NO_PERMISSION` |
| `reenablePrecheckNotFound` | missing rule | `NOT_FOUND` |
| `reenablePrecheckInvalidStatus` | not disabled | `INVALID_STATUS` |
| `reenableOk` | current valid confirm | active detail, version N+1, no reenable action |
| `reenableFloorOverrideOk` | below floor acknowledged | active detail with warning |
| `reenableStateChanged` | state changes after precheck | `STATE_CHANGED` |
| `reenableDuplicate` | **deprecated** | legacy auto-disable success |
| `reenableOverwriteRequired` | overlap at commit, no acknowledge | `OVERWRITE_REQUIRED` |
| `reenableOverwriteConfirmed` | overlap + acknowledgeOverwrite | soft-delete overlapping + active detail |
| `reenableFloorBlocked` | floor without override/ack | `BELOW_FLOOR_BLOCKED` |
| `reenableReferenceInvalid` | reference invalid at commit | `REFERENCE_INVALID` |
| `reenableExpired` | expired at commit | `INVALID_STATUS` |
| `reenableInvalidStatus` | wrong status at commit | `INVALID_STATUS` |

Lane status: CONTRACT `done`, BE `done`, FE `todo`, E2E `todo`.

## §S8 — US-05 Excel import

Lane status: CONTRACT `done`, BE `done`, FE `done`, E2E `done (Fake)`; applied-RPC E2E vẫn cần kiểm chứng thủ công trên môi trường đã chạy draft.

### Contracts

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetCustomerPriceRuleImportTemplateQuery` | tenant context | `CustomerPriceRuleImportTemplateDto` (`Mau_nho_gia.xlsx`) | permission, system |
| `StartCustomerPriceRuleImportCommand` | templateVersion, originalFileName, fileBytes (≤5 MiB), importMode | `CustomerPriceRuleImportDetailDto` | permission, validation, system |
| `GetCustomerPriceRuleImportQuery` | importId, rowStatus?, cursor?, limit (1–100) | batch + paged `CustomerPriceRuleImportRowPreviewDto` | permission, not found, system |
| `ConfirmCustomerPriceRuleImportCommand` | importId, expectedVersion, businessDate (UTC date), acknowledgeWarningRows, acknowledgeOverwrite? | `CustomerPriceRuleImportResultDto` (terminal only; `isReplay` on completed replay) | invalid status, state changed, validation (acknowledgement), system |
| `CancelCustomerPriceRuleImportCommand` | importId, expectedVersion | `CustomerPriceRuleImportDto` | invalid status, state changed, system |

Template V1 (**breaking**): sheets `customer_price_rules` + `instructions`; exact headers `rule_id`, `customer_id`, `product_id`, `product_unit_id`, `rule_price`, `effective_from`, `effective_to`, `note`. Old workbooks with `product_reference_id` fail `TEMPLATE_HEADER_INVALID`. Both `product_id` and `product_unit_id` are required UUID-shaped row values; Catalog owns exact active product–unit relationship (base or conversion). New rows use `unit_resolution_strategy = explicit_selection` (or `not_found`); `AMBIGUOUS_PRODUCT_UNIT` is not emitted for new V1 imports. `REFERENCE_INVALID` covers malformed/inactive/cross-tenant/mismatched IDs and unusable integer-minor-unit snapshots. Preview and confirm both revalidate. The bounded `archive`+`xml` OOXML codec preserves physical row numbers, supports shared/inline/rich strings and native Excel dates, rejects formulas, extra/reordered headers and unsafe/oversized archives. `rule_price` is integer VND minor: accepts Excel wire `N` / `N.0` / `N.00`, VN thousands `100.000`, and comma thousands `100,000`; non-zero fractional part (e.g. `100000.5`) → `INVALID_PRICE` (draft `018`). Blank `effective_from` warns `EFFECTIVE_FROM_DEFAULTED`; confirm defaults it to `businessDate`. Import modes: `create_only`, `update_only`, `upsert`. File/row outcome codes are DTO data (not `PricingBlockedCodes`). Preview snapshots are typed JSON and redact floor/matched-rule identifiers according to permission.

### RPC targets

| Use case | RPC | Status |
| -------- | --- | ------ |
| Create/validate batch | `pricing.create_customer_price_rule_import` | draft trong repo; user-applied test env |
| Read batch/rows | `pricing.get_customer_price_rule_import` | draft trong repo; user-applied test env |
| Confirm | `pricing.confirm_customer_price_rule_import` | draft trong repo; user-applied test env |
| Cancel | `pricing.cancel_customer_price_rule_import` | draft trong repo; user-applied test env |
| Catalog unit resolver | `catalog._resolve_product_unit_for_pricing_import` | internal draft; no client execute |

Draft SQL: `supabase/migrations/_drafts/010_pricing_customer_price_rule_import_s8.sql`, `013_pricing_customer_price_rule_import_overlap_policy.sql` (duplicate → blocking row error + confirm recheck), `003_catalog_pricing_import_product_unit_resolver.sql`, `016_pricing_customer_price_rule_import_explicit_unit.sql` (explicit product/unit V1; unapplied), `017_pricing_customer_price_rule_import_auto_match_upsert.sql` (blank-rule upsert auto-match; draft-only / unapplied). No workbook storage; no async worker in V1.

**BR-05 import overlap (target docs / DOC_AHEAD_OF_CODE):** Với `upsert` không có `rule_id`, preview match active
rule theo `tenant + customer + product + product_unit + closed-interval
overlap`: `0` match → `create`; `1` match → `update` và lưu
`matched_rule_id/version`; `>1` match → `AMBIGUOUS_OVERLAPPING_RULES`,
`error/skip`. Confirm lấy rule-key advisory lock, match lại và chỉ create/update
khi action, matched ID và version không đổi; drift trả `STATE_CHANGED`.
Create/explicit-update rows that overlap a **different** active rule surface
warning `duplicate_rule_overwrite_required` / `OVERWRITE_REQUIRED`. Confirm with
`acknowledgeOverwrite=true` soft-deletes overlapping actives then creates/updates.
Without acknowledge, those rows stay warning/blocked for mutation.
Same-file conflicts are processed by ascending `row_number`. A mixed batch finishes
`completed_with_errors`; users may continue whenever `validRows + warningRows > 0`.

Legacy drafts (`013` blocking `DUPLICATE_ACTIVE_RULE`, no mutate conflicting rule) remain
implementation drift until catch-up.

FE S8 dùng canonical `CustomerPriceRuleImportTemplateDto.versionV1`, tải template qua `GetCustomerPriceRuleImportTemplateQuery`, lưu bytes bằng app-local `PricingImportFileService`, cho phép partial import khi `validRows + warningRows > 0`, bắt buộc acknowledge warning và gọi cancel command trước khi bỏ batch `ready_to_import`. File-level parser errors được map thành thông báo tiếng Việt; tải workbook lỗi nằm ngoài scope.

Fake E2E evidence: `pricing_import_history_e2e_test.dart` kiểm tra tải đúng filename/bytes, mixed-row confirm partial và cancel batch từ preview. Cubit/widget tests bao phủ tenant query, expectedVersion, cancel failure giữ preview, CTA partial/empty và warning acknowledgement.

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `importTemplateV1` | template query | V1 bytes/filename |
| `importReadyMixed` | start/get | ready batch + mixed preview rows |
| `importFailedBadFile` | start | failed batch + file codes |
| `importProductUnitMismatch` | start | row `REFERENCE_INVALID` |
| `importModeMismatch` | start | row `IMPORT_MODE_MISMATCH` |
| `importGetNotFound` | get | `NOT_FOUND` |
| `importConfirmNeedsAcknowledgement` | confirm w/o ack | `VALIDATION_ERROR` acknowledgementRequired |
| `importConfirmPartial` | confirm | `completed_with_errors` |
| `importConfirmRetry` | confirm on completed | same result `isReplay=true` |
| `importConfirmStateChanged` | stale version | `STATE_CHANGED` |
| `importConfirmDenied` | missing permission | `NO_PERMISSION` |
| `importCancelOk` | cancel ready | canceled batch |
| `importCancelStateChanged` | stale cancel | `STATE_CHANGED` |
| `importCancelInvalidStatus` | cancel terminal | `INVALID_STATUS` |

## §S9 — US-09 Remember price from Sales

**S9 baseline 2026-07-16:** CONTRACT + BE frozen. SQL draft `011_pricing_remembered_price_from_order_s9` chưa apply. FE `todo`, E2E `blocked`. Không có Sales dependency, outbox, hay async worker.

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `SaveRememberedPriceFromOrderCommand` | context-derived tenantId/actorId; sourceOrderId, sourceOrderLineId, customerId? (nullable anonymous), productId, productUnitId, soldPriceMinor, currencyCode, soldAt (UTC), idempotencyKey, acknowledgeOverwrite? | `RememberedPriceOutcomeDto` | `NO_PERMISSION`, `VALIDATION_ERROR`, `IDEMPOTENCY_CONFLICT`, `SYSTEM_ERROR` |

`customerId == null` hoặc blank = anonymous/walk-in → stored outcome `skipped / ANONYMOUS_CUSTOMER` (không phải validation error).

Command chuẩn hóa: `currencyCode` trim+uppercase, `soldAt` → UTC, `idempotencyKey` trim. `@RequiresPermission(PricingPermissions.savePriceMemory)` + `@RequiresTenant()`.

`RememberedPriceOutcomeDto` fields: `requestId`, `resultType` (`created|updated|skipped|blocked|overwrite_required`), `ruleId?`, `ruleVersion?`, `reasonCode?`, `warnings`, `isReplay`, optional overlapping rule refs.

**Thrown codes:** `NO_PERMISSION`, `VALIDATION_ERROR`, `IDEMPOTENCY_CONFLICT`, `SYSTEM_ERROR`.

**Stored reason codes (DTO data):** `ANONYMOUS_CUSTOMER`, `REFERENCE_INVALID`, `BELOW_FLOOR_BLOCKED`, `OVERWRITE_REQUIRED` (wire alias `duplicate_rule_overwrite_required`), `STALE_SALE_EVENT`, `PRICE_UNCHANGED`, `REMEMBERED_RULE_DISABLED`, `RULE_REVIEW_REQUIRED`. Deprecated: `MANUAL_RULE_PROTECTED`, `DUPLICATE_ACTIVE_RULE`.

**Update policy (Q-02 superseded 2026-08-04):** Một rule `remembered_price` open-ended active cho mỗi key `(tenant, customer, product, productUnit)` vẫn update-in-place khi khớp remembered rule đó. Overlap với **bất kỳ** active rule khác cùng key (mọi nguồn) → `overwrite_required`; sau `acknowledgeOverwrite` soft-delete overlapping rồi create/update nhớ giá. Không phân biệt manual vs import vs sales vs migration.

Sales chỉ phụ thuộc application contract/DTO — không import Pricing infrastructure hay Sales entities.

### RPC target

| Use case | RPC | Status |
| -------- | --- | ------ |
| Idempotent memory save | `pricing.save_remembered_price_from_order` | drafted / unapplied |

Params: `p_tenant_id`, `p_request_id`, `p_source_order_id`, `p_source_order_line_id`, `p_customer_id`, `p_product_id`, `p_product_unit_id`, `p_sold_price_minor`, `p_currency_code`, `p_sold_at`, `p_idempotency_key`.

JSON outcome (snake_case): `request_id`, `result_type`, `rule_id?`, `rule_version?`, `reason_code?`, `warnings`, `is_replay`.

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `memory_create_ok` | no applicable conflict | `created` + ruleId/version |
| `memory_update_ok` | updatable remembered rule | `updated` + ruleId/version |
| `memory_overwrite_required` | any active overlapping rule | `overwrite_required` |
| `memory_overwrite_confirmed` | overlap + acknowledgeOverwrite | soft-delete + created/updated |
| `memory_manual_conflict` | **deprecated** | legacy `skipped / MANUAL_RULE_PROTECTED` |
| `memory_retry_same_payload` | processed key | original outcome, `isReplay=true` |
| `memory_key_conflict` | same key/different payload | `IDEMPOTENCY_CONFLICT` |
| `memory_anonymous_customer` | anonymous customer | `skipped / ANONYMOUS_CUSTOMER` |
| `memory_reference_invalid` | stale customer/product/unit | `blocked / REFERENCE_INVALID` |
| `memory_below_floor_blocked` | below floor | `blocked / BELOW_FLOOR_BLOCKED` |
| `memory_stale_sale_skipped` | older soldAt | `skipped / STALE_SALE_EVENT` |
| `memory_disabled_remembered_skipped` | disabled remembered rule | `skipped / REMEMBERED_RULE_DISABLED` |
| `memory_system_error` | gateway failure | `SYSTEM_ERROR` |

## §S10 — US-10 Activity history

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetCustomerPriceRuleHistoryQuery` | `ruleId`, `cursor?`, `limit` (default 50, `1..100`) | `CursorPageDto<CustomerPriceRuleActivityDto>` | `NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`, `SYSTEM_ERROR` |

Permission: `PricingPermissions.viewCustomerPriceRuleHistory` (`pricing.customer_price_rule.view_history`) + tenant. `tenantId` luôn bind từ `IExecutionContext`.

#### Activity DTO (frozen)

- `id`, `activityType` (`created`/`updated`/`disabled`/`reenabled`/`deleted`/`importCreated`/`importUpdated`/`memoryCreated`/`memoryUpdated`/`overwritten` — soft-delete of overlapping rule during confirm)
- `actor`: `actorId?`, `displayName`, `isSystemActor` — legacy null actor → `System/Migration` / `isSystemActor=true`; có `created_by` → display prefix 8 chars, không IAM join
- `sourceType` required (`manual`/`excelImport`/`salesOrder`/`migration`) với deterministic RPC fallback cho legacy rows
- `oldValue?` (null trên create), `newValue` required (malformed/null → fail closed)
- `reason?` từ `new_value.reason` rồi `new_value.disabled_reason`
- `sourceTrace`: object luôn có mặt; fields nullable `importId`, `importRowId`, `orderId`, `orderLineId`, `memoryRequestId`, `soldAt` — lấy từ activity row tại thời điểm mutation
- `sensitiveValuesHidden`, `createdAt`
- Snapshots deep-unmodifiable; floor top-level keys redact khi thiếu `override_floor_price`

#### Cursor / sort

- Sort key: `(created_at DESC, id DESC)`
- Opaque cursor: Base64URL (no padding) of `{"createdAt":"...Z","id":"uuid"}`
- Fetch `limit+1`; `next_cursor` null khi `has_more=false`
- Malformed cursor → `VALIDATION_ERROR` `fieldErrors.cursor=invalid`
- Rule missing / cross-tenant / deleted → `NOT_FOUND` (không empty page)
- Valid rule, no activity → empty page

#### RPC

```text
pricing.get_customer_price_rule_history(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_cursor text default null,
  p_limit integer default 50
)
```

| Use case | RPC | Status |
| -------- | --- | ------ |
| Rule history | `pricing.get_customer_price_rule_history` | drafted / unapplied |

| scenario_id / enum | Trigger | Fake response |
| ------------------ | ------- | ------------- |
| `history_mixed_sources` / `historyMixedSources` | manual + import + memory | page sort desc, full traces |
| `history_second_page` / `historySecondPage` | valid cursor | older page, `hasMore=false` |
| `history_empty_legacy` / `historyEmptyLegacy` | valid rule, no activity | empty page |
| `history_system_actor` / `historySystemActor` | missing actor | `System/Migration` |
| `history_not_found` / `historyNotFound` | cross-tenant/deleted/missing | `NOT_FOUND` |
| `history_malformed_cursor` / `historyMalformedCursor` | invalid cursor | `VALIDATION_ERROR` |
| `history_denied` / `historyDenied` | missing permission | `NO_PERMISSION` |
| `history_system_error` / `historySystemError` | gateway failure | `SYSTEM_ERROR` |

## BR-08 — Resolve applicable customer price rule

Pricing-owned resolver only. Does **not** compute final order price, promotions, tax, or list-price fallback. Does **not** integrate Sales.

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `ResolveApplicableCustomerPriceRuleQuery` | tenantId, customerId, productId, productUnitId, businessDate | `ResolveApplicableCustomerPriceRuleResultDto` with optional `ApplicableCustomerPriceRuleDto` (`ruleId`, `price`, `effectivePeriod`, `sourceType`, `version`) | permission, validation, system |

Permission: `pricing.customer_price_rule.view`. Returns `rule: null` when no eligible rule. Eligible = active, not deleted, in closed period for `businessDate`, not blocked / empty `blockingCodes`. More than one applicable row → `SYSTEM_ERROR` (integrity).

### RPC

| Use case | RPC | Status |
| -------- | --- | ------ |
| Resolve applicable | `pricing.resolve_applicable_customer_price_rule` | draft `014_pricing_customer_price_rule_lifecycle_eligibility.sql` |

## BR-09 — Soft-delete customer price rule

No FE soft-delete action in this delivery. BE + SQL only.

### Contract

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `DeleteCustomerPriceRuleCommand` | tenantId, actorId, ruleId, expectedVersion | detail DTO (deleted; `availableActions = []`); replay returns current deleted state | `NOT_FOUND`, `STATE_CHANGED`, `INVALID_STATUS` (disabled), `NO_PERMISSION`, system |

Permission: `pricing.customer_price_rule.delete`. `active`/`needs_review` → `deleted` + `deletedAt` + one `deleted` activity. Already deleted = idempotent replay. Detail DTO may include `deletedAt`.

### RPC / DDL

| Use case | RPC / DDL | Status |
| -------- | --------- | ------ |
| Soft delete | `pricing.delete_customer_price_rule` | draft `014` |
| Exclusion + `deleted_at` | table constraints | draft `014` (manual order after `013`) |

## Contract freeze checklist

- [ ] DTO nullability and enum wire values reviewed by FE/BE.
- [ ] RPC param names exactly match command/query mapping.
- [ ] Fake scenarios implemented before FE work.
- [ ] Error codes are typed; no UI parsing of text.
- [ ] Tenant/actor are context-derived.
- [ ] Money/idempotency/version semantics have tests.
