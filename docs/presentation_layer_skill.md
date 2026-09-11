# Presentation Layer Skill

Canonical spec mirror of `.cursor/skills/presentation-layer/SKILL.md`.

## 1. Purpose

Use this skill when designing, generating, reviewing, or refactoring **Flutter presentation UI** — pages, dialogs, sections, and feature wiring in the ERP/Admin apps.

Presentation displays and interacts with the user. It does not decide business invariants (domain) or call Supabase/PostgREST directly (infrastructure).

```text
Presentation decides how the user sees and interacts with it.
Application decides what use case is being executed.
Domain decides what is valid business behavior.
Infrastructure implements how the module talks to the outside world.
```

---

## 2. App-owned presentation (canonical)

| Kind | Location |
| ---- | -------- |
| Pages / screens | `apps/erp/lib/features/<feature>/presentation/pages/` |
| Feature cubit / orchestration | `apps/erp/lib/features/<feature>/presentation/bloc/` — multi-aggregate: `bloc/<aggregate>/` |
| Widgets / dialogs | `apps/erp/lib/features/<feature>/presentation/widgets/` |
| Display VMs / flow results / handoff args | `apps/erp/lib/features/<feature>/presentation/models/` — multi-aggregate: `models/<aggregate>/` (see §2.1) |
| Cubit-owned contracts / one-shot results | `bloc/<aggregate>/` next to the owning cubit when not shared across surfaces |
| Cross-aggregate UI state | `bloc/shared/`, `models/shared/` |
| Helpers (mapper / factory / PDF) | `presentation/support/` — behavior only, not data shapes |
| Preview catalog | `apps/erp/example/` |
| Admin UI | `apps/admin/lib/features/<feature>/presentation/` |

### 2.1 Presentation data shapes

| Kind | File suffix | Home | Notes |
| ---- | ----------- | ---- | ----- |
| Cubit state | `*_state.dart` | `bloc/<aggregate>/` next to cubit | Bound by `BlocBuilder` |
| Display VM | `*_vm.dart` | `models/<aggregate>/` | Pure display data |
| Flow result | `*_result.dart` only | Owner flow in `bloc/<aggregate>/`, or `models/<aggregate>/` if shared | One-shot action result — **not** Cubit state |
| Handoff / nav args | `*_args.dart` only | `models/<aggregate>/` (or `navigation/` if route-only) | Route `$extra` / screen handoff |
| Callback + request/result | e.g. `*_contracts.dart` | `bloc/<aggregate>/` next to cubit owner | Avoid `*_ports` unless a real port/adapter |
| Helpers | mapper / factory | `support/` | No DTOs / results / args |

**Forbidden for new presentation shapes:** `*_outcome.dart`, `*_snapshot.dart` for handoff. Keep “snapshot” for persistence/domain meanings (e.g. `order_snapshot`).

**Examples (Sales):** `sales_checkout_prepare_result.dart`, `sales_checkout_draft_args.dart`, `sales_compose_line_vm.dart`, `sales_draft_contracts.dart`.

Pricing may still use a flat `cubit/` folder — mirror this taxonomy when that feature is refactored.

**Ownership:** UI belongs to the ship-unit app. Do **not** create `modules/*/presentation`. See [architecture/11-app-owned-presentation.md](architecture/11-app-owned-presentation.md).

**Import rules:**

- Apps **may** import `vet45_<module>_application` (composition root)
- Apps **must not** depend on `vet45_*_presentation` packages (removed)
- `apps/erp/example` **may** import `package:erp` features + `vet45_design_system` (+ application testing/fakes); **must not** use live Supabase
- Mutations/reads: `IExecutionContext` → `IModuleMediator` — no direct Supabase from widgets

**DS vs ERP catalog:** `packages/vet45_design_system/example` = primitives; `apps/erp/example` = feature widgets. Public reusable widget → same-PR `PreviewSection` in ERP example.

---

## 3. Hard rules

