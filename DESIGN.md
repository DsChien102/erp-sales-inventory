---
name: Mosaic Retail
description: ERP cho phòng khám và cửa hàng thú y, gọn như một quầy thuốc ngăn nắp.
colors:
  clinic-leaf-green: "#2F7A3A"
  clinic-leaf-green-hover: "#26612F"
  clinic-leaf-green-pressed: "#1F4D26"
  clinic-leaf-text: "#26612F"
  leaf-wash: "#E8F6EC"
  leaf-wash-pressed: "#DCEFDE"
  leaf-border: "#B8DFBD"
  counter-white: "#FFFFFF"
  shelf-gray: "#F6F8F9"
  hover-gray: "#F8FAFB"
  hairline: "#E5E8EB"
  hairline-strong: "#D0D5DA"
  input-border: "#868E98"
  ink: "#0E1116"
  ink-secondary: "#4A535E"
  ink-muted: "#6B7480"
  amber-warning: "#935A0A"
  amber-wash: "#FDF3E0"
  alert-red: "#B53232"
  alert-wash: "#FBE8E8"
  info-blue: "#2559C4"
  info-wash: "#E8F0FC"
typography:
  display:
    fontFamily: "Inter"
    fontSize: "40px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-1px"
  headline:
    fontFamily: "Inter"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.43
    letterSpacing: "-0.5px"
  title-lg:
    fontFamily: "Inter"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.45
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Inter"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.44
    letterSpacing: "-0.2px"
  body:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.57
  body-sm:
    fontFamily: "Inter"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.54
  label:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.43
  caption:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.5
  label-sm:
    fontFamily: "Inter"
    fontSize: "11px"
    fontWeight: 600
    lineHeight: 1.45
  numeric:
    fontFamily: "JetBrains Mono"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.43
rounded:
  r4: "4px"
  r6: "6px"
  r8: "8px"
  r12: "12px"
  r16: "16px"
  r20: "20px"
  pill: "999px"
spacing:
  space1: "4px"
  space2: "8px"
  space3: "12px"
  space4: "16px"
  space5: "20px"
  space6: "24px"
  space8: "32px"
  space10: "40px"
  space12: "48px"
  space18: "72px"
components:
  button-primary:
    backgroundColor: "{colors.clinic-leaf-green}"
    textColor: "{colors.counter-white}"
    typography: "{typography.label}"
    rounded: "{rounded.r8}"
    padding: "0 16px"
    height: "44px"
  button-primary-pressed:
    backgroundColor: "{colors.clinic-leaf-green-hover}"
  button-secondary:
    backgroundColor: "{colors.counter-white}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.r8}"
    padding: "0 16px"
    height: "44px"
  button-secondary-pressed:
    backgroundColor: "{colors.shelf-gray}"
  button-tertiary:
    textColor: "{colors.clinic-leaf-text}"
    typography: "{typography.label}"
    rounded: "{rounded.r8}"
    padding: "0 16px"
    height: "44px"
  button-tertiary-pressed:
    backgroundColor: "{colors.leaf-wash}"
  input:
    backgroundColor: "{colors.counter-white}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.r8}"
    padding: "8px 12px"
    height: "44px"
  card:
    backgroundColor: "{colors.counter-white}"
    rounded: "{rounded.r12}"
    padding: "16px"
  card-brand:
    backgroundColor: "{colors.leaf-wash}"
    rounded: "{rounded.r12}"
    padding: "16px"
  chip:
    backgroundColor: "{colors.leaf-wash}"
    textColor: "{colors.clinic-leaf-green}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.pill}"
    padding: "0 12px"
  badge:
    textColor: "{colors.clinic-leaf-green}"
    typography: "{typography.caption}"
    rounded: "{rounded.pill}"
  bottom-nav:
    backgroundColor: "{colors.counter-white}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.label-sm}"
    height: "50px"
  bottom-nav-active:
    textColor: "{colors.clinic-leaf-green}"
  side-nav:
    backgroundColor: "{colors.counter-white}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.body}"
    width: "240px"
    borderRight: "{colors.hairline}"
  side-nav-active:
    backgroundColor: "{colors.leaf-wash}"
    textColor: "{colors.clinic-leaf-green}"
    indicatorColor: "{colors.clinic-leaf-green}"
  app-bar:
    backgroundColor: "{colors.counter-white}"
    textColor: "{colors.ink}"
    typography: "{typography.title}"
