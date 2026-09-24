# VET45 Theme 7 Prototype Harness — v3.10.1

**Current full Theme 7 browser-prototype baseline.** Product viewport remains canonical **402×874**. Product documents/BJ/flow/decision/contract decide business behavior; the **Figma Design System is the UI authority** for component, pattern, token, state and visual expression; the HTML harness is the design/verification medium that implements those authorities.





## v3.10.1 — Wave 4 / BJ09 deep-review state-change semantic hardening

This release uses **v3.10.0 as the single direct cumulative parent** and propagates the approved BJ09 Decision Pack across Decision/BJ/UC, Inventory Control data/behavior/technical contracts, UIF09/screen/component contracts, registries/workbench metadata and runtime prototype. The canonical state taxonomy uses `DEMO` (UI: **Dùng thử**); state-transition policy is versioned; partial changes resolve exact valuation slices; `STATE_TRANSFER` preserves valuation state and book value; expiry is system-derived; reservation reconciliation is atomic when eligibility decreases; and approval is bound to an immutable `StateChangeBasis` while system execution performs the final recheck and commit.

BJ01, Wave 2, Wave 3 and BJ08 locks remain protected by regression. Wave 4 remains open for the remaining Audit & Control journeys.

See `RELEASE-VALIDATION-v3.10.1.md`, `CHANGELOG-v3.10.1.md`, and `specs/themes/theme-07/prototype/html/qa/BJ09-DEEP-REVIEW-QA-v3.10.1.md`.

## v3.10.0 — Wave 4 / BJ08 deep-review stock-count semantic hardening

This release uses **v3.9.9 as the single review baseline** and propagates the approved BJ08 Decision Pack across Decision/BJ/UC, Inventory Control data/behavior/technical contracts, UIF08/screen/component contracts, registries/workbench metadata and runtime prototype. Stock count now opens through an atomic scope barrier before cutoff, freezes a canonical CountScopeSnapshot, counts by observable PhysicalCountKey in base UOM, stores immutable FIRST/RECOUNT submissions, treats StockCountSession as a first-class approval subject, requires authoritative surplus value basis, rechecks risk/value basis at approval commit, and completes zero-variance sessions without a synthetic approval.

BJ01, all Wave 2 and all Wave 3 semantic locks remain protected by regression. Wave 4 remains open until the remaining Audit & Control journeys are reviewed.

See `RELEASE-VALIDATION-v3.10.0.md`, `CHANGELOG-v3.10.0.md`, and `specs/themes/theme-07/prototype/html/qa/BJ08-DEEP-REVIEW-QA-v3.10.0.md`.

## v3.9.9 — Wave 3 / BJ14 deep-review costing publication semantic hardening

This release uses **v3.9.8 as the single review baseline** and propagates the approved BJ14 Decision Pack across Business Journey, Use Cases, valuation data entities, shared behavioral/technical contracts, current screen/flow contracts, registry/workbench metadata and runtime prototype. Costing now runs on one ordered `valuation_sequence + within_transaction_ordinal` timeline; immutable per-Product `ProductCostResult` records carry target and authoritative baselines; successor publications post only incremental reconciliation deltas; operational Official Cost never backdates before publication commit; calculation/posting periods are explicit; dirty scope is exact Product + posting period and source-owned; weighted-average edge cases are blocked or classified deterministically.

BJ01, all Wave 2, BJ03 and BJ13 remain protected by regression. Wave 3 cross-BJ audit covers BJ03 → BJ13 → BJ14.

See `RELEASE-VALIDATION-v3.9.9.md`, `CHANGELOG-v3.9.9.md`, and `specs/themes/theme-07/prototype/html/qa/BJ14-DEEP-REVIEW-QA-v3.9.9.md`.

## v3.9.8 — Wave 3 / BJ13 deep-review late-cost semantic hardening

This release uses **v3.9.7 as the single review baseline** and propagates the approved BJ13 Decision Pack across Business Journey, Use Cases, shared behavioral/technical contracts, late-cost data entities, current screen/flow contracts, registry/workbench metadata and runtime prototype. Late-cost identity is now stable across source revisions; target scope is source/policy-authoritative; allocations target immutable `ValuationExposure` snapshots; allocation metrics are frozen to initial direct value/base quantity; final commit rechecks complete basis/allocation hashes; each source component has exactly one DIRECT/LATE accounting route; and original/posting period is resolved per allocation with dirty scope `Product + posting period`.

BJ01, Wave 2 and BJ03 remain protected and regression-tested.

