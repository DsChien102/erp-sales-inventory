# CAP-01 — Chính sách tồn & cận hạn

> Supporting capability của Theme 7. Từ quyết định dự án ngày 15/09/2026, flow này được prototype trong **HTML Theme 7 harness** để toàn bộ Theme 7 có thể review end-to-end.  
> **Figma không phải nơi thiết kế Theme 7**; Figma chỉ cung cấp Design System hiện hành và tham khảo composition từ các theme trước.

## 1. Scope

CAP-01 quản lý hai nhóm cấu hình được BJ01/BJ09 tiêu thụ:

- ngưỡng cảnh báo tồn và mức tồn mục tiêu;
- số ngày cận hạn và hành động cảnh báo/chặn bán.

Thay đổi policy **không tạo Inventory Ledger movement**. Mỗi lần lưu tạo một lần cập nhật chính sách mới và các chỉ báo phụ thuộc được tính lại.

## 2. Prototype flow

```text
Entry cấu hình
 ├─ Chính sách tồn -> SCR-062
 └─ Hàng cận hạn  -> SCR-063

SCR-062 / SCR-063
  -> validate
  -> SCR-064 Rà soát chính sách
      ├─ Chỉnh sửa -> màn cấu hình nguồn
      └─ Lưu -> SCR-065 Kết quả cập nhật

SCR-065 -> Đóng / quay về context gọi
```

## 3. Business constraints

- `Mức tồn mục tiêu >= Ngưỡng cảnh báo >= 0`.
- `Số ngày cận hạn > 0`.
- Save policy không ghi số lượng/vị trí/giá trị vào Inventory Ledger.
- `UNKNOWN` không được blind retry; Product UI không hiển thị success khi chưa xác lập kết quả.
- Permission/entry/return destination production vẫn thuộc `BG-006` và **chưa khóa**. HTML harness dùng fallback context để QA không tạo màn chết; fallback này không phải navigation contract production.

## 4. Screens

- `SCR-062` — Cấu hình chính sách tồn
- `SCR-063` — Cấu hình hàng cận hạn
- `SCR-064` — Rà soát chính sách
- `SCR-065` — Kết quả cập nhật

## 5. UI composition lock

Chỉ dùng component/pattern hiện có trong Figma DS: `VAppBar`, `VNumberField`, `VSelect`, `DS v2 / Info Row`, `DS v2 / Key-value Row`, `VBanner`, `VButton`, `VToast`, result/state composition hiện hành. Không tạo CAP-specific core component.

## 6. Open integration gap

`BG-006` vẫn cần product decision cho entry chính thức, permission matrix và destination khi đóng. Cho tới khi khóa, prototype chỉ chứng minh task flow và UI behavior, không suy diễn information architecture production.
