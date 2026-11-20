# 01 — Baseline Audit

## Tóm tắt

Package `c45_design_system` đã có nền tảng đủ dùng (tokens, theme, ~30 public components, example catalog, UI audit tool). Vấn đề chính là **thiếu quy chuẩn layout/pattern** và **adoption không đồng đều** ở feature UI.

## Component contract gap

Từ [component_audit_report.md](../audit/component_audit_report.md) (2026-07-08):

| Metric | Trạng thái |
|--------|------------|
| Components có Semantics + Tone + State | Chỉ `VButton`, `VTextField`, dropdowns, `VTabs`, `VToast`, `VTable` |
| Primitives (`VBadge`, `VChip`, `VIcon`, `VText`) | Chưa declare Tone/Emphasis/State |
| Business widgets | Chưa có contract chuẩn |

## Feature UI bypass (catalog sample)

Các pattern vi phạm thường gặp trong `apps/erp/lib/features/catalog/presentation/`:

| Anti-pattern | Ví dụ | Thay bằng |
|--------------|-------|-----------|
| Magic spacing | `EdgeInsets.all(16)`, `Column(spacing: 8)` | `VPagePadding`, `VGap` |
| Raw typography | `Text(..., style: VTypography.bodyDefault.copyWith(...))` | `VText(variant: ...)` |
| Raw Material overlay | `AlertDialog`, `showModalBottomSheet` | `showVConfirmDialog`, `showVBottomSheet` |
| Feature-local section card | `ProductControlCenterSectionCard` tự padding | `VSection` + `VCard` |

## Thiếu layout pattern layer

Trước upgrade, DS có atomic components nhưng **không có**:

- `VGap` — vertical/horizontal gap từ token
- `VPagePadding` — screen inset chuẩn
- `VSection` — title + subtitle + content stack
- `VPageScaffold` — page shell (app bar + body + bottom bar)

## Enforcement gap

- Presentation skill bắt buộc dùng DS nhưng không có CI guard chống magic number
- `c45_lints` chỉ là analyzer config — chưa có custom_lint cho UI

## Kết luận

Ưu tiên: **docs → layout primitives → CI guard → golden migration** (Product Control Center), không big-bang toàn catalog.
