# TH-01 — Harness notes

## Guards áp dụng

| Guard | Script |
| ----- | ------ |
| Layer imports | `scripts/ci/guard_layer_imports.sh` |
| Infra Dart-only | `scripts/ci/guard_infra_dart_only.sh` |
| Theme docs structure | `scripts/ci/guard_theme_structure.sh` |
| Theme traceability | `scripts/ci/guard_theme_traceability.sh` |
| Presentation file size | `scripts/ci/guard_presentation_size.sh` |
| Inline dialogs in pages | `scripts/ci/guard_presentation_dialogs.sh` |
| Doc links | `scripts/ci/guard_docs_reference.sh` |

Umbrella: `scripts/ci/verify_harness.sh`

## Verify chain (mỗi slice)

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen          # sau handler mới (BE lane)
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test   # khi slice có Tenant App UI
```

## Quyết định kiến trúc (tóm tắt)

Chi tiết: [03-architecture-and-flows.md](03-architecture-and-flows.md).

| Chủ đề | Chốt |
| ------ | ---- |
| Email | **Resend** qua Notification adapter; IAM chỉ delivery request + outcome |
| Deep link | HTTPS App Link `/i/{opaque}` hoặc `/activate/{opaque}` → app POST token **trong body** |
| Password reset | Mã 6 số trong app (đã login) — **không** magic link URL |
| Surfaces | `apps/erp` = Tenant App; `apps/admin` = Platform Admin (scaffold) |
| Post-MVP | EP-02/US-04 transfer + US-05 close — không slice phase 1 |

## Pitfalls

- **Owner ≠ role** — `is_owner` độc lập `role_id`; không suy Owner từ role `Chủ cửa hàng`.
- **Activation invitation ≠ Tenant Invitation** — hai lifecycle, hai template Resend.
- **Delivery ≠ Invitation status** — fail Resend không tự revoke/expire invitation.
- **Token** — chỉ `token_hash` persist; opaque trên App Link path; API accept dùng body; không log raw.
- **Resend secrets** — không hardcode; `config/secrets` + env sync.
- **Interim IAM** — `owner`/`staff` sẽ thay bằng bốn system role MVP (EP-04).
- **UI** — Design Reference trỏ Theme §5 Screen Groups; không nhân bản wireframe vào US.
- **Admin Melos** — `apps/admin` chưa workspace; Admin FE E2E deferred cho đến khi wire Melos.

## Flywheel log

| Date | Lỗi / ghi chú | Biện pháp |
| ---- | ------------- | --------- |
| 2026-07-16 | Scaffold harness TH-01 sau Epic/US decomposition | harness/00–07; chốt Resend + App Link |
| 2026-07-16 | README link `02-module-map.md` thiếu SoT | SoT = harness/02; root redirect |

## Liên kết

- [harness-engineering.md](../../../architecture/harness-engineering.md)
- [PROGRESS.md](../../../harness/PROGRESS.md)
- [OVERVIEWS.md](../OVERVIEWS.md) · [APPENDICES.md](../APPENDICES.md)
