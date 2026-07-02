# TH-01: Thiết lập cửa hàng

**Trạng thái deliver:** `interim` — IAM đang implement trong `modules/iam/`; harness theme đầy đủ khi có SRS.

Tenant, user, role, phân quyền và nền tảng truy cập đa tenant cho toàn bộ ERP.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| iam | **Owner** — auth, tenant, membership, RBAC catalogue | `modules/iam/` ([README](../../../modules/iam/README.md)) |

## Tài liệu

- [01-business-scope.md](01-business-scope.md)
- [02-module-map.md](02-module-map.md)
- Platform: [docs/architecture/](../../architecture/README.md) — [Identity & Access](../../architecture/06-cross-cutting-concerns.md)

*Epic/US/FR tree và harness đầy đủ khi SRS theme hoàn chỉnh.*
