# Pricing Import Duplicate Blocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Treat an overlapping active customer price rule as a blocking import-row error while preserving partial import for all other eligible rows.

**Architecture:** Keep the existing S8 batch workflow and DTOs. Change the authoritative SQL evaluation/confirm policy and align the ERP in-memory adapter plus application fake; the existing presentation derives red error styling, counters, and CTA eligibility from row/batch statuses.

**Tech Stack:** Dart 3, Flutter/Bloc, PostgreSQL PL/pgSQL draft RPCs, package tests and ERP widget/E2E tests.

## Global Constraints

- A duplicate means overlap with another active, non-deleted rule having the same tenant/customer/product/product-unit key.
- Explicit update excludes its own `rule_id` from conflict detection.
- A duplicate row is skipped; other valid/warning rows remain importable.
- Import must never auto-disable the conflicting active rule.
- SQL changes stay in `supabase/migrations/_drafts/`; no timestamped migration is created.
- Preserve unrelated dirty workspace changes.

---

### Task 1: Freeze the import overlap contract

**Files:**
- Modify: `modules/pricing/infrastructure/test/sql/pricing_customer_price_rule_lifecycle_br070809_contract_test.dart`
- Modify: `modules/pricing/infrastructure/test/pricing_sql_contract_test.dart`
- Modify: `docs/themes/TH-04-pricing-promotions/harness/07-api-contracts.md`
- Modify: `docs/themes/TH-04-pricing-promotions/Epic-02-customer-price-rules/US-05.md`

**Interfaces:**
- Consumes: SQL draft `013_pricing_customer_price_rule_import_overlap_policy.sql`.
- Produces: executable assertions that duplicate codes are errors and import confirm contains no overlap auto-disable call.

- [ ] Add failing SQL contract assertions requiring `DUPLICATE_ACTIVE_RULE` in `error_codes`, row action `skip`, and no `_auto_disable_overlapping_customer_price_rules` call inside import confirm.
- [ ] Run the two focused SQL contract tests and verify they fail against the current warning/auto-disable policy.
- [ ] Update S8 contract and US-05 scenarios to specify row-level failure, partial continuation, self-update exclusion, and confirm-time recheck.

### Task 2: Implement authoritative duplicate blocking in the SQL draft

**Files:**
- Modify: `supabase/migrations/_drafts/013_pricing_customer_price_rule_import_overlap_policy.sql`

**Interfaces:**
- Consumes: `_evaluate_customer_price_rule_import_row(...)` and `confirm_customer_price_rule_import(...)` signatures already frozen by S8.
- Produces: preview/confirm JSON with duplicate in `error_codes`; confirm marks only the row failed and never disables another rule.

- [ ] Change overlap evaluation to append `DUPLICATE_ACTIVE_RULE` to `error_codes`, set `action = 'skip'`, and exclude the explicit update target ID.
- [ ] Retain confirm re-evaluation after acquiring the rule-key advisory lock so a new conflict becomes a failed row.
- [ ] Remove import create/update calls to `_auto_disable_overlapping_customer_price_rules`.
- [ ] Run focused SQL contract tests and verify green.

### Task 3: Align ERP in-memory behavior with partial import

**Files:**
- Modify: `apps/erp/test/features/pricing/data/in_memory_pricing_module_test.dart`
- Modify: `apps/erp/lib/features/pricing/data/in_memory_pricing_module.dart`

**Interfaces:**
- Consumes: `CustomerPriceRuleImportRowPreviewDto.status/errorCodes` and `ConfirmCustomerPriceRuleImportCommand`.
- Produces: in-memory preview that classifies duplicates as errors and confirm that skips errors without mutating existing rules.

- [ ] Add a failing regression test that starts an import containing one duplicate and one eligible row, then asserts duplicate=`error`, eligible row imports, batch=`completed_with_errors`, and the original active rule remains active/version unchanged.
- [ ] Run the focused test and verify the current overwrite behavior fails it.
- [ ] Evaluate overlap while building preview; exclude the explicit `ruleId` target.
- [ ] In confirm, process only `valid` rows and acknowledged `warning` rows; count `error` rows as failed/skipped and do not call `_importRow` for them.
- [ ] Remove duplicate auto-disable from `_importRow`; recheck immediately before mutation and fail only that row if a race introduces a conflict.
- [ ] Run the focused test and existing in-memory Pricing tests.

### Task 4: Align fake and presentation regression coverage

**Files:**
- Modify: `modules/pricing/application/test/fake_pricing_module_test.dart`
- Modify: `modules/pricing/application/lib/src/testing/fake_pricing_module.dart`
- Modify: `modules/pricing/presentation/test/price_rule_import_widgets_test.dart`
- Modify: `apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart` if page-level coverage is not already sufficient.

**Interfaces:**
- Consumes: existing import DTOs and `PriceRuleImportRowTile` error rendering.
- Produces: a duplicate-error fake scenario and regression evidence that the preview shows a red error while continuing remains available when another row is importable.

- [ ] Add failing tests for duplicate error DTO classification and the existing Vietnamese duplicate message rendered in error tone.
- [ ] Update fake import detail/batch counters so duplicate rows use `errorCodes`, `errorRows`, and do not require warning acknowledgement.
- [ ] Verify a mixed preview enables continuation and an all-error preview disables it.
- [ ] Run application, presentation, and ERP Pricing-focused tests.

### Task 5: Verify scope and quality

**Files:**
- Verify all changed files only.

**Interfaces:**
- Consumes: completed Tasks 1–4.
- Produces: analyzer/test/diff evidence and GitNexus affected-flow report.

- [ ] Run `dart format` on changed Dart files and `git diff --check`.
- [ ] Run focused analyzers for Pricing application/infrastructure/presentation and ERP files.
- [ ] Run Pricing-focused application, infrastructure, presentation, and ERP tests.
- [ ] Run `bash scripts/ci/verify_harness.sh` and record unrelated baseline failures separately.
- [ ] Run GitNexus `detect_changes(scope: all)` and review the affected processes.
