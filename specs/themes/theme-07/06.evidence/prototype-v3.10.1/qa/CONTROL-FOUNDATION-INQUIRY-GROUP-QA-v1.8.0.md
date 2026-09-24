# Theme 7 — Control Foundation & Inquiry Group QA v1.8.0

## 1. Release boundary

- Release: `VET45-Theme7-Prototype-Harness-v1.8.0`
- Direct parent: `v1.7.0`
- Target scope: `BJ12/UIF12` and `BJ15/UIF15`
- Product viewport: `402×874`
- Product approval: `PENDING_REVIEW`
- Frozen source rule: SRS and `theme.manifest.yaml` are not rewritten by this UI/UX release.

## 2. BJ12 — Khởi tạo số dư tồn kho đầu kỳ

Product correction applied:

1. Phase 1 is represented as one official opening-inventory initialization, not a user-facing collection of technical batches.
2. The maker prepares source data, `Ngày chốt số dư`, and independent control totals. There is no explicit `Lưu nháp` action.
3. Validation blocks negative quantity, quantity-zero/value-positive combinations, missing price basis for positive quantity, duplicate `Product + warehouse + state + lot`, invalid LOT/NONE data, and control-total mismatch. Invalid master data is not silently created or merged.
4. Review contains business evidence needed for a decision; it omits hash/version/internal operation identifiers.
5. Maker submit ends at `Chờ duyệt`. The maker is not navigated into the approver surface.
6. `SCR-070` is an independent approver task. Approval only records the decision; commit/activation is system-owned afterward.
7. The authoritative result is shown on `SCR-071`. `UNKNOWN` is not treated as `FAILED`, and the user is not offered blind retry or a second opening initialization.

## 3. BJ15 — Tra cứu báo cáo tồn và thẻ kho

Product correction applied:

1. Inquiry is read-only and does not expose ledger mutation controls.
2. `Ngày nghiệp vụ` and `Ngày ghi nhận` are explicit query semantics and are never silently mixed.
3. Inventory-report quantity remains per Product/UOM. Different UOM quantities are not combined into a false grand total.
4. LOT products can reveal actual LOT breakdown progressively; NONE products do not receive a synthetic LOT.
5. Quantity permission and official cost/value permission are independent. With financial restriction, protected values are omitted from the Product DOM rather than visually masked.
6. Projection freshness is persistent and tied to the result/as-of context. A stale report is not presented as a basis for mutation.
7. Stock-card movement details use business source, business/recorded dates, before/delta/after quantity and relevant lot/state/actor context without exposing technical pipeline IDs.
8. Export preserves query scope, date semantics, as-of and permission. Export does not require approval and does not mutate inventory.
9. Discrepancy handling is handed off to BJ16/BJ11; reporting itself does not repair inventory.

## 4. Target QA results

| Gate | Result |
|---|---:|
| Static / contract | `68/68 PASS` |
| Target scenario renders | `78 PASS` |
| End-user behavior | `65/65 PASS` |
| Visual | `67/67 PASS` |
| Visual specimens | `22` at `402×874` |
| Protected non-target regression | `3/3 gates · 73 exact renders PASS` |
| All-flow runtime smoke | `85 active flow/screen renders PASS` |
| Frozen source immutability | `106 SRS files + theme.manifest.yaml byte-identical PASS` |
| JavaScript syntax | `PASS` |
| Modified JSON parse | `PASS` |
| Prototype checksum manifest | `762 artifacts · verify PASS` |

## 5. Prior-cluster runtime regression on v1.8.0

The earlier corrected clusters were executed again against the cumulative v1.8.0 runtime:

| Protected cluster | Result |
|---|---:|
| Inventory Valuation — end-user | `54/54 PASS` |
| Inventory Valuation — scenarios | `27/27 PASS` |
| Inventory Valuation — integration | `14/14 PASS` |
| Inventory Audit & Control — end-user | `48/48 PASS` |
| Inventory Audit & Control — scenarios | `53 renders PASS` |
| Correction & Recovery — end-user | `68/68 PASS` |
| Correction & Recovery — scenarios | `95 renders PASS` |

These runtime gates are additive to the byte/render isolation gate; they are not substitutes for it.

## 6. Cumulative isolation

- Parent used for comparison: `v1.7.0` only.
- Protected renderer comparison: `73` non-target renders are exact against v1.7.0.
- The target shared screens used by UIF15 are context-rendered; legacy UIF01 behavior is protected by regression instead of being rebuilt.
- SRS set: exact file set, `106` files, byte-identical.
- `specs/themes/theme-07/theme.manifest.yaml`: byte-identical.

## 7. Canonical validator status

The canonical frozen validator was run for both parent v1.7.0 and child v1.8.0. Both exit at the same inherited baseline condition before later validator stages:

`FileNotFoundError: specs/themes/theme-07/prototype/screen-map.md`

Therefore v1.8.0 does **not** claim full canonical-validator readiness. The failure is inherited from the direct parent and is not introduced by BJ12/BJ15.

## 8. Review status

Engineering/UX QA: **PASS for the v1.8.0 target scope and cumulative regression gates**.

Product approval/freeze: **PENDING_REVIEW**.
