---
id: PAT-NAV
type: design-pattern
theme: theme-07
title: "Navigation areas"
owner: BA
status: FROZEN
frozen_at: v5.27.0
source_baseline: v5.27.0
---
# PAT-NAV — Navigation areas

## 1. Vấn đề cần giải quyết

Quy định cấu trúc điều hướng, lối vào ứng dụng và kiến trúc thông tin cho phân hệ Kho (Theme 7).

## 2. Khi nào dùng

Áp dụng khi thiết kế, triển khai hoặc kiểm thử luồng điều hướng, thanh điều hướng chính, cây màn hình và các điểm vào (entry points) của Kho trên cả thiết bị di động (iPhone) và máy tính (Web).

## 3. Khi nào không dùng

Không áp dụng để thay thế phân rã nghiệp vụ của các Business Journey (BJ) hoặc quy tắc bảo mật RPC.

## 4. Hành vi bắt buộc

### 1. Lối vào Kho

Kho là một phân hệ trong ứng dụng bán hàng và quản lý tổng thể VET45:
- **Trên iPhone:** Kho nằm trong tab "Thêm" của thanh điều hướng đáy 5 tab (`VET45BottomNavigation`: Trang chủ, Đơn hàng, Sản phẩm, Đối tác, Thêm). Bấm dòng "Kho" trong màn Thêm để mở Home Kho (`SCR-090`).
- **Trên Web:** Kho là mục con của "Thêm" trên thanh bên trái (Web sidebar). Bấm "Kho" để mở Home Kho (`SCR-090`).

### 2. Vị trí trên Home Kho (SCR-090)

Home Kho (`SCR-090`) là hub điều hướng chính, tổ chức theo mức độ ưu tiên và tần suất sử dụng:

| Vị trí | Nghiệp vụ / Màn đích | Cách tới |
|---|---|---|
| 4 nút nhanh | `SCR-007` (Nhận hàng), `SCR-025` (Lấy hàng), `SCR-042` (Kiểm kê), `SCR-001` (Tra cứu tồn) | 1 chạm |
| Cần chú ý (chỉ khi có việc) | Chờ duyệt (mở `SCR-011` hoặc màn duyệt tương ứng), "Hàng cần xử lý" (`SCR-036`), "Hồ sơ cần kiểm tra" (`SCR-078`) | 1 chạm |
| Quản lý kho → Tồn kho (`SCR-091`) | `SCR-001` (Tồn kho & khả dụng), `SCR-062` (Chính sách tồn & cận hạn) | Lớp thứ hai |
| Quản lý kho → Nhập, xuất & hoàn trả (`SCR-092`) | `SCR-007` (Nhận hàng), `SCR-025` (Lấy & bàn giao), `SCR-030` (Hàng khách trả), `SCR-036` (Trả nhà cung cấp) | Lớp thứ hai |
| Quản lý kho → Kiểm kê & xử lý (`SCR-093`) | `SCR-042` (Kiểm kê kho), `SCR-036` (Hàng cần xử lý), `SCR-048` (Hủy & sửa sai nghiệp vụ), `SCR-078` (Đối soát sai lệch) | Lớp thứ hai |
| Quản lý kho → Giá trị kho (`SCR-094`) | `SCR-014` (Hàng chờ xác lập giá trị), `SCR-085` (Điều chỉnh giá trị hàng nhập), `SCR-072` (Giá vốn) — chỉ Chủ cửa hàng | Lớp thứ hai |
| Quản lý kho → Báo cáo & lịch sử (`SCR-095`) | `SCR-055` (Báo cáo tồn & thẻ kho) | Lớp thứ hai |
| Thiết lập kho (`SCR-096`) | `SCR-066` (Khởi tạo tồn đầu kỳ — chỉ Chủ cửa hàng), `SCR-062` (Chính sách tồn & cận hạn) | Sâu |

### 3. Mỗi BJ bắt đầu ở nơi việc phát sinh

Mỗi BJ bắt đầu ở nơi việc phát sinh, menu Kho là đường phụ:
- `BJ-04`, `BJ-05`, `BJ-06` bắt đầu từ ngữ cảnh Đơn hàng bán.
- `BJ-07` bắt đầu từ đơn mua hàng / trả hàng.
- `BJ-03` bắt đầu ngay sau khi nhận hàng xong (`SCR-012`).
- `BJ-16`, `BJ-17` bắt đầu từ cảnh báo hoặc sai lệch đối soát.
- `BJ-09`, `BJ-10` bắt đầu từ danh sách hàng hoặc lô có vấn đề.

Kho không phải là điểm bắt đầu duy nhất của mọi thao tác kho, mà là trung tâm tác nghiệp tại chỗ và rà soát tổng hợp.

### 4. Các Workspace quản lý kho (SCR-091…SCR-096)

Thay thế phân loại NAV-01…06 trước đây bằng 6 workspace chuẩn:
- [`SCR-091` — Tồn kho](../screens/SCR-091.md): Tra cứu số lượng, khả dụng, lô và chính sách tồn.
- [`SCR-092` — Nhập, xuất & hoàn trả](../screens/SCR-092.md): Tác nghiệp nhận hàng, lấy hàng giao đơn, hàng khách trả, trả nhà cung cấp.
- [`SCR-093` — Kiểm kê & xử lý](../screens/SCR-093.md): Đếm kiểm kê, xử lý hàng lỗi/cận hạn, hủy/sửa sai giao dịch và điều tra sai lệch.
- [`SCR-094` — Giá trị kho](../screens/SCR-094.md): Xác lập giá nhập, điều chỉnh giá trị hàng nhập và kỳ tính giá vốn (dành riêng cho Chủ cửa hàng).
- [`SCR-095` — Báo cáo & lịch sử](../screens/SCR-095.md): Báo cáo tồn kho theo thời điểm và thẻ kho chi tiết.
- [`SCR-096` — Thiết lập kho](../screens/SCR-096.md): Khởi tạo số dư tồn kho ban đầu và cấu hình chính sách cảnh báo.

## 5. Bố cục / tương tác chuẩn

Xem chi tiết tại từng Screen Contract tương ứng.

**Màn kết quả (K4, `RESULT`) và thanh điều hướng của app:**
Ở chế độ Toàn Theme 7 trên **iPhone**, màn kết quả hiện thanh 5 tab của app (Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm) để luôn có lối về nhanh ngoài các nút ở chân; các màn đang thao tác trong luồng không hiện thanh dưới để tránh rời luồng dở dang. Khung **Web** luôn có thanh bên trái để chuyển đổi khu vực làm việc.

## 6. Phần được phép thay đổi

Chỉ dữ liệu/copy/variant được nghiệp vụ và Design System cho phép.

## 7. Mapping với Design System

Xem [`../design-system/design-system-profile.md`](../design-system/design-system-profile.md).

## 8. Screen tham chiếu

- [`SCR-090` — Kho](../screens/SCR-090.md)
- [`SCR-091` — Tồn kho](../screens/SCR-091.md)
- [`SCR-092` — Nhập, xuất & hoàn trả](../screens/SCR-092.md)
- [`SCR-093` — Kiểm kê & xử lý](../screens/SCR-093.md)
- [`SCR-094` — Giá trị kho](../screens/SCR-094.md)
- [`SCR-095` — Báo cáo & lịch sử](../screens/SCR-095.md)
- [`SCR-096` — Thiết lập kho](../screens/SCR-096.md)
