# Prototype Theme 1 (TH-01) + Web cho app (10-8)

HTML/CSS/JS thuần (ES module, không build). **iPhone 390** vẽ đúng Flutter hiện tại của các màn TH-01 (chép y nguyên chữ, thứ tự, số đo DS), trừ màn đã thiết kế lại qua impeccable live (từ 2026-11-25, chữ giữ nguyên): ID-01 Đăng nhập, ID-02 Đăng ký (thanh tiến độ 3 đoạn, họ + tên cùng hàng), ID-03 Xác minh email (thẻ nhập mã; ô mã trải hết bề ngang, dùng chung bước 3 Đăng ký), ID-04 / ID-23 Đặt lại mật khẩu (thanh 2 bước, nền trắng), ID-05 Chưa thuộc tổ chức (nút ở đáy), ID-06 Nhập mã lời mời (ô mã 4 + 4), ID-07 Kích hoạt tài khoản theo lời mời (sheet xác nhận + form + màn kết quả), ID-11 Hồ sơ tổ chức (gộp nhắc pháp lý vào thẻ), ID-12 Chỉnh thông tin tổ chức (hai thẻ), ID-13 Hồ sơ pháp lý (hai thẻ, loại chủ thể hai nút), ID-14 Người dùng (tab hai nút, "Mời thành viên" ở thanh dưới), ID-15 Mời thành viên (chọn vai trò bằng danh sách), ID-16 Chi tiết lời mời, ID-17 Chi tiết thành viên, ID-18 Chọn vai trò, ID-19 Vai trò (danh mục + chi tiết), ID-20 Lịch sử quản trị (danh sách theo ngày + chi tiết một thẻ), ID-21 Tài khoản của tôi (thao tác ngay trong màn), ID-22 Chỉnh sửa thông tin (hai thẻ). **Web 1280** là bố cục thiết kế lại qua impeccable live (2026-11-24/25), tách riêng ở `app/web/` + `styles/t1-web.css`: sửa web không đụng iPhone. Sheet / hộp thoại / toast là ca riêng.

Làm theo 3 đợt, mỗi đợt một commit; cột trái trang xem chia theo đợt:

| Đợt | Màn | Trạng thái |
|---|---|---|
| 1 · Công khai | ID-01 Đăng nhập (+ x1, x2, x4), ID-02 Đăng ký 3 bước (+ sheet khu vực), ID-03 Xác minh email, ID-04 / ID-23 Đặt lại mật khẩu, ID-05 Chưa thuộc tổ chức, ID-06 / ID-07 Lời mời (+ sheet xác nhận) | ✅ 58 ca × 2 khổ |
| 2 · Quản trị | ID-11…13 hồ sơ tổ chức, ID-14…18 người dùng (+ 2 sheet lọc, sheet thao tác, thu hồi, 3 sheet vòng đời), ID-19 vai trò, ID-20 lịch sử (+ sheet lọc). ID-10 hub đã vẽ ở prototype Menu Thêm (APP-02) nên không vẽ lại | ✅ 97 ca × 2 khổ |
| 3 · Tài khoản | ID-21 Tài khoản của tôi (+ sheet đăng xuất), ID-22 Chỉnh sửa thông tin (+ hộp thoại bỏ thay đổi). ID-23 đã vẽ ở đợt 1 (chung màn ID-04) | ✅ 16 ca × 2 khổ |

ID-08 Chọn tổ chức đã có ở khung chung (`specs/prototype/shell/html/`, APP-04), không vẽ lại. ID-09 đã bỏ.

## Đã có trong Flutter

