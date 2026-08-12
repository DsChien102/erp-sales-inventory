# LOCAL REVIEW — UIF-07 / BJ-07

> Round `08/17` · Result: `PASS` · Status after local gate: `LOCAL_PASS`.

## Scope

- BJ: `BJ-07` — Thực hiện trả hàng cho nhà cung cấp.
- UCs: `UC-07-01`, `UC-07-02`, `UC-07-03`, `UC-07-04`.
- Screens: `SCR-036`, `SCR-041`, `SCR-037`, `SCR-038`, `SCR-039`.
- Surface mix: detail=1, form=1, list=1, result=1, review=1.
- Transitions: `11`.

## UX review

Trả hàng NCC từ đúng stock evidence, tách rõ state preparation với physical outbound RTV.

- Reuse canonical SCR-036/037 cho selection/evidence thay vì tạo list/detail riêng.
- Nếu cần đổi state trước RTV, SCR-038 dùng context mode; state movement không giảm physical quantity.
- SCR-039 review NCC/source/quantity và impact trước physical handover.
- SCR-041 dùng operation_type để giải thích result đúng ngữ cảnh RTV.

## Corrections applied

- ✅ Khóa shared-screen context mode cho SCR-038/SCR-041 để không clone UI với UIF-09/10.

## DS / component gate

- Public Flutter DS allowlist used: `VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VGap`, `VSearchBar`, `VCard`, `VCardIcon`, `VCardTitle`, `VBadge`, `VText`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`, `VBanner`, `VButton`, `VTextFormField`, `VNumberField`, `VMoneyField`, `VSelect`, `VCombobox`, `VDatePicker`, `VQuantitySelector`, `VFileDropZone`, `VConfirmDialog`, `VBottomSheet`.
- Theme compositions: `Theme7ListSurface`, `Theme7OperationResult`, `Theme7DetailSurface`, `Theme7FormSurface`, `Theme7ReviewSurface`, `Theme7ReviewSummary`.
- App bar uses `VPageScaffold → VAppBar`, `centerTitle=false`; no invented trailing control.
- Visible icon contract maps through `VIcons.*`; no raw Lucide semantic ownership.
- Permission state omits protected content from DOM.

## Local verdict

**PASS.** No unresolved UX/business blocker remains for HTML harness rendering.
