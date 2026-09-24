# LOCAL REVIEW — UIF-16 / BJ-16

> Round `16/17` · Result: `PASS` · Status after local gate: `LOCAL_PASS`.

## Scope

- BJ: `BJ-16` — Điều tra và đối soát sai lệch.
- UCs: `UC-16-01`, `UC-16-02`, `UC-16-03`, `UC-16-04`.
- Screens: `SCR-078`, `SCR-083`, `SCR-079`, `SCR-082`, `SCR-080`, `SCR-081`.
- Surface mix: detail=1, form=1, list=1, result=1, review=1, timeline=1.
- Transitions: `13`.

## UX review

Điều tra sai lệch evidence-first, bảo vệ scope rủi ro và chỉ cho recovery contract đã công bố; không sửa số dư trực tiếp.

- Case list ưu tiên severity/status/owner; whole-card mở evidence.
- Timeline hiển thị expected vs actual/source; technical event IDs on-demand.
- Hệ thống đề xuất recovery action phù hợp evidence thay vì bắt user chọn từ thuật ngữ kỹ thuật thuần.
- Rebuild progress chỉ theo dõi; không có nút sửa số dư.
- Review kết quả expected/actual trước unlock/close.

## Corrections applied

- ✅ Giữ Theme7EvidenceTimeline; chuyển UI copy recovery sang user outcome, technical replay/rebuild chỉ ở detail/on-demand.

## DS / component gate

- Public Flutter DS allowlist used: `VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VGap`, `VSearchBar`, `VCard`, `VCardIcon`, `VCardTitle`, `VBadge`, `VText`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`, `VBanner`, `VButton`, `VIconBox`, `VConfirmDialog`, `VBottomSheet`, `VTextFormField`, `VNumberField`, `VMoneyField`, `VSelect`, `VCombobox`, `VDatePicker`, `VQuantitySelector`, `VFileDropZone`.
- Theme compositions: `Theme7ListSurface`, `Theme7OperationResult`, `Theme7EvidenceTimeline`, `Theme7ReviewSurface`, `Theme7FormSurface`, `Theme7DetailSurface`, `Theme7RecoveryRecommendation`, `Theme7ReviewSummary`.
- App bar uses `VPageScaffold → VAppBar`, `centerTitle=false`; no invented trailing control.
- Visible icon contract maps through `VIcons.*`; no raw Lucide semantic ownership.
- Permission state omits protected content from DOM.

## Local verdict

**PASS.** No unresolved UX/business blocker remains for HTML harness rendering.
