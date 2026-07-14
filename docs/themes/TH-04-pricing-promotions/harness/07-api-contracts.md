# TH-04 EP02 — API contracts (FE ↔ BE)

Source of truth giữa presentation và application cho EP02. Types sẽ sống trong `modules/pricing/application/`; facade mục tiêu `IPricingModule`.

**Baseline 2026-07-14:** contracts ở trạng thái design target, chưa có module/RPC/migration implementation. FE dùng future `FakePricingModule`; BE dùng gateway fakes/in-memory harness. SQL khi có chỉ draft dưới `_drafts/`.

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
| `DUPLICATE_ACTIVE_RULE` | Active interval conflict | Show conflict summary/link |
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
| `ProductUnitRefDto` | `productId`, `productName`, `productUnitId`, `unitName`, `sellableStatus` |
| `RuleValidationOutcomeDto` | outcome, warning codes, blocking codes, floor/list snapshots? |
| `CustomerPriceRuleListItemDto` | id, customer/product/unit refs, price, type, source, persisted/derived status, effectivity, updatedAt |
| `CustomerPriceRuleDetailDto` | list fields + note, validation outcome, source trace, audit metadata, version, availableActions |
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
| `CreateCustomerPriceRuleCommand` | customerId, productId, productUnitId, rulePriceMinor, currencyCode, effectiveFrom, effectiveTo?, note?, acknowledgeFloorWarning, idempotencyKey | `CreateCustomerPriceRuleResult(rule, warnings)` | validation, duplicate, floor, reference, permission |

Server assigns type=`special_price`, source=`manual`, initial status/outcome and actor/tenant. UI cannot override them.

### RPC target

| Use case | RPC | Status |
| -------- | --- | ------ |
| Create rule atomically | `pricing.create_customer_price_rule` | target / not drafted |

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `create_rule_ok` | valid unique candidate | active detail DTO |
| `create_rule_duplicate` | overlapping key | `DUPLICATE_ACTIVE_RULE` |
| `create_rule_floor_warning` | warn policy | result + warning |
| `create_rule_floor_blocked` | block/no override | `BELOW_FLOOR_BLOCKED` |
| `create_rule_reference_invalid` | stale customer/unit | `REFERENCE_INVALID` |

## §S2 — US-01 Search/list

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `SearchCustomerPriceRulesQuery` | q?, statuses?, sources?, customerId?, productId?, businessDate, cursor?, limit | `CursorPageDto<CustomerPriceRuleListItemDto>` | permission, validation, system |

Search response uses resolved labels but IDs remain authoritative. Default query excludes deleted. Cursor sort is updatedAt desc + ID desc.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Search/list | `pricing.search_customer_price_rules` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `search_rules_default` | no filters | mixed source/status page |
| `search_rules_empty` | empty tenant | empty page |
| `search_rules_no_result` | unmatched q | empty page with active filters |
| `search_rules_error` | gateway failure | `SYSTEM_ERROR` |

