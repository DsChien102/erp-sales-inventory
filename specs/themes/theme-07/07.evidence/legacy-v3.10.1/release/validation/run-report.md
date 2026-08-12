# Run report — Theme 7 v4.3.1

## Iteration 0 — Rejected: mutable working tree

- Phát hiện `harness/run-manifest.json` và `harness/validation-report.json` trong thư mục làm việc v4.2.0-rc1 lệch checksum sau khi validator được chạy lại.
- Loại nguồn thư mục; chuyển sang giải nén ZIP v4.2.0-rc1 bất biến đã khóa SHA-256.

## Iteration 1 — Rejected: decision metric parser

- Bản Quyết định nghiệp vụ tối ưu dùng dòng bảng thay vì heading riêng cho từng quyết định; parser ban đầu trả 0 thay vì 102.
- Loại output vòng này, sửa parser theo stable anchor/table row và dựng lại từ ZIP bất biến.

## Iteration 2 — Source closure

- Xác minh SHA-256 của v4.1.0, patch v4.1.3 và UI package v4.2.0-rc1.
- Rerun Harness tiền nhiệm: `14 PASS / 1 BLOCKED`, không có hard failure.

## Iteration 3 — Consolidation

- Copy v4.2.0-rc1 sang output mới; không sửa package nguồn.
- Áp dụng transformer v4.1.3 trên toàn Markdown active, loại fragment ngắn/custom.
- Khóa semantic projection, 17 BJ/70 UC, 83 Screen và trạng thái prototype `NOT_RENDERED`.

## Iteration 4 — Repair và integration evidence

- Sửa metadata/validation cũ mâu thuẫn với trạng thái prototype.
- Khử ba block Change log v4.2.0-rc1 bị lặp và nâng handoff UI từ know-how v4.1.2 lên v4.1.3.
- Thêm Harness UI trace overlay thay vì đổi contract/test nghiệp vụ.
- Sinh validation, manifest và handoff; chạy lại validator đến khi hard gate xanh.

## Iteration 5 — Rejected: predecessor validator trên freeze mới

- Thử chạy validator Harness v4.1.0 trực tiếp với manifest package v4.3.0; validator từ chối tại `G02_FREEZE_INTEGRITY` vì freeze identity khác nhau.
- Không ép PASS và không đổi Harness semantic catalog. Khôi phục báo cáo Harness tiền nhiệm byte-for-byte từ ZIP bất biến; validator v4.3.0 kiểm tra overlay hiện hành riêng.

## Iteration 6 — Rejected: package thiếu carry-forward artifacts

- Package đạt các gate đã khai báo nhưng chưa đưa UI-flow patch chi tiết và prototype hiện có vào artifact inventory.
- Không coi kết quả này là bản bàn giao hoàn chỉnh; mở lại package để sửa phạm vi carry-forward.

## Iteration 7 — Carry-forward closure

- Bổ sung `ui/flows` từ patch v4.2.0-rc1: 17 flow, 70 UC và 201 transition; chỉ rebase đường dẫn tương đối theo vị trí thư mục mới.
- Copy nguyên trạng 6 file prototype v4.1.0 và compatibility screen catalog phục vụ validator cũ; Screen Registry vẫn là nguồn UI hiện hành.
- Khóa lại checksum/manifest, chạy static prototype validator, package validator và fresh rebuild; tất cả hard gate package đạt.
- Ba gate chưa chạy được giữ nguyên là `REPOSITORY_EXECUTION`, `PROTOTYPE_UPGRADE_BROWSER_RUNTIME` và `GITLAB_PREVIEW`.


## Iteration 8 — Cache-bust repackage v4.3.1

- Xác minh package manifest và SHA-256 của ZIP v4.3.0 trước khi copy.
- Giữ nguyên byte toàn bộ artifact ngoài nhóm identity/changelog/validation/checksum của release.
- Đổi package identity sang v4.3.1, sinh freeze mới và chạy lại package/prototype validator trên ZIP cuối.
