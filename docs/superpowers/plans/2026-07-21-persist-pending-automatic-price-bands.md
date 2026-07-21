# Persist Pending Automatic Product Price Bands Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist one base-unit `product_unit_price_bands` row as soon as guided creation has a base unit and a pricing mode; automatic bands display `0đ` until a base price can materialize them, then recalculate correctly.

**Architecture:** Keep `catalog.product_unit_price_bands` as the durable record of the selected pricing mode. `ruleBased` rows resolve the tenant's currently active Store Price Rule whenever a base price or the rule changes; `customConfig` rows resolve their stored ratios whenever a base price changes; `manual` rows remain absolute prices. The Catalog RPC transaction remains the source of truth, while the guided-create resolver and fake module mirror the same behavior for UI and tests.

**Tech Stack:** Flutter/Dart, flutter_bloc, Vet45 Catalog CQRS, Supabase PostgreSQL RPC drafts, Dart/Flutter tests.

## Global Constraints

- Do not create, rename, or edit `supabase/migrations/[0-9]*.sql`; create **one** patch draft only under `supabase/migrations/_drafts/`.
- **Draft merge strategy:** the new draft `catalog_pending_automatic_price_bands.sql` **supersedes** the user's uncommitted `catalog_restore_create_guided_product_note.sql` for `create_guided_product`. Copy the `p_note` signature + forward into the new draft, then delete (or leave empty/retired) the note-only draft so two drafts never both redefine the same RPC. Incorporate rather than discard the note-forwarding behavior and the related contract-test coverage.
- Preserve and extend the user's uncommitted changes in `modules/catalog/infrastructure/test/price_band_sql_contract_test.dart`; do not wipe unrelated assertions.
- Do not hand-edit generated `.g.dart` files.
- Before editing each existing Dart symbol, run GitNexus `impact(target: ..., direction: "upstream")`; stop for user approval if the risk is HIGH or CRITICAL. GitNexus currently does not index the SQL RPC symbols, so record the failed lookup and use focused contract tests for them.
- `ruleBased` must use the Store Price Rule active at the recalculation time, not a ratio snapshot from creation.
- `customConfig` must use `list_markup_ratio` / `floor_markup_ratio` stored on its own band; `manual` must never be automatically changed.
- A row with an automatic pricing mode that has not yet successfully materialized stores numeric `0` for list and floor before/after VAT; it is not represented by `NULL`.
- **Readiness (locked decision):** a zero automatic band is persisted configuration, not proof the product is ready to sell.
  - `missing_price` (thiếu Giá cơ sở) vẫn apply như hiện tại khi mode yêu cầu base price.
  - `has_price_band` / `missing_price_band` **không** coi band automatic là complete chỉ vì amounts = `0`. Complete chỉ khi band đã materialize được giá bán thực sự: có Giá cơ sở **và** (với `ruleBased`) có active Store Price Rule để resolve; `manual` vẫn complete khi có list before+after VAT tuyệt đối.
  - UI/read models: `listBeforeVatMissing` (hoặc tương đương) phải `true` cho automatic pending (`0` chưa materialize), không chỉ khi SQL `NULL`.
- No direct UI Supabase calls and no application-to-infrastructure imports.

### Locked decisions from code review (2026-07-21)

1. **`ruleBased` + `store_price_rule_id`:** pending `ruleBased` **được phép** `store_price_rule_id IS NULL` cho đến lần materialize thành công. Draft **phải** `ALTER` `product_unit_price_bands_calculation_source_check` (và validate lại) vì constraint hiện tại bắt buộc `store_price_rule_id IS NOT NULL` cho `ruleBased`. Khi materialize thành công, set `store_price_rule_id` = id rule active lúc đó (metadata lần materialize gần nhất).
2. **Insert path cho `ruleBased` pending:** không dùng `apply_store_price_rule` khi thiếu base/rule. Mở rộng `set_product_unit_price_band` để chấp nhận `source_type = 'ruleBased'` với prices `0` và `store_price_rule_id` nullable khi chưa materialize (bỏ/thu hẹp exception `use apply_store_price_rule` cho case pending). `apply_store_price_rule` vẫn dùng cho luồng apply tường minh khi đủ điều kiện.
3. **`null` → `0`:** thay semantics pending cũ trong `20260721002` (NULL amounts + `materialization_check` all-null branch). Draft cập nhật `product_unit_price_bands_materialization_check` / comments để amounts `0` là pending automatic hợp lệ; readiness SQL/facts phải đổi theo quyết định ở trên — **không** để `list_price_* is not null` một mình clear `missing_price_band`.
4. **Resolver:** base-price gate cho custom đã được bỏ; Task 2 chỉ đổi `null` amounts → `0`, không “re-open” validation ratios/base-unit.

