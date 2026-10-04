## v4.6.4 — BJ02 pending-approval continuity

- Parent: `v4.6.3`; scope chỉ tập trung BJ02 và integration tối thiểu với Warehouse Hub candidate.
- Final candidate layer: `v464-warehouse-hub-bj02-continuity.css/js`.
- `SCR-010/PENDING_APPROVAL`: sticky CTA **Về Kho** + Back về Kho; không còn đường quay về editor.
- Hub candidate: thêm **Nhận hàng chờ phê duyệt** trong `Cần chú ý`, worklist và route vào `SCR-011` cho fixture Owner có quyền duyệt.
- QA: `qa/WAREHOUSE-HUB-BJ02-CONTINUITY-QA-v4.6.4.*` = 21/21 PASS; `qa/ALL-FLOWS-RUNTIME-SMOKE-v4.6.4.*` = 85/85 PASS.

## v4.5.0 — Snapshot-led visual QA hardening

- Parent: `v4.4.0`. Không thay đổi semantic/flow/Screen Contract.
- QA bằng screenshot thật: 82 active screens, 17 UIF contact sheets, 486 state visual/runtime audit.
- VBanner tuân thủ đúng density Figma DS; long explanatory copy không ép vào Info Row 44px; VProgress chỉ chứa bar.
- Historical v4.4.0 evidence được giữ nguyên; v4.5.0 có evidence riêng.

## v4.4.0 — Theme-wide grouped information surface consistency

- Parent: `v4.3.1`.
- Audit scope: toàn bộ 17 UIF, mọi canonical screen/state của Theme 7.
- Khóa rule toàn Theme: từ 2 `Info Row` / `Key-value Row` cùng một semantic block phải có **một surface chung**; row bên trong không thành card riêng.
- Runtime normalization chỉ bổ sung surface khi block chưa có owner hợp lệ; surface đúng sẵn không bị bọc thêm.
- Audit phát hiện và sửa thiếu surface ở BJ01 `SCR-003`, BJ02 `SCR-010`, BJ05 `SCR-028`; BJ03/BJ13/BJ14 giữ nguyên fix v4.3.1; các BJ còn lại đã compliant và không bị thay composition.
- Independent `List Row` collections vẫn transparent theo rule đã khóa; không biến list thành một card lớn.
- QA: `THEME-WIDE-GROUPED-SURFACE-v4.4.0` = 486/486 PASS; `ALL-FLOWS-RUNTIME-SMOKE-v4.4.0` = 86/86 PASS; valuation regression = 29/29 E2E, 19/19 visual, 54/54 full-state, 8/8 grouped-surface; browser errors = 0.

## v4.3.1 — Grouped surface regression fix

- Parent: `v4.3.0`.
- Khôi phục quy tắc Theme 7: **một nhóm dữ liệu đồng nhất = một surface boundary**.
- `Info Row` / `Key-value Row` khi ghép thành block có nền, viền và bo góc chung; không biến từng row thành card riêng.
- Áp dụng cho toàn bộ BJ03/BJ13/BJ14, gồm căn cứ giá, kết quả phân bổ, kỳ ghi nhận, chính sách, kết quả giá vốn và vùng đối chiếu.
- Không thay đổi BJ/UC/UIF/Screen Contract hay hành vi prototype.
- QA mới: `VALUATION-GROUPED-SURFACE-v4.3.1`, E2E 29/29, visual 19/19, full-state 54/54, all-flow 86/86.

## v4.3.0 — Valuation UI/UX + prototype hardening

Parent: `v4.2.0`. Business semantics and UIF topology are unchanged. This release performs a full UI/UX + interaction review of BJ03/BJ13/BJ14 against live Figma DS v2.

- Final layer: `v430-valuation-uiux.css` + `v430-valuation-uiux.js`, loaded after prior valuation layers.
- First-paint/deep-link bug fixed: the final valuation renderers are rebound and rendered immediately, so legacy UI no longer appears before the first interaction.
- BJ03: long direct-basis entry uses `DS v2 / Form Sheet` with independent scroll body + fixed `Sticky Footer`; money/text/textarea controls use DS-native semantics.
- BJ13: source/target/allocation hierarchy is flattened to List Row + Key-value patterns; no redundant Summary Card.
- BJ14: blockers use `VBanner` + List Row; result uses at most one Summary Card; publish review uses `DS v2 / Confirmation Sheet`.
- Retired routes are compatibility-only: `016→015`, `087→086`, `073/075/076→074`; `018` hands off cross-flow to `UIF-13 / SCR-085`.
- QA: `VALUATION-FLOW-E2E-v4.3.0` = 29/29 PASS; `VALUATION-VISUAL-INTEGRITY-v4.3.0` = 19/19 PASS; `VALUATION-FULL-STATE-SMOKE-v4.3.0` = 54/54 PASS; browser errors = 0.

