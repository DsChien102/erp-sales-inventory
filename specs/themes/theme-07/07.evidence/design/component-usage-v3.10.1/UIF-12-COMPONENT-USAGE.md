# UIF-12 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.8.0` · Scope: `BJ-12/UIF-12` · Parent: `v1.7.0` · Figma DS v2.0.2 là UI source of truth; legacy Flutter labels chỉ là migration inputs.

## 1. UX intent

Khởi tạo tồn kho đầu kỳ như **một controlled activation task**, không như CRUD/list nhiều batch: chuẩn bị dữ liệu → validate → maker review → actor handoff → approval → system commit/reconcile → authoritative result.

## 2. Quyết định UX khóa tại v1.8.0

1. `SCR-066` là status/entry surface của một opening initialization, không là “danh sách batch”.
2. `SCR-067`: `VFileDropZone` + `VDatePicker` + control totals user-supplied; không hỏi lại warehouse nếu hệ thống đã biết kho mặc định.
3. `SCR-068`: file-validation result; lỗi theo business row/rule; không quick-create master.
4. `SCR-069`: review business evidence, không promote hash/version/internal ID; submit kết thúc ở pending maker surface.
5. `SCR-070`: approver task riêng; `Duyệt/Từ chối` bằng `ACT-COMMON-DECIDE`; reject reason trong `VBottomSheet`.
6. `ACT-13-COMMIT` không render CTA; system-owned after approval.
7. `SCR-071`: authoritative finality; UNKNOWN persistent, no blind retry/new opening balance.
8. Product viewport `402×874`; Inspect/workbench nằm ngoài Product UI.

## 3. Component matrix

| Screen | Surface | Composition | Visible action |
|---|---|---|---|
| `SCR-066` | status/entry | `Theme7StatusEntrySurface` | navigation-only |
| `SCR-067` | form | `Theme7FormSurface` | `ACT-13-PREPARE` / `Kiểm tra dữ liệu` |
| `SCR-068` | validation result | `Theme7FileImportValidation` | navigation-only |
| `SCR-069` | review | `Theme7ReviewSurface` | `ACT-13-PREPARE` / `Gửi phê duyệt` |
| `SCR-070` | approval review | `Theme7ReviewSurface` | `ACT-COMMON-DECIDE` |
| `SCR-071` | result | `Theme7OperationResult` | navigation-only; `ACT-13-COMMIT` trace-only |

## 4. Public DS allowlist

`VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VCard`, `VBadge`, `VText`, `VBanner`, `VButton`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`, `VFileDropZone`, `VDatePicker`, `VNumberField`, `VMoneyField`, `VBottomSheet`, `VTextField`.

## 5. Hard guards

- No actor collapse.
- No technical batch/hash/version as Product decision data.
- No Save Draft button.
- No Product/UOM/LOT quick-create from validation error.
- No commit CTA after approval.
- No retry/new opening balance when finality unknown.
