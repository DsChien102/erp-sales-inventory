# Agent Harness — Vet45

Harness Engineering = thiết kế **môi trường** xung quanh AI agent (context, ràng buộc, feedback loops), không chỉ viết prompt.

Tài liệu này mô tả harness của repo Vet45. Điểm vào cho agent: [AGENTS.md](../../AGENTS.md).

## Bốn trụ

### 1. Context (legibility)

Mọi kiến thức agent cần phải nằm trong repo:

| Artifact | Vai trò |
| -------- | ------- |
| [AGENTS.md](../../AGENTS.md) | Onboarding, repo state, verify commands |
| [.cursor/rules/vet45-architecture.mdc](../../.cursor/rules/vet45-architecture.mdc) | Layer rules (always-on) |
| [.cursor/rules/vet45-presentation-ui.mdc](../../.cursor/rules/vet45-presentation-ui.mdc) | UI rules (scoped — `presentation/**`) |
| `.cursor/skills/*` | Workflow theo layer |
| `docs/*_skill.md` | Canonical spec mirror |
| [PROGRESS.md](../harness/PROGRESS.md) | Tiến độ harness maturity |
| `docs/themes/TH-xx/harness/*` | Theme engineering truth (domain-model, module-map, traceability) |

**Nguyên tắc:** Nếu không có trong repo, agent không biết.

### 2. Constraints (mechanical enforcement)

Ràng buộc kiến trúc được **enforce bằng script/CI**, không chỉ bằng review:

| Guard | Script |
| ----- | ------ |
| Infrastructure Dart-only | `scripts/ci/guard_infra_dart_only.sh` |
| Layer import rules | `scripts/ci/guard_layer_imports.sh` |
| Agent doc links | `scripts/ci/guard_docs_reference.sh` |
| Theme doc structure | `scripts/ci/guard_theme_structure.sh` |
| Theme traceability (when exemplar complete) | `scripts/ci/guard_theme_traceability.sh` |
| Codegen freshness (strict, tương lai) | `scripts/ci/guard_codegen_fresh.sh` |
| Presentation file size (≤ 500 lines) | `scripts/ci/guard_presentation_size.sh` |
| Inline dialogs in pages | `scripts/ci/guard_presentation_dialogs.sh` |

Umbrella: `scripts/ci/verify_harness.sh`

Layer rules (tóm tắt):

- Domain: không import `supabase`, `flutter`, `get_it`
- Application: không import `infrastructure`, `supabase`
- Mọi package: cấm `import 'package:other_pkg/src/...'`

### 3. Verification (feedback loops)

```bash
melos bootstrap
melos run analyze
melos run test
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test
cd apps/messaging_worker && dart test
```

CircleCI job `verify_workspace` chạy chuỗi trên trên mọi PR.

### 4. Flywheel

Khi agent fail lặp lại cùng lỗi:

1. **Không** chỉ retry prompt
2. Thêm guard, cập nhật doc/skill, hoặc sửa reference example
3. Ghi vào [PROGRESS.md](../harness/PROGRESS.md)

## Reference implementations

| Giai đoạn | Reference |
| --------- | --------- |
| **Hiện tại (harness phase)** | `packages/vet45_generator/test/fixtures/`, `packages/vet45_shared/testing/` |
| **Presentation UI (golden)** | `apps/erp/lib/features/dashboard/presentation/` |
| **Phase 2 (planned)** | Module `iam` — full vertical slice + ERP wiring |

Tất cả `modules/*` hiện là **skeleton** — xem [04-repository-layout.md](04-repository-layout.md).

## Test harness

Handler tests dùng `vet45_shared_testing`:

- `PipelineTestHarness` — test decorator order (validation trước handler)
- `InMemoryCommandBus` / `RecordingQueryBus` — execute without Supabase
- `FakeExecutionContext`, `FakePermissionChecker` — auth/tenant doubles

Canonical example: `packages/vet45_shared/testing/test/shared_testing_test.dart`

Layout mục tiêu cho module (khi implement):

```text
modules/<module>/application/test/<use_case>/<use_case>_handler_test.dart
modules/<module>/domain/test/<aggregate>/<aggregate>_test.dart
```

## `initializeForTesting` contract

Mọi `{Module}Startup` **sẽ** expose (IAM golden implement đầu tiên):

```dart
static I{Module}Module initializeForTesting({
  required SupabaseClient supabase,
  GetIt? container,
});
```

Dùng `Fake<Module>RpcClient` hoặc in-memory Supabase fake — không gọi production RPC trong unit test.

## Codegen gate (bật sau IAM golden)

`guard_codegen_fresh.sh` mặc định **skip**. Bật strict:

```bash
GUARD_CODEGEN_STRICT=1 ./scripts/ci/guard_codegen_fresh.sh
```

Khi module bật `vet45_generator|cqrs_registrar`, CI nên set `GUARD_CODEGEN_STRICT=1`.

## Liên kết

- [05-layered-module-structure.md](05-layered-module-structure.md)
- [codegen-migration.md](codegen-migration.md)
- [application_layer_skill.md](../application_layer_skill.md)
- [infrastructure_layer_skill.md](../infrastructure_layer_skill.md)
- [presentation_layer_skill.md](../presentation_layer_skill.md)
