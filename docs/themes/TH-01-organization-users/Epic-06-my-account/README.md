# EP-06 — Tài khoản của tôi

**Master spec:** [Theme-1-organization-users.md](../Theme-1-organization-users.md) §4.1 (EP-06) · UI: §5.5.11 TA-SG-10

> US trong epic này **derived from UI contract** (Theme spec chưa có §4.7 chi tiết) — bổ sung khi cần.

## Mục tiêu epic

Cho Platform User đã đăng nhập tự xem/cập nhật hồ sơ cá nhân, đặt lại mật khẩu và đăng xuất qua Platform Identity; Theme 1 chỉ điều phối application flow.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Profile | Xem và cập nhật avatar, họ và tên đệm, tên, SĐT |
| Password | Đặt lại mật khẩu bằng mã xác nhận gửi email đã xác minh |
| Session | Đăng xuất với confirmation |

**Ngoài phạm vi:** Đổi email đăng nhập; MFA/passkey; Theme 1 sở hữu credential/session database.

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Xem hồ sơ cá nhân | [US-01.md](US-01.md) |
| US-02 | Cập nhật hồ sơ cá nhân | [US-02.md](US-02.md) |
| US-03 | Đặt lại mật khẩu | [US-03.md](US-03.md) |
| US-04 | Đăng xuất | [US-04.md](US-04.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract: [Theme-1-organization-users.md](../Theme-1-organization-users.md) §5.5.11 TA-SG-10.
