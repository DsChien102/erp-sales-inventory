---
name: presentation-layer
description: Designs, generates, reviews, and refactors Flutter presentation UI for ERP features and module presentation packages — pages, dialogs, sections, widget decomposition, and IModuleMediator wiring. Use when working on *_page.dart, *_screen.dart, Dialog, BottomSheet, apps/erp/features/*/presentation, modules/*/presentation, or when the user mentions presentation layer, God Widget, widget decomposition, or Flutter UI harness rules.
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

**Đọc trước:** [reference.md](reference.md) · **Canonical spec:** [docs/presentation_layer_skill.md](../../../docs/presentation_layer_skill.md) · **Design System Polaris:** [packages/vet45_design_system/docs/polaris/README.md](../../../packages/vet45_design_system/docs/polaris/README.md) · **Golden reference:** `apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart`

---

## Khi nào dùng

- Scaffold hoặc mở rộng UI feature trong `apps/erp/lib/features/<feature>/presentation/`
- Tạo dialog/section tái dùng trong `modules/<module>/presentation/lib/src/widgets/`
- Review PR UI — phát hiện God Widget, inline dialog, Supabase leak
- Implement FR slice có UI/Dialog/SCN (TH-03 partner, v.v.)

---

## Dual path (canonical)

| Loại | Path | Ví dụ |
| ---- | ---- | ----- |
| Page / screen (route) | `apps/erp/lib/features/<feature>/presentation/pages/` | `partner_detail_page.dart` |
| Feature state (optional) | `apps/erp/lib/features/<feature>/presentation/bloc/` | `partner_detail_cubit.dart` |
| Dialog / widget tái dùng | `modules/<module>/presentation/lib/src/widgets/` | `deactivate_partner_dialog.dart` |
| Widget chỉ dùng trong feature | `apps/erp/lib/features/<feature>/presentation/widgets/` | `partner_profile_header.dart` |
| Module example catalog | `modules/<module>/presentation/example/` | `modules/partner/presentation/example/` |

**Import rule:**

```text
apps/erp MAY import vet45_<module>_presentation
modules/<module>/presentation MUST NOT import apps/erp
modules/<module>/presentation MAY import vet45_<module>_application (DTO, facade)
modules/<module>/presentation/example MAY import presentation + design_system (+ application testing/fakes)
modules/<module>/presentation/example MUST NOT import apps/erp or live Supabase
```

Mutations/reads: `IExecutionContext` → `IModuleMediator` — không bypass qua Supabase từ widget.

**DS vs module catalog:** `packages/vet45_design_system/example` = primitives; module `example/` = BC widgets. Clone partner example khi module mới bắt đầu FE.

---

## Quy tắc cứng

1. **Bắt buộc dùng Design System**: Mọi thành phần UI (Button, TextField, Typography, Colors...) **phải** được sử dụng từ package `vet45_design_system`. Ưu tiên **layout patterns** (`VPageScaffold`, `VGap`, `VPagePadding`, `VSection`) trước khi invent widget mới — xem [06-design-system-spec.md](../../../packages/vet45_design_system/docs/polaris/06-design-system-spec.md). Tuyệt đối không tự custom UI từ đầu nếu design system đã có sẵn.
2. **Page/screen ≤ 500 dòng** — enforce bởi `scripts/ci/guard_presentation_size.sh`. Quy định này bắt buộc bạn phải phân nhỏ UI thành các widget nhỏ hơn (component) ở các file riêng biệt để tránh tình trạng code trải dài, khó bảo trì.
3. **1 dialog = 1 file** — `StatelessWidget` (ưu tiên `const`) trong `widgets/`, không inline `AlertDialog` trong page
4. **Không `Widget _buildXxx()`** cho subtree lớn trong `State` — bắt buộc phải tách thành các class widget riêng biệt hoặc tạo file riêng để chia nhỏ giao diện.
5. **Page = composition root** — compose widgets, wire Bloc/Cubit, navigate; logic nghiệp vụ ở application. Page chỉ nên đóng vai trò là một khung sườn (scaffold) gọi đến các widget con.
6. **Ưu tiên `const`** khi params immutable — giảm rebuild subtree