## v4.1.0 — Canonical UIF + corrected valuation runtime

Parent package: `v4.0.0`; runtime merge source: `v3.13.0`. This package keeps the exact corrected valuation layer and adds canonical UIF contracts/trace. No valuation screen is reverted to the v4.0.0 carry-forward topology.


## v3.13.0 — Valuation Design & Prototype Parity

Parent: `v3.12.0`. Business semantics are unchanged from v3.12.0; this version redesigns BJ03/BJ13/BJ14 and synchronizes Screen Contract, workbench, harness and runtime.

- BJ03: `SCR-014 → 015 → 017 → 019`; no `DirectCostBasis`/Official Cost product copy; Quick can add direct basis in `VBottomSheet`.
- BJ13: `SCR-085 → 086 → 088 → 089`; signed value adjustment; allocation merged into `SCR-086`.
- BJ14: `SCR-072 → 074 → 077`; tenant method is read-only; blockers/setup/review are modes of `SCR-074`; publication confirmation uses `VBottomSheet`.
- Live Figma DS evidence: file `QVJolM5tAdFKkhP7RIwe3y`, Components page `505:5890`; runtime uses semantic token fallbacks aligned to live variables.
- New runtime layer: `v313-valuation-design.css` + `v313-valuation-design.js` loaded last for isolation.
- QA: `ALL-FLOWS-RUNTIME-SMOKE-v3.13.0`, `VALUATION-FLOW-E2E-v3.13.0`, valuation visual captures and visual-integrity gate.

Historical sections below describe previous baselines only and do not override v3.13.0.

# Theme 7 HTML Prototype Harness v3.9.7



## v3.9.7 — Wave 3 / BJ03 direct valuation semantic hardening
- Baseline: v3.9.6; frozen-source remains immutable.
- Direct valuation basis is keyed by mục hàng nhận/commercial source line, not Product+UOM presentation grouping.
- Server preview builds complete `DirectCostBasis` candidates with component provenance, deterministic allocation/rounding and basis/scope freshness tokens.
- Review shows transaction-UOM direct cost plus normalized base-UOM consequence; normal READY state is not rendered as a semantic badge.
- Confirm rechecks selected basis hash/version + scope version atomically, writes receipt-business-date value movements and performs compare-and-create initial Official Cost bootstrap.
- Result renders command-authoritative value, availability, business date, recorded time and bootstrap outcome.



## v3.7.0 — Integrated app navigation / full-theme mode
- Adds two review tabs: **Theo BJ / UIF** and **Toàn Theme 7**.
- `Toàn Theme 7` starts at **Thêm**, opens **Kho**, and routes to all **17 BJ + CAP-01**.
- New app-level screens use canonical `VAppBar` and `DS v2 / List Row`; out-of-scope More items use `State=Disabled` with parent opacity `0.4`.
- Theme navigation reuses the same renderer/state runtime as the BJ/UIF tab; no Theme 7 business screen is cloned.
- Every flow entry has an explicit Back to `Kho` in integrated mode, including contextual flows and CAP-01.
- QA: `qa/INTEGRATED-THEME-NAVIGATION-QA-v3.7.0.*` plus all existing regression gates.

## v3.6.4 — Canonical VRadio / helper-text correction
- BJ09 state-change choices use canonical `VRadio` anatomy instead of the legacy custom `choice-card` helper-pill treatment.
- Supporting/helper text is plain secondary text with transparent background; it is not a `VBadge`.
- v3.6.3 Navigation/Disabled row semantics and chevron consistency remain unchanged.


## v3.6.3 — Homogeneous navigation list / disabled-state correction

This release fixes a cross-list interaction-semantic defect: peer task rows in one navigation collection must not change component type just because one item is temporarily unavailable. Waiting rows in BJ03 `SCR-014` and BJ13 `SCR-085` now remain canonical `DS v2 / List Row · Type=Navigation`, retain the same chevron/geometry as actionable peers, and use `State=Disabled` with DS parent opacity `0.4`.

Whole-runtime list semantics QA scans all **518 declared route-state renders**. No other homogeneous Navigation collection was found with the same mixed `Navigation/Status` defect. Existing list spacing, footer composition, flow behavior, business rules and navigation destinations are preserved.