See `RELEASE-VALIDATION-v3.9.8.md`, `CHANGELOG-v3.9.8.md`, and `specs/themes/theme-07/prototype/html/qa/BJ13-DEEP-REVIEW-QA-v3.9.8.md`.

## v3.9.7 — Wave 3 / BJ03 deep-review direct valuation semantic hardening

This release uses **v3.9.6 as the single review baseline** and propagates the approved BJ03 Decision Pack across Business Journey, Use Cases, shared behavioral/technical contracts, direct-valuation data entities, current screen/flow contracts, registry/workbench metadata and runtime prototype. Direct valuation is now anchored to immutable `DirectCostBasis` identity per commercial receipt item; transaction/base UOM semantics are explicit; allocation and rounding are cumulative and deterministic; final confirmation rechecks basis/scope hashes; initial Official Cost bootstrap is atomic at tenant+product; and receipt business date/accounting-period semantics are locked without rewriting late components into initial valuation.

BJ01 and all Wave 2 semantic locks remain protected and regression-tested.

See `RELEASE-VALIDATION-v3.9.7.md`, `CHANGELOG-v3.9.7.md`, and `specs/themes/theme-07/prototype/html/qa/BJ03-DEEP-REVIEW-QA-v3.9.7.md`.

## v3.9.6 — Wave 2 / BJ04 deep-review reservation semantic hardening

This release uses **v3.9.5 as the single review baseline** and propagates the approved BJ04 Decision Pack across Business Journey, Use Cases, shared behavioral/technical contracts, Reservation/ReservationGroup data entities, current screen/flow contracts, registry/workbench metadata and runtime prototype. Reservation capability is now explicit and source-owned (`NONE | ALL_OR_NOTHING | PARTIAL_ALLOWED`), available only to Advanced Stock; transaction-UOM/conversion snapshots are preserved; `reserved_base_quantity` means current hold while `consumed_base_quantity` preserves committed handover history; deterministic priority is `reservation_priority → source_confirmed_at → stable source_line_id`; BJ04 never mutates an active PickAllocation and only raises `allocation_review_required`; combo reservation is atomic through ReservationGroup; and SCR-021 is a read-only per-line current projection rather than a global FULL/PARTIAL/RELEASED/STALE state surface.

Wave 2 cross-BJ consolidation is included after regression of BJ01/BJ02/BJ05/BJ06/BJ07.

See `RELEASE-VALIDATION-v3.9.6.md`, `CHANGELOG-v3.9.6.md`, and `specs/themes/theme-07/prototype/html/qa/BJ04-DEEP-REVIEW-QA-v3.9.6.md`.

## v3.9.5 — Wave 2 / BJ07 deep-review semantic hardening

This release uses **v3.9.4 as the single review baseline** and propagates the approved BJ07 Decision Pack across current Business Journey, Use Cases, shared behavioral/technical contracts, data entities, screen/flow contracts, registry/workbench metadata and runtime prototype. Supplier-return intake and `RTV_PENDING` are now system-owned; stable source line/allocation identity supports granular source-version invalidation; exact original stock-state source slices preserve reversible state ownership; physical mismatch is an immutable structured observation rather than a dead-end boolean; `HandoverEvidence` is source-agnostic across BJ05/BJ07; and commercial supplier price is explicitly outside the physical handover gate. UNKNOWN keeps the same operation identity and hands finality to BJ17 without blind retry.

Frozen-source history remains byte-identical. BJ01, BJ02, BJ05 and BJ06 semantic locks are protected by regression.

See `RELEASE-VALIDATION-v3.9.5.md`, `CHANGELOG-v3.9.5.md`, and `specs/themes/theme-07/prototype/html/qa/BJ07-DEEP-REVIEW-QA-v3.9.5.md`.

## v3.9.4 — Wave 2 / BJ06 deep-review semantic hardening

This release uses **v3.9.3 as the single review baseline** and applies the approved BJ06 Decision Pack across current SRS, shared contracts, screen contracts, flow, Inspect/workbench data and runtime prototype. Theme 5 ReturnExchangeLine authorization is now the request upper bound; physical partial receipt is supported; declared return condition is context-only while Theme 7 classification owns inventory disposition; wrong-LOT approval is per-line and content-bound; new/existing LOT handling is explicit; expiry is system-derived; result identity stays anchored to the source return request/SalesOrder; UNKNOWN finality hands off to BJ17 with the same operation identity and no blind retry.

