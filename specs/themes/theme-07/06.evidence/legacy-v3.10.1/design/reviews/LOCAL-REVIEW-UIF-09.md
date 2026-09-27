# LOCAL REVIEW — UIF-09 / BJ-09

> Round `09/17` · Result: `PASS` · Status after local gate: `LOCAL_PASS`.

## Scope

- BJ: `BJ-09` — Quản lý trạng thái hàng.
- UCs: `UC-09-01`, `UC-09-02`, `UC-09-03`, `UC-09-04`.
- Screens: `SCR-036`, `SCR-041`, `SCR-056`, `SCR-037`, `SCR-038`.
- Surface mix: detail=2, form=1, list=1, result=1.
- Transitions: `14`.

## UX review

Chuyển trạng thái hàng bằng workflow maker/approver rõ ràng; approval và state movement là hai contract khác nhau.

- SCR-038 PREPARE mode chỉ dành maker; APPROVAL mode chỉ dành approver trong session/task khác.
- Gửi xử lý khóa payload/version; approval chỉ ghi quyết định, chưa tạo state movement.
- Sau approval hệ thống thực hiện state movement; result hiển thị finality.
- Hết hạn tự động theo policy không bắt user nhập lại state đã biết.

## Corrections applied

- ✅ Bổ sung explicit ACT-COMMON-SUBMIT/DECIDE; ACT-08-STATE là system-owned sau approval.

## DS / component gate

- Public Flutter DS allowlist used: `VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VGap`, `VSearchBar`, `VCard`, `VCardIcon`, `VCardTitle`, `VBadge`, `VText`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`, `VBanner`, `VButton`, `VTextFormField`, `VNumberField`, `VMoneyField`, `VSelect`, `VCombobox`, `VDatePicker`, `VQuantitySelector`, `VFileDropZone`.
- Theme compositions: `Theme7ListSurface`, `Theme7OperationResult`, `Theme7DetailSurface`, `Theme7FormSurface`.
- App bar uses `VPageScaffold → VAppBar`, `centerTitle=false`; no invented trailing control.
- Visible icon contract maps through `VIcons.*`; no raw Lucide semantic ownership.
- Permission state omits protected content from DOM.

## Local verdict

**PASS.** No unresolved UX/business blocker remains for HTML harness rendering.
