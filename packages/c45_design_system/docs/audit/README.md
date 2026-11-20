# Audit component trong Design System

Mục tiêu: giúp team audit nhanh toàn bộ component public đang export trong `lib/design_system.dart`.

## Chạy audit

Từ thư mục package:

```bash
cd packages/c45_design_system
dart run tool/component_audit.dart
# Fail if missing required contracts:
dart run tool/component_audit.dart --fail-on-required
# Or from repo root:
./scripts/ci/guard_design_system_contracts.sh
```

## Matrix

Expectations live in [`contract_matrix.yaml`](contract_matrix.yaml) (role + required/preferred/optional/na per field). Spec: [docs/polaris/08-component-contracts.md](../polaris/08-component-contracts.md).

## Artifacts được sinh tự động

- `docs/audit/component_audit_report.md`
- `lib/src/audit/v_component_audit_snapshot.dart`

## Ý nghĩa

- File Markdown dùng cho review tài liệu và PR.
- File Dart snapshot được tab `UI Audit` trong example đọc trực tiếp để hiển thị trạng thái mới nhất.

Vì vậy, mỗi khi thêm/sửa component, hãy chạy lại script để dữ liệu audit luôn đồng bộ.
