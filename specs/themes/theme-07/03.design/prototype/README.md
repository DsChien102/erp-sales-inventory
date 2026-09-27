---
id: PROTOTYPE
type: prototype-manifest
theme: theme-07
title: "Theme 07 mobile prototype mapping"
owner: BA
status: FROZEN
source_baseline: v4.4.0
version: v4.5.0
parent: v4.4.0
---
# Prototype — Theme 07

## v4.5.0 — Snapshot-led visual QA hardening

- Parent package: `v4.4.0`; business semantics, BJ/UC/UIF/Screen Contract topology and actions are unchanged.
- Chụp 82 màn active và ghép 17 contact sheet theo UIF để review trực quan; all-state audit chạy 486 state.
- Sửa verified regressions: VBanner density/copy overflow, long explanatory copy bị ép vào Info Row 44px, VProgress composition sai.
- Không dùng broad CSS normalization; chỉ sửa primitive/copy đã có bằng chứng snapshot.
- Evidence: `html/qa/SNAPSHOT-LED-VISUAL-QA-v4.5.0.*` và regression suite `*v4.5.0*`.

## v4.4.0 — Theme-wide grouped surface consistency

- Parent package: `v4.3.1`; business semantics, BJ/UC/UIF topology and actions are unchanged.
- Toàn bộ 17 UIF được audit theo rule `một nhóm factual rows = một surface boundary`.
- Runtime bổ sung surface tự động chỉ cho semantic row group chưa có surface owner hợp lệ; không tạo nested card và không chạm independent List Row collection.
- Actual repairs: `SCR-003`, `SCR-010`, `SCR-028`. Valuation grouped surfaces từ v4.3.1 được giữ nguyên.
- Evidence: `html/qa/THEME-WIDE-GROUPED-SURFACE-v4.4.0.*` và `ALL-FLOWS-RUNTIME-SMOKE-v4.4.0.*`.

## v4.3.0 — Valuation UI/UX + runtime hardening

- Parent package: `v4.2.0`; business semantic and UIF topology are unchanged.
- Review/fix scope: toàn bộ BJ03, BJ13, BJ14 trên 11 màn active.
- Final valuation runtime layer: `v430-valuation-uiux.css/js`, loaded after prior valuation layers and re-rendered immediately on first paint.
- BJ03 long-form entry uses `DS v2 / Form Sheet` + fixed `Sticky Footer`; BJ14 publication uses `DS v2 / Confirmation Sheet`.
- Retired valuation routes remain compatibility-only and redirect to canonical surfaces; `SCR-018` hands off to BJ13 / `SCR-085`.
- Runtime evidence: `html/qa/VALUATION-FLOW-E2E-v4.3.0.*`, `VALUATION-VISUAL-INTEGRITY-v4.3.0.*`, `VALUATION-FULL-STATE-SMOKE-v4.3.0.json`.


## v3.13.0 — Valuation design parity

- `UIF-03`: 4 active screens; Quick direct-basis sheet; Document commercial conflict is read-only/handoff; result records initial value only.
- `UIF-13`: 4 active screens; signed adjustment; source/scope/allocation combined on `SCR-086`.
- `UIF-14`: 3 active screens; work-oriented queue; tenant costing method read-only; publication review uses canonical `VBottomSheet`.
- Retired: `SCR-016`, `SCR-018`, `SCR-087`, `SCR-073`, `SCR-075`, `SCR-076`.
- Runtime/interaction/visual evidence is under `html/qa/*v3.13.0*`.


## 1. Mục đích

Prototype là design expression/verification medium hiện hành của baseline v4.5.0; không phải nguồn business rule. Runtime HTML được giữ nguyên tại `03.design/prototype/html/` để package có thể chạy prototype độc lập, trong khi manifest này giữ vai trò mô tả cách chạy và mapping theo template.

## 2. Cách chạy

Mở `03.design/prototype/html/index.html` trực tiếp hoặc phục vụ thư mục `03.design/prototype/html/` bằng một static HTTP server. Runtime giữ các layer lịch sử để regression, đồng thời nạp `v430-valuation-uiux.css/js` sau các lớp valuation lịch sử để BJ03/BJ13/BJ14 dùng đúng contract v4.3.0 và Figma DS v2 ngay từ first paint; `v440-theme-wide-grouped-surface.css/js` giữ invariant grouped surface; `v450-theme-visual-qa.css` nạp sau cùng để sửa đúng các visual regression đã được snapshot xác nhận.