---

## Agreed Acceptance Examples

| Creation input | Initial base price | Persisted base-unit band | After setting base price `100,000đ` |
| --- | ---: | --- | --- |
| `ruleBased`, active rule `+20% / +10%` | missing | source=`ruleBased`, list/floor=`0 / 0`, `storePriceRuleId` có thể đã gắn rule active (metadata) hoặc `null` nếu chưa từng materialize | `120,000 / 110,000` from the rule active then |
| `ruleBased`, **không** có active rule | missing | source=`ruleBased`, list/floor=`0 / 0`, `storePriceRuleId`=`null`; readiness vẫn `missing_price_band` (và `missing_price` nếu thiếu base) | Sau khi có rule active **và** base: materialize từ rule hiện tại |
| `customConfig`, ratios `+30% / +10%` | missing | source=`customConfig`, ratios retained, list/floor=`0 / 0` | `130,000 / 110,000` from the stored ratios |
| `manual`, input `150,000 / 120,000` | missing | source=`manual`, list/floor=`150,000 / 120,000` | unchanged |

If the store rule changes from `+20%` to `+30%` before base price is entered, the later rule-based materialization is `130,000đ`, not `120,000đ`.

## File Structure

| File | Responsibility |
| --- | --- |
| `supabase/migrations/_drafts/catalog_pending_automatic_price_bands.sql` | Atomic patch: schema checks + RPCs; persist automatic rows at zero; allow nullable `store_price_rule_id` on pending `ruleBased`; resolve current active rule; readiness facts treat zero automatic as incomplete. |
| `supabase/migrations/_drafts/catalog_restore_create_guided_product_note.sql` | **Superseded** by the patch above (note forward merged in). Remove after merge so only one draft owns `create_guided_product`. |
| `modules/catalog/infrastructure/test/price_band_sql_contract_test.dart` | Static contract assertions for the new draft (schema + RPC + readiness snippets); retire note-only draft assertions into the new draft test. |
| `modules/catalog/presentation/lib/src/mappers/guided_price_band_submission_resolver.dart` | Submit `0` display amounts + ratios for pending custom configuration. |
| `modules/catalog/presentation/test/guided_price_band_submission_resolver_test.dart` | Pin pending-custom → `0 / 0` + ratios. |
| `modules/catalog/application/lib/src/testing/fake_catalog_module.dart` | Persist pending automatic as zero; recalc `ruleBased` from current active rule; align `hasPriceBand` / `listBeforeVatMissing` with readiness decision. |
| `modules/catalog/application/test/fake_catalog_module_test.dart` | Guided create lifecycle + update existing pending-custom `isNull` expectations to zero + readiness. |
| `docs/themes/TH-02-product-pricing/EPIC-02-guided-creation/US-02/FR-03.md` | Guided-create business scenario. |
| `docs/themes/TH-02-product-pricing/harness/07-api-contracts.md` | Zero pending amounts; nullable `storePriceRuleId` until materialize; readiness wording. |

Optional touch if facts live outside the three RPCs (include in same draft `Touches:` / body as needed):

| File / symbol | Why |
| --- | --- |
| Readiness fact SQL inside draft (e.g. `get_product_readiness` / fact refresh helpers that compute `has_price_band`) | `list_price_* is not null` alone must not clear `missing_price_band` for automatic pending zeros |
| Domain/read helpers only if fake/DTO already expose `listBeforeVatMissing` / `isComplete` | Mirror “pending zero ≠ complete band” |

### Task 1: Define and lock the user-visible guided-create contract

**Files:**

- Modify: `docs/themes/TH-02-product-pricing/EPIC-02-guided-creation/US-02/FR-03.md`
- Modify: `docs/themes/TH-02-product-pricing/harness/07-api-contracts.md`