## §S3 — US-03 Detail

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetCustomerPriceRuleDetailQuery` | ruleId, businessDate | `CustomerPriceRuleDetailDto` | permission, not found, system |

`availableActions` is server-derived from status + permissions but UI still receives access enforcement on mutation.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Rule detail | `pricing.get_customer_price_rule_detail` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `rule_detail_active` | active ID | detail + edit/disable/history |
| `rule_detail_disabled` | disabled ID | detail + edit/reenable/history |
| `rule_detail_not_found` | invisible ID | `NOT_FOUND` |
| `rule_detail_reference_stale` | archived product/customer | detail + warning labels |

## §S4 — US-02 Choose add method

No server command/RPC. FE derives visible routes from capabilities and destinations recheck access. Fake test cases: both actions, create-only, import-only, neither, dismiss/no mutation.

## §S5 — US-06 Update rule

| Symbol | Input summary | Success | Errors |
| ------ | ------------- | ------- | ------ |
| `UpdateCustomerPriceRuleCommand` | ruleId, expectedVersion, price/effective dates/note, acknowledgeFloorWarning | updated detail DTO | validation, duplicate, floor, reference, state changed, invalid status |

Immutable via this command: tenant/customer/product/unit/type/source and source trace.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Update atomically | `pricing.update_customer_price_rule` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `update_rule_ok` | current version + changed price | detail version+1 |
| `update_rule_noop` | no actual change | current detail/no new activity |
| `update_rule_state_changed` | stale version | `STATE_CHANGED` |
| `update_rule_duplicate` | new interval overlaps | `DUPLICATE_ACTIVE_RULE` |

## §S6 — US-07 Disable rule

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `DisableCustomerPriceRuleCommand` | ruleId, expectedVersion, reason? | disabled detail DTO | permission, not found, invalid status, state changed |

Repeated request against the already-disabled same state returns the current DTO or stable idempotent result and must not append duplicate activity.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Disable | `pricing.disable_customer_price_rule` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `disable_rule_ok` | active/current | disabled detail |
| `disable_rule_already_disabled` | retry | current disabled detail |
| `disable_rule_state_changed` | stale version | `STATE_CHANGED` |
| `disable_rule_denied` | missing permission | `NO_PERMISSION` |

## §S7 — US-08 Reenable rule

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `PrecheckCustomerPriceRuleReenableQuery` | ruleId, expectedVersion, businessDate | `RuleValidationOutcomeDto` + precheck token/version | permission, not found, invalid status |
| `ReenableCustomerPriceRuleCommand` | ruleId, expectedVersion, precheckToken?, acknowledgeFloorWarning | active detail DTO | duplicate, floor, reference, state changed, invalid status |

Precheck token is advisory/staleness evidence. RPC always runs authoritative checks again.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Precheck | `pricing.precheck_customer_price_rule_reenable` | target / not drafted |
| Reenable | `pricing.reenable_customer_price_rule` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `reenable_precheck_valid` | clean disabled rule | valid outcome |
| `reenable_precheck_warning` | below floor warn | warning outcome |
| `reenable_precheck_blocked` | duplicate/reference/floor block | blocked outcome |
| `reenable_state_changed` | state changes after precheck | `STATE_CHANGED` |
| `reenable_ok` | current valid confirm | active detail |

## §S8 — US-05 Excel import

### Contracts

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `StartCustomerPriceRuleImportCommand` | templateVersion, file token/bytes descriptor, originalFileName, importMode | `CustomerPriceRuleImportDto` | permission, validation, system |
| `GetCustomerPriceRuleImportQuery` | importId, rowStatus?, cursor?, limit | batch + paged `ImportRowPreviewDto` | permission, not found |
| `ConfirmCustomerPriceRuleImportCommand` | importId, expectedVersion, acknowledgeWarningRows | final/in-progress batch DTO | invalid status, state changed, floor, system |
| `CancelCustomerPriceRuleImportCommand` | importId, expectedVersion | canceled batch DTO | invalid status, state changed |

`ImportRowPreviewDto`: row number, raw refs, resolved refs/unit strategy, normalized money/dates, status, action, error/warning codes, matched rule ID if visible.

### RPC targets

| Use case | RPC | Status |
| -------- | --- | ------ |
| Create/validate batch | `pricing.create_customer_price_rule_import` | target / not drafted |
| Read batch/rows | `pricing.get_customer_price_rule_import` | target / not drafted |
| Confirm | `pricing.confirm_customer_price_rule_import` | target / not drafted |
| Cancel | `pricing.cancel_customer_price_rule_import` | target / not drafted |

### Fake scenarios

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `import_ready_mixed` | valid + warning + error rows | ready batch/preview |
| `import_ambiguous_unit` | product multi-unit/no default | row error `AMBIGUOUS_PRODUCT_UNIT` |
| `import_confirm_partial` | some row changes at commit | completed_with_errors |
| `import_confirm_retry` | already completed | same final result/no reapply |
| `import_cancel_ok` | ready batch | canceled batch |

## §S9 — US-09 Remember price from Sales

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SaveRememberedPriceFromOrderCommand` | sourceOrderId, sourceOrderLineId, customerId, productId, productUnitId, soldPriceMinor, currencyCode, soldAt, idempotencyKey | `RememberedPriceOutcomeDto` | permission, reference, validation, idempotency conflict, system |

Outcome fields: requestId, resultType (`created|updated|skipped|blocked`), ruleId?, ruleVersion?, reasonCode?, warnings.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Idempotent memory save | `pricing.save_remembered_price_from_order` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `memory_create_ok` | no applicable conflict | created outcome |
| `memory_update_ok` | updatable remembered rule | updated outcome |
| `memory_manual_conflict` | active manual rule | skipped/blocked outcome |
| `memory_retry_same_payload` | processed key | original outcome |
| `memory_key_conflict` | same key/different payload | `IDEMPOTENCY_CONFLICT` |
| `memory_anonymous_customer` | no valid customer | skipped/blocked reason |

Sales must depend only on this application contract/DTO, never pricing infrastructure or persistence models.

## §S10 — US-10 Activity history

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetCustomerPriceRuleHistoryQuery` | ruleId, cursor?, limit | `CursorPageDto<CustomerPriceRuleActivityDto>` | permission, not found, system |

Activity DTO: ID/type, actor display/system marker, source, old/new snapshots, reason, import/memory/order trace IDs as allowed, createdAt. Sort createdAt desc + ID desc.

| Use case | RPC | Status |
| -------- | --- | ------ |
| Rule history | `pricing.get_customer_price_rule_history` | target / not drafted |

| scenario_id | Trigger | Fake response |
| ----------- | ------- | ------------- |
| `history_mixed_sources` | manual/import/memory activities | paged timeline |
| `history_empty_legacy` | no activity | empty page |
| `history_system_actor` | migration/system record | fallback actor label |
| `history_denied` | missing permission | `NO_PERMISSION` |

## Contract freeze checklist

- [ ] DTO nullability and enum wire values reviewed by FE/BE.
- [ ] RPC param names exactly match command/query mapping.
- [ ] Fake scenarios implemented before FE work.
- [ ] Error codes are typed; no UI parsing of text.
- [ ] Tenant/actor are context-derived.
- [ ] Money/idempotency/version semantics have tests.