| Plan | Phạm vi | Trạng thái |
|---|---|---|
| `10-8d` | Nền chung: ô mã `fill` / `split4`, `VStepProgress`, `VConfirmDialog` 440, `AppLogo`, `isWideLayout`, `StoreShell` | ✅ |
| `10-8e` | ID-01 Đăng nhập, ID-02 Đăng ký, ID-03 Xác minh email, ID-05 Chưa thuộc tổ chức | ✅ |
| `10-8f` | ID-04 / ID-23 Đặt lại mật khẩu, ID-06 Nhập mã lời mời, ID-07 Kích hoạt tài khoản theo lời mời | ✅ |
| `10-8g` | ID-11 Hồ sơ tổ chức, ID-12 Chỉnh thông tin tổ chức, ID-13 Hồ sơ pháp lý | ✅ |
| `10-8h` | ID-14 Người dùng, ID-15 Mời thành viên, ID-16 Chi tiết lời mời, ID-17 Chi tiết thành viên, ID-18 Chọn vai trò | ✅ |
| `10-8i` | ID-19 Vai trò, ID-20 Lịch sử quản trị | ✅ |
| `10-8k` | ID-21 Tài khoản của tôi, ID-22 Chỉnh sửa thông tin | ✅ |

## Chạy

```bash
# xem chung với các prototype khác: python3 specs/prototype/serve.py → http://127.0.0.1:8760/ (mục lục)
cd specs/themes/theme-01/03.design/prototype/html
python3 tools/serve.py &    # cổng 8770, tắt cache
# trang xem: http://127.0.0.1:8770/   (cột trái chọn ca; iPhone / Web / Cả hai; Từng ca / Cả màn / Sửa trực tiếp)
# một ca trần (URL chụp ảnh): index.html?screen=login&state=network&device=web
node --test                 # hàm thuần đối chiếu Dart + mọi ca vẽ được
node tools/capture.mjs      # mọi ca × 2 khổ → tools/proto-final/{iphone,web}/<màn>__<ca>.png (không vào git)
```

Màn trần không có tương tác: mỗi trạng thái là một ca.

## Tệp

| Tệp | Vai trò |
|---|---|
| `app/cases.js` | Nhóm (đợt), màn, ca + điều cần nhìn của từng ca |
| `app/ds.js` | Widget DS chép số đo Dart: VButton, VField / VInput / ô mật khẩu, VVerificationCodeField, VBanner, VSteps, VCard, VAppBar, VToast (SnackBar), showVAdaptiveSheet, VPageScaffold, lớp phủ đang xử lý |
| `app/login.js` | ID-01 |
| `app/signup.js` | ID-02 + ô tỉnh / xã + sheet "Khu vực hành chính"; hàm thuần `accountErrors`, `storeErrors`, `policyError` |
| `app/verify.js` | ID-03, `VerifyEmailView` (bước 3 đăng ký), ID-05; `maskEmail`, `resendLabel` |
| `app/reset.js` | ID-04 / ID-23; `resetResendLabel` |
| `app/invitation.js` | ID-06 / ID-07; `tokenFormatError`, `entryFailureMessage` |
| `app/admin-data.js` | Dữ liệu mẫu đợt 2 (Thú y An Phát: 3 thành viên + 1 đã loại, 4 lời mời, 4 vai trò, 6 nhật ký) |
| `app/org.js` | ID-11 / ID-12 / ID-13 + sheet thao tác, sheet trùng mã số thuế, hộp thoại "Bỏ thay đổi?" |
| `app/users.js` | ID-14…18: khu Người dùng hai cột web (`usersArea`), mời, chi tiết lời mời / thành viên, chọn vai trò, các sheet |
| `app/roles.js`, `app/audit.js` | ID-19, ID-20 (danh sách + chi tiết, hai cột web) |
| `app/account.js` | ID-21 / ID-22 + sheet thao tác tài khoản, sheet đăng xuất |
| `app/main.js` | Ca → trạng thái, vẽ trong `renderShell` (màn công khai nằm ngoài StoreShell → không thanh bên / thanh dưới; route `/more/*` của Theme 1 nằm **trong** `ShellRoute(StoreShell)`, web ≥ 1024 có thanh bên 84 — ảnh không vẽ thanh vì vẽ trang trần) |
| `styles/t1.css` | Rule tiền tố `t1-`, token `--c45-v2-*`; đầu file có bảng màu / chữ Flutter → token |
| `app/web/*.js`, `styles/t1-web.css` | Bố cục web (khung ≥ 840; `main.js` chọn). Trạng thái mẫu, hàm thuần, sheet lấy từ `app/*.js` |
| `app/viewer.js`, `styles/viewer.css`, `styles/stage.css`, `tools/` | Trang xem (thêm tiêu đề đợt), chụp ảnh — chép khuôn Menu Thêm |
| `shared/icons.js` | Thêm `eye` (VIcons.visibility), `mapPin` (Icons.location_on_outlined); đợt 2: `mail`, `send`, `userCheck` (personCheck), `userX` (personRemove), `copy` (clipboard) |