Frozen-source history remains byte-identical. BJ01, BJ02 and BJ05 semantic locks remain protected by regression.

See `RELEASE-VALIDATION-v3.9.4.md`, `CHANGELOG-v3.9.4.md`, and `specs/themes/theme-07/prototype/html/qa/BJ06-DEEP-REVIEW-QA-v3.9.4.md`.

## v3.9.3 — Wave 2 / BJ05 deep-review semantic hardening

- Separate allocation plan, cumulative pick evidence, and cumulative handover consumption.
- Partial handover writes immutable HandoverEvidence without shrinking allocation/requested history.
- LOT changes after pick require explicit physical-correction assertion.
- UNKNOWN transitions the task to non-actionable `Đang xác minh bàn giao` and hands finality to BJ17.
- Source UOM/base normalization, quantity precision, LOT pickable snapshots, partial policy and requested/remaining semantics are explicit.
- BJ01/BJ02 semantics remain unchanged.

See `RELEASE-VALIDATION-v3.9.3.md`, `CHANGELOG-v3.9.3.md`, and `specs/themes/theme-07/prototype/html/qa/BJ05-DEEP-REVIEW-QA-v3.9.3.md`.

## v3.9.2 — Wave 2 / BJ02 deep-review semantic hardening

- Baseline duy nhất: v3.9.1; BJ01 vẫn locked.
- BJ02 khóa semantic `Tổng kiểm nhận` / `Vào tồn vật lý`, kiểm tra vượt source theo accepted physical base quantity và source remainder authoritative.
- Quick Receipt dùng tenant business date read-only, Chứng từ giao nhận theo Shared Attachment Policy, structured ownership assertion và capability gating.
- Approval risk dùng authoritative price per base UOM; approver xem evidence, Người gửi / Gửi lúc và aggregate risk total theo capability.
- LOT HSD/NSX giữ DAY/MONTH/YEAR; source change cần explicit reset; Document zero-impact được mô tả đúng, Quick zero accepted physical bị chặn.
- UNKNOWN tiếp tục dùng cùng operation identity và đối soát bằng evidence authoritative; không blind retry.

See `RELEASE-VALIDATION-v3.9.2.md`, `CHANGELOG-v3.9.2.md`, and `specs/themes/theme-07/prototype/html/qa/BJ02-DEEP-REVIEW-QA-v3.9.2.md`.

## v3.9.1 — Wave 1 / BJ01 deep-review semantic hardening

This release uses **v3.9.0 as the single Theme 7 review baseline** and applies the approved BJ01 Deep-Dive Decision Pack across business/data/presentation/runtime artifacts. BJ01 no longer invents reservation/availability at LOT grain; freshness is server `query_as_of`; physical→eligible differences have explicit reason breakdown; stock-level and expiry attention are independent; `NOT_CONFIGURED` is explicit; near-expiry distinguishes `WARN/BLOCK_SALE`; expiry precision is preserved; provenance names concrete movement/reservation facts; raw availability is a Key-value metric rather than a status badge.

No mutation flow or BJ decomposition changes. Cross-BJ semantic impact is scanned for BJ04/BJ05/BJ09/BJ12/BJ15/CAP-01, but their local UX is not redesigned ahead of their review wave.

See `RELEASE-VALIDATION-v3.9.1.md`, `CHANGELOG-v3.9.1.md`, and `specs/themes/theme-07/prototype/html/qa/BJ01-DEEP-REVIEW-QA-v3.9.1.md`.

## v3.9.0 — Full Theme 7 end-user hardening

This release hardens the complete Theme 7 integrated experience after an end-user review of all **17 Business Journeys + CAP-01**, while preserving their business decomposition and existing state machines. The change is primarily an orchestration layer above the existing BJ renderers.

- **Dynamic work projection:** `Việc của bạn` is now projected by simulated persona, business state and session outcome instead of a fixed five-item fixture. Operator, controller and manager see different work.
- **Exact task routing:** concrete work items deep-link to the exact receipt/case/session instead of reopening a generic queue and forcing the user to search again.
- **Context before action:** `Chuyển tình trạng hàng` and `Tạo yêu cầu tiêu hủy` started from Kho now begin at an eligible item/product/lot selection list; a fixture product is never preselected without user context.
- **Context-aware exits:** task-originated handoffs/results return to Kho and remove the resolved work item; catalog-originated flows can return to the catalog. Internal BJ navigation remains unchanged.
- **Permission/persona projection:** the integrated Home, manual-start sheet and long-tail function catalog expose only capabilities relevant to the active simulated persona. The catalog is searchable.
- **Handoff lock:** once a supported request is in `PENDING_APPROVAL`, the integrated journey cannot Back into an editable draft revision.
- **Cross-BJ language polish:** BJ06 distinguishes the inspection screen, BJ09 names its approval handoff as `Gửi chờ duyệt`, and BJ17 uses `Lần xử lý` instead of implementation-centric identity wording.

