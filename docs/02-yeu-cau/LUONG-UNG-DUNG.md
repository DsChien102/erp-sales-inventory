# Luồng ứng dụng sau khi gộp app (một app, hai khu vực)

> Phiên bản 1.0 · 2026-10-09 · Bổ sung cho [TH-01](TH-01-to-chuc-va-nguoi-dung.md) mục 1.2, 2.3, 5.11 và [PLAN](../refactor/PLAN.md) P2, P8.
> Tài liệu này mô tả **đường đi giữa các màn**. Nội dung từng màn (chuỗi UI, trạng thái, lỗi) vẫn lấy theo TH-01…TH-08.

## 1. Tổng quan

Trước đây có 2 app: `apps/erp` (cửa hàng) và `apps/admin` (Platform Admin), mỗi app một màn đăng nhập. Sau refactor chỉ còn `apps/erp`, chia 3 vùng:

| Vùng | Route | Ai dùng | Khung điều hướng |
|---|---|---|---|
| **Công khai** | `/login`, `/login/reset-password`, `/signup`, `/verify-email`, `/invitation` | Chưa đăng nhập (và người đang nhận lời mời) | Không có thanh dưới |
| **Cửa hàng** | `/`, `/orders…`, `/products…`, `/partners…`, `/more/**`, `/no-organization` | Owner, thành viên | Thanh dưới 5 tab: **Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm** |
| **Quản trị nền tảng** | `/admin/**` | Platform Admin | Thanh dưới 5 tab: **Tổng quan · Tổ chức · Người dùng · Nhật ký · Thêm** |

Nguyên tắc:
1. **Một màn đăng nhập** cho mọi người. Đăng nhập xong app tự đưa tới đúng vùng (mục 3).
2. **Không ai tạo tổ chức sau khi đăng nhập.** Tổ chức chỉ sinh ra từ "Đăng ký cửa hàng mới" (`/signup`). Khu `/admin` không có nút tạo tổ chức (BR-01).
3. Người vừa là Platform Admin vừa là thành viên cửa hàng chuyển vùng bằng **"Chuyển không gian"** (mục 7).
4. Router guard chỉ để ẩn / chuyển màn; quyền thật do RPC kiểm (BR-60).

```mermaid
flowchart LR
  subgraph PUB["Công khai"]
    L["/login"]
    S["/signup"]
    V["/verify-email"]
    I["/invitation"]
    R["/login/reset-password"]
  end
  subgraph STORE["Khu cửa hàng"]
    H["/ Trang chủ"]
    N["/no-organization"]
  end
  subgraph ADMIN["Khu quản trị nền tảng"]
    A["/admin Tổng quan"]
  end
  L -->|"đăng nhập"| ROUTE{"Định tuyến<br/>(mục 3)"}
  V -->|"xác minh xong"| ROUTE
  ROUTE --> H
  ROUTE --> N
  ROUTE --> A
  H <-->|"Chuyển không gian"| A
```

## 2. Ai thấy gì

| Người dùng | Vào được | Không thấy |
|---|---|---|
| Khách (chưa đăng nhập) | Vùng công khai | Mọi thứ khác → `/login` |
| Thành viên (không phải Owner) | Khu cửa hàng: 4 tab nghiệp vụ; "Thêm": Tài khoản của tôi, Thiết lập (phần được phép), Đăng xuất | Mục "Người dùng & vai trò", hồ sơ tổ chức, `/admin` |
| Owner | Như thành viên + **"Người dùng & vai trò"** (hồ sơ tổ chức, người dùng, vai trò, lịch sử quản trị), banner hồ sơ pháp lý | `/admin` |
| Platform Admin (không có tổ chức) | Chỉ khu `/admin` + Tài khoản của tôi | Khu cửa hàng (gõ `/` → về `/admin`) |
| Platform Admin + thành viên / Owner | Cả hai khu, chuyển bằng "Chuyển không gian" | — |
| Người không còn tổ chức nào | `/no-organization`, `/invitation` | Khu cửa hàng |

