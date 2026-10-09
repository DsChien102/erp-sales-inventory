# Luồng ứng dụng sau khi gộp app

> Phiên bản 1.1 · 2026-10-09 · Bổ sung cho [TH-01](TH-01-to-chuc-va-nguoi-dung.md) mục 1.2, 2.3, EP-09 và [PLAN](../refactor/PLAN.md) P2, P8.
> v1.1: chốt **phương án A** — không có khu `/admin`; quản lý tổ chức nằm ở nhóm "Quản trị nền tảng" cuối tab Thêm ([ADMIN-SCREENS](../refactor/ADMIN-SCREENS.md)).
> Tài liệu này mô tả **đường đi giữa các màn**. Nội dung từng màn vẫn lấy theo TH-01…TH-08. Luồng đăng ký / xác minh / gửi lại mail: [LUONG-DANG-KY-XAC-MINH-EMAIL](LUONG-DANG-KY-XAC-MINH-EMAIL.md).

## 1. Tổng quan

Trước đây có 2 app: `apps/erp` (cửa hàng) và `apps/admin` (Platform Admin). Sau refactor chỉ còn `apps/erp`:

| Vùng | Route | Ai dùng | Khung |
|---|---|---|---|
| **Công khai** | `/login`, `/login/reset-password`, `/signup`, `/verify-email`, `/invitation` | Chưa đăng nhập (và người đang nhận lời mời) | Không có thanh dưới |
| **Cửa hàng** | `/`, đơn hàng, sản phẩm, đối tác, `/more/**`, `/no-organization` | Owner, thành viên, Platform Admin | Thanh dưới 5 tab: **Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm** |
| **Quản trị nền tảng** | `/more/platform/organizations`, `/:id`, `/:id/owner` | Chỉ Platform Admin | **Không có khung riêng**: các trang mở từ tab Thêm (hoặc từ `/no-organization`) |

Nguyên tắc:
1. **Một màn đăng nhập** cho mọi người.
2. **Không ai tạo tổ chức sau khi đăng nhập.** Tổ chức chỉ sinh ra từ `/signup` (BR-01).
3. Platform Admin chỉ **quản lý tổ chức**: tạm ngừng, khôi phục, đóng, chuyển chủ sở hữu. Không có tổng quan, người dùng nền tảng, nhật ký nền tảng trên app.
4. Router guard chỉ để ẩn / chuyển màn; quyền thật do RPC kiểm (BR-60).

```mermaid
flowchart LR
  subgraph PUB["Công khai"]
    L["/login"]
    S["/signup"]
    V["/verify-email"]
    I["/invitation"]
  end
  subgraph STORE["Cửa hàng (5 tab)"]
    H["/ Trang chủ"]
    M["Tab Thêm"]
    N["/no-organization"]
  end
  subgraph PLAT["Quản trị nền tảng (chỉ Platform Admin)"]
    O["/more/platform/organizations"]
  end
  L -->|"đăng nhập"| ROUTE{"Định tuyến<br/>(mục 3)"}
  V -->|"xác minh xong"| ROUTE
  ROUTE --> H
  ROUTE --> N
  M -->|"Quản trị nền tảng ▸ Tổ chức"| O
  N -->|"nút Quản trị nền tảng"| O
```

## 2. Ai thấy gì

| Người dùng | Vào được | Không thấy |
|---|---|---|
| Khách (chưa đăng nhập) | Vùng công khai | Mọi thứ khác → `/login` |
| Thành viên (không phải Owner) | Khu cửa hàng; tab Thêm: nghiệp vụ, Tài khoản của tôi, Thiết lập, Đăng xuất | "Người dùng & vai trò", "Quản trị nền tảng" |
| Owner | Như thành viên + **"Người dùng & vai trò"**, banner hồ sơ pháp lý | "Quản trị nền tảng" |
| Platform Admin có cửa hàng | Như vai trò của họ ở cửa hàng + nhóm **"Quản trị nền tảng"** cuối tab Thêm | — |
| Platform Admin không có cửa hàng | `/no-organization` có thêm nút **"Quản trị nền tảng"** → danh sách tổ chức | Khu cửa hàng |
| Người không còn tổ chức nào | `/no-organization`, `/invitation` | Khu cửa hàng |