QA adds **Full Theme End-user Hardening 19/19 PASS** and reruns the current package's semantic flow (**21/21**), all-flow runtime smoke (**89/89**), runtime UI (**14/14 across 518 declared states**), representative coherence (**8/8**) and device frame (**7/7; 89 screens**) with **0 browser errors**.

See `RELEASE-VALIDATION-v3.9.0.md`, `CHANGELOG-v3.9.0.md`, and `specs/themes/theme-07/prototype/html/qa/FULL-THEME-END-USER-HARDENING-QA-v3.9.0.md`.

## v3.8.3 — Warehouse Home clarity polish

This release removes the remaining ambiguity in the task-driven **Kho** Home. The `Việc của bạn` disclosure is now owned by the section header (`Xem tất cả (5)` / `Thu gọn`) instead of sharing a mixed action row with a creation CTA. Starting user-initiated warehouse work is presented as one canonical Navigation List Row named **Bắt đầu việc mới**, with helper copy `Nhập hàng nhanh, kiểm kê hoặc xử lý hàng`; the four underlying manual-start destinations are unchanged.

The full-function catalog also drops explanatory badges such as `Khi có sai sót`, `Khi có chênh lệch`, `Từ đơn bán`, `Khởi tạo`, and `Thiết lập`. Those strings are access/context explanations rather than object statuses. The contextual reservation capability is represented by the canonical **Disabled Navigation List Row** state with helper `Thực hiện từ chi tiết đơn bán`. No business flow, state machine, finality or existing BJ renderer changes.

See `RELEASE-VALIDATION-v3.8.3.md`, `CHANGELOG-v3.8.3.md`, and `specs/themes/theme-07/prototype/html/qa/WAREHOUSE-HOME-CLARITY-QA-v3.8.3.md`.

## v3.8.2 — Warehouse Home action hierarchy

This release corrects the remaining visual/behavioral hierarchy issue on the task-driven **Kho** Home. `Tạo thao tác` is no longer a standalone full-width Primary CTA after `Tra cứu`; it now sits inside **Việc của bạn** as a canonical **Secondary VButton** beside the task disclosure control. The Home therefore communicates the intended priority clearly: continue concrete work first, deliberately start new work second, use lookup utilities afterward, and use `Tất cả chức năng kho` only for long-tail discovery.

The existing four-action bottom sheet, the v3.8.1 full-function catalog, all **17 BJ + CAP-01**, and all business/state behavior are preserved. See `RELEASE-VALIDATION-v3.8.2.md`, `CHANGELOG-v3.8.2.md`, and `specs/themes/theme-07/prototype/html/qa/WAREHOUSE-HOME-ACTION-HIERARCHY-QA-v3.8.2.md`.

## v3.8.1 — Secondary function catalog & dismissible-sheet cleanup

This release keeps the **task-driven Warehouse Home** from v3.8.0 as the primary Product surface and adds one low-emphasis **Tất cả chức năng kho** route at the end of Kho. The secondary catalog exposes all **17 BJ + CAP-01** for long-tail discoverability without returning the exhaustive business-journey catalog to the Home decision surface. Catalog-launched flows reuse the existing Theme 7 runtime and return to the catalog from their entry screen.

The `Tạo thao tác` bottom sheet still contains only the four genuinely user-initiated actions, but the explanatory helper and redundant **Đóng** CTA are removed; backdrop click and Escape dismiss the sheet. A cross-theme sheet audit also removes pure `Đóng` CTAs from dismissible/view-only BJ02 review detail, BJ08 select, and BJ15 product-detail sheets while preserving `Hủy`, `Quay lại`, `Xong`, `Lưu`, and confirmation actions where edits or decisions need an explicit semantic boundary.

See `RELEASE-VALIDATION-v3.8.1.md`, `CHANGELOG-v3.8.1.md`, and `specs/themes/theme-07/prototype/html/qa/FUNCTION-CATALOG-SHEET-QA-v3.8.1.md`.


## v3.8.0 — Task-driven Warehouse Home