## 3. Mở app và định tuyến sau đăng nhập

Thay cho bảng TH-01 2.3, viết thành thứ tự kiểm (dừng ở dòng đầu tiên khớp):

```mermaid
flowchart TD
  START(["Mở app / vừa đăng nhập / vừa xác minh"]) --> AUTH{"Có phiên đăng nhập?"}
  AUTH -->|"Không"| LOGIN["/login"]
  AUTH -->|"Có"| SUSP{"Tài khoản bị tạm ngừng?"}
  SUSP -->|"Có"| OUT["Đăng xuất + thông báo<br/>'Tài khoản bị tạm ngừng'"] --> LOGIN
  SUSP -->|"Không"| PA{"Là Platform Admin?"}
  PA -->|"Có"| HASMEM{"Có tổ chức hoạt động?"}
  HASMEM -->|"Không"| ADM["/admin"]
  HASMEM -->|"Có"| LAST{"Khu dùng lần trước?"}
  LAST -->|"Quản trị"| ADM
  LAST -->|"Cửa hàng / chưa có"| BOOT
  PA -->|"Không"| BOOT["Bootstrap tổ chức:<br/>tổ chức chọn gần nhất,<br/>không hợp lệ → tổ chức hoạt động đầu tiên"]
  BOOT -->|"Tổ chức active"| HOME["/ Trang chủ"]
  BOOT -->|"Chỉ còn tổ chức tạm ngừng / đóng"| BLOCK["Màn ID-09<br/>Tổ chức không thể truy cập"]
  BOOT -->|"Không có tổ chức nào"| NOORG["/no-organization"]
```

Bảng guard đầy đủ (`core/router/route_guard.dart`):

| # | Điều kiện | Đang ở | Chuyển tới |
|---|---|---|---|
| G1 | Chưa đăng nhập | ngoài vùng công khai | `/login` |
| G2 | Đã đăng nhập | `/login`, `/signup`, `/verify-email` | vùng mặc định (G3–G6) |
| G3 | Platform Admin, không có tổ chức | khu cửa hàng | `/admin` |
| G4 | Không phải Platform Admin | `/admin/**` | `/` |
| G5 | Không có tổ chức (không phải Platform Admin) | khu cửa hàng (trừ `/no-organization`, `/invitation`) | `/no-organization` |
| G6 | Có tổ chức | `/no-organization` | `/` |
| — | Email chưa xác minh | — | **Không phải guard**: lúc này chưa có phiên. Màn đăng nhập nhận lỗi `email_not_confirmed` rồi chuyển `/verify-email` |
| — | Tổ chức bị tạm ngừng / đóng | — | Trang chủ hiện màn ID-09 (không đổi route) |

G1, G2, G5, G6 đã làm ở 2-B1. **G3, G4 làm ở P8.**

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
  R -->|"Đặt lại xong"| L2["/login + banner<br/>'Cập nhật mật khẩu thành công'"]
  I -->|"Tham gia xong"| L3["/login + banner<br/>'Tham gia tổ chức thành công'"]
```

### 4.2 Đăng ký cửa hàng mới (TH-01 EP-01)

```mermaid
flowchart LR
  S1["1/3 Tài khoản"] -->|"Tiếp tục"| S2["2/3 Cửa hàng"]
  S2 -->|"Quay lại (giữ dữ liệu)"| S1
  S2 -->|"Tạo cửa hàng<br/>(signUp, chưa có tổ chức)"| S3["3/3 Xác minh email"]
  S2 -->|"Email đã đăng ký"| EX["'Email đã được đăng ký'<br/>Đăng nhập / Quên mật khẩu"]
  S3 -->|"Nhập đúng mã<br/>(trigger tạo tổ chức)"| HOME["/ + toast 'Chào mừng…'"]
  S3 -->|"Thoát giữa chừng"| LATER["Lần sau đăng nhập → /verify-email"]
