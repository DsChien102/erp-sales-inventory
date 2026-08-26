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
| Invitation confirmation | Email chỉ chứa opaque token; user đang đăng xuất tự mở app và copy/paste token; API nhận token **trong body** |
| Existing account | Token hợp lệ → Invitation Login với `invitee_email` điền sẵn và khóa read-only |
| New account | Token hợp lệ là email proof → Registration khóa email → tạo verified Platform User → accept invitation |
| Password reset | Mã 6 số trong app (đã login) — không dùng URL xác nhận |
| Surfaces | `apps/erp` = Tenant App; `apps/admin` = Platform Admin (Login + S15 wired) |
| Post-MVP | EP-02/US-04 transfer + US-05 close — không slice phase 1 |
| Platform Admin bootstrap | Không self-signup. Preferred: `vet45 admin create --email …` (Auth Admin + `iam.platform_admins`). Fallback SQL: `INSERT INTO iam.platform_admins (user_id)`. Product invite (`CreatePlatformAdmin`) = slice sau. |

## Pitfalls

- **Owner ≠ role** — `is_owner` độc lập `role_id`; không suy Owner từ role `Chủ cửa hàng`.
- **Activation invitation ≠ Tenant Invitation** — hai lifecycle, hai template Resend.
- **Delivery ≠ Invitation status** — fail Resend không tự revoke/expire invitation.
- **Token** — backend sinh 32-byte CSPRNG Base64URL; chỉ `token_hash` persist; user copy/paste; API dùng body; không log raw.
- **Gửi lại lời mời** — IAM rotate token và vô hiệu token cũ trước khi Notification gửi email mới qua Resend.
- **Resend secrets** — không hardcode; `config/secrets` + env sync.
- **Interim IAM** — `owner`/`staff` sẽ thay bằng bốn system role MVP (EP-04).
- **UI** — Design Reference trỏ Theme §5 Screen Groups; không nhân bản wireframe vào US.
- **Admin login gate** — sau `SignInCommand`, Admin gọi `IPermissionChecker.require(platform.user.view)`; thiếu `iam.platform_admins` → SignOut + toast (không để tenant user vào dashboard).
- **Admin Melos** — `apps/admin` trong workspace; Login + S15 FE dùng FakeIamModule.

## Flywheel log

| Date | Lỗi / ghi chú | Biện pháp |
| ---- | ------------- | --------- |
| 2026-07-16 | Scaffold harness TH-01 sau Epic/US decomposition | harness/00–07; chốt Resend + invitation confirmation |
| 2026-07-16 | README link `02-module-map.md` thiếu SoT | SoT = harness/02; root redirect |
| 2026-07-19 | S-NOTIFY: worker registry rỗng; chưa có Dart claim client | Bootstrap đăng ký `iam`; draft outcome SQL (chưa promote). *(Lịch sử: lần đầu dùng outbox gateway — đã thay bằng internal command 2026-07-20.)* |
| 2026-07-19 | Resend HTTP nằm trong IAM infra — khó tái dùng module khác | Tách `packages/vet45_resend` (`IResendClient` / real / fake) |
| 2026-07-20 | S-NOTIFY dùng outbox như task queue (vi phạm internal command) | Refactor: `SendEmailDeliveryCommand` + `iam.internal_commands`; worker claim → CommandBus; đóng debt outbox-as-task-queue |
| 2026-07-29 | Bỏ URL confirmation | Email chỉ chứa backend-generated opaque token; user nhập token khi logged out; existing account login khóa email, new account đăng ký với token làm email proof |
| 2026-07-20 | IAM messaging folder/wiring ≠ golden sales (`modules/sales/infrastructure`, `dev-old`) | **Closed:** IAM có `Process{Outbox,Inbox,InternalCommands}` + `ICommandScheduler` + self-consume inbox; adapters `src/adapters/notification/`; thin `IamMessagingModule` |
| 2026-07-20 | Dart client gọi `enqueue_outbox_message` (vi phạm RPC same-txn) | **Closed:** bỏ `enqueue` khỏi `IIamOutboxClient`; port production chỉ đọc outcome; docs/tests seed outbox như RPC |
| 2026-07-24 | Admin chưa có Login — mở thẳng dashboard | LoginPage + router guard + platform.user.view gate; ops bootstrap `iam.platform_admins` ghi trong notes |
| 2026-07-27 | Bootstrap platform admin thủ công dễ quên | `vet45 admin create\|grant\|list` (service role + Auth Admin API) |
| 2026-08-23 | IAM audit + owner activation trôi khỏi thiết kế | Cleanup: bỏ legacy `iam.platform_audit_logs`; retire `iam.owner_activations`; platform audit đọc canonical `iam.audit_logs(scope='platform')`. Owner = **người dùng đầu tiên, mặc định là chủ** — membership tạo ngay ở onboarding (không dùng bảng activation), kích hoạt = đặt mật khẩu qua Auth; staff mới đi luồng mời `tenant_invitations`. `iam.platform_admins` bàn riêng. Plan: `docs/superpowers/plans/2026-08-21-iam-audit-owner-activation-cleanup.md`. |

## Liên kết

- [harness-engineering.md](../../../architecture/harness-engineering.md)
- [PROGRESS.md](../../../harness/PROGRESS.md)
- [OVERVIEWS.md](../OVERVIEWS.md) · [APPENDICES.md](../APPENDICES.md)