## Nguồn Flutter (đợt 1)

| Màn | Flutter |
|---|---|
| Khung màn công khai | `features/auth/presentation/auth_layout.dart` (`authMaxWidth`: mobile ∞, tablet / desktop 480) |
| ID-01 | `features/auth/presentation/pages/login_page.dart`, `logic/login_cubit.dart`, `core/iam/iam_ui_failure_mapper.dart` |
| ID-02 | `pages/signup_page.dart`, `logic/signup_cubit.dart`, `core/widgets/address/{administrative_units_form_section, vn_administrative_unit_picker_sheet}.dart`, `core/validation/password_policy.dart` |
| ID-03 | `pages/verify_email_page.dart`, `widgets/{verify_email_view, resend_countdown}.dart`, `logic/verify_email_cubit.dart` |
| ID-04 / ID-23 | `features/iam/presentation/users/views/reset_password_page.dart`, `users/widgets/reset_password_{verify_code,create_password}_step.dart`; route `core/router/app_router.dart` (`/login/reset-password`, `/more/my-account/reset-password`) |
| ID-05 | `pages/no_organization_page.dart` |
| ID-06 / ID-07 | `pages/{invitation_token_page, invitation_registration_page}.dart`, `widgets/{invitation_token_entry_form, invitation_confirm_bottom_sheet, invitation_registration_form, invitation_outcome_view}.dart` |
| DS | `packages/c45_design_system/lib/src/components/{v_button, v_input, v_text_field, v_text_field_focus_ring, v_banner, v_steps, v_verification_code_field, v_toast, v_app_bar, v_card, v_adaptive_sheet, v_bottom_sheet}.dart`, `patterns/{v_field, v_page_scaffold}.dart`, `forms/v_password_field.dart` |

## Nguồn Flutter (đợt 2)