```

### 4.3 Nhận lời mời (TH-01 EP-03)

```mermaid
flowchart TD
  I["/invitation: nhập mã lời mời"] --> CHK{"Mã hợp lệ?"}
  CHK -->|"Không / hết hạn / đã dùng"| ERR["Thông báo theo mã lỗi"] --> I
  CHK -->|"Có"| ACC{"Email đã có tài khoản?"}
  ACC -->|"Chưa"| REG["Đăng ký: họ tên, mật khẩu<br/>(email lấy từ lời mời)"] --> OTP["Nhập mã xác minh email"] --> JOIN
  ACC -->|"Có"| PW["Nhập mật khẩu"] --> JOIN["Chấp nhận lời mời"]
  CHK -->|"Từ chối"| DEC["Đã từ chối"]
  JOIN --> DONE["/login + banner 'Tham gia tổ chức thành công'"]
```

Điểm vào `/invitation`: nút "Kích hoạt tài khoản" ở `/login`, và nút "Nhập mã lời mời" ở `/no-organization`.

## 5. Khu cửa hàng

```mermaid
flowchart TD
  NAV["Thanh dưới"] --> T1["Trang chủ"]
  NAV --> T2["Đơn hàng"]
  NAV --> T3["Sản phẩm"]
  NAV --> T4["Đối tác"]
  NAV --> T5["Thêm"]
  T1 --- BAN["Banner 'Bổ sung hồ sơ pháp lý'<br/>(chỉ Owner, chưa có MST)"]
  T1 --- SEL["Sheet chọn tổ chức<br/>(khi có nhiều tổ chức)"]
  T5 --> M1["Khách hàng & NCC · Đơn nhập · Kho · Báo cáo · Giá riêng"]
  T5 --> M2["Người dùng & vai trò (chỉ Owner)"]
  T5 --> M3["Tài khoản của tôi"]
  T5 --> M4["Thiết lập"]
  T5 --> M5["Chuyển sang Quản trị nền tảng<br/>(chỉ Platform Admin)"]
  T5 --> M6["Đăng xuất"]
  M2 --> U1["Hồ sơ tổ chức → Sửa / Hồ sơ pháp lý"]
  M2 --> U2["Người dùng: Thành viên / Lời mời<br/>→ Mời · Chi tiết lời mời · Chi tiết thành viên → Đổi vai trò"]
  M2 --> U3["Vai trò → Chi tiết vai trò"]
  M2 --> U4["Lịch sử quản trị → Chi tiết"]
  M3 --> A1["Sửa tài khoản · Đặt lại mật khẩu"]
```

Thay đổi so với app cửa hàng cũ:
- **Bỏ**: màn readiness `/more/readiness`, sheet "Kích hoạt tổ chức?", mục "Quyền sở hữu" trong hub (2-B3).
- **Thêm**: banner hồ sơ pháp lý (2-B1), trang Vai trò thật (2-B3), mục "Chuyển sang Quản trị nền tảng" (P8).
- Chuyển Owner **không** làm ở khu cửa hàng — chỉ Platform Admin ở `/admin` (BR-32).

## 6. Khu quản trị nền tảng (`/admin`, P8)

```mermaid
flowchart TD
  NAV["Thanh dưới /admin"] --> A1["Tổng quan<br/>/admin"]
  NAV --> A2["Tổ chức<br/>/admin/organizations"]
  NAV --> A3["Người dùng<br/>/admin/users"]
  NAV --> A4["Nhật ký<br/>/admin/audit-logs"]
  NAV --> A5["Thêm"]
  A2 --> D["Chi tiết tổ chức<br/>/admin/organizations/:id"]
  D --> D1["Tạm ngừng / Khôi phục / Đóng<br/>(nhập lý do)"]
  D --> D2["Chuyển chủ sở hữu<br/>/admin/organizations/:id/owner"]
  A3 --> UD["Chi tiết người dùng<br/>/admin/users/:id<br/>Tạm ngừng / Khôi phục / Gửi đặt lại mật khẩu"]
  A4 --> LD["Chi tiết nhật ký"]
  A5 --> X1["Tài khoản của tôi (dùng chung)"]
  A5 --> X2["Chuyển sang Cửa hàng<br/>(khi có tổ chức)"]
  A5 --> X3["Đăng xuất"]
