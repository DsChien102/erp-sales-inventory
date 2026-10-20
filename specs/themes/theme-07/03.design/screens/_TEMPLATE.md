---
id: SCR-XXX
type: screen-contract
theme: theme-07
title: "<Tiêu đề hiện trên app bar>"
bj: BJ-XX
uif: UIF-XX
status: IN_REVIEW
prototype: "app/bjXX.js · renderXXX"
updated: YYYY-MM-DD
---
# SCR-XXX — <Tiêu đề>

## 1. Mục đích

Một đoạn: ai đến màn này, lúc nào, để biết hoặc làm gì.

## 2. Lối vào và lối ra

| Hướng | Từ / đến | Điều kiện | Cách (nút, liên kết) |
|---|---|---|---|
| Vào | | | |
| Ra | | | |

## 3. Thứ bậc thông tin

Từ trên xuống, mỗi dòng một khối:

1. <Khối> — <nội dung> — <thành phần DS>

## 4. Trạng thái

| Trạng thái | Khi nào | Hiện gì | Làm được gì | Lối ra |
|---|---|---|---|---|

## 5. Hành động

| Hành động | Bật khi | Kết quả | Mã |
|---|---|---|---|

## 6. Quyền và che tài chính

Ai thấy / làm được gì; dữ liệu nào không được có trong màn khi không có quyền; số tiền nào ẩn khi `FINANCIAL_MASKED`.

## 7. Thành phần DS

Danh sách thành phần dùng (tên trong `vet45_design_system` / prototype), ghi rõ thành phần mới.

## 8. Chữ trên màn

| Vị trí | Chữ |
|---|---|

## 9. Truy vết

BJ · UC · UIF · BC · quyết định `T7-DR-…` · kịch bản golden.

---

## Quy tắc ghi (xoá phần này khi tạo Screen Contract từ khuôn)

- Không có mục lịch sử phiên bản; thay đổi ghi ở `03.design/prototype/html/CHANGELOG.md`, lịch sử để git giữ.
- Một hệ đánh số `## 1…9`; mục con dùng `###` không đánh số.
- Mã kỹ thuật (BC, API, enum) chỉ ở mục 9; các mục khác viết bằng lời người dùng.
- Chữ ở mục 8 là chuỗi chuẩn: prototype và Flutter chép đúng.
- **Màn dùng chung nhiều luồng** (SCR-036 / 037 / 041: BJ-07, 09, 10; SCR-056: BJ-09, 15; SCR-078…083: BJ-16, 17 — prototype dựng mỗi luồng một hàm qua `flowRenderers`): frontmatter `bj` / `uif` / `prototype` ghi danh sách (vd. `bj: [BJ-07, BJ-09, BJ-10]`); mục 1 viết chung; mục 2–5 và 8 chia `### UIF-NN` theo luồng; BJ nào thiết kế lại trước thì viết phần của luồng mình, để trống phần luồng khác kèm ghi "chưa viết lại".