**Consumes:** The agreed pricing-mode matrix and locked decisions above.

**Produces:** One unambiguous contract for RPC, fake, and UI tests: a base unit plus a selected pricing mode always produces one base-unit band; pending automatic uses `0` not `null`; readiness does not treat pending zero as sellable price band.

- [ ] **Step 1: Add the failing/absent scenario to the product requirement**

  Add this scenario to `EPIC-02-guided-creation/US-02/FR-03.md`:

  ```gherkin
  Scenario: Lưu cấu hình giá tự động khi chưa có Giá cơ sở
    Given sản phẩm mới có đơn vị cơ sở là "Lọ"
    And người dùng chưa nhập Giá cơ sở định giá
    When người dùng chọn "Giá cửa hàng" hoặc "Tự động riêng"
    And người dùng lưu sản phẩm
    Then hệ thống tạo Product Unit Price Band cho đơn vị "Lọ"
    And Giá niêm yết và Giá sàn ban đầu là 0 đồng
    And hệ thống giữ nguồn tính giá và tỷ lệ cấu hình nếu có
    And sản phẩm chưa sẵn sàng bán vì thiếu Giá cơ sở / chưa materialize khung giá
    When người dùng nhập Giá cơ sở định giá hợp lệ sau đó
    Then hệ thống tự tính lại khung giá tự động (ruleBased dùng rule active lúc đó)
  ```

- [ ] **Step 2: Make the contract explicit in `07-api-contracts.md`**

  Replace the pending-`null` wording in the EPIC-06/US-03 mode matrix and RPC mapping with:

  ```markdown
  | `ruleBased` | `store_price_rules` active tại thời điểm tái tính | `storePriceRuleId` nullable khi chưa materialize; sau materialize = metadata lần resolve gần nhất | hai ratio riêng trên band | Thiếu Giá cơ sở hoặc chưa có rule active: tạo/giữ band `0`; khi có/đổi Giá cơ sở hoặc rule active đổi: materialize lại từ rule active hiện tại |
  | `customConfig` | `product_unit_price_bands` | `listMarkupRatio`; floor ratio optional | `storePriceRuleId` | Thiếu Giá cơ sở: lưu band `0` và tỷ lệ; khi có/đổi Giá cơ sở: materialize lại |
  | `manual` | Không có | Giá tuyệt đối | rule id và hai ratio | Không tự tái tính |
  ```

  Also state explicitly:

  - `CreateGuidedProductCommand` tạo base-unit row cho cả ba mode khi có base unit; **không** mô tả pending bằng `null` amounts.
  - `has_price_band` / clear `missing_price_band` chỉ khi band automatic đã materialize (có base + với `ruleBased` resolve được rule active), hoặc `manual` có list before+after VAT.
  - Change history: đổi Store Price Rule recalculate **mọi** active `ruleBased` band của tenant theo rule active mới (không còn giới hạn “chỉ band gắn đúng historical rule id”); update sentence hiện tại trong contract cho khớp.
  - Retire references to draft `catalog_product_price_band_pending_custom_config.sql` / NULL pending as current behavior; point at the new draft intent.

- [ ] **Step 3: Review the documentation change**

  Run:

  ```bash
  git diff --check -- docs/themes/TH-02-product-pricing/EPIC-02-guided-creation/US-02/FR-03.md docs/themes/TH-02-product-pricing/harness/07-api-contracts.md
  ```

  Expected: no whitespace errors; terminology vẫn `ruleBased` / `customConfig` / `manual`.

- [ ] **Step 4: Commit the contract change**

  ```bash
  git add docs/themes/TH-02-product-pricing/EPIC-02-guided-creation/US-02/FR-03.md docs/themes/TH-02-product-pricing/harness/07-api-contracts.md
  git commit -m "docs: define pending automatic product price bands"
  ```

### Task 2: Make guided-create submission retain pending custom configuration as `0đ`

**Files:**

- Modify: `modules/catalog/presentation/lib/src/mappers/guided_price_band_submission_resolver.dart`
- Modify: `modules/catalog/presentation/test/guided_price_band_submission_resolver_test.dart`

**Consumes:** `ProductGuidedCreateState`, `PriceBandSourceType.customConfig`, `StorePriceSuggestionCalculator` (current resolver already allows missing base price).

