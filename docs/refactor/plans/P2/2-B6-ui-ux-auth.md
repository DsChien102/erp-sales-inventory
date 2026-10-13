# 2-B6 — Hoàn thiện UI/UX các màn auth (đăng nhập, đăng ký, xác minh email, lời mời)

> Phase: P2 · Trạng thái: Plan ✅ (duyệt 2026-10-13) | Làm ⬜ | Review ⬜
> **Làm sau khi 2-B5 commit** (2-B5 đang sửa `invitation_token_page.dart`, `invitation_acceptance_cubit.dart` — chưa commit lúc viết plan).
> Nguồn: `/impeccable audit apps/erp/lib/features/auth` (2026-10-13, đọc mã nguồn + đối chiếu TH-01 mục 5.2–5.6, 5.12). Điểm: **13/20** (Tiếp cận 2 · Hiệu năng 3 · Theme 3 · Chuẩn nền tảng 2 · Thích ứng 3).
> Tài liệu liên quan: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) mục 4 (FR / chuỗi chuẩn), 5.2 ID-01, 5.3 ID-02, 5.4, 5.6 ID-06/07, 5.12; BR-65; [10-5](../P10/10-5-tuong-phan-tone-va-vien-o-nhap.md), [10-6](../P10/10-6-vung-cham-nhan-inset-chuyen-dong.md) (sửa phía design system, độc lập với plan này).

## 1. Mục tiêu

Các màn auth — phần đầu tiên của kịch bản demo — **khớp wireframe TH-01**, báo lỗi đúng chỗ, không có ngõ cụt, dùng được với VoiceOver / TalkBack và **tự điền mật khẩu / mã** của iOS và Android. Không đổi luồng, không đổi chuỗi đã chốt trong TH-01; chỉ đổi cách trình bày và hành vi UI.

## 2. Hiện trạng (đo 2026-10-13)

### 2.1 Lệch đặc tả / ngõ cụt (P1)

| # | Vấn đề | Vị trí | Đặc tả |
|---|---|---|---|
| A | Sheet xác nhận lời mời chỉ có "Mã lời mời hợp lệ." — **không hiện Tổ chức, Vai trò, Email**; người dùng bấm "Xác nhận" mà không biết vào đâu, với vai trò gì. `InvitationTokenInspection` đã có `tenantName`, `initialRoleLabel`, `inviteeEmail` | `widgets/invitation_confirm_bottom_sheet.dart` | 5.6 V-04: "Tổ chức / Vai trò / Email" |
| B | Màn nhập mã lời mời **không có nút "Tiếp tục"**, chỉ tự gửi khi đủ 8 ký tự. `VVerificationCodeField` chỉ gọi `onCompleted` **một lần cho mỗi mã** (`_lastCompleted`) ⇒ sau lỗi mạng hoặc khi người dùng vuốt đóng sheet xác nhận (trả `null`), **không gửi lại được** nếu không sửa mã | `widgets/invitation_token_entry_form.dart`; DS `v_verification_code_field.dart:186-195` | 5.6 wireframe: `[ Tiếp tục ]` |
| C | Đăng ký: lỗi validate chỉ **một dòng ở cuối danh sách**, dưới nút; không trường nào được đánh dấu đỏ; trên điện thoại dòng lỗi thường nằm ngoài màn. Bước 2 kiểm "địa chỉ" trước "tên cửa hàng" (ngược thứ tự hiển thị) | `pages/signup_page.dart:182-185`; `logic/signup_cubit.dart:156-183`; `signup_state.dart` (`String? failure`) | FR-03 (chuỗi lỗi) |

### 2.2 Tiếp cận và chuẩn nền tảng

