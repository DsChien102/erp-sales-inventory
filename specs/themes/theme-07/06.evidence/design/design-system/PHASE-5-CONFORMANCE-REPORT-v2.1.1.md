# Phase 5 — Final Figma DS Conformance Report v2.1.1

## Objective

Review the completed v2.1.0 rollout under two lenses simultaneously:

1. **Figma-DS correctness:** is the Component / Pattern / Template responsibility actually the one defined in live DS v2.0.2?
2. **End-user correctness:** did migration introduce mechanical UI that is technically mapped but semantically weaker or visually wrong?

Business source is frozen; Phase 5 changes UI expression/renderer robustness only.

## Findings and corrections

### 1. Result screens were mechanically classified as State

Figma `Mobile / State` (`551:1746`) is defined for Empty / Error / No Permission / Blocked / No Result, not success. v2.1.0 had assigned it to 17 result/status/validation flow occurrences.

**Correction:** base archetype is now `Mobile / Detail` (`551:1396`). At runtime, only a centered true `VEmptyState` switches the shell to `Mobile / State`. This preserves a business-detail result while still using the State template for its intended states.

### 2. Success result anatomy incorrectly borrowed VEmptyState owned slots

Several result renderers used `VEmptyMedia`, `VEmptyTitle` and `VEmptyDescription` as though `VEmptyState` had Success.

**Correction:** success/finality now uses a justified `VSection` composition from `VIcon + VText`, followed by canonical detail rows/sections. Owned VEmpty slots exist only below an actual `VEmptyState`.

### 3. Exact Info Row was only calibrated in selected UIFs

The live `DS v2 / Info Row` requires supporting-metadata rhythm. UIF09 exposed glued text such as label/value without the canonical gap.

**Correction:** exact Info Row is enforced globally at minimum 44px height and 8px gap, with Body Small label + Label Default value semantics.

### 4. Multiline input used the wrong direct component

The inventory-condition reason field rendered a raw textarea annotated as `VTextField`.

**Correction:** it is exact `VTextarea` (`522:7212`). All visible multiline fields now resolve to `VTextarea`; canonical 88px input-frame behavior and no browser resize handle are enforced.

### 5. Monetary control used a generic numeric field

`Tổng giá trị kiểm soát` is an amount but was treated as a generic number input.

**Correction:** exact `VMoneyField` (`522:7322`) with formatted VND amount and the live master’s in-field `₫` suffix. Input events normalize display text back to the numeric business value before validation.

### 6. Incoherent harness state leaked raw null

Directly selecting a later return-classification state without a physically recorded quantity could render `null hộp`.

**Correction:** nullable quantity display uses `—`; a missing/non-positive quantity can no longer satisfy classification-complete validation. Valid scenario fixtures are used in visual QA.

## Frozen boundaries

- 106 SRS files: byte-identical to v2.1.0.
- canonical screen registry `.json/.md`: byte-identical to v2.1.0.
- `theme.manifest.yaml`: byte-identical to v2.1.0.
- 17 UIF / 73 canonical active screens / 497 registered states: unchanged.

## Status

Engineering/UX QA: **PASS**.  
Product approval: **PENDING_REVIEW**.