**Produces:** `GuidedPriceBandSubmission(sourceType: customConfig, listBeforeVat: 0, floorBeforeVat: 0, ratios...)` when there is a base unit and valid ratios but no base price.

- [ ] **Step 1: Replace the pending-custom test assertions**

  In `keeps custom configuration pending when base price is missing`, replace `isNull` with:

  ```dart
  expect(submission.sourceType, PriceBandSourceType.customConfig);
  expect(submission.listBeforeVat, 0);
  expect(submission.floorBeforeVat, 0);
  expect(submission.listMarkupRatio, 0.3);
  expect(submission.floorMarkupRatio, 0.1);
  ```

- [ ] **Step 2: Run the focused test to observe failure**

  Run:

  ```bash
  cd modules/catalog/presentation && flutter test test/guided_price_band_submission_resolver_test.dart
  ```

  Expected: FAIL because the resolver currently returns `null` amounts (`suggested?.listBeforeVat` without `?? 0`).

- [ ] **Step 3: Implement the minimum resolver change**

  In `_resolveCustomConfig`, **keep** unit + ratio validation unchanged. Only default missing suggestion amounts to zero:

  ```dart
  final baseCost = parseCatalogCurrencyAmount(state.baseCost);
  // Validate listPercent/floorPercent before this block (unchanged).
  final listRatio = listPercent / 100;
  final floorRatio = floorPercent / 100;
  final suggested = baseCost == null
      ? null
      : StorePriceSuggestionCalculator.suggest(
          basePrice: baseCost.toDouble(),
          listMarkupRatio: listRatio,
          floorMarkupRatio: floorRatio,
        );

  return GuidedPriceBandReady(
    GuidedPriceBandSubmission(
      sourceType: PriceBandSourceType.customConfig,
      useStorePriceRule: false,
      listBeforeVat: suggested?.listBeforeVat ?? 0,
      floorBeforeVat: suggested?.floorBeforeVat ?? 0,
      listMarkupRatio: listRatio,
      floorMarkupRatio: floorRatio,
    ),
  );
  ```

  Do not reintroduce a mandatory-base-price invalid branch. Do not modify the manual or `storeRule` paths.

- [ ] **Step 4: Re-run the focused test**

  Run the command from Step 2.

  Expected: all resolver tests pass, including calculation from a supplied base price and `0 / 0` from a missing one.

- [ ] **Step 5: Commit the presentation-boundary change**

  ```bash
  git add modules/catalog/presentation/lib/src/mappers/guided_price_band_submission_resolver.dart modules/catalog/presentation/test/guided_price_band_submission_resolver_test.dart
  git commit -m "feat: retain pending custom price configuration"
  ```

### Task 3: Implement the atomic database draft for pending automatic bands

**Files:**

- Create: `supabase/migrations/_drafts/catalog_pending_automatic_price_bands.sql`
- Modify: `modules/catalog/infrastructure/test/price_band_sql_contract_test.dart`
- Remove or empty after merge: `supabase/migrations/_drafts/catalog_restore_create_guided_product_note.sql` (behavior folded into the new draft)

**Consumes:** Promoted `20260721002_catalog_product_price_band_pending_custom_config.sql`, `20260717008_catalog_product_price_band_change_history_recalculation.sql`, `20260717004_catalog_price_band_calculation_modes_schema.sql` (source check), and the user's note draft body.

**Produces:** One non-timestamped patch draft that (a) relaxes/updates CHECK constraints, (b) redefines `create_guided_product` (with `p_note`), `set_product_unit_price_band`, `_recalculate_product_price_bands`, and (c) updates any readiness-fact SQL in the same draft that currently treats `list_price_* is not null` as complete for automatic pending zeros. Header `-- Touches:` must list **every** `create or replace` function in the file.