Ngoại lệ nhỏ: private widget cục bộ (vd. `_SectionHeader`) OK nếu file page vẫn ≤ 500 dòng và subtree nhỏ.

---

## Workflow

### 1. Đọc FR + UI artifacts

Từ product spec (`US/FR` hoặc Epic/US `README.md`), lấy bảng **UI artifacts** — danh sách widget và path file. Nếu chưa có, tạo manifest trước khi code.

### 2. Widget manifest (bắt buộc trước implement)

Đọc `harness/07-api-contracts.md` (fake scenario ids) khi slice mới — FE có thể implement song song BE sau CONTRACT.

```text
PartnerDetailPage          → apps/erp/.../pages/partner_detail_page.dart
DeactivatePartnerDialog    → modules/partner/presentation/.../deactivate_partner_dialog.dart
ReactivatePartnerDialog    → modules/partner/presentation/.../reactivate_partner_dialog.dart
```

### 3. Scaffold files

Tạo file rỗng / class stub theo manifest — tránh gom tất cả vào một file rồi tách sau.

### 4. Implement widgets trước, page cuối

```text
dialogs/sections (modules/<module>/presentation + apps/erp/widgets)
  → PreviewSection trong modules/<module>/presentation/example/
  → page compose imports
  → bloc/cubit wire mediator calls
```

Public reusable widget mới → cùng PR cập nhật module example catalog (loading/empty/error/filled khi API có).

### 5. Widget test (khi FR có SCN dialog)

Dùng `FakePartnerModule` / `FakeExecutionContext` từ `vet45_partner_application/testing.dart` + `vet45_shared_testing` — scenario ids khớp `07-api-contracts.md`.

```text
modules/partner/presentation/test/widgets/<dialog>_test.dart
apps/erp/test/features/<feature>/...
Test id: wgt_e{epic}_u{us}_fr{fr}_{nn}
```

### 6. Verify

```bash
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/<feature>/
# khi đổi module widgets / example catalog:
vet45 run partner_presentation debug   # hoặc target tương ứng khi module có example
cd modules/<module>/presentation/example && flutter analyze
```

---

## Golden reference

Copy pattern từ Product Control Center (DS-compliant page + widgets tách file):

| File | Vai trò |
| ---- | ------- |
| `apps/erp/lib/features/catalog/presentation/pages/product_control_center_page.dart` | `VPageScaffold`, Bloc wire |
| `apps/erp/lib/features/catalog/presentation/widgets/product_control_center_body.dart` | Scroll body + `VGap` |
| `apps/erp/lib/features/catalog/presentation/widgets/product_control_center_section_card.dart` | Section card pattern |
| `modules/partner/presentation/example/` | Per-module widget preview catalog (template) |

Dashboard (page mỏng cũ): `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart`

---

## Anti-patterns (từ chối)

- God Widget — page > 500 dòng, layout + dialog + form trong một file
- Inline `showDialog` + `AlertDialog` trong `*_page.dart` (guard fail)
- `Widget _buildLargeSection()` trong State thay vì class widget
- Direct PostgREST / `Supabase.instance` từ widget
- Business rule trong `build()` hoặc dialog callback (thuộc domain/application)
- Import `package:.../src/...` từ package khác
- Widget BC demo trong `vet45_design_system/example` (sai boundary)
- Module example phụ thuộc `apps/erp` / live Supabase / `env:doctor`

---

## Liên kết

- [reference.md](reference.md) — folder layout, naming, agent prompt template
- [application-layer](../application-layer/SKILL.md) — mediator, commands, DTOs
- [docs/architecture/harness-engineering.md](../../../docs/architecture/harness-engineering.md)
- TH-03 ritual: `docs/themes/TH-03-partner/harness/00-agent-ritual.md`
