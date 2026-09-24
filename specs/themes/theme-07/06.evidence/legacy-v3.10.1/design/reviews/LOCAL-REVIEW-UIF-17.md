# LOCAL REVIEW — UIF-17 / BJ-17

> Round `17/17` · Result: `PASS` · Status after local gate: `LOCAL_PASS`.

## Scope

- BJ: `BJ-17` — Phục hồi nghiệp vụ có kết quả chưa xác định.
- UCs: `UC-17-01`, `UC-17-02`, `UC-17-03`, `UC-17-04`.
- Screens: `SCR-078`, `SCR-083`, `SCR-079`, `SCR-080`, `SCR-082`.
- Surface mix: form=1, list=1, result=1, review=1, timeline=1.
- Transitions: `10`.

## UX review

Phục hồi UNKNOWN bằng đúng operation identity, query evidence trước và không blind retry; unresolved case phải có owner/escalation.

- Reuse SCR-078/079/080/082/083 của reconciliation family.
- Không tạo operation mới khi retry/continue; identity và payload gốc được giữ.
- UI ưu tiên “Xác minh kết quả / Tiếp tục cùng lần xử lý / Giữ chưa xác định” thay vì replay/rebuild jargon.
- Nếu evidence chứng minh committed thì chỉ xác lập result, không ghi lại movement.
- UNKNOWN kéo dài phải bảo vệ scope và hiển thị owner/escalation.

## Corrections applied

- ✅ Promote no-blind-retry + same-identity recovery thành cross-Theme pattern; không render mutation “thử lại” mù.

## DS / component gate

- Public Flutter DS allowlist used: `VPageScaffold`, `VAppBar`, `VPagePadding`, `VSection`, `VGap`, `VSearchBar`, `VCard`, `VCardIcon`, `VCardTitle`, `VBadge`, `VText`, `VSkeleton`, `VEmptyState`, `VLoading`, `VEmptyMedia`, `VEmptyTitle`, `VEmptyDescription`, `VBanner`, `VButton`, `VIconBox`, `VTextFormField`, `VNumberField`, `VMoneyField`, `VSelect`, `VCombobox`, `VDatePicker`, `VQuantitySelector`, `VFileDropZone`, `VConfirmDialog`, `VBottomSheet`.
- Theme compositions: `Theme7ListSurface`, `Theme7OperationResult`, `Theme7EvidenceTimeline`, `Theme7FormSurface`, `Theme7ReviewSurface`, `Theme7RecoveryRecommendation`.
- App bar uses `VPageScaffold → VAppBar`, `centerTitle=false`; no invented trailing control.
- Visible icon contract maps through `VIcons.*`; no raw Lucide semantic ownership.
- Permission state omits protected content from DOM.

## Local verdict

**PASS.** No unresolved UX/business blocker remains for HTML harness rendering.