- [ ] **Step 1: Add static contract tests before the SQL**

  Add one test named `pending automatic bands persist as zero and materialize from current sources` that reads `supabase/migrations/_drafts/catalog_pending_automatic_price_bands.sql`. Assert all of the following (adjust if readiness helper names differ, but keep intent):

  ```dart
  expect(sql, contains('-- Kind: patch'));
  expect(sql, contains('-- Intent: catalog_pending_automatic_price_bands'));
  expect(sql, contains('product_unit_price_bands_calculation_source_check'));
  expect(sql, contains('p_note text default null'));
  expect(sql, contains('p_note => p_note'));
  // Touches must include every replaced RPC; readiness helpers if redefined.
  expect(
    sql,
    contains(
      '-- Touches: create_guided_product, set_product_unit_price_band, _recalculate_product_price_bands',
    ),
  );
  expect(guided, contains("when 'ruleBased' then"));
  expect(guided, contains("when 'customConfig' then"));
  expect(guided, contains('p_list_price_before_vat => 0'));
  expect(guided, contains('p_floor_price_before_vat => 0'));
  expect(setBand, contains('when v_base_price is null then 0'));
  expect(setBand, isNot(contains("raise exception 'validation_exception: use apply_store_price_rule'")));
  expect(recalculate, contains("pb.source_type = 'ruleBased'"));
  expect(recalculate, contains("pb.source_type = 'customConfig'"));
  expect(recalculate, isNot(contains("pb.source_type = 'manual'")));
  expect(recalculate, contains('r.tenant_id = pb.tenant_id'));
  expect(recalculate, contains("r.status = 'active'"));
  expect(recalculate, isNot(contains('on sr.id = pb.store_price_rule_id')));
  ```

  Migrate the note-restoration test to assert against the **new** draft (still requires `p_note`). Delete assertions that pointed at `catalog_restore_create_guided_product_note.sql` once that file is removed. Keep the historical promoted-migration test for `20260721002` as documentation of past NULL behavior; do not rewrite that file.

- [ ] **Step 2: Run the focused SQL contract test and confirm failure**

  Run:

  ```bash
  cd modules/catalog/infrastructure && dart test test/price_band_sql_contract_test.dart
  ```

  Expected: FAIL because the new draft does not yet exist (or fails new assertions).

- [ ] **Step 3: Write the patch draft with the exact behavioral boundaries**

  Use this required header (extend `-- Touches:` if the draft also replaces readiness RPCs):

  ```sql
  -- Title: catalog persist pending automatic product price bands
  -- Kind: patch
  -- Intent: catalog_pending_automatic_price_bands
  -- Context: TH-02 guided create — keep selected automatic pricing when base price is absent
  -- Touches: create_guided_product, set_product_unit_price_band, _recalculate_product_price_bands
  -- Safety: idempotent ; medium — schema checks + zero-valued automatic bands; recalculates only automatic sources
  -- Depends on: 20260721002_catalog_product_price_band_pending_custom_config.sql
  ```

  **Schema (required in the same draft):**

  - Drop/recreate `product_unit_price_bands_calculation_source_check` so `ruleBased` allows `store_price_rule_id IS NULL` **or** NOT NULL, still forbids markup ratios on `ruleBased`, and keeps `customConfig`/`manual` exclusivity.
  - Update `product_unit_price_bands_materialization_check` / column comments: automatic pending uses numeric `0` (not all-`NULL`); do not leave the old “customConfig waits with null” comment as the live rule.
  - Update readiness fact computation so automatic pending zeros do **not** set `has_price_band = true`.

  **`set_product_unit_price_band`:**

  ```sql
  -- customConfig (and ruleBased pending) when base missing
  v_list_price := case
    when v_base_price is null then 0
    else round(v_base_price * v_conversion_rate * (1 + p_list_markup_ratio))
  end;
  v_floor_price := case
    when p_floor_markup_ratio is null then 0
    when v_base_price is null then 0
    else round(v_base_price * v_conversion_rate * (1 + p_floor_markup_ratio))
  end;
  ```

  - Accept `ruleBased` pending: prices `0`, `store_price_rule_id` nullable, no markup ratios on row.
  - When base + active rule exist for `ruleBased`, materialize and set `store_price_rule_id` to that active rule.
  - Keep `manual` absolute-price validation.

  **`create_guided_product`:**

  - Include `p_note text default null` and `p_note => p_note` (from the superseded note draft).
  - Retain no-base-price validation relaxation for `customConfig`.
  - Create `customConfig` base-unit row via `set_product_unit_price_band` with ratios and zero placeholders.
  - When `ruleBased` and base unit exists: always create a row (even without base price and/or without active rule) with prices `0`, source `ruleBased`, `store_price_rule_id` null until materialize; if base + active rule exist in the same transaction, materialize immediately.
  - Preserve manual path and validation.
  - Resolve stale overloads the same way `20260721002` / the note draft did if still needed for PostgREST.

  **`_recalculate_product_price_bands`:**

  - Resolve `ruleBased` by joining the **active** rule for `pb.tenant_id` (not `pb.store_price_rule_id = sr.id`).
  - On successful rule-based materialization, set `store_price_rule_id` to that active rule's id.
  - Use ratios stored on `customConfig` rows.
  - Update only when automatic row values differ (`IS DISTINCT FROM`); keep `basePriceChanged` / `storeRuleChanged` history payload shape.
  - Never select/update `manual` rows.
  - If no rule is active, leave rule-based amounts unchanged (pending stays `0 / 0`); readiness remains incomplete for price band.

  Do not modify an official timestamped migration, the migration registry, or other promoted SQL.