| Màn | Flutter (`apps/erp/lib/features/iam/presentation/…`) |
|---|---|
| Route / khung | `core/router/app_router.dart`: `/more/organization-profile…`, `/more/users/invite` là GoRoute gốc; `/more/users`, `/more/roles`, `/more/audit-logs` là ShellRoute riêng (`users_area_shell`, `roles/roles_area_shell`, `audit_logs/audit_area_shell`; chỉ cấp cubit, web bảng toàn màn từ 10-8h / 10-8i), đều nằm **trong** `ShellRoute(StoreShell)` (`app_router.dart:468`; web ≥ 1024 có thanh bên 84, ảnh không vẽ thanh vì vẽ trang trần) |
| ID-11…13 | `organization_profile/views/{organization_profile_page, organization_edit_profile_page, organization_legal_profile_form_page}.dart`, `organization_profile/widgets/{organization_profile_actions_bottom_sheet, tax_code_duplicate_warning_bottom_sheet}.dart`, `organizations/widgets/organization_empty_view.dart`, `logic/organization_profile_cubit.dart` |
| ID-14 | `users/views/organization_users_page.dart`, `users/widgets/{organization_users_body, member_list_section, invitation_list_section, member_card, invitation_card, users_empty_state, member_filter_bottom_sheet, invitation_filter_bottom_sheet}.dart`, `logic/{member_ui_mapper, invitation_ui_mapper, iam_date_formatter}.dart` |
| ID-15 | `users/views/organization_invite_member_page.dart`, `logic/organization_invite_member_cubit.dart` |
| ID-16 | `users/views/organization_invitation_detail_page.dart`, `users/widgets/revoke_invitation_bottom_sheet.dart`, `shared/iam_action_tile.dart` |
| ID-17 | `users/views/organization_member_detail_page.dart`, `users/widgets/{member_detail_body, member_lifecycle_actions, membership_lifecycle_confirm_sheet, deactivate_/reactivate_/remove_membership_bottom_sheet}.dart`, `logic/organization_member_detail_state.dart` |
| ID-18 | `users/views/organization_select_role_page.dart` (`organization_preview_role_change_page.dart` còn trong code nhưng route redirect, không mở được) |
| ID-19 | `roles/views/{organization_roles_page, organization_role_detail_page}.dart`, `roles/widgets/{role_card, roles_narrow, roles_wide, role_detail_narrow, role_detail_wide}.dart`, `logic/roles_cubit.dart`, `core/iam/iam_role_label_mapper.dart` |
| ID-20 | `audit_logs/views/{organization_audit_logs_page, audit_log_detail_page}.dart`, `audit_logs/widgets/{audit_narrow, audit_wide, audit_day_section, audit_detail_narrow, audit_detail_wide, detail_part, audit_log_category_filter_chips, audit_log_filter_bottom_sheet, audit_log_empty_view, audit_detail_row}.dart`, `audit_logs/mappers/tenant_audit_ui_mapper.dart` |
| DS thêm | `components/{v_tabs, v_search_bar, v_modal (VConfirmDialog), v_radio, v_empty_state}.dart`, `primitives/{v_chip, v_badge}.dart`, `forms/v_select.dart`, `patterns/{v_list_detail_layout, v_page_scaffold}.dart`; Flutter `material/scaffold.dart` (SnackBar hiện ở mọi Scaffold gốc của cùng ScaffoldMessenger) |

## Nguồn Flutter (đợt 3)

| Màn | Flutter (`apps/erp/lib/features/iam/presentation/users/…`) |
|---|---|
| ID-21 | `views/my_account_page.dart`, `widgets/{my_account_actions_bottom_sheet, logout_confirmation_bottom_sheet}.dart`; route `/more/my-account` (GoRoute gốc, `onLogout` trong `core/router/app_router.dart`) |
| ID-22 | `views/edit_my_account_page.dart` (mở bằng `Navigator.push`, không có route) |

## Hiện trạng Flutter (để rà) — đợt 1

**Bố cục chung, web**

1. **Ba kiểu khung cho cùng nhóm màn công khai.** Đăng nhập, Xác minh email, Chưa thuộc tổ chức: nền trắng, không app bar. Đăng ký: nền trắng + app bar. Lời mời, Đặt lại mật khẩu: `VPageScaffold` nền **xám** + app bar + thanh dưới cố định. Đi từ Đăng nhập (trắng) sang Kích hoạt tài khoản (xám) đổi nền đột ngột.
2. **Web: app bar và thanh dưới kéo hết 1280 px, thân chỉ 480 px ở giữa.** Tiêu đề "Đăng ký cửa hàng" / nút ← nằm sát mép trái, cách form ~400 px. Nút "Tiếp tục" nằm ở đáy cửa sổ, cách ô mã hàng trăm px.
3. **Web: không có gì "đóng khung" form** (không thẻ, không nền khác) — cột 480 trôi giữa nền trắng 1280; dòng "© Mosaic Retail · **Phiên bản Mobile**" vẫn hiện trên web.
4. **Toast (VToast trong SnackBar floating) không giới hạn bề ngang**: web kéo dài ~1218 px. Toast chỉ hiện câu `message`, `title` bị bỏ (VToast chỉ vẽ một dòng). Màn có thanh dưới: toast nổi trên thanh dưới.
5. **Sheet trên web (`VSheetDialog` không tiêu đề) cộng hai lớp đệm**: hộp thoại 16 / 24 + nội dung tự đệm 16 → chữ cách mép 32. Sheet "Khu vực hành chính" có **hai nút Đóng** chồng nhau (của hộp thoại và của sheet) và cao cố định 75% màn.

**Đăng nhập (ID-01)**

