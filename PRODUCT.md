# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Người dùng chính là **chủ (Owner)** phòng khám thú y hoặc cửa hàng bán lẻ thú y ở Việt Nam. Họ tự quản lý cửa hàng trên điện thoại: bán hàng, quản lý sản phẩm, khách hàng/nhà cung cấp, giá, hoá đơn điện tử, và quản trị tổ chức (mời thành viên, gán vai trò).

Thành viên (nhân viên) cũng dùng app nhưng là đối tượng phụ. Họ thấy khu cửa hàng giống Owner, trừ "Người dùng & vai trò".

## Product Purpose

VET45 là ERP multi-tenant cho phòng khám và cửa hàng thú y: một tổ chức có nhiều cửa hàng/chi nhánh. Người dùng tự đăng ký và tự tạo tổ chức, sau đó vận hành nghiệp vụ hằng ngày trong một app duy nhất (`apps/erp`).

Thành công nghĩa là Owner hoàn tất nghiệp vụ (lập đơn, thu tiền, phát hành hoá đơn, cập nhật sản phẩm/giá) nhanh, đúng, không cần người hỗ trợ.

Đây là **đồ án tốt nghiệp**: sản phẩm sẽ được demo và chấm bởi hội đồng, nên luồng chính phải dễ trình bày và dễ hiểu.

## Operating Context

- Ngôn ngữ giao diện: **tiếng Việt**. Trên UI, `Tenant` hiển thị là **Tổ chức** (hoặc **Cửa hàng** trong luồng đăng ký).
- Khung điều hướng: vùng công khai (`/login`, `/signup`, `/verify-email`, `/invitation`) không có thanh dưới; khu cửa hàng có thanh dưới 5 tab **Trang chủ · Đơn hàng · Sản phẩm · Đối tác · Thêm**. Chi tiết: `docs/02-yeu-cau/LUONG-UNG-DUNG.md`.
- Nghiệp vụ theo theme: TH-01 tổ chức & người dùng, TH-02 sản phẩm & giá bán, TH-03 đối tác, TH-04 chính sách giá, TH-05 bán hàng & đơn hàng, TH-07 kho, TH-08 hoá đơn điện tử (MISA). Đặc tả chuẩn nằm trong `docs/02-yeu-cau/TH-0X-*.md`.
- Tác vụ thực tế: in/chia sẻ phiếu và biên lai, quét barcode, import Excel bảng giá, phát hành và gửi hoá đơn điện tử qua email.

## Capabilities and Constraints

- Stack: Flutter (Dart ≥ 3.11), flutter_bloc, go_router, get_it; backend Supabase (Auth, Postgres, Storage, Edge Functions). Repo cũng build được web, nhưng thiết kế nhắm iOS và Android.
- Design system nội bộ: package `vet45_design_system`.
- Không có quản trị nền tảng (Platform Admin) trong app; chỉ có Owner và thành viên. Quyền thật do RPC kiểm, router guard chỉ ẩn/chuyển màn.
- Tổ chức chỉ được tạo từ `/signup`; không ai tạo tổ chức sau khi đăng nhập.
- Đang refactor kiến trúc (branch `refactor/simple-arch`): giữ nguyên hành vi người dùng thấy; thiết kế lại UI/UX nằm ngoài phạm vi đợt này, trừ luồng khởi tạo tổ chức (TH-01).
- Ngoài phạm vi hiện tại: TH-06 công nợ đầy đủ, báo cáo (TH-10), kiểm kê/giá vốn đầy đủ.

## Brand Commitments

- Tên sản phẩm: **VET45**.

## Evidence on Hand

- Đặc tả yêu cầu: `docs/02-yeu-cau/` (TH-01…TH-08, luồng ứng dụng, luồng đăng ký/xác minh email).
- Không có khách hàng thật, testimonial, số liệu sử dụng hay bảng giá thương mại. Không được bịa các thông tin này.

## Product Principles

1. **Owner tự làm được mọi thứ trên điện thoại**: mỗi tác vụ hằng ngày hoàn tất được không cần máy tính hay người hỗ trợ.
2. **Đúng nghiệp vụ trước, đẹp sau**: số tiền, tồn kho, giá và hoá đơn phải rõ ràng, khó nhập sai.
3. **Dễ trình bày**: luồng chính đi thẳng, ít nhánh, để demo trước hội đồng mạch lạc.
4. **Đặc tả là chuẩn**: hành vi và chuỗi chữ trên UI theo `docs/02-yeu-cau`, không tự ý đổi.