---

# Design System: Mosaic Retail

## Overview

**Creative North Star: "The Tidy Counter"**

Mosaic Retail là một quầy thuốc thú y ngăn nắp: mọi thứ cần dùng đều trong tầm tay, đặt đúng chỗ, không có gì thừa trên mặt quầy. Owner mở app giữa lúc đang bán hàng hoặc tiếp khách, nên giao diện phải để họ thấy ngay số tiền, tồn kho, trạng thái đơn và bấm đúng hành động trong một lần nhìn.

Hệ thống tiết chế và tinh gọn. Nền xám lạnh nhạt (Shelf Gray) làm mặt quầy, các khối trắng (Counter White) là khay đựng, viền mảnh 1px phân ngăn thay cho bóng đổ. Màu xanh lá Clinic Leaf Green là nhãn dán duy nhất trên quầy: nó đánh dấu hành động chính và trạng thái đang chọn, không dùng để trang trí. Vàng, đỏ, xanh dương chỉ xuất hiện khi có điều cần báo.

Trên iPhone mật độ ở mức thoải mái cho ngón tay (comfortable): control cao 44px, vùng chạm tối thiểu 44px. Trên web ở máy tính (chuột, bàn phím) dùng mật độ gọn (compact) và màn rộng có thanh bên; cùng màu, chữ, token. Chữ Inter đậm hơn mặc định một bậc (w500 cho chữ thân) để đọc rõ trên điện thoại dưới ánh đèn cửa hàng. Số liệu tài chính và mã dùng JetBrains Mono khi cần căn thẳng cột.

**Key Characteristics:**
- Một màu nhấn duy nhất (Clinic Leaf Green), còn lại là thang xám lạnh.
- Phẳng: phân lớp bằng nền xám / khối trắng / viền mảnh; bóng đổ chỉ khi cần nhấn mạnh.
- Bo góc vừa phải: 8px cho control, 12px cho thẻ, 16px cho sheet, tròn hẳn cho chip/badge.
- Vùng chạm ≥ 44px, chữ thân 14px w500.
- Giao diện sáng là mặc định đang chạy; bảng màu tối đã định nghĩa nhưng app chưa bật.

## Colors

Một xanh lá phòng khám trên nền xám lạnh, với ba màu trạng thái chỉ dùng khi có thông tin cần báo.

