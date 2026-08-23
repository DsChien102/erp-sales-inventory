# Ship-unit versioning & changelog

Monorepo policy: **ship units** carry versions and Keep a Changelog files. Other
`modules/*` / `packages/*` stay workspace-pinned unless added to the table below.

## Ship units

| Unit | Path | Framework | Version shape | Bump script | Git tag |
| --- | ---- | --------- | ------------- | ----------- | ------- |
| ERP | `apps/erp` | `flutter_exec` | `MAJOR.MINOR.PATCH+BUILD` | [`apps/erp/scripts/bump_version.sh`](../../apps/erp/scripts/bump_version.sh) | `erp-v1.8.0+37` |
| Admin | `apps/admin` | `flutter_exec` | `MAJOR.MINOR.PATCH+BUILD` | [`apps/admin/scripts/bump_version.sh`](../../apps/admin/scripts/bump_version.sh) | `admin-v1.0.1+2` |
| Messaging worker | `apps/messaging_worker` | `dart_exec` | `MAJOR.MINOR.PATCH` | [`apps/messaging_worker/scripts/bump_version.sh`](../../apps/messaging_worker/scripts/bump_version.sh) | `messaging_worker-v0.2.0` |
| Design system | `packages/vet45_design_system` | `flutter_lib` | `MAJOR.MINOR.PATCH` | [`packages/vet45_design_system/scripts/bump_version.sh`](../../packages/vet45_design_system/scripts/bump_version.sh) | `vet45_design_system-v1.0.1` |

Mention other module/package work under **Internal** in the ship-unit changelog that
actually ships the change. Design-system API/UI changes: update
`packages/vet45_design_system/CHANGELOG.md`; if the change is user-facing in ERP/Admin,
also add bullets there.

## Architecture (agnostic common + framework files)

```text
scripts/release/
  lib/bump_common.sh              # language/framework agnostic orchestration
  lib/manifests/pubspec.sh        # Pub version I/O (Flutter + Dart today)
  frameworks/
    flutter_exec.sh               # Flutter app (+BUILD)
    flutter_lib.sh                # Flutter package library
    dart_exec.sh                  # Dart executable
    dart_lib.sh                   # Dart package library
  cut_changelog_unreleased.py
```

| Layer | Responsibility | Must not know |
| --- | --- | --- |
| `bump_common.sh` | Flags, dirty tree, Keep a Changelog cut, commit/tag/push | `pubspec`, Cargo, go.mod, `+build` math |
| `frameworks/<framework>_<exec\|lib>.sh` | Bump math, `--build` policy, wire a manifest adapter | Git remotes / changelog cutter internals |
| `lib/manifests/<format>.sh` | Read/write one version-file format | Ship-unit identity / tags |

Naming: flat files `frameworks/<framework>_<deploy>.sh` with `deploy` ∈ `{exec, lib}`.
Future Go/Rust: add e.g. `go_exec.sh` + `lib/manifests/go_mod.sh` — no nested `frameworks/go/`.

| Framework file | Project | Deployment | Default bump | `--build` |
| --- | --- | --- | --- | --- |
| [`flutter_exec`](../../scripts/release/frameworks/flutter_exec.sh) | Flutter | executable (app) | `--build` | allowed |
| [`flutter_lib`](../../scripts/release/frameworks/flutter_lib.sh) | Flutter | library | `--patch` | rejected |
| [`dart_exec`](../../scripts/release/frameworks/dart_exec.sh) | Dart | executable | `--patch` | rejected |
| [`dart_lib`](../../scripts/release/frameworks/dart_lib.sh) | Dart | library | `--patch` | rejected |

Changelog cutter: [`scripts/release/cut_changelog_unreleased.py`](../../scripts/release/cut_changelog_unreleased.py)
(called by each unit’s thin `bump_version.sh` wrapper).

## Day-to-day

1. While developing, append bullets under `## [Unreleased]` in the affected unit’s `CHANGELOG.md`.
2. On release, run **that unit’s** `bump_version.sh` (updates version manifest + cuts changelog).
3. Use `--commit` / `--tag` / `--push` when ready, or commit manually.

PR / MR checklist:

- GitLab: [`.gitlab/merge_request_templates/Default.md`](../../.gitlab/merge_request_templates/Default.md)
- GitHub (mirror): [`.github/pull_request_template.md`](../../.github/pull_request_template.md)

## Bump scripts (per unit)

```bash
# Flutter apps — default is --build (+N only)
./apps/erp/scripts/bump_version.sh --build --dry-run
./apps/erp/scripts/bump_version.sh --patch --commit --tag
./apps/admin/scripts/bump_version.sh --build --commit --push --ci

# Dart executable (worker) — no build number; default is --patch
./apps/messaging_worker/scripts/bump_version.sh --minor --commit --tag
./apps/messaging_worker/scripts/bump_version.sh --patch --date 2026-08-20

# Flutter library (design system) — no build number; default is --patch
./packages/vet45_design_system/scripts/bump_version.sh --patch --dry-run
./packages/vet45_design_system/scripts/bump_version.sh --minor --commit --tag
```

Common flags: `--dry-run`, `--date YYYY-MM-DD`, `--skip-changelog`, `--commit`, `--tag`, `--push`, `--ci`, `--allow-dirty`, `--set VERSION`, `--output-file F`.

| Flag | `flutter_exec` (erp, admin) | Semver frameworks (worker, design_system, …) |
| ---- | --------------------------- | -------------------------------------------- |
| `--major` | `x+1.0.0+(N+1)` | `x+1.0.0` |
| `--minor` | `x.y+1.0+(N+1)` | `x.y+1.0` |
| `--patch` | `x.y.z+1+(N+1)` | `x.y.z+1` |
| `--build` | `x.y.z+(N+1)` (default) | **invalid** |

Every Flutter **app** bump that changes marketing version also increments **BUILD**
(store requirement). Prefer `--build` for TestFlight-only uploads.

## Semver guide

- **PATCH** — bug fix, copy, small non-breaking fixes
- **MINOR** — user-facing feature / completed theme slice / library API addition
- **MAJOR** — breaking UX, mandatory migration, or breaking library API
- **BUILD** (`flutter_exec` only) — every uploaded binary

## Release checklist

1. `./<unit>/scripts/bump_version.sh --patch` (or `--build` / `--minor` / …)
2. Review generated `CHANGELOG.md` section
3. Commit (script `--commit` or manual): `chore(<unit>): bump version to …`
4. Tag: script `--tag` or `git tag <unit>-v<version>`
5. Deploy (TestFlight / Play / Railway) per existing ops docs when applicable

Related: [testflight-asc-setup.md](testflight-asc-setup.md), [apps/messaging_worker/README.md](../../apps/messaging_worker/README.md).