## v3.6.2 — Independent list/card rhythm correction

- Whole-runtime spacing audit covers all **518 declared route-state renders**.
- Independent bordered peer cards must not touch; the collection owns an explicit DS-token gap and stays transparent.
- Corrected BJ08 count-session list, BJ09 timeline-card composition, and BJ15 fallback inventory-result list states.
- Joined parent→child grouped surfaces remain joined and are explicitly excluded from the independent-card rule.
- Business/state/action/navigation behavior is unchanged.


## v3.6.1 — Dual Sticky Footer correction

Two-action Sticky Footers are normalized at the shared runtime layer to the canonical horizontal Dual pattern (`Secondary/Destructive | Primary`). All 17 dual-footer route-state occurrences pass geometry/order/bleed QA; single-action footers are unchanged.

## v3.6.0 — full Theme 7 completion

- Parent: `v3.5.1`. Scope: **17 BJ + CAP-01**, **89 canonical route occurrences**, **77 active unique screens**, **518 declared route-state renders**.
- CAP-01 renders `SCR-062..065`; exact production entry/permission/return integration remains an explicit boundary (`BG-006`).
- BJ08 cancellation is inside the opened session only, with required reason and destructive confirmation; no cancel CTA is present on the browse list.
- Same-context mutations receive semantic toast feedback when needed; dedicated results, inline errors, blockers and UNKNOWN recovery avoid duplicate feedback.
- All stable non-root states have executable exits. Navigation/Back does not mutate finality.
- Representative READY screens are semantically coherent with their predecessor prerequisites.
- Current QA: `STATIC-CONSISTENCY-QA-v3.6.0`, `FLOW-LOGIC-E2E-QA-v3.6.0`, `RUNTIME-UI-QA-v3.6.0`, and `FULL-THEME-COMPLETION-QA-v3.6.0`.


The HTML harness is the Theme 7 screen-design and executable UX artifact. Figma supplies the current VET45 Design System and mature prior-theme design references only; it is not the Theme 7 screen-design source.

## v3.5.1 — list surface, chip strip & auxiliary navigation correction

- Parent: `v3.5.0`; business state-machine behavior is preserved.
- Independent List Row collections use a transparent collection layer; each row/card owns its surface and row gaps reveal the page background. Semantic grouped Product→facts/LOT surfaces remain grouped.
- Search/filter `VChip` collections stay on one mobile row and use horizontal scrolling when necessary; chips never wrap or truncate.
- BJ09 history Back returns to `SCR-037` (the launching detail) without result mutation. BJ15 movement/source drill-down Back paths use explicit parent navigation for the same reason.
- Current UI gate: `qa/RUNTIME-UI-QA-v3.5.1.*` — 14/14 PASS across 500 states, including one-row chip reachability, transparent list gaps and auxiliary navigation.
- Semantic gate is re-run against the effective v3.5.1 runtime as `qa/FLOW-LOGIC-E2E-QA-v3.5.1.*`.
- No new core DS component/pattern is introduced.

## v3.5.0 — executable flow/logic correction

- Parent: `v3.4.0`.
- Fixes semantic transition defects found by the holistic 17-BJ review: BJ08 blind count/branching, BJ09/BJ10 input binding, BJ05/BJ06 stale-source protection, BJ12 control totals, BJ14 successor policy lineage, BJ15 report scoping, BJ16 context/evidence recovery, BJ17 same-operation finality, actor handoff and UNKNOWN recovery.
- Restores functional search/filter behavior after DS List Row migration and validates canonical entry contexts.
- Effective UI gate covers all `500` declared states on the `402×874` canonical canvas, including chip integrity, hidden-row behavior, technical-language leakage and browser errors.
- Semantic gate is `qa/FLOW-LOGIC-E2E-QA-v3.5.0.*`; UI gate is `qa/RUNTIME-UI-QA-v3.5.0.json`.
- Backend transaction/database/outbox atomicity is outside this browser harness.

## v3.1.0 — Inventory Audit & Control cluster