- [ ] **Step 4: Re-run the focused SQL contract test**

  Run the command from Step 2.

  Expected: PASS for draft metadata, zero persistence, nullable rule id on pending ruleBased, current-active rule lookup, custom-ratio recalculation, manual isolation, note forward, and readiness snippet.

- [ ] **Step 5: Validate draft policy, retire note draft, commit**

  Run:

  ```bash
  melos run migrate:verify-policy -- --strict
  git add supabase/migrations/_drafts/catalog_pending_automatic_price_bands.sql modules/catalog/infrastructure/test/price_band_sql_contract_test.dart
  git add -u supabase/migrations/_drafts/catalog_restore_create_guided_product_note.sql
  git commit -m "fix: persist pending automatic price bands"
  ```

  Expected: policy verification passes; no timestamped migration is staged; at most one draft owns `create_guided_product`.

### Task 4: Align the Catalog fake with the database lifecycle

**Files:**

- Modify: `modules/catalog/application/lib/src/testing/fake_catalog_module.dart`
- Modify: `modules/catalog/application/test/fake_catalog_module_test.dart`

**Consumes:** `CreateGuidedProductCommand`, `SetManualBasePriceCommand`, `SetStorePriceRuleCommand`, `SetProductUnitPriceBandCommand`, `PriceBandSourceType`.

**Produces:** FE/E2E tests observe the same pending-then-materialized behavior and readiness as production RPCs.

