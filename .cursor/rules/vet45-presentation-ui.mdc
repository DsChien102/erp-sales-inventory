---
description: Flutter presentation UI rules — widget decomposition, dialog extraction, and async query integration
globs: apps/erp/lib/**/presentation/**,apps/erp/example/**,apps/admin/lib/**/presentation/**,packages/vet45_async_query/**
alwaysApply: false
---

# Vet45 Presentation UI

## App-owned (canonical)

- **Pages / cubits / widgets / display VMs:** `apps/erp/lib/features/<feature>/presentation/` (Admin: `apps/admin/...`)
- **Preview catalog:** `apps/erp/example/`
- **Do not** add files under `modules/*/presentation`

Apps import `vet45_*_application` directly. See `docs/architecture/11-app-owned-presentation.md`.

## Example catalog

Path: `apps/erp/example/` (app name `erp_presentation_example`). **Không** thêm vào root Melos `workspace:`.

| Layer | Catalog |
| --- | --- |
| Design system primitives | `packages/vet45_design_system/example` — `melos run design-system:example` |
| Feature widgets | `apps/erp/example` |

Hard rules:

1. Public reusable widget mới trong `apps/erp/lib/features/*/presentation` → cùng PR thêm `PreviewSection` trong `apps/erp/example`.
2. Example chỉ import `package:erp` features + `vet45_design_system` (+ application **testing/fakes** nếu cần). **Cấm** live Supabase, `env:doctor`.
3. DS example = primitives only; ERP example = feature widgets.

## Hard rules

1. `*_page.dart` / `*_screen.dart` **≤ 500 lines** (`guard_presentation_size.sh`)
2. **One dialog = one file** — `StatelessWidget` in `widgets/`; no inline `AlertDialog` in pages (`guard_presentation_dialogs.sh`)
3. No large `Widget _buildXxx()` in `State` — extract class widget or separate file
4. Page = thin composition: widgets + Bloc/Cubit + `IModuleMediator` — no direct Supabase/PostgREST
5. Prefer `const` constructors when parameters are immutable
6. Khi dùng `vet45_async_query`, query/mutation function phải đi qua module facade (`executeQueryAsync`/`executeCommandAsync`)
7. Query key phải stable, serializable, có tenant scope cho tenant data; không dùng UUID/random làm key
8. Sau mutation, ưu tiên `invalidateQueries` thay vì gọi `load()` thủ công lặp lại
9. Không force unwrap `result.data!` trước khi đảm bảo `hasData`
10. Tránh duplicate state machine: đã dùng `UseQuery` thì không tạo thêm loading/error machine trùng lặp
11. **Aggregate folders (multi-aggregate features):** khi feature map nhiều domain aggregate (vd. Sales), nhóm `presentation/bloc/<aggregate>/` và `presentation/models/<aggregate>/` đúng tên snake_case domain (`sales_order`, `sales_order_draft`, …). `shared/` chỉ cho cubit/VM cross-aggregate (picker, pricing helpers). **Cấm** thêm file flat mới vào `bloc/*.dart` / `models/*.dart` khi feature đã có map aggregate.
12. **Feature typed routes (Sales):** navigate bằng `*Route(...).push/go/pushReplacement` từ `presentation/navigation/sales_typed_routes.dart` (`go_router_builder`). **Cấm** literal `'/sales/...'` và **cấm** quay lại string location builders kiểu `SalesRoutes.*`. Tab `/orders` dùng `SalesNav.ordersList`. Codegen: `cd apps/erp && dart run build_runner build --build-filter="lib/features/sales/presentation/navigation/*"`.
