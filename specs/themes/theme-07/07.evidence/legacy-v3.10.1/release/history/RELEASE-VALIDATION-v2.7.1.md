# Release Validation — v2.7.1

**Result: PASS · 33/33 release checks**

## Scope

Shared live-Figma primitive correction over parent v2.7.0: List Row, Info Row grouping, Key-value Row and VToast, plus BJ05 re-QA. Business behavior is unchanged.

## Checks

- [x] Root README identifies v2.7.1 and parent v2.7.0.
- [x] Launcher targets BJ05 and v2.7.1 release validation.
- [x] HTML manifest is cumulative from v2.7.0.
- [x] v2.7.1 correction CSS is wired after v2.7.0 BJ05 layer.
- [x] Correction CSS introduces no raw color values.
- [x] Live List Row node 525:519 is release-locked.
- [x] Live Info Row node 525:351 is release-locked.
- [x] Live Key-value Row node 525:358 is release-locked.
- [x] Live VToast node 526:4305 is release-locked.
- [x] List Row density locks Default=76 and Compact=52.
- [x] List Row affordance semantics are explicit.
- [x] Info Row grouping preserves transparent 338x44 primitive.
- [x] VToast release lock is 370x56 with semantic leading circle.
- [x] Shared primitive QA passes 31/31.
- [x] Full List Row audit passes 30 rendered canonical instances.
- [x] Full Info Row audit passes 265 rendered instances.
- [x] BJ05 Product/DS QA passes 71/71.
- [x] All-flow runtime smoke passes 85 active renders.
- [x] BJ04 regression remains 34/34.
- [x] UIF-05 migration remains review-ready.
- [x] Runtime registry records shared primitive correction.
- [x] No new feature component created.
- [x] BJ05 business behavior unchanged.
- [x] BJ05 physical stock commit boundary retained.
- [x] BJ05 cross-UOM aggregation remains prohibited.
- [x] UNKNOWN no-blind-retry rule retained.
- [x] app.js syntax passes Node check.
- [x] Action registry hash remains preserved.
- [x] Screen registry hash remains preserved.
- [x] Visual QA report is PASS.
- [x] BJ05 has 10 canonical 402x874 captures.
- [x] Shared primitive visual evidence exists.
- [x] Inherited package-validator gap is documented, not hidden.

## QA evidence

- `specs/themes/theme-07/prototype/html/qa/FIGMA-DS-PRIMITIVES-QA-v2.7.1.md`
- `specs/themes/theme-07/prototype/html/qa/LIST-ROW-FULL-AUDIT-v2.7.1.md`
- `specs/themes/theme-07/prototype/html/qa/INFO-ROW-GROUP-FULL-AUDIT-v2.7.1.md`
- `specs/themes/theme-07/prototype/html/qa/BJ05-FIGMA-DS-QA-v2.7.1.md`
- `specs/themes/theme-07/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v2.7.1.md`
- `specs/themes/theme-07/prototype/html/qa/FIGMA-DS-VISUAL-QA-v2.7.1.md`
- `specs/themes/theme-07/prototype/html/qa/v271-bj05-captures/`
- `specs/themes/theme-07/prototype/html/qa/v271-shared-captures/`

## Inherited package-validator note

The legacy full-package validator still cannot start because the cumulative parent lineage lacks `specs/themes/theme-07/prototype/prototype.manifest.json`. v2.7.1 does not fabricate that unrelated artifact; release quality is gated by shared-primitive audits, BJ05 Product/DS QA, all-flow runtime smoke, BJ04 regression, JavaScript syntax, registry integrity and visual evidence.