1. **Design System First**: You **must** use UI components from the `vet45_design_system` package. Do not build custom UI components from scratch (like buttons, text fields, typography, colors) if a corresponding component exists in the design system.
2. `*_page.dart` / `*_screen.dart` **≤ 500 lines** — `scripts/ci/guard_presentation_size.sh`. This forces breaking down UI into smaller, reusable widgets to prevent long, unmaintainable code files.
3. **One dialog = one file** — `StatelessWidget` in `widgets/`; no inline `AlertDialog` in pages — `scripts/ci/guard_presentation_dialogs.sh`
4. **No large `Widget _buildXxx()` methods**: Do not use `_buildXxx()` for large UI subtrees in `State`. You must extract them into separate stateless or stateful widget classes, preferably in their own files if they are substantial.
5. Page = thin composition root (widgets + Bloc/Cubit + navigation). A page should mostly be a scaffold composing smaller widgets.
6. Prefer `const` constructors when parameters are immutable.
7. **Multi-aggregate features** (e.g. Sales): place cubits/VMs under `presentation/bloc/<aggregate>/` and `presentation/models/<aggregate>/` matching domain folder names; use `shared/` only for cross-aggregate UI state. Do not add new flat files under `bloc/` or `models/` roots once the feature is aggregate-grouped.
8. **Feature typed routes** (Sales): navigate via `*Route(...).push/go` from `sales_typed_routes.dart` (`go_router_builder`). Do not add raw `'/sales/...'` literals. Regenerates with `dart run build_runner` under `apps/erp` (see `build.yaml` filter).
9. **Presentation data shapes** (§2.1): new flow results use `*_result.dart`; handoff/nav extras use `*_args.dart`. Do not introduce `*_outcome.dart` or handoff `*_snapshot.dart`. Do not put results/args/contracts in `support/`.

Small private widgets (e.g. `_SectionHeader`) in the same file are OK if the page stays ≤ 500 lines.

---

## 4. Workflow

1. Read FR + **UI artifacts** table from product spec
2. Create **widget manifest** (file paths) before coding
3. Scaffold empty files per manifest
4. Implement dialogs/sections first → `PreviewSection` in module `example/` → page last
5. Widget tests for confirmation dialogs (when FR has SCN)
6. Verify:

```bash
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/<feature>/
cd apps/erp/example && flutter analyze
```

---

## 5. Golden reference

| File | Role |
| ---- | ---- |
| `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` | Thin page, tab composition |
| `apps/erp/lib/features/dashboard/presentation/widgets/dashboard_header.dart` | Extracted `const` section |
| `apps/erp/example/` | Feature widget preview catalog |

---

## 6. Anti-patterns

- God Widget (page > 500 lines, layout + dialogs + forms in one file)
- Inline `showDialog` + `AlertDialog` in `*_page.dart`
- Large `Widget _buildXxx()` instead of dedicated widget classes
- Direct PostgREST / `Supabase.instance` from widgets
- Business rules in `build()` or dialog callbacks
- Cross-package `import 'package:.../src/...'`
- BC widget demos inside `vet45_design_system/example` (wrong boundary)
- Creating or expanding `modules/*/presentation`
- Flat `presentation/bloc/*.dart` / `presentation/models/*.dart` when the feature already groups by domain aggregate
- Raw `'/sales/...'` (or equivalent feature paths) in pages/widgets — use `*Route(...).push/go` from `go_router_builder`
- New presentation `*_outcome.dart` or handoff `*_snapshot.dart` (use `*_result` / `*_args`)
- Results, args, or cubit contracts living under `support/`
---

## 7. CI guards

| Guard | Script |
| ----- | ------ |
| Presentation file size | `scripts/ci/guard_presentation_size.sh` |
| Inline dialogs in pages | `scripts/ci/guard_presentation_dialogs.sh` |

Umbrella: `scripts/ci/verify_harness.sh`

Legacy: `GUARD_PRESENTATION_DIALOGS_LEGACY=1` until einvoice inline dialog is refactored. Per-file: `// harness:allow-inline-dialog` at top of file.

---

## 8. Links

- Skill (agent): `.cursor/skills/presentation-layer/SKILL.md`
- Reference: `.cursor/skills/presentation-layer/reference.md`
- Cursor rule: `.cursor/rules/vet45-presentation-ui.mdc`
- Harness: [docs/architecture/harness-engineering.md](architecture/harness-engineering.md)
- TH-03 ritual: [docs/themes/TH-03-partner/harness/00-agent-ritual.md](themes/TH-03-partner/harness/00-agent-ritual.md)