| # | Vấn đề | Vị trí |
|---|---|---|
| D | Nút dạng link (`VButtonVariant.link`) **không có vùng chạm tối thiểu** — cao bằng dòng chữ (~20px). Màn auth dùng 6 chỗ: "Quên mật khẩu?", "Kích hoạt tài khoản", "Đã có tài khoản? Đăng nhập", "Gửi lại mã", "Đăng xuất" (`/verify-email`), "Quên mật khẩu" (email đã đăng ký); cả app 10 chỗ | DS `components/v_button.dart` `_VLinkButton.build` (~564-603) |
| E | Nút quay lại **không có nhãn** cho trình đọc màn hình và **3 icon khác nhau**: `Icons.chevron_left` (Material, đăng ký), `VIcons.arrowLeft` (2 màn lời mời), `VIcons.chevronLeft` (`VAppBar`) | `signup_page.dart:156`, `invitation_token_entry_form.dart:50`, `invitation_registration_form.dart:137` |
| F | **Không có tự điền**: không `AutofillGroup`, không `autofillHints`, không `textInputAction` → iOS Keychain / Android Autofill không gợi ý email, mật khẩu, mật khẩu mạnh, mã 6 số từ email; bàn phím không có "Tiếp" giữa các ô. DS chưa có tham số cho việc này | `login_page.dart`, `signup_page.dart`, `invitation_registration_form.dart`; DS `forms/v_email_field.dart`, `v_password_field.dart`, `v_phone_field.dart`, `components/v_text_field.dart` |
| G | Ô mã 6 số là `TextField` Material thô (`OtpCodeField`): không nhãn (chỉ hint `••••••`), không `AutofillHints.oneTimeCode`, không tự gửi khi đủ 6 số, khác hẳn ô mã lời mời 8 ký tự. DS đã có `VVerificationCodeField` (ô từng ký tự, dán cả mã, `oneTimeCode`, semantics) | `widgets/otp_code_field.dart`, `widgets/verify_email_view.dart:95` |

### 2.3 Trình bày lệch wireframe (P2)

| # | Vấn đề | Vị trí | Đặc tả |
|---|---|---|---|
| H | Lỗi đăng nhập ngoài "sai email / mật khẩu" hiện bằng **toast** (tự mất) | `login_page.dart:211-216` | 5.2 A-03: "thông điệp dưới form" |
| I | Lỗi khi kiểm mã lời mời hiện bằng **toast** (có `message: ''` rỗng), ô mã không báo lỗi | `invitation_token_page.dart:133-137` | 5.6 V-02: "thông điệp theo mã" |
| J | Đăng ký: chỉ báo bước là chữ "1/3 · Tài khoản"; thiếu dấu `*` bắt buộc; ô mật khẩu không có mô tả quy tắc ≥ 8 ký tự (form lời mời có); SĐT dùng `VTextField` (form lời mời dùng `VPhoneField`) | `signup_page.dart:74, 175-180, 213-293` | 5.3 wireframe `●───○───○`, `Họ và tên đệm *`; BR-65 |
| K | `/no-organization`: `Column` + 2 `Spacer`, **không cuộn** → tràn khi chữ lớn / xoay ngang | `pages/no_organization_page.dart` | — |

### 2.4 Nhỏ (P3)

| # | Vấn đề | Vị trí |
|---|---|---|
| L | "Quên mật khẩu?" khi chưa nhập email: vừa lỗi dưới ô **vừa** toast (trùng) | `login_page.dart:148-158` |
| M | Logo: gradient `primary → primaryFocus` nay cùng màu (sau 10-4) nên phẳng; trình đọc đọc "V45" rồi "VET45" (thừa) | `login_page.dart:245-276` |
| N | Tiêu đề màn (`/no-organization`, `/verify-email`, kết quả lời mời, sheet xác nhận) không có `header` semantics → không nhảy theo tiêu đề được | 4 file |
| O | Link "Kích hoạt tài khoản" vẫn bấm được khi đang đăng nhập (các nút khác đều khoá) | `login_page.dart:384-388` |

### 2.5 Điểm tốt (giữ, dùng làm mẫu)