6. Logo là ô xanh chữ "V45" (không phải tên sản phẩm Mosaic Retail). Prototype (iPhone + web) đã thay bằng icon app (2026-11-25); Flutter còn "V45". Khẩu hiệu "Quản trị bán hàng thuốc thú y".
7. Sai email / mật khẩu: câu lỗi gắn dưới ô **Email** (ô Mật khẩu không đỏ), dễ hiểu nhầm là email sai. Lỗi mạng: banner đỏ chen giữa ô Mật khẩu và "Quên mật khẩu?".
8. Bốn lối đi trên một màn, cùng độ nổi gần nhau: "Quên mật khẩu?" (link), "Đăng nhập", "Đăng ký cửa hàng mới" (viền), "Kích hoạt tài khoản" (link dưới câu hỏi). Hai link cao tối thiểu 44 nên khoảng trống quanh chúng lớn hơn quanh nút.
9. Sau Quên mật khẩu → toast; sau đổi mật khẩu từ Tài khoản → banner. Cùng câu "Cập nhật mật khẩu thành công", hai cách báo.

**Đăng ký (ID-02)**

10. Lỗi máy chủ hiện banner **chỉ có tiêu đề** (câu lỗi đặt làm tiêu đề, không mô tả).
11. "Email đã được đăng ký": cả form biến mất, chỉ còn một dòng chữ đỏ (không banner, không giải thích) + "Đăng nhập" + link "Quên mật khẩu"; thanh bước vẫn ở bước 2 dù lỗi thuộc bước 1.
12. Ô Tỉnh / Xã dùng viền `borderDefault` (nhạt) trong khi mọi ô nhập khác viền `borderInput` (đậm) → nhìn như ô tắt. Ô Xã khi chưa chọn tỉnh mới thật sự tắt nhưng trông gần giống.
13. Sheet khu vực: danh sách sắp theo mã ký tự nên "Thành phố Đà Nẵng", "Thành phố Đồng Nai" nằm sau "Hồ Chí Minh"; "Tỉnh Đắk Lắk", "Tỉnh Điện Biên", "Tỉnh Đồng Tháp" xuống cuối danh sách.
14. Bước 3 không có tiêu đề riêng; "Xác minh" và gửi lại nằm ngay dưới thanh bước.
15. Nhãn khác nhau giữa hai form tạo tài khoản: Đăng ký ghi "Nhập lại mật khẩu", gợi ý "Nguyễn Thị" / "Lan"; Lời mời ghi "Xác nhận mật khẩu", gợi ý "Nhập họ và tên đệm" / "Nhập tên". Câu lỗi mật khẩu cũng khác ("…ít nhất 8 ký tự" so với "…ít nhất 8 ký tự, gồm 1 số và 1 ký tự đặc biệt").

**Xác minh email / ô mã (ID-03, bước 3)**

