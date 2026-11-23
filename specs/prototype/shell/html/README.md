# Prototype khung chung (10-8 "Layout tổng thể")

HTML/CSS/JS thuần (ES module, không build). Vẽ **đúng Flutter hiện tại** của khung app cửa hàng để người dùng rà bằng impeccable (bước 3 của 10-8, người dùng tự rà). Nội dung bên trong khung chỉ là ô giữ chỗ.

## Chạy

```bash
# xem chung với các theme khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/prototype/shell/html
python3 tools/serve.py &    # cổng 8767, tắt cache
# trang xem: http://127.0.0.1:8767/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
#   phím: ↑/↓ (k/j) ca trước / sau · 1 iPhone · 2 Web · 3 Cả hai · g Cả màn · e Sửa trực tiếp
# một ca trần (URL chụp ảnh, bấm được): index.html?screen=tab&state=home&device=web
node --test                 # hàm thuần của khung đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # 23 ca × 2 khổ → tools/proto-final/{iphone,web}/<screen>__<state>.png (không vào git)
```

Khổ chụp: iPhone 390×844, Web 1280×800, scale 1. Ở ca trần bấm được: tab / mục con (chuyển trang), tên tổ chức (mở APP-04: gõ tìm, chọn → xác nhận → đang chuyển → toast), Esc đóng sheet.

## Tệp

| Tệp | Vai trò |
|---|---|
| `shared/shell.js` | **Dùng chung cho mọi theme.** `renderShell(opts, contentHtml)`, `sideNav`, `bottomNav`, `tabFromLocation`, `selectedMoreEntry`, `insideShell`, `TABS`, `MORE_ENTRIES`, thẻ báo (`noticeCard`, `gateError`, `blockedNotice`) |
| `shared/shell.css` | Rule của khung, tiền tố `sh-`, chỉ dùng token `--c45-v2-*`; cỡ chữ `--sh-fs-*` (tokens.css chưa có token cỡ chữ) |
| `shared/icons.js` | Thêm icon khung: `home`, `receipt`, `inventory`, `users`, `swapVert`, `logout`, `wallet`, `tag`, `settings`, `download`, `chart`, `store`, `error` |
| `app/org.js` | APP-04 chọn tổ chức (sheet / hộp thoại 480, xác nhận, đang chuyển, toast) |
| `app/main.js` | Ca → trạng thái khung; ô giữ chỗ; màn "Thêm" (đủ 10 mục để ca iPhone tab Thêm có nội dung) |
| `app/cases.js`, `app/viewer.js`, `styles/viewer.css` | Danh sách ca, trang xem (chép khuôn Theme 6) |

Theme khác dùng khung: nạp `shared/shell.css`, `import { renderShell } from '../shared/shell.js'`, gọi `renderShell({ device, location, ... }, htmlMàn)`.

## Nguồn Flutter

| Phần | Flutter |
|---|---|
| Chọn bố cục ≥ 1024 / < 1024, màn chờ / lỗi kho mặc định | `features/dashboard/presentation/store_shell.dart`, `widgets/default_pair_gate_error_view.dart` |
| Thanh dưới, tab | `erp_tab_scaffold.dart`, `widgets/erp_bottom_navigation.dart`, DS `v_bottom_navigation_bar.dart` |
| Thanh bên, đầu (tên tổ chức + đổi), cuối (Đăng xuất) | `widgets/erp_side_navigation.dart`, DS `v_side_navigation.dart` |
| Mục con "Thêm" | `features/more/presentation/more_entries.dart` (`kSideNavSubEntries` = mục có route và đang bật → 6 mục) |
| Tổ chức bị chặn | `widgets/tenant_ready_gate.dart` + `organization_empty_view.dart` |
| Route trong / ngoài khung | `core/router/app_router.dart` (`ShellRoute(StoreShell)`) |
| APP-04 | `iam/presentation/organizations/widgets/{select_organization_bottom_sheet, confirm_switch_organization_bottom_sheet, organization_empty_view}.dart`, DS `v_adaptive_sheet.dart` |

## Phát hiện khi chép (để rà)

1. **Mục con của "Thêm" mở ngoài khung.** Chỉ 5 nhánh tab và `/warehouse` nằm trong `ShellRoute(StoreShell)`. `/more/receivables`, `/pricing`, `/more/users-and-roles`, `/more/my-account`, `/more/settings` khai báo ngoài → trên web bấm mục con ở thanh bên sẽ mở **toàn màn, mất thanh bên**; trạng thái "mục con được chọn" chỉ thấy được ở "Kho". Ca `sub__*`.
2. **Thanh dưới hiện cả ở trang con trong nhánh** (ví dụ `/warehouse/...`), vì `ErpTabScaffold` luôn vẽ thanh dưới trên màn hẹp; chú thích trong `store_shell.dart` ghi "chỉ trang gốc" là không đúng.
3. **Màn lỗi kho mặc định và thẻ "bị chặn" trên web rộng hết khung** (không giới hạn bề ngang), thẻ lỗi kho mặc định dính sát trên.
4. Nội dung web ở 1280 rộng 1040 (< 1120) nên giới hạn `VContentWidth` 1120 chưa bao giờ có tác dụng ở khổ này.
5. Thanh bên Theme 7 (FROZEN) lệch Flutter: 5 mục con cũ, icon Trang chủ là nhà kho, không có icon đổi tổ chức, Đăng xuất không đỏ. Khung này theo Flutter, không theo Theme 7.

## Đề xuất đã chốt, chưa có trong Flutter (2026-11-23)

- **Thanh biểu tượng web thay thanh bên 240** (`sideNav` trong `shared/shell.js`, CSS `.sh-side*`, `.sh-menu*`): rộng 84; ô tổ chức (chữ cái đầu, bấm để đổi), 4 tab icon + nhãn (**bỏ "Thêm" trên web**), "Quản lý" mở menu nổi (popover) có 6 tính năng phụ kèm mô tả, Đăng xuất ở đáy. Đang ở tính năng phụ → "Quản lý" sáng, mục trong menu tô nền brand. iPhone giữ thanh dưới 5 tab (còn "Thêm").
- Nội dung web vì vậy rộng 1196 → `VContentWidth` 1120 bắt đầu có tác dụng (phát hiện 4 ở trên không còn đúng).
- Cần sửa theo khi làm Flutter: `erp_side_navigation.dart`, `v_side_navigation.dart`, mục Navigation trong `DESIGN.md`.

## Khác biệt có chủ đích với Flutter

- Icon: Material (`Icons.*`, `VIcons.*`) thay bằng nét kiểu Lucide trong `icons.js`, giữ ý nghĩa và cỡ (24 thanh dưới, 20 thanh bên).
- Font: như Theme 6 / 7, không nạp Inter; ảnh dùng font hệ thống.
- Màn "Thêm" trên iPhone chỉ là danh sách đủ mục và thứ tự; bố cục thật rà ở mục "Menu Thêm + Thiết lập hệ thống" của 10-8.
- Toast: vị trí theo ước lượng (Flutter đặt bằng overlay của `VToast`).
- Dữ liệu tổ chức là dữ liệu mẫu (`app/org.js`).
