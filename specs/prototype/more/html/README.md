# Prototype Menu Thêm + Thiết lập hệ thống APP-02 (10-8)

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của ba màn menu (Thêm, Thiết lập, Người dùng & vai trò), đặt trong khung chung (`shared/shell.js`), để người dùng rà bằng impeccable (bước 3 của 10-8). Chép y nguyên chữ và thứ tự mục, không thiết kế lại. Màn con (HĐĐT, thiết lập sản phẩm, hồ sơ tổ chức, người dùng, vai trò, lịch sử quản trị, tài khoản) **không** vẽ ở đây: rà cùng theme của chúng.

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/prototype/more/html
python3 tools/serve.py &    # cổng 8769, tắt cache
# trang xem: http://127.0.0.1:8769/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=more&state=blocked&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # 7 ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

Màn trần không có tương tác: mọi thẻ trong Flutter `push` sang route khác.

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/main.js` | Ba màn (`morePage`, `settingsPage`, `usersPage`), hàm thuần `isVisible`, `moreItems`, `hubItems`, `columnMax`, ca → trạng thái. Danh sách mục lấy từ `MORE_ENTRIES` của `shared/shell.js` |
| `styles/more.css` | Rule của màn, tiền tố `mr-`, token `--c45-v2-*`; đầu file có bảng màu Flutter → token |
| `app/cases.js`, `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Danh sách ca, trang xem, chụp ảnh (chép khuôn Trang chủ) |
| `shared/icons.js` | Thêm `building` (VIcons.apartment), `list` (VIcons.listView) |

## Nguồn Flutter

| Phần | Flutter |
|---|---|
| Khung màn Thêm | `core/router/app_router.dart` route `/more`: `Scaffold` + `VAppBar('Thêm', showBackButton: false)` + `MorePage` |
| Danh sách mục, luật hiện / bấm | `features/more/presentation/more_entries.dart` (`kMoreEntries`, `isVisible`, `isInteractive`) |
| Thẻ màn Thêm | `features/more/presentation/pages/more_page.dart` (`_MoreView`, `_MoreMenuItem`) |
| Thiết lập | `features/more/presentation/pages/system_settings_page.dart` |
| Người dùng & vai trò | `features/more/presentation/pages/users_and_roles_page.dart` (`_HubMenuCard`), quyền ở `logic/iam_feature_access_state.dart` |
| DS | `v_card.dart` (subtle: không bóng), `v_icon_box.dart`, `v_app_bar.dart`, `patterns/v_page_scaffold.dart` (thân tối đa 720 khi ≥ 1024) |

## Hiện trạng Flutter (để rà)

1. **Thiết lập và Người dùng & vai trò mở ngoài khung.** `/more/settings`, `/more/users-and-roles` khai báo ngoài `ShellRoute(StoreShell)` → web mất thanh bên, iPhone mất thanh dưới (đã ghi ở Khung chung, phát hiện 1).
2. **Web dùng nguyên bố cục điện thoại cho màn Thêm:** 10 thẻ cao 74 xếp dọc, giãn hết vùng nội dung (~1008 px), chữ dồn bên trái, mũi tên sát mép phải; web 800 px vẫn phải cuộn mới thấy "Thiết lập", "Đăng xuất". Thanh bên đã có đủ mục con nên màn Thêm trên web lặp lại thanh bên.
3. **Ba kiểu thẻ menu cho cùng một việc:** Thêm = hộp icon 44 nền xanh nhạt + tiêu đề 1 dòng; Thiết lập = hộp icon 44 **nền trắng trùng nền thẻ** (không truyền `backgroundColor`) + phụ đề 2 dòng; Người dùng & vai trò = icon trần 20 màu chữ, đệm dọc 16, khe 8, chữ không giới hạn dòng.
4. **Màn Thêm trên web khi tổ chức bị chặn:** 7/10 thẻ mờ 45%; chỉ "Tài khoản của tôi" và "Đăng xuất" bấm được, không có dòng giải thích vì sao mờ. Mờ dùng chung một cách cho "chưa làm" (Khách hàng & NCC, Đơn nhập, Báo cáo) và "bị chặn" → người dùng không phân biệt được.
5. **Mục tắt vì chưa làm vẫn hiện:** "Khách hàng & NCC" (trùng tab Đối tác), "Đơn nhập", "Báo cáo" là `enabled: false`, không route.
6. **Người dùng & vai trò lỗi im lặng:** cubit lỗi / không quyền → danh sách rỗng, không chữ, không nút thử lại (ca `users__empty`). Có `RefreshIndicator` (kéo để tải lại) nhưng web không kéo được.
7. **"Đăng xuất" là thẻ menu như mọi mục** (nền đỏ nhạt, chữ đỏ, có mũi tên `>`), đặt cuối danh sách, không hỏi xác nhận. Mũi tên gợi ý "mở màn khác" trong khi bấm là đăng xuất ngay.
8. **Trùng icon:** "Khách hàng & NCC" và "Người dùng & vai trò" cùng `VIcons.people`; trong màn Người dùng & vai trò, "Người dùng" lại dùng `people`.
9. Màn Thêm có `VAppBar` "Thêm" trong khi thanh bên web đã ghi "Thêm" đang chọn → tiêu đề lặp.

## Khác biệt có chủ đích với Flutter

- Icon: Material thay bằng nét kiểu Lucide trong `shared/icons.js`, giữ ý nghĩa và cỡ.
- Font: không nạp Inter (như các prototype 10-8 khác).
- Hover thẻ: lớp đen 4% (màu hover mặc định Material vì `VCard` tắt splash / highlight); theo ước lượng.
- Không vẽ hộp thoại / toast đăng xuất (`more_logout.dart`): Flutter không có hộp xác nhận; toast lỗi thuộc phiên.