### Primary
- **Clinic Leaf Green** (#2F7A3A, 5.3:1 với chữ trắng): nút chính, tab đang chọn ở thanh dưới, viền ô nhập khi focus, con trỏ nhập, link. Cũng là màu **success** (badge, thẻ trạng thái thành công dùng chung màu này).
- **Clinic Leaf Green Hover / Pressed** (#26612F / #1F4D26): trạng thái nhấn của nút chính.
- **Clinic Leaf Text** (#26612F): chữ mang màu thương hiệu (nút tertiary, nhãn nhấn) để đạt tương phản trên nền trắng.
- **Leaf Wash** (#E8F6EC): nền thẻ tông thương hiệu, nền khi nhấn nút tertiary, nền vòng focus của ô nhập, nền trạng thái success.
- **Leaf Border** (#B8DFBD): viền thẻ tông thương hiệu, màu vòng focus.

### Secondary
- **Amber Warning** (#935A0A; hover #70450C, pressed #53330D) trên **Amber Wash** (#FDF3E0): cảnh báo, việc cần xử lý. Ngả nâu có chủ đích để đạt 5.66:1 trên trắng, 5.14:1 trên wash.
- **Alert Red** (#B53232; hover #922828, pressed #701F1F) trên **Alert Wash** (#FBE8E8): lỗi, thao tác nguy hiểm (xoá, huỷ), ô nhập sai.
- **Info Blue** (#2559C4; hover #1E479E, pressed #183878) trên **Info Wash** (#E8F0FC): thông tin trung tính, gợi ý.

### Neutral
- **Counter White** (#FFFFFF): bề mặt thẻ, app bar, thanh dưới, ô nhập, nút secondary.
- **Shelf Gray** (#F6F8F9): nền trang phía sau các thẻ; cũng là nền nhấn của nút secondary.
- **Hover Gray** (#F8FAFB): nền hover nhẹ.
- **Hairline** (#E5E8EB): đường kẻ chia vùng (dưới app bar, trên thanh dưới), viền control **vô hiệu**.
- **Hairline Strong** (#D0D5DA): viền thẻ trung tính, viền trang trí cần rõ hơn.
- **Input Border** (#868E98, 3.31:1 trên trắng): ranh giới control — ô nhập, ô chọn, ô ngày, ô mã, checkbox, radio (token `borderInput`).
- **Ink** (#0E1116): chữ chính, tiêu đề.
- **Ink Secondary** (#4A535E, 7.81:1): chữ phụ, mô tả, icon tab chưa chọn.
- **Ink Muted** (#6B7480, 4.74:1 trên trắng): placeholder, gợi ý, chữ cấp ba. Chỉ đặt trên Counter White (thẻ, ô nhập, sheet), không đặt thẳng trên Shelf Gray (4.44:1).

### Named Rules
**The One Sticker Rule.** Clinic Leaf Green là nhãn dán duy nhất trên quầy. Mỗi màn chỉ một hành động chính mang nền xanh; mọi hành động khác là secondary hoặc tertiary.

**The Semantic-Only Rule.** Component, app và module chỉ lấy màu qua `context.vColors` (bảng màu ngữ nghĩa). Không dùng `VColors.*` (bảng màu gốc) ngoài theme builder và trang preview token, nếu không chế độ tối và đổi theme sẽ không áp dụng.

**The Status Earns Color Rule.** Vàng, đỏ, xanh dương chỉ xuất hiện khi có trạng thái thật cần báo. Không dùng chúng để phân loại hay trang trí.

**The 4.5 Floor Rule.** Mọi chữ và icon mang màu ở theme sáng đạt 4.5:1 trên nền nó đặt lên (cả nền wash của chính tone đó); ranh giới control đạt 3:1. `test/theme/v_color_scheme_contrast_test.dart` khoá quy tắc này — đổi màu thì test phải còn xanh.

## Typography

**Display Font:** Inter (gói kèm trong `c45_design_system`)
**Body Font:** Inter
**Label/Mono Font:** JetBrains Mono, cùng cỡ và vai trò với bản Inter tương ứng

**Character:** Inter rõ ràng, trung tính, hỗ trợ tốt dấu tiếng Việt. Toàn hệ thống đậm hơn mặc định một bậc, tiêu đề siết chữ nhẹ (letter-spacing âm) cho cảm giác chắc gọn.

### Hierarchy
- **Display** (800, 40px, 44px): con số lớn đơn lẻ, ví dụ tổng tiền nổi bật. Hiếm dùng. **Chỉ chứa số**: dòng quá chật cho dấu tiếng Việt.
- **Headline** (700, 28px, 40px): tiêu đề trang lớn.
- **Title Large** (700, 22px, 32px): tiêu đề khu vực.
- **Title** (600, 18px, 26px): tiêu đề thẻ; app bar dùng cỡ này ở weight 700.
- **Body** (500, 14px, 22px): chữ thân, giá trị trong ô nhập.
- **Body Small** (500, 13px, 20px): chữ phụ, nhãn chip, mô tả dưới tiêu đề.
- **Label** (600, 14px, 20px): nhãn form, chữ trên nút và link. Tiêu đề nhỏ (`headingH4`) dùng cùng thông số.
- **Caption** (600, 12px, 18px): chú thích, badge nhỏ.
- **Label Small** (600, 11px, 16px): badge trạng thái, nhãn chật chỗ.

### Named Rules
**The Tabular Figures Rule.** Mọi vai trò Inter bật `tnum`: chữ số cùng bề rộng, nên số tiền và số lượng tự thẳng cột ở bất kỳ style nào.

**The Mono for Money Rule.** Khi cả chuỗi (mã, SKU, số tiền kèm ký hiệu) cần căn thẳng cột theo từng ký tự (bảng, danh sách dòng hàng), dùng biến thể JetBrains Mono cùng vai trò thay vì Inter. Bản mono có cùng chiều cao dòng với bản Inter.

**The Stacked Marks Rule.** Dấu chồng tiếng Việt (Ẫ, Ỗ, Ặ) cao hơn ascender của Inter. Từ Title trở lên, chiều cao dòng ≥ 1.43 × cỡ chữ để dấu không bị cắt hay đè lên dòng trên; không hạ line-height của token. `test/tokens/v_typography_test.dart` vẽ chữ thật để khoá quy tắc này.

## Layout

Hai thiết bị: **iPhone** và **web trên máy tính** (không làm iPad), **cả hai đều là thiết bị chính** — mỗi màn có bố cục cho từng bên, thiết kế và tối ưu như nhau; web không phải cột iPhone đặt giữa hay bản iPhone kéo giãn (`docs/02-yeu-cau/LUONG-UNG-DUNG.md` mục 1.1). Ba breakpoint theo chiều rộng: mobile (< 600px), tablet (600–1023px), desktop (≥ 1024px); "tablet" chỉ là cửa sổ web hẹp, dùng bố cục như mobile. Từ desktop: thanh bên trái, nội dung rộng tối đa 1120px, danh sách – chi tiết hai cột, bảng khi nhiều cột số, sheet dưới thành hộp thoại. Lề màn hình 16px trên mobile, 24px trên tablet, 32px trên desktop.

Khoảng cách theo thang 4px: 4, 8, 12, 16, 20, 24, 32, 40, 48, 72. Nhịp thường dùng là 16px giữa các khối và trong thẻ, 8px giữa phần tử liên quan, 4px giữa icon và chữ.

Có hai mật độ: **comfortable** (mặc định; control 36 / 44 / 52px, ô nhập đệm 12 × 16px) và **compact** (control 32 / 40 / 48px, ô nhập đệm 10 × 14px). Control nào thấp hơn 44px vẫn được nới vùng chạm ra 44px. Mật độ chọn theo **cách thao tác**, không theo bề rộng: cảm ứng (iPhone, Android, web trên điện thoại) → comfortable; web trên máy tính → compact.

Khu cửa hàng có app bar trắng ở trên và 5 mục điều hướng: thanh dưới trên iPhone / cửa sổ hẹp, thanh bên trái trên web từ desktop; vùng công khai (đăng nhập, đăng ký) không có thanh điều hướng.

## Elevation & Depth

Hệ thống phẳng theo mặc định. Chiều sâu đến từ phân lớp tông màu: nền Shelf Gray, khối Counter White, viền Hairline 1px. App bar và thanh dưới không đổ bóng, chỉ có một đường kẻ 1px ngăn với nội dung.

### Shadow Vocabulary
- **e1** (`0 2px 8px rgba(14,17,22,0.04)`): thẻ cần nhấn mạnh vừa.
- **e2** (`0 4px 16px rgba(14,17,22,0.08)`): thẻ nhấn mạnh mạnh.
- **e3** (`0 8px 24px rgba(14,17,22,0.12)`): lớp nổi như menu, popover.
- **e4** (`0 16px 32px rgba(14,17,22,0.16)`): modal, sheet.

### Named Rules
**The Hairline First Rule.** Muốn tách hai vùng, dùng viền 1px hoặc đổi nền trước. Bóng đổ chỉ dành cho thứ thật sự nổi lên trên trang (menu, sheet, modal) hoặc thẻ được đặt emphasis.

## Shapes

Bo góc vừa phải, nhất quán theo loại phần tử: 8px cho nút và ô nhập, 12px cho thẻ và hộp icon, 16px cho bottom sheet, tròn hẳn (999px) cho chip và badge. Viền 1px là mặc định; 2px chỉ cho trạng thái nhấn mạnh mạnh. Trạng thái vô hiệu làm mờ toàn bộ control về 40% opacity thay vì đổi màu riêng.

## Components

### Buttons
Tiết chế và rõ ràng: một nút đặc màu xanh, còn lại là viền hoặc chữ.
- **Shape:** bo góc nhẹ (8px); cao 36 / 44 / 52px theo cỡ nhỏ / vừa / lớn; đệm ngang 12 / 16 / 24px.
- **Primary:** nền Clinic Leaf Green, chữ trắng, typography Label.
- **Pressed / Hover:** tối dần sang #26612F, rồi #1F4D26 khi vừa hover vừa nhấn.
- **Secondary:** nền trắng có viền, chữ Ink; nhấn chuyển nền Shelf Gray.
- **Tertiary:** không nền, chữ Clinic Leaf Text; nhấn hiện nền Leaf Wash.
- **Link:** chỉ chữ màu xanh, gạch chân khi focus hoặc nhấn.
- **Tone:** cùng biến thể có thể mang tone danger hoặc warning (nền đỏ / vàng cho primary; chữ đỏ / vàng và nền wash khi nhấn cho secondary, tertiary).
- **Disabled:** toàn nút mờ 40%.

### Chips
- **Style:** nền wash theo tone, viền 1px cùng tone, chữ Body Small, bo tròn hẳn; đệm ngang 12px.
- **State:** có thể kèm icon trước và nút xóa phía sau. Chip tương tác giữ phần vẽ compact, khung chạm tối thiểu 44px và semantics báo nút/trạng thái đã chọn; vùng chạm xóa 44×44 ở đuôi chip, đọc "Xóa <nhãn>".

### Badges
- **Style:** bo tròn hẳn, có thể kèm chấm 8px; chữ Caption (nhỏ) hoặc Body Small.
- **Tone:** success dùng Clinic Leaf Green, warning vàng, danger đỏ, info xanh dương, neutral Ink.

### Cards / Containers
- **Corner Style:** 12px.
- **Background:** tone quyết định nền và viền: trung tính là trắng + Hairline Strong; thương hiệu là Leaf Wash + Leaf Border; success / warning / danger / info dùng wash + màu tone.
- **Shadow Strategy:** emphasis quyết định bóng: medium dùng e1, strong dùng e2; mặc định không bóng.
- **Internal Padding:** 16px. Thẻ có các phần header, title, icon, action, content, footer.
- **Interactive:** `VCard(onTap)` là một nút semantics; phần nội dung thẻ vẫn là nhãn của nút.

### Inputs / Fields
- **Style:** nền trắng, viền Input Border 1px, bo 8px, đệm 8 × 12px, chữ Body màu Ink, placeholder Ink Muted. Nút trong ô (ẩn / hiện mật khẩu…) có vùng chạm 44×44, icon 24px.
- **Disabled:** viền Hairline, cả control mờ 40%.
- **Focus:** viền chuyển Clinic Leaf Green, bên ngoài có vòng nền Leaf Wash.
- **Error:** viền, chữ và con trỏ chuyển Alert Red; vòng focus dùng Alert Wash.
- **Forms chuyên dụng:** email, mật khẩu, tiền, số, số điện thoại, chọn, danh sách lựa chọn, ngày, mã xác minh, bàn phím số dạng sheet.

### Navigation
- **App bar:** nền trắng, không bóng, đường kẻ Hairline 1px phía dưới; tiêu đề cỡ Title (18px) weight 700 màu Ink; nút quay lại là chevron trái, đọc "Quay lại".
- **Thanh dưới:** nền trắng, đường kẻ Hairline phía trên, đệm trên 4px, ô tab cao tối thiểu 48px, đệm dưới bằng trọn inset của thanh Home / thanh cử chỉ (tối thiểu 12px); mỗi tab có icon 24px và nhãn Label Small bên dưới (cách 4px, 1 dòng, cỡ chữ phóng tối đa ×1.3); tab đang chọn màu Clinic Leaf Green, tab khác Ink Secondary; không có hiệu ứng splash. Mỗi tab là một nút semantics mang tên tab và trạng thái đã chọn.
- **Thanh bên (Web / màn rộng ≥ 1024px):** bề rộng 240px cố định, nền trắng, viền phải Hairline 1px; phần đầu (header) chứa selector tổ chức, phần thân là danh sách cuộn các mục chính và mục con (một cấp, luôn mở); mỗi mục cao tối thiểu 44px, bo góc 8px (R8), đệm ngang 12px (mục con thụt vào 44px khi không có icon); mục đang chọn tô nền Leaf Wash (`surfaceBrand`), chữ và icon màu Clinic Leaf Green (`primary` / `textBrand`); mục phụ khi đang chọn nhánh tô nền Leaf Wash 50% alpha; hover nền xám nhạt (`surfaceHover`); focus bàn phím qua phím Tab có viền xanh 2px nhìn thấy rõ, kích hoạt bằng Enter hoặc Space; mục bị vô hiệu hoá mờ 40% (`vDisabledOpacity`); hỗ trợ semantics nút và trạng thái đã chọn. Phần cuối (footer) có viền trên Hairline 1px, chứa nút Đăng xuất.

### List-Detail Layout (Danh sách – chi tiết hai cột)
- **Breakpoint chia cột:** kích hoạt khi bề rộng layout ≥ 840px (`VListDetailLayout`), tương đương màn hình ≥ 1080px khi có thanh bên 240px. Dưới ngưỡng này, bố cục hiển thị một cột tuần tự theo điều hướng.
- **Cột danh sách (trái):** cố định 360px (`listWidth: 360`), cuộn độc lập; chứa danh sách tóm tắt (thành viên, vai trò, lịch sử).
- **Cột chi tiết (phải):** chiếm toàn bộ không gian còn lại (`Expanded`), cuộn độc lập; hiển thị form xem/sửa chi tiết. Khi chưa chọn mục nào, hiển thị `VEmptyState` với thông điệp hướng dẫn.
- **Đường phân cách:** `VDivider(axis: Axis.vertical)` 1px, màu `borderDefault`.
- **Trạng thái đang chọn:** thẻ tóm tắt ở cột trái dùng `VCard(isSelected: true)`, tô nền `surfaceBrand` (Leaf Wash) và viền `borderBrand` (Leaf Border), gán nhãn semantics `selected: true`.

### Adaptive Sheet / Dialog (Hộp thoại thích ứng)
- **Hành vi thích ứng:** `showVAdaptiveSheet` tự động mở bottom sheet (`VBottomSheet`) khi màn hình hẹp (< 1024px) và mở hộp thoại căn giữa (`VSheetDialog`) khi màn hình rộng (≥ 1024px, tức `VBreakpoints.desktop`).
- **Kích thước hộp thoại:** `VSheetDialog` có chiều rộng tối đa 480px, chiều cao tối đa 85% chiều cao màn hình; bo góc 16px (`VRadius.r16`).
- **Thanh tiêu đề hộp thoại:** khi có tiêu đề (`title != null`), hiển thị tiêu đề `headingH3` bên trái, nút đóng hình dấu X bên phải (`Semantics(label: 'Đóng')`) và đường kẻ ngang Hairline bên dưới; khi không có tiêu đề (`title == null`), không hiển thị thanh tiêu đề và đường kẻ, nút đóng được đặt ở góc trên bên phải.
- **Thao tác đóng:** hỗ trợ đóng khi nhấn phím Escape, nhấn vùng ngoài hộp thoại (barrier dismissible), hoặc bấm nút đóng.

## Do's and Don'ts

### Do:
- **Do** lấy màu qua `context.vColors` và token `VSpacing` / `VRadius` / `VTypography` / `VShadows`; dùng component `V*` trước khi tự dựng widget.
- **Do** giữ đúng một nút primary mỗi màn (The One Sticker Rule).
- **Do** giữ vùng chạm ≥ 44px cho mọi control, kể cả icon chạm được (`VIconBox(onTap)` tự nới) và nút xoá của chip; phần vẽ có thể nhỏ hơn.
- **Do** tách vùng bằng nền Shelf Gray / khối trắng / viền Hairline 1px trước khi nghĩ đến bóng.
- **Do** dùng biến thể JetBrains Mono khi số tiền hoặc số lượng cần căn cột.
- **Do** làm mờ 40% để biểu thị trạng thái vô hiệu.
- **Do** cho mọi tab và nút chỉ có icon một nhãn đọc được (chữ hiển thị hoặc semantics label); hành động ẩn sau thao tác vuốt phải có `semanticActions`.
- **Do** dùng chấm hình học kèm nhãn "đang áp dụng" cho nút lọc; không chỉ đổi màu để báo trạng thái.
- **Do** tôn trọng Giảm chuyển động (`MediaQuery.disableAnimations`): skeleton đứng yên, thao tác vuốt mở / đóng tức thì.
- **Do** cho web đi được bằng bàn phím: Tab qua mọi control theo thứ tự đọc, vòng focus nhìn thấy, Enter / Space kích hoạt, Esc đóng hộp thoại và sheet; mọi hành động vuốt có nút hoặc menu thay thế dùng chuột.

### Don't:
- **Don't** dùng `VColors.*` trực tiếp trong component, app hoặc module.
- **Don't** dùng vàng, đỏ, xanh dương để trang trí hay phân loại; chúng chỉ dành cho trạng thái.
- **Don't** thêm bóng đổ cho app bar, thanh dưới hoặc thẻ thường.
- **Don't** dùng bậc 500 của các thang màu (`primary500`, `yellow500`, `red500`, `blue500`) cho chữ, icon hoặc nền nút có chữ trắng ở theme sáng; chúng chỉ đạt 2.5–4.7:1 (vd. `primary500` 3.8:1, `yellow500` 2.8:1). Theme sáng dùng bậc 600–700.
- **Don't** đặt UI nghiệp vụ (thẻ dashboard, dòng việc cần làm…) vào `c45_design_system`; chúng thuộc `apps/erp/lib/features/*/presentation`.