This release changes the integrated **Kho** experience from an operation catalog into a production-like **Warehouse Work Center**. The separate **Theo BJ / UIF** tab remains the exhaustive review surface for all **17 BJ + CAP-01**; the Product-like **Toàn Theme 7** tab now exposes only what an end user should actually decide.

The Kho root now contains:
- **Inventory search** for product / SKU / lot context.
- **Việc của bạn** — concrete work items generated by current business context; three are visible by default and two more expand inline.
- **Tra cứu** — only `Tồn kho` and `Báo cáo & thẻ kho` remain direct utility destinations.
- **Tạo thao tác** — one CTA opens a canonical bottom sheet for truly user-initiated work: quick receipt, new stock count, item-state change and disposal request.
- Contextual / exception / setup journeys such as reservation, correction, reconciliation, recovery, opening balance and policy configuration are no longer presented as normal menu choices in Product UI. They remain fully reviewable in **Theo BJ / UIF**.

Direct work items route into the relevant existing BJ screen without duplicating renderers. Their entry Back returns straight to Kho, while internal journey navigation remains unchanged. No BJ is merged or removed; this is a presentation/read-model and navigation refinement only.

See `RELEASE-VALIDATION-v3.8.0.md`, `CHANGELOG-v3.8.0.md`, and `specs/themes/theme-07/prototype/html/qa/TASK-DRIVEN-WAREHOUSE-HOME-QA-v3.8.0.md`.

## v3.7.1 — Flat Kho hub + progressive disclosure

This release keeps the two workbench tabs and integrated **Thêm → Kho** entry from v3.7.0, but refactors the Kho root so business architecture is no longer exposed as a long 18-item navigation catalog. **Kho is now one flat task hub**: priority work is surfaced first, seven frequent destinations remain one-tap entries, and eleven infrequent/contextual/setup journeys expand inline on the same screen. Visual grouping never creates a category route.

Key rules locked in this release:
- **Kho → BJ directly** for frequent work; no `Kho → category → BJ` route.
- **Cần xử lý** surfaces current work without creating another dashboard layer.
- **Nghiệp vụ khác** uses inline progressive disclosure; expand/collapse does not push navigation history.
- All **17 BJ + CAP-01** remain reachable from the same Kho screen.
- Flow-entry Back still returns directly to **Kho** in the integrated tab; existing internal BJ navigation and the **Theo BJ / UIF** tab are unchanged.

QA adds `FLAT-HUB-NAVIGATION-QA-v3.7.1` and preserves the full 518-state, semantic-flow, list, footer, VRadio/helper, device and all-flow regression gates.

See `RELEASE-VALIDATION-v3.7.1.md`, `CHANGELOG-v3.7.1.md`, and `specs/themes/theme-07/prototype/html/qa/FLAT-HUB-NAVIGATION-QA-v3.7.1.md`.

## v3.7.0 — Integrated VET45 navigation + full Theme 7 workbench tab

This release keeps the existing **Theo BJ / UIF** review mode unchanged and adds a second **Toàn Theme 7** tab. The integrated mode starts at **VET45 → Thêm → Kho**, then exposes all **17 Business Journeys + CAP-01** through a single Theme 7 module root. It reuses the same cumulative screen renderers and state objects as the BJ/UIF harness; no business screen is duplicated or forked.

New Product surfaces:
- **Thêm** — reproduces the current VET45 entry surface with `Kho` enabled for this package; out-of-scope modules are true Disabled Navigation rows.
- **Kho** — grouped module root for Tồn kho, vận hành kho, giá trị & giá vốn, kiểm kê & kiểm soát, báo cáo, related/contextual work and policy capability.
- Every Theme 7 entry has deterministic Back navigation to `Kho`; screen-level Back and result behavior inside each BJ remain unchanged.

QA adds `INTEGRATED-THEME-NAVIGATION-QA-v3.7.0` and preserves the existing 518-state, flow, list, footer, VRadio/helper, device and all-flow gates.

See `RELEASE-VALIDATION-v3.7.0.md`, `CHANGELOG-v3.7.0.md`, and `specs/themes/theme-07/prototype/html/qa/INTEGRATED-THEME-NAVIGATION-QA-v3.7.0.md`.

## v3.6.4 — Canonical VRadio / helper-text correction

This release preserves the v3.6.3 homogeneous Navigation/Disabled-row correction and removes a legacy non-DS helper treatment found in BJ09 state-change choices. The old `choice-card` helper rendered supporting copy as a green pill; v3.6.4 replaces that active choice rendering with the canonical `VRadio` anatomy and keeps supporting text as plain secondary text. A cumulative helper guardrail also prevents reachable legacy helper text from acquiring badge/pill backgrounds. Business behavior and state transitions are unchanged.

