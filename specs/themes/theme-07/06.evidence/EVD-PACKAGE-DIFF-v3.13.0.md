---
id: EVD-PACKAGE-DIFF-v3.13.0
type: diff-evidence
theme: theme-07
title: "Package diff — v3.12.0 → v3.13.0"
owner: QA/HARNESS
status: PASS
version: v3.13.0
parent: v3.12.0
---
# EVD — Package Diff — v3.13.0

## 1. Phạm vi thay đổi

v3.13.0 là bản **Design + HTML parity** trên semantic v3.12.0. Không thay đổi quyết định nghiệp vụ, Domain hay Technical Contract.

- Parent: `v3.12.0`
- Candidate: `v3.13.0`
- File parent: **7.030**
- File candidate trước checksum freeze: **7.066**
- Thêm: **36**
- Xóa: **0**
- Sửa: **59**

Chi tiết machine-readable nằm tại `EVD-PACKAGE-DIFF-v3.13.0.json`.

## 2. Bảo toàn semantic

- `01.knowledge/**`: **byte-identical** với v3.12.0.
- `02.specification/domain/**`: **byte-identical**.
- `02.specification/technical-contracts/**`: **byte-identical**.
- Chỉ 4 UC valuation thay đổi, và chỉ tại `source_baseline` + mục **Liên hệ giao diện**:
  - `UC-03-01`
  - `UC-13-01`
  - `UC-14-01`
  - `UC-14-04`
- BF/AF/EF/BR/Acceptance của 4 UC trên không thay đổi.

## 3. Impact set có chủ đích

1. Screen Contract và UI pattern của BJ03/BJ13/BJ14.
2. HTML runtime valuation và workbench metadata.
3. Harness FE slice/manifest tương ứng với topology mới.
4. Registry/matrix dẫn xuất cho Screen/Action/UIF/Component Usage.
5. QA/evidence v3.13.0.
6. README/manifest/version metadata.

## 4. Topology active

- BJ03: `SCR-014 → SCR-015 → SCR-017 → SCR-019`.
- BJ13: `SCR-085 → SCR-086 → SCR-088 → SCR-089`.
- BJ14: `SCR-072 → SCR-074 → SCR-077`.

Các màn `SCR-016`, `SCR-018`, `SCR-073`, `SCR-075`, `SCR-076`, `SCR-087` chỉ còn để migration/trace, không còn route sản phẩm active.

## 5. Kết luận

**PASS.** Diff nằm đúng impact set Design/HTML, không phát hiện semantic drift ngoài phạm vi.