- BJ08 / UIF-08: blind count → recount → independent approval → result; Product identity is the parent row, quantity/evidence are nested controls, and read-only comparison uses canonical Key-value rows.
- BJ09 / UIF-09: Product state management keeps meaningful Product icons; state decisions use `VRadio`; read-only history uses canonical `DS v2 / Audit Item` (`525:621`).
- BJ10 / UIF-10: disposal remains a controlled two-boundary flow — approval is not physical disposal; physical completion is a separate destructive action.
- BJ11 / UIF-11: generic operation queue is text-first with hidden decorative icons; cancel/correction facts are grouped; correction strategy uses `VRadio`; unknown outcomes hand off to BJ17.
- BJ12 / UIF-12: opening-balance file selection uses a File Drop composition; validation errors are compact grouped List Rows; maker/approver/system boundaries remain distinct.
- BJ15 / UIF-15: report/date semantics use `VRadio`; Product reports keep Product icons; stock-card movements are text-first; source trace uses Audit Items.
- BJ16 / UIF-16: reconciliation queue/evidence/recovery uses grouped facts and clear case actions; source correction hands off to BJ11.
- BJ17 / UIF-17: committed/no-effect/insufficient-evidence paths preserve finality and never offer blind duplicate stock actions.
- User-facing terminology is Vietnamese; raw technical/revision vocabulary is removed. No new core DS component is introduced.
- Audit & Control base layer: `v310-audit-control-cluster.css` + `v310-audit-control-cluster.js`; current executable correction layer: `v350-flow-logic-correction.css` + `v350-flow-logic-correction.js`.
- QA gate: `qa/AUDIT-CONTROL-CLUSTER-QA-v3.1.0.md` — 52/52 PASS, 269 scope-state renders, 497 full-harness state renders, 85/85 canonical device frames.

## v3.0.0 — Inventory Valuation cluster

- BJ03 (`SCR-014/015/017/019`): Product/UOM is the parent context; LOT/non-LOT + physical state are nested valuation scopes in one grouped collection. Conflict evidence stays contextual in canonical `VBottomSheet`; sources start unselected and require explicit authority/reason when conflicting.
- BJ13 (`SCR-085..089`): source facts, target selection, allocation preview, period effect, final review and result use one homogeneous surface per collection. Monetary amounts are plain values/Key-value rows, never status badges.
- BJ14 (`SCR-072/073/074/076/077`): immutable run mental model; policy costing method remains read-only; two run-kind choices use canonical `VRadio` (`522:7410`) rather than a custom two-option segmented control; blockers and comparison methods are flat grouped collections.
- Business handlers for UIF-03/UIF-13/UIF-14 are byte-for-byte unchanged from v2.9.4. No new core DS component is introduced.
- Current correction layer: `v300-valuation-cluster.css`.

## Authority and component selection

1. Product/BJ/UC/Decision/Behavioral/UI contracts decide business behavior.
2. Live Figma DS (`QVJolM5tAdFKkhP7RIwe3y`; Foundations `505:5889`, Components `505:5890`, Patterns/Templates `505:5891`) decides component, variant, token, typography, spacing, state, icon and interaction convention.
3. Compare mature Product screens in other available Figma Themes for composition/rhythm after checking DS/Patterns. They are consistency evidence, not authority over DS semantics.
4. HTML implements and verifies the result.

Selection order: **valid V_component → existing canonical non-V Figma component → Pattern/Template → composition from existing DS assets → new component only after a proven reusable gap**.

## Device and review workbench

- Product viewport remains exactly **402×874 CSS px**.
- Product layout is never resized to make screenshots fit.
- On desktop, the separate review workbench uniformly scales the decorated phone preview using available width and height so the complete phone remains visible without document scrolling.
- Product root and content must not horizontally overflow; sticky footer and safe area remain reachable.


## v2.9.4 — BJ07 Product/LOT hierarchy correction

- SCR-037: Product+UOM is a lightweight group header; LOT/non-LOT allocations are flat nested rows with hierarchy connectors inside one grouped surface.
- SCR-039 and SCR-041 reuse the same Product group-header hierarchy; read-only allocation evidence remains canonical Key-value Row.
- Removes the remaining Product/LOT card-like visual ambiguity without creating a new core DS component.
- Business rules, exact-source verification, handover commit and recovery behavior are unchanged.

## v2.9.3 — DS-native grouped collection correction

- Live Figma Layout / Surface Grouping (`4518:1545`) is enforced: use the lightest boundary that preserves hierarchy; avoid Card soup.
- `VSection` remains structural grouping and is not automatically a Card.
- BJ05/SCR-028, BJ06/SCR-035 and BJ07/SCR-037/SCR-039/SCR-041 no longer create one outer Product card per repeated Product+UOM. One homogeneous collection owns one light grouped surface.
- Visible primitives remain exact live Figma components: Product+UOM `List Row / Status / Compact` 370×52; actionable LOT `List Row / Navigation / Default` 370×76; read-only evidence `Info Row`/`Key-value Row` 338×44.
- Raw quantity is data, not `VBadge` status. Badges express semantic state/progress only.
- Cross-migrated visual review covered 33 canonical screens in BJ01/BJ02/BJ04/BJ05/BJ06/BJ07/BJ08; unaffected DS-valid compositions are preserved.
- Current correction layer: `v293-grouped-collection-density.css`.