```

Đối chiếu với `apps/admin`:

| `apps/admin` (cũ) | Sau gộp |
|---|---|
| `/login` riêng | Bỏ — dùng `/login` chung |
| Tab Tổng quan `/dashboard/home` | `/admin` |
| Tab Tổ chức `/dashboard/organizations`, `/:tenantId` | `/admin/organizations`, `/:id` |
| `/dashboard/organizations/new` (wizard khởi tạo) | **Bỏ** (BR-01) |
| "Gửi lại lời mời Owner", "Gửi lại kích hoạt" | **Bỏ** (không còn lời mời Owner) |
| Tab Người dùng `/dashboard/users`, `/:userId` | `/admin/users`, `/:id` |
| Tab Nhật ký `/dashboard/audit` | `/admin/audit-logs` |
| Tab Thêm `/dashboard/more` | Thêm: Tài khoản của tôi, Chuyển không gian, Đăng xuất |
| Bộ lọc "Mức hoàn thiện", nhãn "Đang thiết lập", cảnh báo "Email Chủ sở hữu chưa xác minh" | **Bỏ** (không còn `provisioning`) |

Thứ tự tab giữ giống app cũ trừ đổi chỗ "Tổ chức" lên trước "Người dùng" (tổ chức là việc chính của Platform Admin).

## 7. Chuyển không gian

- Hiện ở tab **Thêm** của cả hai khu, chỉ khi người dùng **vừa** là Platform Admin **vừa** có tổ chức hoạt động.
  - Khu cửa hàng: "Chuyển sang Quản trị nền tảng" → `/admin`.
  - Khu quản trị: "Chuyển sang Cửa hàng" → `/` (bootstrap tổ chức như mục 3).
- **Nhớ khu dùng lần trước** theo từng người dùng, lưu **trên máy** (shared preferences, khoá theo `userId`). Không thêm cột DB. Đăng xuất không xoá giá trị này; người khác đăng nhập dùng khoá riêng.
- Không chuyển được giữa chừng một thao tác chưa lưu: dùng cùng cơ chế "rời trang khi có thay đổi" của màn đang mở.

## 8. Mất quyền khi đang dùng (TH-01 US-04.2)

| Sự kiện | App làm gì |
|---|---|
| Tài khoản bị Platform Admin tạm ngừng | RPC kế tiếp lỗi `PLATFORM_USER_SUSPENDED` → đăng xuất, `/login` với thông báo tạm ngừng |
| Bị loại / tạm ngừng khỏi tổ chức đang dùng | Bootstrap lại: còn tổ chức khác → vào tổ chức đó; không còn → `/no-organization` |
| Tổ chức đang dùng bị tạm ngừng / đóng | Trang chủ hiện ID-09: "Chọn tổ chức khác" / "Đăng xuất" |
| Platform Admin bị gỡ quyền nền tảng | Đang ở `/admin` → guard G4 đưa về `/` (hoặc `/no-organization`) |

## 9. Việc cần làm để khớp tài liệu này

| Việc | Ở đâu |
|---|---|
| G1, G2, G5, G6; `/signup`, `/verify-email`, `/no-organization`; bỏ readiness | Đã làm: 2-B1, 2-B3 |
| `SessionController.isPlatformAdmin` (RPC kiểm quyền nền tảng); guard G3, G4 | P8 (8.1) |
| Shell `/admin` + 5 tab; chuyển màn từ `apps/admin` theo bảng mục 6 | P8 (8.1, 8.2) |
| "Chuyển không gian" + nhớ khu dùng lần trước | P8 (8.4) |
| Bỏ `apps/admin`, wizard khởi tạo, `provisioning` | P8 (8.6), P9 |
| Ô "Định tuyến" trong TH-01 2.3 trỏ sang mục 3 tài liệu này | Cập nhật TH-01 khi bắt đầu P8 |
