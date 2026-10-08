---
name: presentation-layer
description: Designs, generates, reviews, and refactors Flutter presentation UI for ERP/Admin features — pages, dialogs, sections, widget decomposition, and IModuleMediator wiring. Use when working on *_page.dart, *_screen.dart, Dialog, BottomSheet, apps/erp/features/*/presentation, apps/admin/features/*/presentation, or when the user mentions presentation layer, God Widget, widget decomposition, or Flutter UI harness rules.
---

# Presentation Layer

## Mục đích

Presentation layer **hiển thị và tương tác** với người dùng — không quyết định invariant nghiệp vụ (domain) và không gọi Supabase/PostgREST trực tiếp (infrastructure).

```text
Presentation hiển thị cho người dùng.
Application điều phối use case đang được thực thi.
Domain quyết định hành vi nghiệp vụ hợp lệ.
Infrastructure triển khai kỹ thuật (RPC, views, cache, workers).
```

**Đọc trước:** [reference.md](reference.md) · **Canonical spec:** [docs/presentation_layer_skill.md](../../../docs/presentation_layer_skill.md) · **Design System Polaris:** [packages/vet45_design_system/docs/polaris/README.md](../../../packages/vet45_design_system/docs/polaris/README.md) · **Golden reference:** `apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart` · **Ownership ADR:** [docs/architecture/11-app-owned-presentation.md](../../../docs/architecture/11-app-owned-presentation.md)

---

## Khi nào dùng

- Scaffold hoặc mở rộng UI feature trong `apps/erp/lib/features/<feature>/presentation/` (hoặc `apps/admin/...`)
- Review PR UI — phát hiện God Widget, inline dialog, Supabase leak
- Implement FR slice có UI/Dialog/SCN

---

## App-owned presentation (canonical)

| Loại | Path | Ví dụ |
| ---- | ---- | ----- |
| Page / screen (route) | `apps/erp/lib/features/<feature>/presentation/pages/` | `partner_detail_page.dart` |
| Feature cubit / orchestration | `apps/erp/lib/features/<feature>/presentation/bloc/` — multi-aggregate: `bloc/<aggregate>/` | `sales_order_draft/sales_compose_cubit.dart` |
| Widgets / sheets / dialogs | `apps/erp/lib/features/<feature>/presentation/widgets/` | `deactivate_partner_dialog.dart` |
| Display VMs | `models/<aggregate>/` → `*_vm.dart` | `sales_order/sales_order_detail_vm.dart` |
| Flow result | `bloc/<aggregate>/` hoặc `models/<aggregate>/` → `*_result.dart` only | `sales_checkout_prepare_result.dart` |
| Handoff / nav args | `models/<aggregate>/` → `*_args.dart` only | `sales_checkout_draft_args.dart` |
| Cubit contracts | `bloc/<aggregate>/` (không đặt trong `support/`) | `sales_draft_contracts.dart` |
| Helpers (mapper/factory) | `presentation/support/` | `sales_checkout_draft_args_mapper.dart` |
| Cross-aggregate UI state | `bloc/shared/`, `models/shared/` | `sales_product_picker_cubit.dart` |
| Feature typed routes | `presentation/navigation/sales_typed_routes.dart` (+ `.g.dart` via `go_router_builder`) | `SalesOrderDetailRoute(orderId: id).push(context)` |
| Preview catalog | `apps/erp/example/` | Sales / Partner sections |

**Cấm shape presentation mới:** `*_outcome.dart`, handoff `*_snapshot.dart`. Từ “snapshot” giữ cho persistence/domain (vd. `order_snapshot`). Chi tiết: [docs/presentation_layer_skill.md](../../../docs/presentation_layer_skill.md) §2.1. Pricing `cubit/` phẳng — mirror khi refactor.

**Ownership:**

- Toàn bộ UI của feature thuộc **ship unit** (`erp` hoặc `admin`) — **không** `modules/*/presentation`.
- App được import nhiều `vet45_*_application` (composition root).
- Module chỉ còn domain / application / infrastructure / integration_events.
- UI dùng chung ERP+Admin: **duplicate** trong từng app — không tái tạo package presentation shared.

**Import rule:**

```text
apps/erp|admin MAY import vet45_<module>_application (+ domain as needed)
apps MUST NOT depend on vet45_<module>_presentation (package removed)
modules/* MUST NOT contain a presentation package
apps/erp/example MAY import package:erp features + design_system (+ application testing/fakes)
apps/erp/example MUST NOT import live Supabase
```

Mutations/reads: `IExecutionContext` → `IModuleMediator` — không bypass qua Supabase từ widget.

**DS vs ERP catalog:** `packages/vet45_design_system/example` = primitives; `apps/erp/example` = feature widgets. Public reusable widget mới → cùng PR thêm `PreviewSection` trong `apps/erp/example`.

---

## Quy tắc cứng

1. **Bắt buộc dùng Design System**: Mọi thành phần UI **phải** từ `vet45_design_system`. Ưu tiên layout patterns (`VPageScaffold`, `VGap`, `VPagePadding`, `VSection`) — xem [06-design-system-spec.md](../../../packages/vet45_design_system/docs/polaris/06-design-system-spec.md).
2. **Page/screen ≤ 500 dòng** — `scripts/ci/guard_presentation_size.sh`.
3. **1 dialog = 1 file** — `StatelessWidget` trong `widgets/`, không inline `AlertDialog` trong page.
4. **Không `Widget _buildXxx()`** cho subtree lớn trong `State` — tách class/file.
5. **Page = composition root** — compose widgets, wire Bloc/Cubit, navigate.
6. **Ưu tiên `const`** khi params immutable.

---

## Workflow

### 1. Đọc FR + UI artifacts

### 2. Widget manifest (bắt buộc trước implement)

```text
PartnerDetailPage          → apps/erp/.../pages/partner_detail_page.dart
DeactivatePartnerDialog    → apps/erp/.../widgets/deactivate_partner_dialog.dart
```

### 3. Scaffold → widgets → PreviewSection trong `apps/erp/example` → page

### 4. Verify

```bash
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/<feature>/
cd apps/erp/example && flutter analyze
```

---

## Golden reference

| File | Role |
| ---- | ---- |
| `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` | Thin page |
| `apps/erp/example/` | Feature widget preview catalog |

---

## Anti-patterns

- God Widget / inline dialog / `_buildXxx` lớn
- Direct PostgREST từ widget
- Tạo hoặc mở rộng `modules/*/presentation`
- Business rules trong `build()`
- Flat `presentation/bloc/*.dart` / `presentation/models/*.dart` mới khi feature đã nhóm theo domain aggregate (Sales: dùng `bloc/<aggregate>/`, `models/<aggregate>/`; chỉ `shared/` cho cross-aggregate)
- Literal `'/sales/...'` (hoặc tương đương feature path) trong pages/widgets — dùng `*Route(...).push/go` (`go_router_builder`); tab recovery `/orders` qua `SalesNav`
- `*_outcome.dart` / handoff `*_snapshot.dart` mới; result/args/contracts trong `support/`