See `RELEASE-VALIDATION-v3.6.4.md` and `CHANGELOG-v3.6.4.md`.


## v3.6.3 — Homogeneous navigation list / disabled-state correction

This release fixes a cross-list interaction-semantic defect: peer task rows in one navigation collection must not change component type just because one item is temporarily unavailable. Waiting rows in BJ03 `SCR-014` and BJ13 `SCR-085` now remain canonical `DS v2 / List Row · Type=Navigation`, retain the same chevron/geometry as actionable peers, and use `State=Disabled` with DS parent opacity `0.4`.

Whole-runtime list semantics QA scans all **518 declared route-state renders**. No other homogeneous Navigation collection was found with the same mixed `Navigation/Status` defect. Existing list spacing, footer composition, flow behavior, business rules and navigation destinations are preserved.

## v3.6.2 — Independent list/card rhythm correction

This cumulative release fixes the spacing defect reported on BJ08 and expands the QA to all declared route-state renders. Independent bordered List Row/card peers must expose page background between items; they must never visually fuse because a collection wrapper forgot its inter-item gap. True grouped parent→child surfaces remain intentionally joined.

The cross-runtime audit found three real defect classes: BJ08 count-session rows, BJ09 state-history timeline cards, and BJ15 fallback inventory-result cards. All are corrected with the existing Figma DS spacing token; no business rule, action, navigation or core DS component changes. See `RELEASE-VALIDATION-v3.6.2.md`, `CHANGELOG-v3.6.2.md`, and `specs/themes/theme-07/prototype/html/qa/LIST-SURFACE-RHYTHM-QA-v3.6.2.md`.

## v3.6.1 — Dual Sticky Footer correction

This release corrects the two-action footer composition across the complete Theme 7 runtime. Every visible footer with exactly two actions now follows the canonical horizontal `Secondary/Destructive | Primary` layout at 402×92 with 181/8/181 action geometry and 44 px action height. The reported `Hủy phiên / Nộp kết quả đếm` case is fixed together with the same defect in approval footers elsewhere. Single-action footers and business behavior are unchanged.

Footer-specific QA covers all declared route-state renders and passes 11/11 checks; the existing runtime, flow, completion, coherence, all-flow and device-frame gates also remain green. See `RELEASE-VALIDATION-v3.6.1.md`, `CHANGELOG-v3.6.1.md`, and `specs/themes/theme-07/prototype/html/qa/FOOTER-ACTION-QA-v3.6.1.md`.

## v3.6.0 — Full Theme completion, flow exits & semantic feedback

- Scope is now **17 Business Journeys + CAP-01 supporting policy capability**, covering **89 canonical route occurrences**, **77 active unique screens** and **518 declared route-state renders**.
- `SCR-062..065` are now rendered as CAP-01: stock policy, near-expiry policy, policy review and update result. The unresolved production entry/permission/return integration remains explicitly tracked as `BG-006`; the harness does not invent that production IA.
- BJ08 cancellation is no longer a browse-list action. `Hủy phiên` exists only inside an opened active count/recount session, requires a reason, confirms destructively, ends in `CANCELLED`, then returns with visible feedback.
- Stable non-root screens have an executable exit; auxiliary Back targets are explicit and navigation actions never create business finality.
- Same-context mutations now use semantic toast feedback where the result would otherwise be easy to miss. Dedicated result screens, inline validation, blockers and `UNKNOWN` recovery do not receive redundant success toasts.
- Representative READY fixtures are reachability-coherent for BJ02, BJ03, BJ07, BJ13 and BJ14, avoiding review/approval screens that display prerequisite-invalid data.
- UX simplification reduces informational-banner noise while preserving warning/error/blocker semantics. Existing one-row horizontally scrollable VChip and transparent independent-list spacing rules remain locked.
- Current release gates: static consistency, semantic transition E2E, effective-runtime UI, full-theme completion, legacy regressions, current package validation and visual review. Browser validation does not claim backend transaction/outbox/database atomicity.

See `RELEASE-VALIDATION-v3.6.0.md`, `CHANGELOG-v3.6.0.md`, and `specs/themes/theme-07/prototype/html/qa/`.


Cumulative mobile HTML prototype. Product viewport remains canonical **402×874** inside the corrected decorative review bezel **418×890**.