- `InvitationRegistrationForm` là **mẫu chuẩn** cho form: lỗi từng trường + `VField(invalid)`, dấu `*` (`VFieldLabel(isRequired: true)`), mô tả quy tắc mật khẩu, nút chính ghim đáy (`VPageScaffold.bottomBar`), xoá mật khẩu khi thoát. Đăng ký nên theo đúng mẫu này.
- Màu đều qua `context.vColors`; chuỗi tiếng Việt khớp TH-01; email che (`maskEmail`); đếm ngược gửi lại; bề ngang giới hạn 450–500 trên màn rộng; nút đăng nhập khoá khi đang gửi.

## 3. Quyết định (đã chốt 2026-10-13)

**Chốt:** Q1–Q4 theo đề xuất; logo màn đăng nhập **nền phẳng `primary`** (Q5).


| # | Câu hỏi | Đề xuất |
|---|---|---|
| Q1 | Sửa 2 chỗ trong design system ngay trong plan này (vùng chạm link; tham số tự điền)? | **Có** — auth cần, và nhỏ. 10-6 không làm lại 2 mục này (ghi chú chéo ở 10-6) |
| Q2 | Lỗi đăng ký hiển thị thế nào? | **Lỗi từng trường** theo mẫu `InvitationRegistrationForm`; kiểm **tất cả** trường một lần; cuộn tới trường lỗi đầu tiên. Lỗi máy chủ (S-08) hiện `VBanner` danger ở đầu bước |
| Q3 | Màn nhập mã lời mời: nút "Tiếp tục" ở đâu? | Ghim đáy (`VPageScaffold.bottomBar`) giống màn kích hoạt tài khoản; vẫn giữ tự gửi khi đủ 8 ký tự |
| Q5 | (M) Logo đăng nhập | Nền phẳng `colors.primary`, bỏ gradient và bóng; `ExcludeSemantics` |
| Q4 | Ô mã 6 số | Thay `OtpCodeField` bằng `VVerificationCodeField(length: 6, charset: numeric)`, tự gửi khi đủ 6 số; xoá `otp_code_field.dart` |

## 4. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| **Design system** | | |
| `packages/vet45_design_system/lib/src/components/v_button.dart` | sửa | `_VLinkButton`: vùng chạm ≥ 44 (D) |
| `…/components/v_input.dart`, `v_text_field.dart`, `forms/v_email_field.dart`, `v_password_field.dart`, `v_phone_field.dart` | sửa | Thêm `autofillHints`, `textInputAction` (truyền xuống `TextField`) (F) |
| `CHANGELOG.md`, `pubspec.yaml` | sửa | `[Unreleased]` + `bump_version.sh --minor` |
| **Auth** | | |
| `widgets/invitation_confirm_bottom_sheet.dart` | sửa | Nhận `InvitationTokenInspection`, hiện 3 dòng Tổ chức / Vai trò / Email (A) |
| `pages/invitation_token_page.dart` | sửa | Truyền `inspection` cho sheet; lỗi kiểm mã → trả về form thay vì toast (I) |
| `widgets/invitation_token_entry_form.dart` | sửa | `bottomBar` "Tiếp tục"; tham số `errorMessage` hiện dưới ô mã; nút quay lại thống nhất (B, I, E) |
| `logic/signup_state.dart`, `logic/signup_cubit.dart` | sửa | Lỗi theo trường (`Map<SignupField, String> fieldErrors`) + `failure` chung; kiểm đúng thứ tự hiển thị (C) |
| `pages/signup_page.dart` | sửa | Lỗi từng trường, `*`, quy tắc mật khẩu, `VSteps`, `VPhoneField`, `AutofillGroup`, nút quay lại (C, E, F, J) |
| `pages/login_page.dart` | sửa | Lỗi dưới form, `AutofillGroup`, logo `ExcludeSemantics`, bỏ toast trùng, khoá link khi gửi (F, H, L, M, O) |
| `widgets/invitation_registration_form.dart` | sửa | `AutofillGroup` + hints; nút quay lại thống nhất (E, F) |
| `widgets/verify_email_view.dart` | sửa | Dùng `VVerificationCodeField` (G) |
| `widgets/otp_code_field.dart` | xoá | (G, Q4) |
| `pages/no_organization_page.dart` | sửa | Cuộn được; tiêu đề `header` (K, N) |
| `pages/verify_email_page.dart`, `widgets/invitation_outcome_view.dart` | sửa | Tiêu đề `header` (N) |
| Test (mục 6.1) | sửa / tạo | `presentation/pages/{login,signup,no_organization}_page_test.dart`, `presentation/invitation/invitation_token_page_test.dart`, `logic/signup_cubit_test.dart`, `presentation/wgt_th01_s0_login_test.dart`; DS: `v_button_test.dart`, test autofill |