- [ ] **Step 1: Add failing behavior tests**

  Add these focused tests to `fake_catalog_module_test.dart`:

  ```dart
  test('guided rule-based band persists as zero then uses the active rule after base price is set', () async {
    final module = FakeCatalogModule();
    final created = await module.executeCommandAsync<CreateGuidedProductResult>(
      CreateGuidedProductCommand(
        tenantId: 'tenant-1',
        actorId: 'user-1',
        productName: 'Thuốc theo giá cửa hàng chờ giá vốn',
        baseUnit: const NewTenantUnit('Lọ'),
        useStorePriceRule: true,
        priceBandSourceType: PriceBandSourceType.ruleBased,
      ),
    );
    var pcc = await module.executeQueryAsync(
      GetProductControlCenterQuery(tenantId: 'tenant-1', productId: created.productId),
    );
    expect(pcc.priceBand.sourceType, PriceBandSourceType.ruleBased);
    expect(pcc.priceBand.listBeforeVat, 0);
    expect(pcc.priceBand.floorBeforeVat, 0);
    expect(
      created.readinessSummary.blockers.map((b) => b.code),
      contains(ReadinessBlockerCode.missingPrice),
    );
    // Pending zero must not clear missing_price_band.
    expect(
      created.readinessSummary.blockers.map((b) => b.code),
      contains(ReadinessBlockerCode.missingPriceBand),
    );

    await module.executeCommandAsync(
      SetStorePriceRuleCommand(
        tenantId: 'tenant-1', name: 'Giá bán mới',
        listMarkupRatio: 0.30, floorMarkupRatio: 0.10,
      ),
    );
    await module.executeCommandAsync(
      SetManualBasePriceCommand(
        tenantId: 'tenant-1', productId: created.productId, basePrice: 100000,
      ),
    );
    pcc = await module.executeQueryAsync(
      GetProductControlCenterQuery(tenantId: 'tenant-1', productId: created.productId),
    );
    expect(pcc.priceBand.listBeforeVat, 130000);
    expect(pcc.priceBand.floorBeforeVat, 110000);
  });

  test('guided custom-config band persists ratios and zero then recalculates after base price is set', () async {
    final module = FakeCatalogModule();
    final created = await module.executeCommandAsync<CreateGuidedProductResult>(
      CreateGuidedProductCommand(
        tenantId: 'tenant-1', actorId: 'user-1',
        productName: 'Thuốc cấu hình riêng chờ giá vốn',
        baseUnit: const NewTenantUnit('Lọ'),
        priceBandSourceType: PriceBandSourceType.customConfig,
        listMarkupRatio: 0.30, floorMarkupRatio: 0.10,
        listBeforeVat: 0, floorBeforeVat: 0,
      ),
    );
    var pcc = await module.executeQueryAsync(
      GetProductControlCenterQuery(tenantId: 'tenant-1', productId: created.productId),
    );
    expect(pcc.priceBand.sourceType, PriceBandSourceType.customConfig);
    expect(pcc.priceBand.listBeforeVat, 0);
    expect(pcc.priceBand.floorBeforeVat, 0);

    await module.executeCommandAsync(
      SetManualBasePriceCommand(
        tenantId: 'tenant-1', productId: created.productId, basePrice: 100000,
      ),
    );
    pcc = await module.executeQueryAsync(
      GetProductControlCenterQuery(tenantId: 'tenant-1', productId: created.productId),
    );
    expect(pcc.priceBand.listBeforeVat, 130000);
    expect(pcc.priceBand.floorBeforeVat, 110000);
  });

  test('base price changes do not overwrite a guided manual band', () async {
    final module = FakeCatalogModule();
    final created = await module.executeCommandAsync<CreateGuidedProductResult>(
      CreateGuidedProductCommand(
        tenantId: 'tenant-1', actorId: 'user-1',
        productName: 'Thuốc giá thủ công', baseUnit: const NewTenantUnit('Lọ'),
        priceBandSourceType: PriceBandSourceType.manual,
        listBeforeVat: 150000, floorBeforeVat: 120000,
      ),
    );
    await module.executeCommandAsync(
      SetManualBasePriceCommand(
        tenantId: 'tenant-1', productId: created.productId, basePrice: 100000,
      ),
    );
    final pcc = await module.executeQueryAsync(
      GetProductControlCenterQuery(tenantId: 'tenant-1', productId: created.productId),
    );
    expect(pcc.priceBand.sourceType, PriceBandSourceType.manual);
    expect(pcc.priceBand.listBeforeVat, 150000);
    expect(pcc.priceBand.floorBeforeVat, 120000);
  });
  ```

  Also update existing tests that encode old pending semantics:

  - `guided create skips store pricing without a unit or base price` → no base unit still missing; **with** base unit + `ruleBased` must expose persisted zero band (not `isMissing`).
  - `pending custom config materializes when base price is added` → expect `listBeforeVat/floorBeforeVat == 0` (not `isNull`) while still asserting `missing_price` / `missing_price_band` until materialize.
  - Any `listBeforeVatMissing: isTrue` case driven by pending custom must remain true for zero pending.

- [ ] **Step 2: Run the focused fake tests and confirm failure**

  Run:

  ```bash
  cd modules/catalog/application && dart test test/fake_catalog_module_test.dart
  ```

  Expected: rule-based pending and/or readiness assertions fail under current fake.

- [ ] **Step 3: Implement the fake lifecycle**

  In `_handleCreateGuidedProduct`, when `product.hasBaseUnit` is true:

  - `ruleBased`: always set source type and `0 / 0` before attempting immediate calculation; set current rule id/name only when an active rule exists **and** materialization succeeds (or store id as metadata only after materialize — match SQL). If base price + active rule available, call formula recalculation so amounts materialize.
  - `customConfig`: always set source type, ratios, and `0 / 0` before attempting immediate calculation (command may already send `0` from resolver).
  - `manual`: retain existing direct input behavior.

  In `_handleSetProductUnitPriceBand` / price resolution for `customConfig` without base: return `0 / 0` instead of `null / null`.

  In `_recalculateFormulaPriceBandsForProduct`, replace:

  ```dart
  unit.storePriceRuleId == rule.id
  ```

  with selection by `unit.priceBandSourceType == PriceBandSourceType.ruleBased` plus an active tenant rule. When calculation succeeds, refresh `storePriceRuleId` and `storePriceRuleName` from that active rule. Apply the same rule to the `_StoredProduct` fallback branch.

  Update `hasPriceBand` / `hasCompletePriceBand` / PCC `isMissing` / `listBeforeVatMissing` so automatic pending zeros remain incomplete until materialize (mirror SQL readiness decision). Do **not** use `listBeforeVat != null` alone.

