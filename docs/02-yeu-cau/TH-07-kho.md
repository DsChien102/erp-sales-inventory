# TH-07 — Kho & Giá vốn

> **Source of truth:** spec v1 đầy đủ tại [`specs/themes/theme-07`](../../specs/themes/theme-07/README.md) (Theme 07 — Kho & Giá vốn, v4.6.8, FROZEN). **Không viết lại, không cắt MVP** (quyết định 2026-10-07).
> **Ngày:** 2026-10-07 · **Trạng thái code:** chưa làm. Hiện chỉ có tồn kho cơ bản trong `catalog` (thuộc TH-02) và module `modules/inventory` mới tạo "cặp cửa hàng–kho mặc định".
> **Kế hoạch:** làm ở phase riêng **sau refactor** (P11), viết thẳng theo kiến trúc đơn giản (Page → Cubit → Repository → RPC).

File này chỉ để đánh số cho đủ bộ tài liệu, và ghi những chỗ các theme khác chạm vào Theme 7.

---

## 1. Đọc spec v1 ở đâu

| Cần | Đọc |
|---|---|
| Phạm vi, quyết định | `README.md`, `01.knowledge/decisions/decision-register.md` |
| Tri thức nghiệp vụ | `01.knowledge/know-how/` (46 bài KB-KGV) |
| Hành trình, use case | `02.specification/behavior/journeys/00-business-journey-map.md` (17 BJ), `use-cases/` (65 UC), `behavioral-contracts/` |
| Mô hình miền | `02.specification/domain/` (aggregate, entity, read model, `INT-01` liên theme) |
| Thiết kế | `03.design/flows/` (17 UIF), `03.design/screens/` (96 SCR), `03.design/prototype/html/` |
| Chia việc | `04.harness/` |

## 2. Điểm chạm với các theme khác

Khi làm Theme 7 phải tuân theo `INT-01` và các behavioral contract dưới đây. Các theme đã xong cần sửa đúng những chỗ này.

| Theme | Điểm chạm | Contract v1 | Hiện trạng code |
|---|---|---|---|
| TH-02 Sản phẩm | Tồn kho cơ bản (`catalog.product_stock_profiles`, `product_stock_movements`) được thay bằng sổ tồn của Theme 7. Tồn khởi tạo chuyển sang BJ-12 | BJ-12, KB-KGV-022 | Đang dùng tồn cơ bản |
| TH-05 Bán hàng | Hoàn tất đơn POS phải xuất kho nguyên tử cùng checkout. Không đủ khả dụng thì chặn | `BC-IO-04` (Complete online POS checkout), UC-05-05 | Chưa trừ tồn (TH-05 KI-01) |
| TH-05 Bán hàng | Huỷ đơn: hoàn nguyên xuất kho | `BC-IO-13`, UC-11-05 | Chưa |
| TH-05 Bán hàng | Khách trả hàng: nhận hàng trả và phân loại | `BC-IO-07`, UC-06-03/04 | Chưa; hàng trả không cộng tồn |
| TH-05 Bán hàng | Hiển thị khả dụng khi chọn sản phẩm | `BC-IO-01`, UC-01-02 | Đọc tồn cơ bản qua `search_sellable_products` |
| TH-04 Giá | Nhận cost basis để tham chiếu giá bán | KB-KGV-044, `INT-01` | Chưa |
| TH-03 Đối tác | Nhà cung cấp cho nhận hàng / trả NCC | BJ-02, BJ-07 | Partner có vai trò supplier |

## 3. Lỗi đã thấy trong tồn kho cơ bản hiện tại

Đã chuyển sang [TH-02 mục 7.3](TH-02-san-pham-va-gia-ban.md#73-vấn-đề-đã-biết-và-quyết-định) (cùng mã KI-01…KI-07, sửa ở P3 PR 3.5). Bảng dưới giữ để tra nhanh.

| Mã | Vấn đề |
|---|---|
| KI-01 | `actor_id` của biến động tồn và lịch sử sản phẩm ghi `tenant_id` thay vì người thao tác (`adjust_basic_stock`, `set_basic_stock_quantity_base`) |
| KI-02 | `expected_quantity` tuỳ chọn: gọi thiếu thì ghi đè không kiểm |
| KI-03 | `get_product_stock_history` có handler nhưng không màn nào gọi; trả 8 ký tự UUID thay tên |
| KI-04 | Màn điều chỉnh có câu "Ở Growth, tồn được đọc từ module Kho (read-only)" |
| KI-05 | Điều chỉnh về đúng số đang có vẫn ghi biến động chênh lệch 0 |
| KI-06 | `set_basic_stock_quantity_base` không kiểm version |
| KI-07 | Lỗi hiện chuỗi exception thô; page gọi module trực tiếp, không cubit |