## 3. Screen → route/state mapping

| Screen | Route / state | Ghi chú |
|---|---|---|
| `SCR-001` | `#/sg-01/scr-01` | BJ01_ACTIVE_v3.9.1 |
| `SCR-002` | `#/sg-01/scr-02` | MERGED_INTO_SCR-003 |
| `SCR-003` | `#/sg-01/scr-03` | BJ01_ACTIVE_v3.9.1 |
| `SCR-004` | `#/sg-01/scr-04` | OVERLAY_IN_SCR-003_v3.9.1 |
| `SCR-005` | `#/sg-01/scr-05` | OVERLAY_IN_SCR-003_v3.9.1 |
| `SCR-006` | `#/sg-02/scr-01` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-007` | `#/sg-02/scr-02` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-008` | `#/sg-02/scr-03` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-009` | `#/sg-02/scr-04` | BJ02_PILOT_REFINED_v0.3.4 |
| `SCR-010` | `#/sg-02/scr-05` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-011` | `#/sg-02/scr-06` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-012` | `#/sg-02/scr-07` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-013` | `#/sg-02/scr-08` | BJ02_PILOT_CALIBRATING_v0.2.9 |
| `SCR-014` | `#/sg-03/scr-01` | UIUX_HARDENED_v4.3.0 |
| `SCR-015` | `#/sg-03/scr-02` | UIUX_HARDENED_v4.3.0 |
| `SCR-016` | `#/sg-03/scr-03` | RETIRED_v3.13.0 → SCR-015 |
| `SCR-017` | `#/sg-03/scr-04` | UIUX_HARDENED_v4.3.0 |
| `SCR-018` | `#/sg-03/scr-05` | RETIRED_v3.13.0 → SCR-085 |
| `SCR-019` | `#/sg-03/scr-06` | UIUX_HARDENED_v4.3.0 |
| `SCR-020` | `#/sg-04/scr-01` | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-021` | `#/sg-04/scr-02` | ACTIVE_v3.9.6 |
| `SCR-022` | `#/sg-04/scr-03` | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-023` | `#/sg-04/scr-04` | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-024` | `#/sg-04/scr-05` | RETIRED_FROM_UIF04_v1.3.4 |
| `SCR-025` | `#/sg-06/scr-01` | ACTIVE_v1.3.7 |
| `SCR-026` | `#/sg-06/scr-02` | ACTIVE_v1.3.7 |
| `SCR-027` | `#/sg-06/scr-03` | ACTIVE_v1.3.7 |
| `SCR-028` | `#/sg-06/scr-04` | ACTIVE_v1.3.7 |
| `SCR-029` | `#/sg-06/scr-05` | ACTIVE_v1.3.7 |
| `SCR-030` | `#/sg-07/scr-01` | ACTIVE_v1.3.9 |
| `SCR-031` | `#/sg-07/scr-02` | ACTIVE_v1.3.9 |
| `SCR-032` | `#/sg-07/scr-03` | ACTIVE_v1.3.9 |
| `SCR-033` | `#/sg-07/scr-04` | ACTIVE_v1.3.9 |
| `SCR-034` | `#/sg-07/scr-05` | ACTIVE_v1.3.9 |
| `SCR-035` | `#/sg-07/scr-06` | ACTIVE_v1.3.9 |
| `SCR-036` | `#/sg-08/scr-01` | UIF07_CONTEXT_ACTIVE_v1.3.6 |
| `SCR-037` | `#/sg-08/scr-02` | UIF07_CONTEXT_ACTIVE_v1.3.6 |
| `SCR-038` | `#/sg-08/scr-03` | EXCLUDED_FROM_UIF07_v1.3.4 |
| `SCR-039` | `#/sg-08/scr-04` | UIF07_DEEP_CORRECTED_v1.3.9 |
| `SCR-040` | `#/sg-08/scr-05` | HARNESS_FULL_WORKBENCH |
| `SCR-041` | `#/sg-08/scr-06` | UIF07_CONTEXT_ACTIVE_v1.3.4 |
| `SCR-042` | `#/sg-09/scr-01` | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-043` | `#/sg-09/scr-02` | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-044` | `#/sg-09/scr-03` | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-045` | `#/sg-09/scr-04` | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-046` | `#/sg-09/scr-05` | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-047` | `#/sg-09/scr-06` | PRODUCT_CORRECTED_v3.10.0 |
| `SCR-048` | `#/sg-10/scr-01` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-049` | `#/sg-10/scr-02` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-050` | `#/sg-10/scr-03` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-051` | `#/sg-10/scr-04` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-052` | `#/sg-10/scr-05` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-053` | `#/sg-10/scr-06` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-054` | `#/sg-11/scr-01` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-055` | `#/sg-11/scr-02` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-056` | `#/sg-11/scr-03` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-057` | `#/sg-11/scr-04` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-058` | `#/sg-11/scr-05` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-059` | `#/sg-11/scr-06` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-060` | `#/sg-12/scr-01` | MERGED_INTO_SCR-001 |
| `SCR-061` | `#/sg-12/scr-02` | MERGED_INTO_SCR-003 |
| `SCR-062` | `#/sg-12/scr-03` | RENDERED_v3.6.0 |
| `SCR-063` | `#/sg-12/scr-04` | RENDERED_v3.6.0 |
| `SCR-064` | `#/sg-12/scr-05` | RENDERED_v3.6.0 |
| `SCR-065` | `#/sg-12/scr-06` | RENDERED_v3.6.0 |
| `SCR-066` | `#/sg-13/scr-01` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-067` | `#/sg-13/scr-02` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-068` | `#/sg-13/scr-03` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-069` | `#/sg-13/scr-04` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-070` | `#/sg-13/scr-05` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-071` | `#/sg-13/scr-06` | PRODUCT_CORRECTED_v1.8.0 |
| `SCR-072` | `#/sg-14/scr-01` | UIUX_HARDENED_v4.3.0 |
| `SCR-073` | `#/sg-14/scr-02` | RETIRED_v3.13.0 → SCR-074 |
| `SCR-074` | `#/sg-14/scr-03` | UIUX_HARDENED_v4.3.0 |
| `SCR-075` | `#/sg-14/scr-04` | RETIRED_v3.13.0 → SCR-074 |
| `SCR-076` | `#/sg-14/scr-05` | RETIRED_v3.13.0 → SCR-074 |
| `SCR-077` | `#/sg-14/scr-06` | UIUX_HARDENED_v4.3.0 |
| `SCR-078` | `#/sg-15/scr-01` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-079` | `#/sg-15/scr-02` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-080` | `#/sg-15/scr-03` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-081` | `#/sg-15/scr-04` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-082` | `#/sg-15/scr-05` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-083` | `#/sg-15/scr-06` | PRODUCT_CORRECTED_v1.7.0 |
| `SCR-084` | `BJ02_PILOT_REFINED_v1.3.4` | BJ02_PILOT_REFINED_v1.3.4 |
| `SCR-085` | `PRODUCT_CORRECTED_v1.5.0` | UIUX_HARDENED_v4.3.0 |
| `SCR-086` | `PRODUCT_CORRECTED_v1.5.0` | UIUX_HARDENED_v4.3.0 |
| `SCR-087` | `PRODUCT_CORRECTED_v1.5.0` | RETIRED_v3.13.0 → SCR-086 |
| `SCR-088` | `PRODUCT_CORRECTED_v1.5.0` | UIUX_HARDENED_v4.3.0 |
| `SCR-089` | `PRODUCT_CORRECTED_v1.5.0` | UIUX_HARDENED_v4.3.0 |

## 4. Design System dependency

{
  "business": "Product documents / BJ / flow / decision / contract decide business requirements, UX flow, business rules, information and user behavior.",
  "figmaDesignSystem": "Figma Design System is the UI authority for components, patterns, templates, tokens, typography, spacing, state, interaction conventions and visual rules.",
  "htmlPrototype": "HTML prototype is the design/verification medium and must implement both the product documents and the Figma Design System; it does not invent business rules or UI conventions.",
  "implementation": "Production code decides the technical implementation."
}

## 5. Trạng thái hiện tại

- Source prototype version: `3.10.1`.
- Product kind: `mobile_app`.
- Canonical viewport: `402×874`.
- Screen count: `89`.

## 6. Known gaps

- Runtime HTML v3.10.1 được giữ tại `03.design/prototype/html/` để chạy prototype.
- Runtime bundle, kể cả QA nội bộ mà manifest của prototype tham chiếu, là frozen runtime artifact; nguồn evidence canonical của package vẫn nằm ở `06.evidence/`.
- Không file runtime nào được coi là nguồn business semantics.
