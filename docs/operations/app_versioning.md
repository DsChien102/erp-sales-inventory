# App versioning & changelog (ship units)

Monorepo policy: **only shipable apps** carry user/ops-facing versions and changelogs.

| App | Path | Version shape | Bump script | Git tag |
| --- | ---- | ------------- | ----------- | ------- |
| ERP | `apps/erp` | `MAJOR.MINOR.PATCH+BUILD` | [`apps/erp/scripts/bump_version.sh`](../../apps/erp/scripts/bump_version.sh) | `erp-v1.8.0+37` |
| Admin | `apps/admin` | `MAJOR.MINOR.PATCH+BUILD` | [`apps/admin/scripts/bump_version.sh`](../../apps/admin/scripts/bump_version.sh) | `admin-v1.0.1+2` |
| Messaging worker | `apps/messaging_worker` | `MAJOR.MINOR.PATCH` | [`apps/messaging_worker/scripts/bump_version.sh`](../../apps/messaging_worker/scripts/bump_version.sh) | `messaging_worker-v0.2.0` |

Internal `modules/*` and `packages/*` stay workspace-pinned — do **not** bump them for product releases. Mention relevant module work under **Internal** in the app changelog that ships the change.

Shared helper (not a bump entrypoint): [`scripts/release/cut_changelog_unreleased.py`](../../scripts/release/cut_changelog_unreleased.py) — called by each app script to cut `## [Unreleased]`.

## Day-to-day

1. While developing, append bullets under `## [Unreleased]` in the affected app’s `CHANGELOG.md`.
2. On release, run **that app’s** `bump_version.sh` (updates `pubspec.yaml` + cuts changelog).
3. Use `--commit` / `--tag` / `--push` when ready, or commit manually.

PR / MR checklist:

- GitLab: [`.gitlab/merge_request_templates/Default.md`](../../.gitlab/merge_request_templates/Default.md)
- GitHub (mirror): [`.github/pull_request_template.md`](../../.github/pull_request_template.md)

## Bump scripts (per app)

```bash
# Flutter apps — default is --build (+N only)
./apps/erp/scripts/bump_version.sh --build --dry-run
./apps/erp/scripts/bump_version.sh --patch --commit --tag
./apps/admin/scripts/bump_version.sh --build --commit --push --ci

# Worker — no build number; default is --patch
./apps/messaging_worker/scripts/bump_version.sh --minor --commit --tag
./apps/messaging_worker/scripts/bump_version.sh --patch --date 2026-08-20
```

Common flags: `--dry-run`, `--date YYYY-MM-DD`, `--skip-changelog`, `--commit`, `--tag`, `--push`, `--ci`, `--allow-dirty`, `--set VERSION`, `--output-file F`.

| Flag | Flutter (`erp`, `admin`) | Worker |
| ---- | ------------------------ | ------ |
| `--major` | `x+1.0.0+(N+1)` | `x+1.0.0` |
| `--minor` | `x.y+1.0+(N+1)` | `x.y+1.0` |
| `--patch` | `x.y.z+1+(N+1)` | `x.y.z+1` |
| `--build` | `x.y.z+(N+1)` (default) | **invalid** |

Every Flutter bump that changes marketing version also increments **BUILD** (store requirement). Prefer `--build` for TestFlight-only uploads.

## Semver guide (apps)

- **PATCH** — bugfix, copy, small non-breaking fixes
- **MINOR** — user-facing feature / completed theme slice
- **MAJOR** — breaking UX or mandatory migration for end users
- **BUILD** (Flutter) — every uploaded binary

## Release checklist

1. `./apps/<app>/scripts/bump_version.sh --patch` (or `--build` / `--minor` / …)
2. Review generated `CHANGELOG.md` section
3. Commit (script `--commit` or manual): `chore(<app>): bump version to …`
4. Tag: script `--tag` or `git tag <app>-v<version>`
5. Deploy (TestFlight / Play / Railway) per existing ops docs

Related: [testflight-asc-setup.md](testflight-asc-setup.md), [apps/messaging_worker/README.md](../../apps/messaging_worker/README.md).
