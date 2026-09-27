# LOCAL REVIEW — UIF-04 / BJ-04

> **HISTORICAL HARNESS REVIEW.** UIF04 Product truth since v1.3.4/v1.4.3 is contextual-only `Order detail → SCR-021 → Back to order`; `SCR-020/022/023/024` are retired and must not be restored as active Product routes.


> Round `05/17` · Result: `PASS` · Status after local gate: `LOCAL_PASS`.

## Scope

- BJ: `BJ-04` — Quản lý vòng đời giữ hàng.
- UCs: `UC-04-01`, `UC-04-02`, `UC-04-03`, `UC-04-04`.
- Screens: `SCR-020`, `SCR-024`, `SCR-021`, `SCR-022`, `SCR-023`.
- Surface mix: detail=1, form=1, list=1, result=1, review=1.
- Transitions: `10`.

## UX review

Giữ/giải phóng hàng theo đơn với allocation dễ hiểu: user thấy “cần/đã giữ/thiếu” trước khi quyết định.

- Order list whole-card tap; status/shortage đủ để ưu tiên mà không nhồi chi tiết.
- SCR-021 so sánh need/available/reserved theo line; shortage nổi bật hơn metadata.
- Review chỉ hỏi policy thật sự cần lựa chọn; hệ thống tính phần giữ/thiếu.
- Release/reallocate prefill reservation context và chỉ hỏi delta + reason.
- Result nhắc rõ reservation không làm thay đổi tồn vật lý.

## Corrections applied

- ✅ Không phát hiện structural gap mới; chuẩn hóa reservation family theo shared list/detail/review/result patterns.

## DS / component gate

- Public Flutter DS allowlist used: `VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VGap`, `VSearchBar`, `VCard`, `VCardIcon`, `VCardTitle`, `VBadge`, `VText`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`, `VBanner`, `VButton`, `VConfirmDialog`, `VBottomSheet`, `VTextFormField`, `VNumberField`, `VMoneyField`, `VSelect`, `VCombobox`, `VDatePicker`, `VQuantitySelector`, `VFileDropZone`.
- Theme compositions: `Theme7ListSurface`, `Theme7OperationResult`, `Theme7DetailSurface`, `Theme7ReviewSurface`, `Theme7FormSurface`, `Theme7ReviewSummary`.
- App bar uses `VPageScaffold → VAppBar`, `centerTitle=false`; no invented trailing control.
- Visible icon contract maps through `VIcons.*`; no raw Lucide semantic ownership.
- Permission state omits protected content from DOM.

## Local verdict

**PASS.** No unresolved UX/business blocker remains for HTML harness rendering.