## 5. Các bước

### 5.0 Trước khi sửa

1. 2-B5 đã commit.
2. `impact` (upstream) cho `VButton`, `VInput`, `VTextField`, `VEmailField`, `VPasswordField`, `VPhoneField`, `SignupCubit`, `SignupState`, `InvitationTokenEntryForm`, `showInvitationConfirmBottomSheet`, `VerifyEmailView`, `OtpCodeField`, `LoginPage`. Ghi vào mục Review. `VButton` sẽ HIGH (cả app); thay đổi chỉ là vùng chạm của biến thể `link`.

### 5.1 Design system (Q1)

**D — `_VLinkButton`** (`v_button.dart`, khối `GestureDetector` ~590-602): bọc phần chạm trong khung tối thiểu, chữ vẫn căn giữa, không gạch chân rộng ra:

```dart
child: ConstrainedBox(
  constraints: const BoxConstraints(
    minHeight: VSpacing.minTouchTarget,
    minWidth: VSpacing.minTouchTarget,
  ),
  child: Align(
    alignment: Alignment.center,
    widthFactor: widget.expandText ? null : 1,
    heightFactor: 1,
    child: content,
  ),
),
```

Link cao thêm (~20 → 44) ở 10 chỗ trong app → kiểm 6.3. Trên màn đăng nhập có thể giảm `VGap` quanh link để giữ bố cục gần như cũ.

**F — tham số tự điền**: thêm vào `VInput` (nơi dựng `TextField`), rồi truyền qua `VTextField`, `VEmailField`, `VPasswordField`, `VPhoneField`:

```dart
final Iterable<String>? autofillHints;
final TextInputAction? textInputAction;
// TextField(..., autofillHints: widget.autofillHints, textInputAction: widget.textInputAction)
```

Mặc định hợp lý (truyền đè được): `VEmailField` → `[AutofillHints.email]`, `TextInputType.emailAddress`; `VPasswordField` → `[AutofillHints.password]`; `VPhoneField` → `[AutofillHints.telephoneNumber]`.

### 5.2 (A) Sheet xác nhận lời mời

```dart
Future<bool?> showInvitationConfirmBottomSheet({
  required BuildContext context,
  required InvitationTokenInspection inspection,
})
```

Nội dung theo wireframe 5.6:

```text
Xác nhận lời mời tham gia tổ chức?      ← headingH3, Semantics(header: true)
Mã lời mời hợp lệ.
Tổ chức   <tenantName>
Vai trò   <initialRoleLabel>
Email     <inviteeEmail>
[ Xác nhận ]
[ Từ chối ]
```

Ba dòng dùng một hàng nhãn (`textSecondary`, `bodySmall`) + giá trị (`textPrimary`, `labelDefault`), nhãn rộng cố định để thẳng cột; mỗi hàng `MergeSemantics` để đọc "Tổ chức, Thú y An Phát". Thứ tự nút giữ như code (Xác nhận trên, Từ chối dưới) — wireframe đặt ngang, trên điện thoại xếp dọc dễ bấm hơn.

`invitation_token_page.dart:112`: `showInvitationConfirmBottomSheet(context: context, inspection: inspection)`.

### 5.3 (B, I) Màn nhập mã lời mời

`InvitationTokenEntryForm`:
- Thêm `final String? errorMessage;` — hiện `VFieldError(errorMessage)` khi `_error == null`; `VField(invalid: _error != null || errorMessage != null)`. Gõ lại mã → gọi `onEditing` (callback mới) để trang xoá lỗi.
- `VPageScaffold(bottomBar: …)`:

```dart
bottomBar: Padding(
  padding: const EdgeInsets.all(VSpacing.space4),
  child: VButton(
    key: const Key('invitation_token_submit'),
    label: 'Tiếp tục',
    fullWidth: true,
    isLoading: isSubmitting,
    onPressed: isSubmitting ? null : _submit,
  ),
),
```

`_submit()` giữ nguyên kiểm định dạng (chuỗi FR-02). Nút luôn gửi lại được ⇒ hết ngõ cụt sau lỗi mạng / đóng sheet.

`invitation_token_page.dart` (nhánh `tokenEntry` ~133-137): **bỏ toast**, giữ thông điệp trong state để form hiện dưới ô mã. Ánh xạ `code → message` (`_entryFailureToast`) giữ nguyên chuỗi, đổi tên `_entryFailureMessage`, bỏ phần `VToastType`. Cần cubit giữ `failure` ở bước `tokenEntry` tới khi người dùng sửa mã (hiện đang `clearFeedback()` ngay) — đổi: chỉ `clearFeedback()` khi `onEditing` hoặc khi gửi lại.

### 5.4 (C, J, F, E) Đăng ký

**State / cubit:**

```dart
enum SignupField { familyName, givenName, email, phone, password, confirmPassword,
                   storeName, storePhone, province, commune, address, contactEmail }

// SignupState
final Map<SignupField, String> fieldErrors; // const {}
final String? failure;                       // lỗi chung (máy chủ, S-08)
```

- `_validateAccount` / `_validateStore` trả `Map<SignupField, String>` gồm **mọi** lỗi, giữ nguyên chuỗi FR-03 (`'Vui lòng nhập họ và tên đệm'`, `'Email không hợp lệ'`, `'Mật khẩu phải có ít nhất 8 ký tự'`, `'Mật khẩu xác nhận không khớp'`, `'Số điện thoại phải có 9–11 chữ số'`, …).
- Bước 2 kiểm theo thứ tự hiển thị: tên cửa hàng → SĐT → tỉnh → xã → địa chỉ.
- `failure` chỉ còn cho lỗi từ máy chủ; "Email đã được đăng ký" giữ nhánh `emailExists` như cũ.
- Hàm mới `clearFieldError(SignupField f)` gọi từ `onChanged` của từng ô.

**Trang** (theo mẫu `InvitationRegistrationForm`):
- `_field(label:, field:, isRequired:, child:)` → `VField(invalid: state.fieldErrors[field] != null)` + `VFieldLabel(label, isRequired: …)` + `child` + `VFieldError` hoặc `VFieldDescription`.
- `*` cho: Họ và tên đệm, Tên, Email, Mật khẩu, Nhập lại, Tên cửa hàng, SĐT cửa hàng, Tỉnh, Xã, Địa chỉ chi tiết (đúng wireframe 5.3; SĐT cá nhân và Email liên hệ không `*`).
- Ô Mật khẩu: `VFieldDescription(PasswordPolicy.requirementText)` khi không lỗi.
- Ô SĐT: `VPhoneField` thay `VTextField`.
- Chỉ báo bước: `VSteps(steps: [Tài khoản, Cửa hàng, Xác minh email], currentStep: state.step.index)` thay dòng chữ; giữ chữ `1/3 · Tài khoản` làm `semanticLabel` / nhãn bên cạnh cho khớp wireframe.
- Lỗi chung: `VBanner(status: danger, title: state.failure!)` **đầu** bước, không ở cuối.
- Sau khi bấm "Tiếp tục" / "Tạo cửa hàng" có lỗi: cuộn tới trường lỗi đầu tiên (`Scrollable.ensureVisible` với `GlobalKey` của trường đó).
- Tự điền: bọc mỗi bước trong `AutofillGroup`; hints: Họ và tên đệm `familyName`, Tên `givenName`, Email `email`, SĐT `telephoneNumber`, Mật khẩu + Nhập lại `newPassword`, Tên cửa hàng `organizationName`, Địa chỉ `fullStreetAddress`; `textInputAction: next` (ô cuối mỗi bước `done` + `onSubmitted` gọi nút chính).
- Nút quay lại: `VIcon(icon: VIcons.chevronLeft)` + `tooltip: 'Quay lại'` (giữ logic lùi bước hiện có).

