# Audit component trong Design System

Mục tiêu: giúp team audit nhanh toàn bộ component public đang export trong `lib/design_system.dart`.

## Chạy audit

Từ thư mục package:

```bash
cd packages/vet45_design_system
dart run tool/component_audit.dart
```

## Artifacts được sinh tự động

- `docs/audit/component_audit_report.md`
- `lib/src/audit/v_component_audit_snapshot.dart`

## Ý nghĩa

- File Markdown dùng cho review tài liệu và PR.
- File Dart snapshot được tab `UI Audit` trong example đọc trực tiếp để hiển thị trạng thái mới nhất.

Vì vậy, mỗi khi thêm/sửa component, hãy chạy lại script để dữ liệu audit luôn đồng bộ.