- [ ] **Step 4: Re-run the focused fake tests**

  Run the command from Step 2.

  Expected: pending automatic bands initially read `0đ` and keep price-band incompleteness; later base-price (+ active rule for ruleBased) materializes; manual stays unchanged.

- [ ] **Step 5: Commit the fake parity change**

  ```bash
  git add modules/catalog/application/lib/src/testing/fake_catalog_module.dart modules/catalog/application/test/fake_catalog_module_test.dart
  git commit -m "test: mirror pending automatic price band lifecycle"
  ```

### Task 5: Full verification and change-scope review

**Files:**

- Verify: all files above only (plus any readiness SQL symbols listed in the draft `Touches:`).

**Consumes:** Completed focused tests and the draft SQL policy check.

**Produces:** Evidence that the contract, UI resolver, fake, SQL draft, and readiness agree on zero pending ≠ sellable band.

- [ ] **Step 1: Format only touched Dart files**

  Run:

  ```bash
  dart format modules/catalog/presentation/lib/src/mappers/guided_price_band_submission_resolver.dart modules/catalog/presentation/test/guided_price_band_submission_resolver_test.dart modules/catalog/application/lib/src/testing/fake_catalog_module.dart modules/catalog/application/test/fake_catalog_module_test.dart modules/catalog/infrastructure/test/price_band_sql_contract_test.dart
  ```

- [ ] **Step 2: Run focused verification**

  Run:

  ```bash
  cd modules/catalog/presentation && flutter test test/guided_price_band_submission_resolver_test.dart
  cd ../application && dart test test/fake_catalog_module_test.dart
  cd ../infrastructure && dart test test/price_band_sql_contract_test.dart
  cd ../../..
  melos run migrate:verify-policy -- --strict
  ```

  Expected: all commands pass.

- [ ] **Step 3: Run repository guards**

  Run:

  ```bash
  melos run analyze
  melos run test
  bash scripts/ci/verify_harness.sh
  ```

  Expected: all pass. If the environment requires initialization, run the documented `melos run env:init` first; do not run `supabase db reset` for this draft.

- [ ] **Step 4: Inspect impact and diff before final commit**

  Run GitNexus after modifications:

  ```text
  detect_changes(scope: "all")
  detect_changes(scope: "compare", base_ref: "main")
  ```

  Expected: Catalog pricing/guided-create/readiness flows and the listed documentation/tests. Recheck every unexpected symbol before staging. Confirm no second draft still redefines `create_guided_product`.

- [ ] **Step 5: Commit verification-only adjustments if any**

  ```bash
  git status --short
  git diff --check
  ```

  Stage only planned files.

## Plan Self-Review

- **Spec coverage:** Tasks 1–4 cover persistence of all three modes, zero-valued pending automatic bands, nullable `store_price_rule_id` until materialize, current-active store rule recalculation, custom-ratio recalculation, manual isolation, readiness incompleteness for pending zeros, history semantics, contracts, fake behavior, and focused tests.
- **Schema honesty:** Draft explicitly alters calculation/materialization checks and readiness facts — not RPC-only — because promoted constraints currently forbid the acceptance examples.
- **Draft cohesion:** One patch owns `create_guided_product` (note + pending automatic); note-only draft is superseded.
- **No placeholders:** Every changed area has explicit file paths, expected values, and verification commands. No timestamped migration is requested.
- **Type consistency:** Existing `PriceBandSourceType` values remain; public command shapes stay compatible (`int?` amounts already allow `0`). Semantics of pending change from `null` → `0` + readiness rules.
- **Scope:** This plan does not add a scheduling job, alter Sales snapshots beyond readiness/price-band completeness rules already listed, backfill old NULL rows (optional follow-up), or promote the draft. Those are separate decisions.
)