### 5.5 (H, F, L, M, O) Đăng nhập

- State `_formError`: lỗi khác `invalidCredentials` → `setState(() => _formError = failure.message)` thay toast; hiện `VBanner(status: VBannerStatus.danger, title: 'Đăng nhập thất bại', description: _formError)` ngay **trên nút "Đăng nhập"** (dưới các ô — "dưới form" theo A-03). Xoá khi sửa email / mật khẩu hoặc gửi lại.
- `AutofillGroup` bọc 2 ô; email `autofillHints: [AutofillHints.username, AutofillHints.email]`, `textInputAction: next`; mật khẩu `[AutofillHints.password]`, `done`. Đăng nhập thành công: `TextInput.finishAutofillContext()` để máy hỏi lưu mật khẩu.
- `_navigateToResetPassword` khi email trống: **chỉ** lỗi dưới ô, bỏ `VToast`.
- Logo (Q5): bọc `ExcludeSemantics`; `BoxDecoration(color: colors.primary, borderRadius: …)` — bỏ `gradient` và `boxShadow`.
- "Kích hoạt tài khoản": `onPressed: isSubmitting ? null : …`.

### 5.6 (G) Ô mã 6 số

`verify_email_view.dart`:

```dart
VField(
  invalid: state.failure != null,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const VFieldLabel('Mã xác minh', isRequired: true),
      KeyedSubtree(
        key: const Key('otp_code_field'), // giữ key cho test
        child: VVerificationCodeField(
          length: 6,
          charset: VVerificationCodeCharset.numeric,
          autofocus: true,
          enabled: !state.submitting,
          semanticLabel: 'Mã xác minh 6 chữ số',
          onChanged: (value) => _code = value,
          onCompleted: (value) => _cubit.verify(value),
        ),
      ),
      if (state.failure != null) VFieldError(state.failure!),
    ],
  ),
),
```

`_code` đổi từ `TextEditingController` sang `String`; nút "Xác minh" vẫn còn (gửi lại được sau lỗi). Xoá `otp_code_field.dart` và import.

### 5.7 (K, N) `/no-organization` và tiêu đề

`no_organization_page.dart`: thay `Padding(Column(Spacer…))` bằng

```dart
LayoutBuilder(builder: (context, c) => SingleChildScrollView(
  padding: const EdgeInsets.all(VSpacing.screenMobile),
  child: ConstrainedBox(
    constraints: BoxConstraints(minHeight: c.maxHeight - VSpacing.screenMobile * 2),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [/* như cũ, bỏ 2 Spacer */]),
  ),
))
```

Tiêu đề màn bọc `Semantics(header: true, child: VText(…))` ở: `no_organization_page`, `verify_email_page` ("Xác minh email để tiếp tục"), `invitation_outcome_view` (title), sheet xác nhận.

### 5.8 (E) Nút quay lại thống nhất

Ba chỗ (`signup_page`, `invitation_token_entry_form`, `invitation_registration_form`) dùng cùng mẫu với `VAppBar`:

```dart
IconButton(
  tooltip: 'Quay lại',
  icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
  onPressed: …, // giữ logic hiện có
)
```

(10-6 thêm `tooltip` cho nút mặc định của `VAppBar`; nếu sau này `VAppBar` nhận `onBack`, ba chỗ này có thể bỏ `leading` tự dựng.)

### 5.9 Tài liệu

1. CHANGELOG design system: *Added* `autofillHints` / `textInputAction` cho field; *Fixed* vùng chạm `VButton.link`. Bump minor.
2. `docs/refactor/plans/P10/10-6-…`: ghi chú "vùng chạm link và tham số tự điền làm ở 2-B6".
3. PLAN.md: dòng 2-B6 (P2).
4. CHECKLIST.md mục P2 — TH-01: tick lại các màn ID-01, ID-02, ID-06/07 sau kiểm tay.