## 3. Mở app và định tuyến sau đăng nhập

```mermaid
flowchart TD
  START(["Mở app / vừa đăng nhập / vừa xác minh"]) --> AUTH{"Có phiên đăng nhập?"}
  AUTH -->|"Không"| LOGIN["/login"]
  AUTH -->|"Có"| SUSP{"Tài khoản bị tạm ngừng?"}
  SUSP -->|"Có"| OUT["Đăng xuất + 'Tài khoản bị tạm ngừng'"] --> LOGIN
  SUSP -->|"Không"| BOOT["Bootstrap tổ chức:<br/>tổ chức chọn gần nhất,<br/>không hợp lệ → tổ chức hoạt động đầu tiên"]
  BOOT -->|"Tổ chức active"| HOME["/ Trang chủ"]
  BOOT -->|"Chỉ còn tổ chức tạm ngừng / đóng"| BLOCK["Màn ID-09<br/>Tổ chức không thể truy cập"]
  BOOT -->|"Không có tổ chức nào"| NOORG["/no-organization<br/>(Platform Admin: thêm nút 'Quản trị nền tảng')"]
```

Platform Admin **không** có nhánh định tuyến riêng: họ đi cùng đường với mọi người, chỉ thấy thêm lối vào "Quản trị nền tảng".

Bảng guard (`core/router/route_guard.dart`):

| # | Điều kiện | Đang ở | Chuyển tới | Làm ở |
|---|---|---|---|---|
| G1 | Chưa đăng nhập | ngoài vùng công khai | `/login` | 1-B |
| G2 | Đã đăng nhập | `/login`, `/signup`, `/verify-email` | `/` | 2-B1 |
| G5 | Không có tổ chức | khu cửa hàng (trừ `/no-organization`, `/invitation`, `/more/platform/**` nếu là Platform Admin) | `/no-organization` | 2-B1; ngoại lệ Platform Admin ở P8 |
| G6 | Có tổ chức | `/no-organization` | `/` | 2-B1 |
| G7 | Không phải Platform Admin | `/more/platform/**` | `/` | P8 |
| — | Email chưa xác minh | — | Không phải guard: màn đăng nhập nhận `email_not_confirmed` rồi chuyển `/verify-email` | 2-B1 |
| — | Tổ chức tạm ngừng / đóng | — | Trang chủ hiện ID-09 | có sẵn |

(G3, G4 của bản 1.0 — chuyển vào / ra khu `/admin` — đã bỏ.)

## 4. Vùng công khai

### 4.1 Đăng nhập

```mermaid
flowchart TD
  L["/login"] -->|"Đăng nhập"| C{"Kết quả"}
  C -->|"Thành công"| ROUTE["Định tuyến (mục 3)"]
  C -->|"Sai email / mật khẩu"| E1["Lỗi dưới form"] --> L
  C -->|"Email chưa xác minh"| V["/verify-email<br/>(gửi lại mã được ngay)"]
  C -->|"Tài khoản tạm ngừng"| E2["Thông báo tạm ngừng"] --> L
  L -->|"Quên mật khẩu?"| R["/login/reset-password"]
  L -->|"Đăng ký cửa hàng mới"| S["/signup"]
  L -->|"Kích hoạt tài khoản"| I["/invitation"]
  R -->|"Đặt lại xong"| L2["/login + 'Cập nhật mật khẩu thành công'"]
  I -->|"Tham gia xong"| L3["/login + 'Tham gia tổ chức thành công'"]
```

### 4.2 Đăng ký, xác minh, lời mời

Xem [LUONG-DANG-KY-XAC-MINH-EMAIL](LUONG-DANG-KY-XAC-MINH-EMAIL.md) (luồng A, B, C).

## 5. Khu cửa hàng

