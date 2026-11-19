# Theme 7 HTML ↔ Mosaic Retail Design System Conformance — v3.6.0

## Authority

- **Business authority:** Product documents, BJ/UC, decisions, behavioral and UI-flow contracts determine requirements, flow, state and behavior.
- **Theme 7 design artifact:** the mobile HTML prototype/harness is the current screen-design and executable UX surface for Theme 7.
- **Figma:** the current Mosaic Retail Design System in `QVJolM5tAdFKkhP7RIwe3y` supplies components, variants, tokens, typography, spacing, icon semantics and interaction conventions. Mature prior-theme Figma screens may be used as composition/rhythm references. Figma is **not** the Theme 7 screen-design source.

Relevant DS pages: Foundations & Icons `505:5889`, Components `505:5890`, Patterns & Templates `505:5891`.

## Current scope and conformance

`v3.6.0` reviews the effective HTML runtime for **17 BJ + CAP-01**, covering **89 canonical route occurrences / 77 active unique screens / 518 declared route-state renders**. Conformance evidence comes from executable HTML/runtime QA plus direct DS mapping/inspection; historical migration statuses are not allowed to override the current runtime status. A `data-figma-node` attribute is trace metadata, not conformance evidence by itself.

## v3.6.0 release-blocking UX rules

- Destructive cancellation of an active business object belongs inside that object's context, not in a browse list when the user has not opened the object. BJ08 `Hủy phiên` is the reference case.
- Every stable non-root state must provide at least one executable continuation, Back/Close, recovery/handoff, or terminal next destination. No dead screens.
- Representative/default state fixtures must be reachable and semantically coherent with predecessor requirements; a READY state may not display stale/error/unfinished evidence.
- Mutations need visible feedback when the changed result would otherwise be easy to miss. Prefer toast for same-screen success; do not duplicate a dedicated result, inline validation, warning/blocker, or UNKNOWN recovery state with a success toast.
- Navigation actions must not mutate business finality. Back targets are explicit for auxiliary drill-down surfaces.
- Informational context does not automatically deserve a banner. Reserve semantic banners for exception, warning, blocker, consequence, or state that must interrupt scanning.
- Independent List Row collections have transparent parent surfaces; only the row/card owns its surface, so row spacing shows page background.
- Saved-search/filter `VChip` sets stay on one row and scroll horizontally when needed; chips do not wrap or truncate.
- No new Theme-specific component/pattern is introduced where existing DS primitives and layout composition are sufficient.

## v2.9.0 BJ07 conformance

- Search/filter follows canonical `DS v2 / Search & Filter Header` full-width composition.
- Record collections use canonical `DS v2 / List Row` variants and do not mix contradictory affordances inside one semantic collection.
- Supporting facts use canonical `Info Row`; allocation evidence uses `Key-value Row / Default`.
- Contextual physical verification uses canonical normal `VBottomSheet 4695:6353`, no close X.
- Semantic blockers use `VBanner / Compact`; normal states avoid feedback noise.
- Product viewport remains exact `402×874`; decorative review bezel is external to Product geometry.

## Conformance gate

Migrated Product UI is accepted only after component anatomy/variant/state, typography, spacing, token usage, icon semantics, 402×874 geometry, overflow, navigation, state/finality and browser-error checks pass. Mature Product UI in other available Figma Themes is used after DS/Patterns to validate composition and rhythm, not to override canonical DS semantics.

See `../contracts/figma-ds/UIF-MIGRATION-STATUS.json`. Sau T7-P0: token runtime nằm ở `styles/tokens.css` (giá trị theo DESIGN.md từ đợt v4.7.0); `figma-ds.exact.css` không còn là file riêng và không còn là bản chép Figma nguyên chữ. Thư mục `qa/` và `figma-ds-runtime/` đã xoá — kiểm bằng `tools/golden.mjs`.

## Locked composition rules — v3.2.1

The following presentation rules are release gates for all subsequent Theme 7 Product UI work:

- **No feature-specific product cards when canonical DS primitives already cover the content.** Product identity uses canonical `DS v2 / List Row`; read-only facts use `DS v2 / Info Row` or `DS v2 / Key-value Row`; editable values use the canonical field component. Layout wrappers may group those primitives, but must not masquerade as a new component family.
- **No card-on-card count/recount composition.** A Product row plus its count facts/quantity input belongs to one grouped surface. Do not wrap the facts or quantity field in another bordered/radius surface simply to create hierarchy.
- **Product → LOT/scope is parent-child, never peer-card hierarchy.** Product may retain its meaningful product icon. LOT/non-LOT/scope children are subordinate flat rows/dividers inside the same collection surface unless a documented DS pattern explicitly requires another treatment.
- **Hierarchy must come from DS anatomy, spacing, typography, dividers and semantic state — not from multiplying borders, backgrounds, badges or rounded cards.**
- **`VChip` filter/search strips stay on one row.** Never wrap a saved-search/filter chip set into a second row on mobile. Keep canonical `VChip` anatomy unchanged and use horizontal scrolling inside the 370 px content width; the final chip must be fully reachable.
- **A section/list heading must add information.** Do not repeat the AppBar title, list meaning, or an obvious single collection with headings such as “Công việc”, “Phiên đang thực hiện”, or equivalent labels.
- Before accepting a new composition, compare it against mature Product UI in other Themes after checking canonical Figma DS components/patterns. A custom HTML treatment is not acceptable merely because it can be assembled from CSS.

## Locked composition rules — v3.4.0

- **One semantic group = one visual boundary.** Product identity + its immediate facts/fields may share one grouped surface; do not stack a Product card and a second fact/input card for the same task.
- **Product task headers stay quiet.** Do not repeat generic task labels such as `Cần đếm` on every row when the screen context already communicates that task.
- **Variance is evidence before it is status.** In count/recount/review flows, numeric comparison belongs with aligned facts (`Key-value Row`) unless a true workflow state needs a badge.

- **Independent List Row collections have a transparent collection layer.** Each independent row/card owns its own surface. The spacing between rows must reveal the page/background surface; a parent list wrapper must not paint white (or any card surface) into the gap.
- **Auxiliary drill-down Back returns to the launching context.** History/source/evidence detail screens must not rely on flow-array order when that order can point to a result/terminal screen. Back navigation is explicit and must not mutate business state.
- **Product → LOT uses one Product/UOM group.** Product is the identity row; LOT/non-LOT entries are flat children inside the same boundary. Do not wrap all products into one collection card and do not use connector-line pseudo trees when rows + divider + spacing are sufficient.
- **Dense chip sets use horizontal overflow, not wrapping.** Canonical `VChip` stays one-line and scrollable; do not invent compact chips, truncate labels, or wrap the filter strip.
- **No new visual family to repair hierarchy.** Fix hierarchy with canonical component responsibility, grouped-surface layout, spacing, divider, typography, and icon semantics before introducing any new pattern.

## v3.6.4 — Helper/supporting text is not a badge

- Supporting/helper copy inside `VRadio`, input fields, selection rows, or form compositions must render as plain secondary text.
- Do not apply pill radius, semantic fill, badge background, or badge typography to helper/supporting copy unless the content is explicitly modeled as `VBadge`/status.
- `VRadio` follows the Figma DS component `522:7410`: 20px control, label text, canonical On/Off/Disabled state. Additional explanatory copy may be composed as secondary `VText`, but must not mutate the radio component into a feature-specific chip/card treatment.
- Disabled appearance is parent opacity `0.4`; no custom disabled color.

## Locked composition rules — v4.4.0

- **Homogeneous factual rows own one shared surface.** When two or more `DS v2 / Info Row` and/or `DS v2 / Key-value Row` instances belong to the same semantic block, the collection must have one visible surface boundary: surface background, thin border and canonical radius. Rows inside remain primitives separated by dividers; do not render one card per row.
- **Emphasis stays inside the same block.** `Key-value Row / Emphasis` may keep its semantic brand surface, but it remains a row of the shared block rather than a separate floating card.
- **Do not apply this rule to independent `List Row` collections.** Independent navigation/status rows keep the transparent collection layer and row gaps defined by the existing locked rule. Product→LOT/task subgroups that already own a valid surface must not be wrapped in another surface.
- **Runtime gate is Theme-wide.** QA must scan every canonical UIF screen/state and fail when a minimal factual row group has no surface owner or when a new wrapper creates nested/card-soup surfaces.


## Locked visual QA rules — v4.5.0

- Visual QA không được chỉ dựa vào DOM/static validator: mọi release UI-wide phải có screenshot của từng active screen ở `402×874` và contact sheet theo UIF.
- `VBanner` phải dùng đúng density/geometry của DS: Compact `72px`, Default `96px`; nếu copy vượt ngân sách của variant thì rút copy hoặc chọn variant phù hợp, không kéo cao component bằng CSS.
- `DS v2 / Info Row` là primitive `44px` cho nhãn/giá trị ngắn. Giải thích dài phải dùng text/read-note phù hợp trong cùng surface, không ép wrap vào Info Row.
- `VProgress` chỉ sở hữu progress bar; title/helper là content sibling của composition.
- Không tạo broad selector để “normalize” toàn Theme nếu chưa có snapshot evidence; sửa ở primitive/source copy nhỏ nhất có thể.