## v2.8.0 corrections

### BJ05 / UIF-05

`Chọn lô thay thế` uses canonical `VBottomSheet` (`4695:6353`): 402px shell, 48×4 handle, 16px horizontal edge, content-driven height with max-height only, no close-X and canonical 44px bottom safe area. `VTextarea` remains canonical `522:7212`; lot options use one List Row Selection geometry. Generic sheet flex/min-height rules must never force unused whitespace into this sheet.

### BJ06 / UIF-06

Structurally migrated screens: `SCR-030 / 031 / 032 / 033 / 034 / 035`.

- Queue and line collections use a single canonical `DS v2 / List Row` family/type/density per record collection. Disabled navigation retains its anatomy/chevron and uses parent opacity 0.4.
- Supporting request/source facts use content-sized grouped surfaces composed from transparent `DS v2 / Info Row` rows.
- Editable quantities/reasons use canonical `VTextField` (`522:7186`) and `VTextarea` (`522:7212`).
- Normal temporary sheets use `VBottomSheet`; no arbitrary X close control is added.
- Business state uses `VBadge`/`VBanner` only when semantically useful; normal states avoid success noise.
- Goods receipt remains all-or-nothing. Wrong-LOT approval is per line and snapshot-based. Classification remains Product+UOM+LOT and never aggregates unlike UOMs.

## Current Product migration

- BJ01 / UIF-01 — migrated.
- BJ02 / UIF-02 — migrated.
- BJ04 / UIF-04 — migrated.
- BJ05 / UIF-05 — migrated; sheet corrected in v2.8.0; grouped handover density corrected in v2.9.3.
- BJ06 / UIF-06 — structurally migrated; UX/navigation corrected in v2.8.2; result hierarchy corrected in v2.9.3.
- BJ07 / UIF-07 — structurally migrated in v2.9.0; hierarchy corrected in v2.9.1/v2.9.2; grouped-collection density corrected in v2.9.3; Product/LOT hierarchy clarified in v2.9.4.
- BJ08 / UIF-08 — redesigned in Audit & Control cluster v3.1.0.
- BJ03 / UIF-03 — migrated as part of Inventory Valuation cluster v3.0.0.
- BJ13 / UIF-13 — migrated as part of Inventory Valuation cluster v3.0.0.
- BJ14 / UIF-14 — migrated as part of Inventory Valuation cluster v3.0.0.
- BJ09 / UIF-09, BJ10 / UIF-10, BJ11 / UIF-11, BJ12 / UIF-12, BJ15 / UIF-15, BJ16 / UIF-16, BJ17 / UIF-17 — redesigned in Audit & Control cluster v3.1.0.
- All 17 UIFs now have a Product-aligned presentation layer in the cumulative HTML harness.

## QA gates

Latest correction layer: `v350-flow-logic-correction.css` + `v350-flow-logic-correction.js`.

Required before release: exact 402×874 Product root; desktop full-device fit; no root horizontal overflow; no browser errors; BJ06 interaction/fidelity QA; prior-BJ regression; all-flow runtime smoke; mobile-prototype validator.

## v2.8.2 UX correction

- BJ05 SCR-027 scales to many LOT allocations using canonical Navigation List Rows; one LOT is edited at a time in canonical VBottomSheet.
- BJ06 maker Back navigation is semantic and cannot enter approver-only SCR-034.
- BJ06 SCR-031/SCR-033 use compact request context to remove repeated metadata and duplicate progress copy.
- Existing 402×874 Product/device-frame correction remains unchanged.

## v2.9.1 — BJ07 hierarchy correction

- Queue: one canonical Navigation/Default List Row collection. No interleaved stage headings; waiting uses Navigation/Disabled with the same anatomy.
- Preparation: compact request context → structural Product+UOM heading → exact-source allocation Navigation rows. Product and LOT no longer share the same visual weight.
- Final review/result: concise grouped Info Rows plus structural Product+UOM heading → Key-value allocation evidence. Evidence is left-aligned and optimized for scanning.
- No cross-UOM grand total; no extra confirmation step; no new Theme component.
- Canonical 402×874 Product geometry and corrected 418×890 review bezel remain unchanged.