```mermaid
flowchart TD
  NAV["Thanh dưới"] --> T1["Trang chủ"]
  NAV --> T2["Đơn hàng"]
  NAV --> T3["Sản phẩm"]
  NAV --> T4["Đối tác"]
  NAV --> T5["Thêm"]
  T1 --- BAN["Banner 'Bổ sung hồ sơ pháp lý'<br/>(chỉ Owner, chưa có MST)"]
  T1 --- SEL["Sheet chọn tổ chức (nhiều tổ chức)"]
  T5 --> M1["Khách hàng & NCC · Đơn nhập · Kho · Báo cáo · Giá riêng"]
  T5 --> M2["Người dùng & vai trò (chỉ Owner)"]
  T5 --> M3["Tài khoản của tôi"]
  T5 --> M4["Thiết lập"]
  T5 --> M5["QUẢN TRỊ NỀN TẢNG ▸ Tổ chức<br/>(chỉ Platform Admin)"]
  T5 --> M6["Đăng xuất"]
  M2 --> U1["Hồ sơ tổ chức · Người dùng · Vai trò · Lịch sử quản trị"]
  M5 --> P1["Danh sách tổ chức (mục 6)"]
```

## 6. Quản trị nền tảng (P8)

```mermaid
flowchart TD
  IN1["Tab Thêm ▸ Quản trị nền tảng ▸ Tổ chức"] --> C1["C1 Danh sách tổ chức<br/>/more/platform/organizations<br/>tìm · chip Tất cả / Đang hoạt động / Tạm ngừng / Đã đóng"]
  IN2["/no-organization ▸ Quản trị nền tảng"] --> C1
  C1 --> C2["C2 Chi tiết tổ chức<br/>/more/platform/organizations/:id"]
  C2 -->|"Thao tác"| C3["C3 Sheet Thao tác"]
  C3 -->|"Tạm ngừng / Khôi phục / Đóng"| C4["C4 Xác nhận + Lý do *"]
  C4 --> C2
  C4 -.->|"phía cửa hàng"| C7["C7 Owner & thành viên thấy ID-09"]
  C3 -->|"Thay đổi chủ sở hữu"| C5["C5 Chọn thành viên đang hoạt động<br/>/more/platform/organizations/:id/owner"]
  C5 --> C6["C6 Xác nhận chuyển"]
  C6 --> C2
```

Chi tiết từng màn và phần bỏ so với `apps/admin`: [ADMIN-SCREENS](../refactor/ADMIN-SCREENS.md). Mã C1–C7 trùng với bảng thiết kế.

## 7. Mất quyền khi đang dùng (TH-01 US-04.2)

| Sự kiện | App làm gì |
|---|---|
| Tài khoản bị tạm ngừng (làm bằng SQL, không còn màn) | RPC kế tiếp lỗi `PLATFORM_USER_SUSPENDED` → đăng xuất, `/login` với thông báo tạm ngừng |
| Bị loại / tạm ngừng khỏi tổ chức đang dùng | Bootstrap lại: còn tổ chức khác → vào tổ chức đó; không còn → `/no-organization` |
| Tổ chức đang dùng bị Platform Admin tạm ngừng / đóng | Trang chủ hiện ID-09: "Chọn tổ chức khác" / "Đăng xuất" |
| Platform Admin bị gỡ quyền nền tảng | Nhóm "Quản trị nền tảng" biến mất; đang ở `/more/platform/**` → guard G7 về `/` |

## 8. Việc cần làm để khớp tài liệu này

| Việc | Ở đâu |
|---|---|
| G1, G2, G5, G6; `/signup`, `/verify-email`, `/no-organization`; bỏ readiness | Đã làm: 2-B1, 2-B3 |
| `SessionController.isPlatformAdmin`; guard G7; ngoại lệ G5 cho Platform Admin | P8 (8.1) |
| Trang C1, C2, C5 + sheet C3, C4, C6 | P8 (8.2) |
| Lối vào ở tab Thêm và `/no-organization` | P8 (8.3) |
| Chặn chuyển Owner cho người đã là Owner nơi khác (KI-08) | P8 (8.4) |
| Bỏ `apps/admin`, wizard khởi tạo, `provisioning` | P8 (8.6), P9 |