16. **Sai mã: gần như không thấy ô nào đỏ.** *Đã sửa ở prototype + Flutter 10-8d:* mọi ô viền `danger`, vòng đỏ nhạt chỉ ở ô đang focus, chữ số không đỏ. Áp cho mọi ô mã (OTP, mã lời mời).
17. Bấm "Xác minh" khi chưa đủ 6 số vẫn báo "Mã xác minh không đúng hoặc đã hết hạn." (cubit dùng một câu cho cả hai).
18. Vòng focus của ô (3 px `successBg` #EBF4EE trên nền trắng) gần như không thấy.
19. **Đủ mã là tự gửi** (`onCompleted` → xác minh / xác nhận mã / kiểm mã lời mời) ở cả ba ô mã → nút "Xác minh", "Xác nhận mã", "Tiếp tục" hầu như không bao giờ phải bấm, nhưng vẫn là nút chính to nhất màn. Gửi lại mã lỗi: câu lỗi mạng hiện đúng chỗ lỗi mã.

**Đặt lại mật khẩu (ID-04 / ID-23)**

20. Gửi mã lỗi: thân màn ghi lỗi **và** toast đỏ cùng câu (báo hai lần).
21. **Sai mã không báo tại ô**: `errorText` của bước 1 không được truyền → chỉ có toast. Đã sửa 10-8f.
22. Thẻ "Xác minh email" dính sát nhãn "Mã xác nhận" (không khe). Nút gửi lại là nút viền đầy ngang (Đăng ký / Xác minh dùng link nhỏ); nhãn luôn "00:ss" nên lúc vừa gửi lại có thể hiện "00:60". Đã sửa 10-8f.
23. Thanh dưới bước 2 (`_PasswordBottomBar`) tự vẽ nền + gạch trên + đệm 16 bên trong bottomBar của VPageScaffold (đã có nền + gạch) → hai gạch / đệm chồng (khó thấy, cùng màu).
24. Đang xử lý: lớp phủ trắng 50% + vòng tải che cả màn (gồm app bar), trong khi nơi khác dùng vòng xoay trong nút.
25. Hai lối vào (quên mật khẩu / đổi mật khẩu khi đã đăng nhập) chung một màn, không có chữ nào cho biết đang ở trường hợp nào; ID-23 nằm trong khung StoreShell (web có thanh bên 84; ảnh vẽ trang trần).

**Chưa thuộc tổ chức (ID-05)**

26. Chỉ có chữ + hai nút, không icon / minh hoạ, không cho biết đang đăng nhập bằng email nào.

**Lời mời (ID-06 / ID-07)**

27. iPhone: 8 ô mã co còn ~38 × 48 px. Banner info "Nhập mã lời mời" lặp tiêu đề app bar "Kích hoạt tài khoản" và nhãn "Mã lời mời".
28. Sheet xác nhận hiện cho cả người đã có tài khoản và chưa có (comment Dart ghi "khi tài khoản đã tồn tại"); bấm "Xác nhận" với tài khoản đã có → quay về màn nhập mã với nút xoay rồi sang Đăng nhập.
29. Màn kết quả (Đã từ chối / Không thể tiếp tục): nền trắng, không app bar, không nút quay lại hay về Đăng nhập — chỉ "Nhập mã khác". `onRetryLater` không được truyền nên "Thử lại sau" không bao giờ hiện.
30. Lỗi máy chủ khi kích hoạt: chỉ toast; hai ô mật khẩu bị xoá trắng.

## Hiện trạng Flutter (để rà) — đợt 2

**Chung**

31. Web: các route quản trị nằm trong StoreShell (có thanh bên 84 ở ≥ 1024; ảnh vẽ trang trần); toàn màn 1280; chỉ còn nút ← để quay ra. Ba kiểu khung trong cùng một khu: VPageScaffold cột 720 (hồ sơ, mời), hai cột 360 | chi tiết (người dùng, vai trò, lịch sử), Scaffold thường không giới hạn rộng (lịch sử quản trị — thẻ chi tiết kéo hết cột phải ~900 px).
32. Mời thành viên là route gốc: đang ở hai cột bấm + → mất cột danh sách; gửi xong nhảy sang chi tiết lời mời nhưng danh sách bên trái vẫn ở tab Thành viên nếu trước đó ở tab đó.
33. Hộp thoại "Bỏ thay đổi?" (VConfirmDialog = Dialog Material không maxWidth): web rộng 1200 px, hai nút dồn mép phải.
34. Sheet không tiêu đề tự vẽ tiêu đề bên trong (Thao tác hồ sơ / thành viên, xác nhận vòng đời, thu hồi) còn sheet bộ lọc / "Thao tác lời mời" dùng tiêu đề của sheet → hai kiểu đầu sheet; trên web thêm lớp đệm hộp thoại như đợt 1.
35. Ba kiểu chip: VChip (chip nhanh, lịch sử), `_SelectableFilterChip` (bộ lọc người dùng, viền xanh nền xanh nhạt), chip trong bộ lọc lịch sử dùng lại VChip. Ba kiểu trạng thái trống / lỗi: `UsersEmptyState` (hộp icon 56 vuông, nút đặc), `OrganizationEmptyView` / `AuditLogEmptyView` (thẻ, vòng 64, link), thẻ lỗi riêng của Vai trò (vòng 56).
36. Lỗi tải chi tiết (hồ sơ, lời mời, thành viên, mời) chỉ là chữ + nút "Thử lại", không icon, khác hẳn các trạng thái trống bên trên.

**Hồ sơ tổ chức (ID-11…13)**

37. Banner "Bổ sung hồ sơ pháp lý" và hộp vàng "Chưa có hồ sơ pháp lý" nói cùng một việc trên một màn; thẻ đầu chỉ lặp tên tổ chức (đã có ở dòng "Tên hiển thị").
38. Trang hồ sơ chỉ hiện địa chỉ chi tiết, không hiện tỉnh / xã dù form có hai ô này. (Đã sửa 10-8g)
39. "Loại chủ thể" bắt buộc (lỗi "Vui lòng chọn loại chủ thể") nhưng nhãn không có *. Lưu thiếu: vừa lỗi dưới ô vừa toast "Thiếu thông tin"; sai dạng mã số thuế cũng ra toast "Thiếu thông tin". (Đã sửa 10-8g)
40. Màn không quyền: câu "…quản lý tổ chức nền tảng" sót từ phần quản trị nền tảng đã bỏ. (Đã sửa 10-8g)

**Người dùng (ID-14…18)**

41. Dưới tab có hai gạch chồng (gạch của VTabs + Divider); ô tìm nền trắng nhưng hàng tab / chip nền xám.
42. Thẻ thành viên: tên + "Chủ sở hữu" xuống dòng trong cột 360; "email · vai trò" xuống dòng. Bộ lọc đã áp dụng chỉ báo bằng chấm 8 px, chip nhanh vẫn "Tất cả".
43. Chi tiết lời mời: in giá trị thô "Giao nhận: sent", "Trạng thái: expired"; thanh "Thao tác" có hai gạch trên (Container tự vẽ thêm). Lời mời hết hạn không có thao tác nào (không mời lại được từ đây).
44. Chi tiết thành viên: "Danh tính: Chỉ đọc" cho mọi người không phải chủ — đọc như quyền chỉ đọc. Chủ sở hữu duy nhất không có thanh thao tác và không có câu giải thích vì sao. (Đã sửa 10-8h)
45. Sheet thu hồi: ô lý do dính sát câu mô tả (không khe); lý do bắt buộc nhưng nhãn không có *. Nút xác nhận nguy hiểm là nút viền đỏ đặt dưới "Quay lại" (thứ tự ngược hộp thoại "Bỏ thay đổi?" nơi nút đỏ đặc bên phải). (Đã sửa 10-8h)
46. Mời thành viên: bấm gửi khi trống chỉ ô Email báo "Vui lòng nhập email và chọn vai trò."; thiếu vai trò thì câu đó hiện dưới VSelect nhưng viền không đỏ; nút đang gửi đổi chữ "Đang gửi..." không vòng xoay (các màn khác dùng vòng xoay). Gợi ý "nhanvien@minhphat.vn" là tên cửa hàng khác. (Đã sửa 10-8h)
47. Chọn vai trò: không có bước "Xem trước thay đổi" (TH-01 ID-18 có) — chọn xong bấm Tiếp tục là đổi ngay; mô tả vai trò ở màn này khác mô tả ở màn Vai trò. (Đã sửa 10-8h)

**Vai trò (ID-19)**

48. Thẻ có người giữ hiện nhãn "Đang dùng" thay mũi tên → trông như không bấm được; mô tả "Chủ cửa hàng" lộ ghi chú kỹ thuật "(gán mặc định cho Owner…, BR-36)". (Đã sửa 10-8i)
49. Không có trạng thái đang tải: hiện "0 vai trò hệ thống" + danh sách trống tới khi có dữ liệu. Chi tiết vai trò liệt kê tên trần, không bấm sang thành viên được. (Đã sửa 10-8i)

**Lịch sử quản trị (ID-20)**

50. Dòng 3 mỗi thẻ "Loại đối tượng: Trần Văn Minh" — nhãn là loại nhưng giá trị là tên; chi tiết có dòng "Loại chủ thể: Chủ cửa hàng" thực ra là vai trò người thực hiện. (Đã sửa 10-8i)
51. Chi tiết in mã sự kiện thô ("iam.membership.role_changed"); khối thay đổi không có tiêu đề ("Dữ liệu thay đổi" có trong model nhưng không vẽ); AppBar Material tiêu đề 14 px, không gạch dưới, khác mọi màn khác (18 px + gạch). (Đã sửa 10-8i: có tiêu đề "Dữ liệu thay đổi", `VAppBar` chung; mã sự kiện giữ chữ nhỏ cuối phần truy vết theo prototype)
52. Bộ lọc: tiêu đề "Bộ lọc nhật ký nền tảng"; nhóm "Loại chủ thể" chọn được nhưng không áp dụng; chip nhanh thiếu "Lời mời" dù có sự kiện lời mời. (Đã sửa 10-8i: tiêu đề, bỏ nhóm "Loại chủ thể"; chip nhanh giữ 4 nhóm theo TH-01 US-07.2 FR-01)

## Hiện trạng Flutter (để rà) — đợt 3

**Tài khoản của tôi (ID-21 / ID-22)**

53. Web: toàn màn (route nằm trong StoreShell, thanh bên 84 ở ≥ 1024; ảnh vẽ trang trần). Màn không cho biết đang ở tổ chức nào, vai trò gì — chỉ có nhãn "Chủ sở hữu" theo tổ chức đang dùng. (Đã sửa 10-8k: hai cột 1040)
54. Thẻ đầu ở ID-21 là hộp icon người trống, còn ID-22 lại có avatar chữ "NL"; thẻ "Ảnh đại diện" có mũi tên và câu "Chạm để thay hoặc xóa ảnh" nhưng không bấm được. (Đã sửa 10-8k: ID-21 dùng avatar chữ viết tắt, ID-22 bỏ mũi tên và câu phụ)
55. Thanh "Thao tác" có hai gạch trên (Container tự vẽ thêm); mọi việc (sửa, đổi mật khẩu, đăng xuất) đều phải mở sheet, không có nút trực tiếp. "Đăng xuất" lặp với mục Đăng xuất ở Menu Thêm. (Đã sửa 10-8k: bỏ thanh/sheet Thao tác, đưa ba thao tác vào màn)
56. Sheet đăng xuất dùng hai nút large 52 chia đôi; các sheet xác nhận khác (tạm ngừng, loại, thu hồi) dùng nút 44 xếp dọc. (Giữ 10-8k Q13: sheet xác nhận đăng xuất theo prototype, hai nút 52.)
57. Sửa thông tin: "Lưu thay đổi" mờ tới khi có thay đổi mà không nói vì sao; đang lưu chỉ đổi chữ "Đang lưu..." (không vòng xoay); số điện thoại sai chỉ có dòng lỗi, viền ô không đỏ (VField bọc ngoài không đánh dấu invalid); Email khoá mờ không có câu giải thích. (Đã sửa 10-8k: SĐT lỗi viền đỏ, bỏ gạch chồng thanh dưới)
58. Đặt lại mật khẩu từ tài khoản mở bằng `Navigator.push`, trong khi router cũng khai báo `/more/my-account/reset-password` → hai lối vào cùng màn (ca reset/from-account ở đợt 1). (Giữ 10-8k: vẫn `Navigator.push` để quay về đúng trang; route giữ cho lối vào trực tiếp.)

## Khác biệt có chủ đích với Flutter

- Icon: Material thay bằng nét kiểu Lucide trong `shared/icons.js`, giữ ý nghĩa và cỡ.
- Font: không nạp Inter (như các prototype 10-8 khác).
- Ô mật khẩu có giá trị vẽ bằng `<input type="password">` (chấm tròn của trình duyệt).
- Không vẽ: dialog chọn ngày, bàn phím, autofill; toast "Chào mừng đến Mosaic Retail!" sau khi tạo cửa hàng (hiện ở Trang chủ).