## v3.5.1 — List surface, VChip & drill-down correction

This cumulative UI/prototype correction keeps the v3.5.0 business state machine unchanged and fixes the classes of defects found in the BJ09 review. Independent List Row collections now have a **transparent collection layer**, so only each row/card owns the white surface and the spacing between rows reveals the page background. Search/filter `VChip` sets remain on **one horizontal row** and are swipe/scrollable when the full set exceeds the 370 px content width; chips do not wrap or truncate.

BJ09 `Xem lịch sử` now returns explicitly to the detail that launched it rather than relying on flow-array order and accidentally landing on the result screen. The same auxiliary-drill-down rule is applied proactively to BJ15 movement/source evidence. No business finality is mutated by Back navigation and no new DS component/pattern is introduced.

Current gates: **500/500 declared states**, **272/272 Audit & Control states**, **85/85 canonical routes**, semantic flow/logic **21/21**, runtime UI **14/14**, all-flow smoke **85/85**, device frame **7/7**, prior-BJ regression **23/23**, valuation integration **14/14**, review fit **3/3**, with **0 browser errors**.

See `RELEASE-VALIDATION-v3.5.1.md`, `CHANGELOG-v3.5.1.md`, and `specs/themes/theme-07/prototype/html/qa/`.

## v3.5.0 — Flow, logic, recovery & full-runtime QA correction

This cumulative release fixes the flow/state-machine defects found by the post-v3.4.0 holistic QA across all 17 Business Journeys. It adds executable stale-source guards, actor-boundary checks, UNKNOWN/finality recovery through BJ17, bound mutation inputs, control-total validation, report scoping, costing successor lineage preservation, entry-context routing, and full search/filter behavior. UI remains aligned to the live Figma Design System; no new core DS component is introduced.

Release gates are split deliberately: semantic flow/logic E2E and effective-runtime UI/state rendering. `500/500` state renders is no longer treated as proof of transition correctness. Browser QA does not claim backend DB/outbox/network atomicity.

See `RELEASE-VALIDATION-v3.5.0.md`, `CHANGELOG-v3.5.0.md`, and `specs/themes/theme-07/prototype/html/qa/`.

## v3.2.1 — DS composition correction

This release corrects the visual-composition problems found after the v3.2.0 review, with particular focus on **BJ08 counting/recount**, **BJ09 filter chips**, and the same product→LOT hierarchy issue in **BJ07**. Business/state/action topology is preserved.

- BJ08 no longer uses feature-specific product/count cards or nested card-on-card surfaces. Product identity is a canonical `DS v2 / List Row`; count/recount facts are subordinate `DS v2 / Key-value Row` content and the editable quantity remains the canonical quantity field, all inside one grouped surface.
- Product context and editable facts are separated by hierarchy, typography, spacing and dividers rather than repeated borders/radii. No Theme-specific component or new UI pattern is introduced.
- BJ07 product→LOT presentation is flattened: Product remains the parent List Row with meaningful product icon, while LOT/non-LOT children are flat subordinate List Rows separated inside the same collection surface rather than peer cards.
- Audit & Control `VChip` groups wrap complete canonical chips when the available 370 px width cannot contain the full filter set. A chip must never be partially clipped.
- Redundant list headings and browse-list destructive actions remain prohibited from v3.2.0.
- A locked composition rule is added to `DS-CONFORMANCE.md` so the same anti-pattern is rejected in subsequent Theme 7 work.

QA: **16/16 composition/release gates PASS**, **269/269 Audit & Control declared-state renders PASS**, cumulative **497/497 state renders PASS**, **0 browser errors**, topology unchanged from v3.2.0, and focused visual captures reviewed for BJ08/BJ09/BJ07.

See `RELEASE-VALIDATION-v3.2.1.md` for release gates.

## v3.1.0 — Inventory Audit & Control cluster

This release redesigns the full **Inventory Audit & Control** cluster in one pass: **BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17** (44 canonical routes). It keeps the v3.0.1 business/state topology and aligns presentation to the live Figma DS.

- Generic work, case and movement queues are text-first `DS v2 / List Row` collections with optional leading icons hidden when they add no semantic value; Product rows retain the Product icon.
- Physical count/recount uses Product parent context plus nested quantity/evidence controls; count evidence uses `Info Row`/`Key-value Row` instead of repeated cards.
- Item-state and correction decisions use canonical `VRadio`; no custom two-option segmented selector is introduced.
- Audit/history and source trace use canonical `DS v2 / Audit Item` (`525:621`).
- Opening-balance validation, disposal, reconciliation and unknown-result recovery are flattened into one conceptual surface per collection to avoid card soup.
- User-facing copy is Vietnamese and does not expose `Cut-off`, `LOT`, `UOM`, `UNKNOWN`, raw revision labels, or implementation terms such as ledger/recovery/projection/commit.

