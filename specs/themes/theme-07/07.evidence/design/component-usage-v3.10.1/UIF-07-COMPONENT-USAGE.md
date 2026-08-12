# UIF-07 Component Usage — v3.9.5

## Authority & common rules

- Business behavior: BJ07/UC/Decision/behavioral/UI contracts. UI implementation authority: live Figma Design System.
- Canonical Product canvas: `402×874`; Product edge `16px`; content width `370px`. Review bezel/desktop scaling must not change Product geometry.
- Reuse order: existing V component → existing non-V Figma component → Pattern/Template → composition of existing DS assets. Do not create Theme-specific components for grouping alone.
- Same record collection uses one `List Row` Type/Density. Temporary unavailability is a component `State`, not a different row family.
- Product+UOM is a parent information level; LOT/allocation is a child level. They must not share the same visual weight.

## SCR-036 — Hàng chờ trả nhà cung cấp

- `DS v2 / Search & Filter Header` + quick `VChip`, `Tất cả` selected by default.
- Exactly one request collection: every visible supplier-return request uses `DS v2 / List Row`, `Type=Navigation`, `Density=Default`, `370×76`.
- Actionable/ready request: `State=Default`. Waiting/source-owned request: **same Navigation variant with `State=Disabled`**, same chevron/anatomy/geometry, non-interactive, parent opacity `0.4`.
- Work-stage labels such as `Cần chuẩn bị`, `Cần kiểm lại`, `Sẵn sàng`, `Chờ cập nhật` are trailing `VBadge`; never insert stage headings between records.
- Source-changed actionable work opens the same `SCR-037`; exact delta is shown there, not duplicated as queue prose.

## SCR-037 — Chuẩn bị hàng trả

- Request context: one `Status / Compact` List Row (`370×52`) containing request identity + Supplier/source + concise progress.
- Product+UOM parent: canonical `DS v2 / List Row`, `Type=Status`, `Density=Compact` inside one coherent bordered group surface. The row carries product name + code/UOM + concise progress badge; no floating text+badge header.
- Allocations: one uniform `Navigation / Default` List Row (`370×76`) per exact source allocation. Title identifies `Lô <LOT>` or `Không theo lô`; subtitle holds source quantity and HSD when applicable.
- Source Product/UOM/LOT/quantity remain read-only. Verification is contextual: canonical `VBottomSheet 4695:6353`, no X; scan/type LOT is only comparison assistance.
- Source delta uses `VBanner` only when action is needed and invalidates affected evidence only.

## SCR-039 — Bàn giao trả nhà cung cấp

- Decision context uses grouped `Info Row`: `Nhà cung cấp`, `Yêu cầu trả`, `Kho`. Do not duplicate source/version prose that does not change the decision.
- Each Product+UOM is a canonical `Status / Compact` List Row inside the group surface, with a quantity `VBadge` scoped to that exact Product+UOM only.
- Each LOT/non-LOT allocation is one `Key-value Row / Default`: left = LOT/HSD identity, right = quantity + UOM.
- One Primary CTA confirms actual handover. No second confirmation modal and no cross-UOM total.

## SCR-041 — Kết quả trả nhà cung cấp

- `COMPLETED`: finality hero first, then concise Info Rows, then the **same factual hierarchy** as final review: Product+UOM Status/Compact summary row → allocation Key-value evidence. Factual evidence is left-aligned.
- `UNKNOWN`: keep operation identity and safe recovery; no blind retry.
- Terminal result has no Back into a consumed commit screen.

## Canonical Figma references

- `DS v2 / List Row` — `525:519`: Default `370×76`; Compact Status `370×52`; Navigation Disabled preserves geometry/anatomy and applies parent opacity `0.4`.
- `DS v2 / Key-value Row` — `525:358`: Default `338×44`; Emphasis only for real totals/outcomes.
- `VBanner` — `526:4215`: Compact `72px`, Default `96px`, semantic only.
- `VBottomSheet` — `4695:6353`: 402px shell, 48×4 handle, px16, pt12, pb44, no normal close X.
- `DS v2 / Entity Card` — `525:539`; `DS v2 / Summary Card` — `525:552`: use only when semantics warrant them, not merely to create visual grouping.

Before changing Product UI, compare canonical DS + Patterns/Templates with mature Product UI in other Themes available in the Figma file. Use them to validate hierarchy, grouped surfaces, density and spacing; do not copy legacy outliers.

## v2.9.2 — Product-group surface correction

- A business group may be a composition, but visible entity identity/status must reuse an existing DS component when one exists. For BJ07 that primitive is `DS v2 / List Row 525:519`, `Type=Status`, `Density=Compact`.
- The Product+UOM summary row sits inside one `370px` bordered surface (`12px` vertical / `16px` horizontal composition padding). Inner DS rows are responsive instances at `338px`, matching mature Theme 1 grouped detail compositions.
- LOT allocations remain a lower information level: `Navigation / Default` rows during preparation, `Key-value Row / Default` during handover/result.
- Do not restore raw `VSection + VText + VBadge` product headers. Do not use Summary Card/Entity Card just to obtain a background when their semantic/height is not appropriate.

## v2.9.3 — DS-native grouped collection density correction

This section **supersedes the v2.9.2 bordered Product-group rule above**.

- Figma Layout `Surface Grouping` (`4518:1545`) is authoritative: use the lightest surface that preserves hierarchy; repeated/nested cards are the documented `Card soup` anti-pattern.
- `SCR-037`: one grouped surface owns the complete `Hàng cần chuẩn bị` collection. Product+UOM = exact `List Row / Status / Compact` (`370×52`); actionable LOT/non-LOT allocation = exact `List Row / Navigation / Default` (`370×76`). No outer card per Product.
- `SCR-039`: one grouped read-only collection. Product+UOM = `Status / Compact` with semantic `Đã kiểm`; LOT/non-LOT evidence = `Key-value Row / Default` (`338×44`). Quantity is a value, not a badge.
- `SCR-041`: same hierarchy as final review; Product+UOM badge is semantic `Đã bàn giao`; evidence remains `Key-value Row`.
- Verification `VBottomSheet` no longer uses a raw quantity badge. Product status is `Cần kiểm`/`Đã kiểm`; `Cần chuẩn bị` quantity is an `Info Row` fact.
- Group wrappers are Layout compositions (`data-layout-pattern="Grouped surface"`), not invented DS components. Inspect must not claim a new Product/LOT component.


## v3.9.5 additions
- Ambiguous original-state composition uses the existing `VBottomSheet` + `VNumberField`/Info Row composition under the label **Xác định nguồn tồn**; no new Theme-7 visual component is invented.
- Physical mismatch uses `VBottomSheet`, existing selection control, conditional `VNumberField`/`VTextField`/textarea composition and one Primary CTA `Gửi chênh lệch`.
- Source delta remains `VBanner` only when a change is decision-relevant; content is a concrete business delta, never raw source-version metadata.
- Final review/result may add a Key-value Row `Nguồn tồn` only for allocations where the multi-state composition matters.
