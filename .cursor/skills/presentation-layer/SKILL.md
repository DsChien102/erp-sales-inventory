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

**Đọc trước:** [reference.md](reference.md) · **Canonical spec:** [docs/presentation_layer_skill.md](../../../docs/presentation_layer_skill.md) · **Golden reference:** `apps/erp/lib/features/dashboard/presentation/`

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

**Import rule:**

```text
apps/erp MAY import vet45_<module>_presentation
modules/<module>/presentation MUST NOT import apps/erp
modules/<module>/presentation MAY import vet45_<module>_application (DTO, facade)
```

Mutations/reads: `IExecutionContext` → `IModuleMediator` — không bypass qua Supabase từ widget.

---

## Quy tắc cứng

1. **Bắt buộc dùng Design System**: Mọi thành phần UI (Button, TextField, Typography, Colors...) **phải** được sử dụng từ package `vet45_design_system`. Tuyệt đối không tự custom UI từ đầu nếu design system đã có sẵn.
2. **Page/screen ≤ 500 dòng** — enforce bởi `scripts/ci/guard_presentation_size.sh`. Quy định này bắt buộc bạn phải phân nhỏ UI thành các widget nhỏ hơn (component) ở các file riêng biệt để tránh tình trạng code trải dài, khó bảo trì.
3. **1 dialog = 1 file** — `StatelessWidget` (ưu tiên `const`) trong `widgets/`, không inline `AlertDialog` trong page
4. **Không `Widget _buildXxx()`** cho subtree lớn trong `State` — bắt buộc phải tách thành các class widget riêng biệt hoặc tạo file riêng để chia nhỏ giao diện.
5. **Page = composition root** — compose widgets, wire Bloc/Cubit, navigate; logic nghiệp vụ ở application. Page chỉ nên đóng vai trò là một khung sườn (scaffold) gọi đến các widget con.
6. **Ưu tiên `const`** khi params immutable — giảm rebuild subtree

Ngoại lệ nhỏ: private widget cục bộ (vd. `_SectionHeader`) OK nếu file page vẫn ≤ 500 dòng và subtree nhỏ.

---

## Workflow

### 1. Đọc FR + UI artifacts

Từ product spec (`US/FR` hoặc `01-overview.md`), lấy bảng **UI artifacts** — danh sách widget và path file. Nếu chưa có, tạo manifest trước khi code.

### 2. Widget manifest (bắt buộc trước implement)

```text
PartnerDetailPage          → apps/erp/.../pages/partner_detail_page.dart
DeactivatePartnerDialog    → modules/partner/presentation/.../deactivate_partner_dialog.dart
ReactivatePartnerDialog    → modules/partner/presentation/.../reactivate_partner_dialog.dart
```

### 3. Scaffold files

Tạo file rỗng / class stub theo manifest — tránh gom tất cả vào một file rồi tách sau.

### 4. Implement widgets trước, page cuối

```text
dialogs/sections (modules/partner/presentation + apps/erp/widgets)
  → page compose imports
  → bloc/cubit wire mediator calls
```

### 5. Widget test (khi FR có SCN dialog)

```text
apps/erp/test/features/<feature>/widgets/<dialog>_test.dart
Test id: wgt_e{epic}_u{us}_fr{fr}_{nn}
```

### 6. Verify

```bash
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/<feature>/
```

---

## Golden reference

Copy pattern từ dashboard (page mỏng + widgets tách file):

| File | Vai trò |
| ---- | ------- |
| `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` | Page compose, tab state |
| `apps/erp/lib/features/dashboard/presentation/widgets/dashboard_header.dart` | Section widget `const` |
| `apps/erp/lib/features/dashboard/presentation/widgets/metric_tile.dart` | Reusable tile |

---

## Anti-patterns (từ chối)

- God Widget — page > 500 dòng, layout + dialog + form trong một file
- Inline `showDialog` + `AlertDialog` trong `*_page.dart` (guard fail)
- `Widget _buildLargeSection()` trong State thay vì class widget
- Direct PostgREST / `Supabase.instance` từ widget
- Business rule trong `build()` hoặc dialog callback (thuộc domain/application)
- Import `package:.../src/...` từ package khác

---

## Liên kết

- [reference.md](reference.md) — folder layout, naming, agent prompt template
- [application-layer](../application-layer/SKILL.md) — mediator, commands, DTOs
- [docs/architecture/harness-engineering.md](../../../docs/architecture/harness-engineering.md)
- TH-03 ritual: `docs/themes/TH-03-partner/harness/00-agent-ritual.md`