QA: **52/52 release checks PASS**, covering all **269 Audit & Control declared-state renders**, full-harness **497/497 declared-state renders**, and **85/85 canonical screens at 402×874** with no browser errors or root/content horizontal overflow.

See `RELEASE-VALIDATION-v3.1.0.md` for release gates.

## v3.0.1 — Operations + Valuation UI hardening

This release audits the full **Inventory Operations + Inventory Valuation** scope: **BJ01, BJ02, BJ03, BJ04, BJ05, BJ06, BJ07, BJ13, BJ14** (41 canonical screens). `DS v2 / List Row` now treats its leading icon as semantic and optional: product identity keeps the product icon, while work queues, request context, LOT/child rows, and other text-first rows hide decorative icons so copy reclaims that space. BJ07 Product → lot hierarchy and BJ03 valuation Product → scope hierarchy use existing Figma DS primitives/compositions rather than a new core component.

The audit also removes redundant queue section headings such as **“Công việc”**, prevents copy/status overlap in dense List Rows, fixes the blank BJ03 **“Căn cứ và cách tính”** sheet, and removes user-facing implementation vocabulary/raw revision labels such as `Cut-off`, `UOM`, `LOT`, `v7/v8`, policy-version codes, and backend state names. Business behavior, commit semantics, and journey topology remain unchanged.

See `RELEASE-VALIDATION-v3.0.1.md` for release gates.

## v3.0.0 — Inventory Valuation cluster

This milestone redesigns **BJ03 + BJ13 + BJ14 as one cluster** while preserving their existing business contracts and state machines. BJ03 now uses a clear Product/UOM → LOT/non-LOT valuation hierarchy with contextual evidence in `VBottomSheet`; BJ13 uses compact source context plus one scope/allocation collection; BJ14 uses immutable run summaries, one method-comparison surface, explicit blockers, and canonical `VRadio` for the two run-kind choices. Money/quantity remain values, not status badges, and no new core Design System component is created.

Figma DS references include `DS v2 / List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, `VBadge 525:309`, `VRadio 522:7410`, `VSelect 522:7291`, `VBottomSheet 4695:6353`, and `VAppBar 547:1594`.

See `RELEASE-VALIDATION-v3.0.0.md` for release gates.

## v2.9.4 — BJ07 Product/LOT hierarchy

This release clarifies the remaining BJ07 parent-child ambiguity between Product/UOM and LOT/non-LOT data. SCR-037 now uses one grouped surface with a lightweight Product group header and flat nested allocation rows. The same hierarchy is reused on SCR-039 and SCR-041; read-only allocation evidence remains canonical `Key-value Row` at **338×44**. No new core Design System component is created and business behavior is unchanged.

See `RELEASE-VALIDATION-v2.9.4.md` for release gates.

## v2.9.3 — DS-native grouped collections

This release removes the remaining **card-soup** pattern from migrated BJ05/BJ06/BJ07 without relaxing Figma DS fidelity. A homogeneous collection now owns one light grouped surface; repeated Product+UOM groups are layout subgroups, not independent outer cards. The actual visible rows remain canonical Figma components: Product+UOM uses `DS v2 / List Row · Type=Status · Density=Compact` at **370×52**; actionable LOT uses `List Row · Navigation · Default` at **370×76**; read-only LOT/evidence uses canonical `Info Row` or `Key-value Row` at **338×44**.

Raw quantities such as `6 hộp` / `5 lọ` are data values, not `VBadge` statuses. `VBadge` is reserved for semantic progress/state such as `Đã kiểm`, `Đã bàn giao`, or `Đã phân loại`. No Theme-specific component was created and business behavior is unchanged.

The migrated Product UI audit covered **33 canonical screens** across BJ01, BJ02, BJ04, BJ05, BJ06, BJ07 and BJ08. The same nested per-Product card anti-pattern required correction only in BJ05/SCR-028, BJ06/SCR-035 and BJ07/SCR-037/SCR-039/SCR-041; the other migrated screens were preserved where their card/surface semantics were already valid.

See `RELEASE-VALIDATION-v2.9.3.md` for release gates.