## 6. Kiểm tra

### 6.1 Tự động
- [ ] `dart analyze lib test` (`apps/erp`, `packages/vet45_design_system`): không lỗi mới.
- [ ] `signup_cubit_test`: bước 1 trống → `fieldErrors` có đủ 5 lỗi đúng chuỗi FR-03; bước 2 trống → lỗi đủ 5 trường; `clearFieldError` xoá đúng một trường; lỗi máy chủ vào `failure`, không vào `fieldErrors`.
- [ ] `signup_page_test`: lỗi hiện **dưới đúng ô**; ô lỗi `invalid`; có `*`; có `VSteps`; có mô tả quy tắc mật khẩu.
- [ ] `login_page_test` / `wgt_th01_s0_login_test`: lỗi mạng → banner dưới form, **không** có toast; sai thông tin → lỗi dưới ô email (giữ); quên mật khẩu khi trống → không toast; logo không có trong cây semantics.
- [ ] `invitation_token_page_test`: có nút "Tiếp tục"; lỗi `INVITATION_EXPIRED` → chữ dưới ô mã, không toast; đóng sheet → bấm "Tiếp tục" mở lại sheet; sheet hiện tên tổ chức, vai trò, email.
- [ ] `verify_email_cubit_test` không đổi; widget: dán 6 số → gọi `verify` một lần.
- [ ] `no_organization_page_test`: `textScaleFactor` 2.0 trên màn 320×568 không overflow.
- [ ] Toàn bộ màn auth: `expectLater(tester, meetsGuideline(labeledTapTargetGuideline))` và `meetsGuideline(iOSTapTargetGuideline)` đạt.
- [ ] `flutter test apps/erp/test/features/auth` + test DS: không lỗi mới.
- [ ] `detect_changes()` trước commit.

### 6.2 Kiểm tay (iPhone + Android)
- [ ] Đăng nhập: iOS gợi ý tài khoản từ Keychain; Android gợi ý từ Autofill; bấm "Tiếp" trên bàn phím nhảy sang mật khẩu; mất mạng → banner dưới form vẫn còn khi đọc xong.
- [ ] Đăng ký: bấm "Tiếp tục" khi trống → mọi ô bắt buộc đỏ, màn cuộn tới ô đầu; iOS đề xuất mật khẩu mạnh ở ô Mật khẩu; ô mã 6 số nhận gợi ý mã từ Mail (iOS) và tự xác minh.
- [ ] Lời mời: dán mã → sheet có Tổ chức / Vai trò / Email; vuốt đóng sheet → "Tiếp tục" mở lại; mã hết hạn → chữ dưới ô.
- [ ] VoiceOver / TalkBack đi hết 4 màn: mọi nút có tên ("Quay lại", "Hiện mật khẩu", "Quên mật khẩu?"…), tiêu đề nhảy được bằng rotor.
- [ ] Cỡ chữ lớn nhất + xoay ngang: `/no-organization`, đăng nhập, đăng ký không tràn.

## 7. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Link cao 44 đẩy bố cục 10 chỗ trong app | Kiểm 6.2 + chỉnh `VGap` cục bộ; vùng chạm là yêu cầu chuẩn |
| Đổi `SignupState` làm vỡ test cũ | Test cập nhật trong cùng plan; chuỗi lỗi không đổi |
| Giữ `failure` ở bước `tokenEntry` làm lệch luồng 2-B5 | Chỉ đổi thời điểm `clearFeedback()`; test lời mời của 2-B5 phải còn xanh |
| `AutofillGroup` + `finishAutofillContext` hỏi lưu mật khẩu cả khi đăng nhập sai | Chỉ gọi `finishAutofillContext()` khi `LoginStatus.success` |

## Review

_(Claude ghi sau khi bạn làm xong.)_
