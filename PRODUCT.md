# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Người dùng chính là **chủ (Owner)** phòng khám thú y hoặc cửa hàng bán lẻ thú y ở Việt Nam. Họ tự quản lý cửa hàng trên **iPhone** và **web ở máy tính** (chốt 2026-10-20): bán hàng, quản lý sản phẩm, khách hàng/nhà cung cấp, giá, hoá đơn điện tử, và quản trị tổ chức (mời thành viên, gán vai trò).

Thành viên (nhân viên) cũng dùng app nhưng là đối tượng phụ. Họ thấy khu cửa hàng giống Owner, trừ "Người dùng & vai trò". Nhân viên làm việc tay chân tại quầy / kho chủ yếu trên iPhone; Owner duyệt, quản trị và làm việc giá trị chủ yếu trên web.

## Product Purpose

Mosaic Retail là ERP multi-tenant cho phòng khám và cửa hàng thú y: một tổ chức có nhiều cửa hàng/chi nhánh. Người dùng tự đăng ký và tự tạo tổ chức, sau đó vận hành nghiệp vụ hằng ngày trong một app duy nhất (`apps/erp`).

Thành công nghĩa là Owner hoàn tất nghiệp vụ (lập đơn, thu tiền, phát hành hoá đơn, cập nhật sản phẩm/giá) nhanh, đúng, không cần người hỗ trợ.

Đây là **đồ án tốt nghiệp**: sản phẩm sẽ được demo và chấm bởi hội đồng, nên luồng chính phải dễ trình bày và dễ hiểu.

## Operating Context

- Ngôn ngữ giao diện: **tiếng Việt**. Trên UI, `Tenant` hiển thị là **Tổ chức** (hoặc **Cửa hàng** trong luồng đăng ký).
- Thiết bị: **iPhone** và **web trên trình duyệt máy tính**; Android build cùng mã nhưng không thiết kế / kiểm riêng; không iPad, không app desktop. **Cả hai đều là thiết bị chính**: mỗi màn thiết kế và tối ưu đủ cho iPhone và cho web, không có thiết bị phụ. Chi tiết: `docs/requirements/LUONG-UNG-DUNG.md` mục 1.1.
- Khung điều hướng: vùng công khai (`/login`, `/signup`, `/verify-email`, `/invitation`) không có thanh điều hướng; khu cửa hàng có 5 mục **Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm** — thanh dưới trên iPhone / cửa sổ hẹp, **thanh bên trái** trên web cửa sổ rộng (≥ 1024px). Chi tiết: `docs/requirements/LUONG-UNG-DUNG.md`.
- Nghiệp vụ theo theme: TH-01 tổ chức & người dùng, TH-02 sản phẩm & giá bán, TH-03 đối tác, TH-04 chính sách giá, TH-05 bán hàng & đơn hàng, TH-07 kho, TH-08 hoá đơn điện tử (MISA). Đặc tả chuẩn nằm trong `docs/requirements/TH-0X-*.md`.
- Tác vụ thực tế: in/chia sẻ phiếu và biên lai, quét barcode (camera trên iPhone, máy quét USB trên web), import Excel bảng giá (trên web kéo thả được), phát hành và gửi hoá đơn điện tử qua email.

## Capabilities and Constraints

- Stack: Flutter (Dart ≥ 3.11), flutter_bloc, go_router, get_it; backend Supabase (Auth, Postgres, Storage, Edge Functions). Target thiết kế: iOS (iPhone) và web; Android build được, xếp sau.
- Design system nội bộ: package `c45_design_system`.
- Không có quản trị nền tảng (Platform Admin) trong app; chỉ có Owner và thành viên. Quyền thật do RPC kiểm, router guard chỉ ẩn/chuyển màn.
- Tổ chức chỉ được tạo từ `/signup`; không ai tạo tổ chức sau khi đăng nhập.
- Đang refactor kiến trúc (branch `refactor/simple-arch`): giữ nguyên hành vi người dùng thấy; thiết kế lại UI/UX nằm ngoài phạm vi đợt này, trừ luồng khởi tạo tổ chức (TH-01), Theme 7 Kho & Giá vốn, và **bố cục web** của mọi màn (khung thanh bên, danh sách – chi tiết, bảng, hộp thoại — PLAN mục "Web cho app"; nội dung và chữ không đổi).
- Theme 7 (`apps/erp/lib/features/inventory`) được chỉnh lại UI/UX **trên nền thiết kế hiện tại**: giữ DESIGN.md (màu, chữ, token), không đổi sang phong cách mới. Sửa bố cục, thứ bậc thông tin, mật độ, trạng thái và lối đi giữa các màn.
- Thành phần UI của Theme 7 lấy từ `c45_design_system`. Khi DS chưa có thành phần phù hợp thì **thêm mới vào `c45_design_system`** (dựng từ token có sẵn, đặt tên `V…` như các thành phần khác), không dựng widget riêng trong feature.
- Ngoài phạm vi hiện tại: TH-06 công nợ đầy đủ, báo cáo (TH-10).

## Brand Commitments

- Tên sản phẩm: **Mosaic Retail**.

## Evidence on Hand

- Đặc tả yêu cầu: `docs/requirements/` (TH-01…TH-08, luồng ứng dụng, luồng đăng ký/xác minh email).
- Không có khách hàng thật, testimonial, số liệu sử dụng hay bảng giá thương mại. Không được bịa các thông tin này.

## Product Principles

1. **Owner tự làm được mọi thứ, trên iPhone hoặc máy tính**: mỗi tác vụ hằng ngày hoàn tất được trên cả iPhone lẫn máy tính, với bố cục hợp từng thiết bị, không cần người hỗ trợ, không ngõ cụt.
2. **Đúng nghiệp vụ trước, đẹp sau**: số tiền, tồn kho, giá và hoá đơn phải rõ ràng, khó nhập sai.
3. **Dễ trình bày**: luồng chính đi thẳng, ít nhánh, để demo trước hội đồng mạch lạc.
4. **Đặc tả là chuẩn**: hành vi và chuỗi chữ trên UI theo `docs/requirements`, không tự ý đổi. Riêng Theme 7: nghiệp vụ (BJ / UC) và chuỗi chữ theo `specs/themes/theme-07`; **luồng, điều hướng và bố cục màn (UIF / Screen Contract) được thiết kế lại** trên prototype HTML `specs/themes/theme-07/03.design/prototype/html`, Screen Contract sửa theo sau. Spec hiện tại và các Hub cũ là đầu vào tham khảo, không phải đáp án.
