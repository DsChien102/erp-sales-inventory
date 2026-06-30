# Presentation Layer Skill

Canonical spec mirror of `.cursor/skills/presentation-layer/SKILL.md`.

## 1. Purpose

Use this skill when designing, generating, reviewing, or refactoring **Flutter presentation UI** — pages, dialogs, sections, and feature wiring in the ERP app and module presentation packages.

Presentation displays and interacts with the user. It does not decide business invariants (domain) or call Supabase/PostgREST directly (infrastructure).

```text
Presentation decides how the user sees and interacts with it.
Application decides what use case is being executed.
Domain decides what is valid business behavior.
Infrastructure implements how the module talks to the outside world.
```

---

## 2. Dual path (canonical)

| Kind | Location |
| ---- | -------- |
| Pages / screens | `apps/erp/lib/features/<feature>/presentation/pages/` |
| Feature-only widgets | `apps/erp/lib/features/<feature>/presentation/widgets/` |
| Feature state (optional) | `apps/erp/lib/features/<feature>/presentation/bloc/` |
| Reusable dialogs/widgets | `modules/<module>/presentation/lib/src/widgets/` |

**Import rules:**

- `apps/erp` **may** import `vet45_<module>_presentation`
- `modules/<module>/presentation` **must not** import `apps/erp`
- Mutations/reads: `IExecutionContext` → `IModuleMediator` — no direct Supabase from widgets

---

## 3. Hard rules

1. **Design System First**: You **must** use UI components from the `vet45_design_system` package. Do not build custom UI components from scratch (like buttons, text fields, typography, colors) if a corresponding component exists in the design system.
2. `*_page.dart` / `*_screen.dart` **≤ 500 lines** — `scripts/ci/guard_presentation_size.sh`. This forces breaking down UI into smaller, reusable widgets to prevent long, unmaintainable code files.
3. **One dialog = one file** — `StatelessWidget` in `widgets/`; no inline `AlertDialog` in pages — `scripts/ci/guard_presentation_dialogs.sh`
4. **No large `Widget _buildXxx()` methods**: Do not use `_buildXxx()` for large UI subtrees in `State`. You must extract them into separate stateless or stateful widget classes, preferably in their own files if they are substantial.
5. Page = thin composition root (widgets + Bloc/Cubit + navigation). A page should mostly be a scaffold composing smaller widgets.
6. Prefer `const` constructors when parameters are immutable.

Small private widgets (e.g. `_SectionHeader`) in the same file are OK if the page stays ≤ 500 lines.

---

## 4. Workflow

1. Read FR + **UI artifacts** table from product spec
2. Create **widget manifest** (file paths) before coding
3. Scaffold empty files per manifest
4. Implement dialogs/sections first, page last
5. Widget tests for confirmation dialogs (when FR has SCN)
6. Verify:

```bash
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/<feature>/
```

---

## 5. Golden reference

| File | Role |
| ---- | ---- |
| `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` | Thin page, tab composition |
| `apps/erp/lib/features/dashboard/presentation/widgets/dashboard_header.dart` | Extracted `const` section |

---

## 6. Anti-patterns

- God Widget (page > 500 lines, layout + dialogs + forms in one file)
- Inline `showDialog` + `AlertDialog` in `*_page.dart`
- Large `Widget _buildXxx()` instead of dedicated widget classes
- Direct PostgREST / `Supabase.instance` from widgets
- Business rules in `build()` or dialog callbacks
- Cross-package `import 'package:.../src/...'`

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
