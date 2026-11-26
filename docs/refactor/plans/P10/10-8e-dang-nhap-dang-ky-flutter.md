# 10-8e Đăng nhập, Đăng ký, Xác minh email, Chưa thuộc tổ chức — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bốn màn công khai ID-01, ID-02, ID-03, ID-05 có bố cục iPhone và web đúng prototype Theme 1; gửi lại mã lỗi không còn hiện như sai mã (lỗi 2).

**Architecture:** Mỗi trang giữ cubit, controller, câu lỗi, toast, điều hướng; `build` chọn `XNarrow` / `XWide` bằng `isWideLayout(context)` (10-8d). Ô nhập và `VerifyEmailView` gắn `GlobalKey` ở trang, nên kéo cửa sổ qua 840 thì widget được chuyển chỗ, không dựng lại. Phần dùng chung với Đặt lại mật khẩu (feature `iam`, không được import `auth/presentation`) đặt ở `core/widgets/flow/`.

**Tech Stack:** Flutter, flutter_bloc, go_router, `c45_design_system` 1.10.0.

**Spec:** bản thiết kế "10-8: Theme 1 về Flutter" duyệt trong chat 2026-11-25, phần chung chép ở [10-8d](10-8d-nen-theme1-flutter.md#thiết-kế-đã-duyệt-phần-chung-cho-10-8dk). Nguồn hình: `specs/themes/theme-01/03.design/prototype/html/app/{login,signup,verify}.js`, `app/web/{login,signup,verify}.js`. **Làm sau 10-8d.**

## Global Constraints

- Chữ, thứ tự kiểm lỗi, câu lỗi, RPC, route, `Key` đang có (`login_signup`, `signup_*`, `otp_code_field`, `no_organization_*`) giữ nguyên, trừ điều ghi ở Quyết định.
- Không đổi `LoginCubit`, `SignupCubit`. `VerifyEmailCubit` chỉ đổi theo Q5.
- Màu qua `context.vColors` / `VColors`, khoảng cách `VSpacing`, bo `VRadius`, chữ `VTypography` (`copyWith` cỡ / độ đậm theo CSS). Bề mặt nền xám: `colors.background`.
- Sửa `XWide` không đụng `XNarrow`; hai bố cục không import nhau.
- `AutofillGroup`, `autofillHints`, `textInputAction`, `TextInput.finishAutofillContext()` giữ như cũ ở cả hai bố cục.
- Chỉ chạy test liệt kê ở từng task; **không** chạy `flutter test` toàn app.

## Quyết định

| # | Quyết định | Lý do |
|---|---|---|
| Q1 | Ô nhập (`VField` + ô) do trang dựng, gắn `GlobalKey`, truyền vào bố cục như `Widget` | Giữ chữ, con trỏ, trạng thái hiện mật khẩu khi đổi bố cục; một nơi khai báo hint / autofill / lỗi |
| Q2 | `VerifyEmailView` có `GlobalKey` ở `VerifyEmailPage` (đổi sang `StatefulWidget`) và ở `_SignupViewState` | View tự giữ cubit, bộ đếm và mã đang gõ; dựng lại sẽ mất mã và đếm lại từ đầu |
| Q3 | `VerifyEmailView` thêm `showPrompt` (mặc định `true`). ID-03 iPhone đặt `false` và tự vẽ lời nhắc căn giữa, email che in đậm | `verify.js:56-68` để lời nhắc ngoài thẻ; web và bước 3 Đăng ký để trong |
| Q4 | Thứ tự trong `VerifyEmailView`: ô mã (`layout: fill`) → 24 → "Xác minh" → 8 → gửi lại (cao tối thiểu 44, căn giữa). Còn đếm ngược là chữ thường `textSecondary`, số đều bề ngang; hết là nút link | `verify.js:33-44`, hai khung như nhau |
| Q5 | **Lỗi 2:** `VerifyEmailState.resendFailure` (`String?`) tách khỏi `failure`. `resend()` lỗi (không phải `resendCooldown`) đặt `resendFailure`; bắt đầu `resend()` hoặc `verify()` xoá nó. View nghe `resendFailure` đổi sang khác `null` → `VToast.show(title: 'Không gửi được mã', message: <câu lỗi>, type: danger)`; ô mã không đỏ | Lỗi gửi lại không phải lỗi mã. Xoá lúc bắt đầu để lỗi trùng câu vẫn hiện toast lần hai |
| Q5b | **Sửa kèm:** `VerifyEmailState.resending` (`bool`) tách khỏi `submitting`. `resend()` đặt `resending`, không đặt `submitting`; `canResend` đòi cả hai là `false`. Đang gửi lại: link "Gửi lại mã" tắt, ô mã và "Xác minh" dùng bình thường | Hiện bấm "Gửi lại mã" thì nút "Xác minh" quay và ô mã bị khoá (`verify_email_cubit.dart`, `resend()` dùng chung `submitting`) |
| Q6 | `ResendCountdown` chuyển sang `core/widgets/flow/resend_countdown.dart`, giữ chữ và định dạng `mm:ss` | 10-8f dùng chung (lỗi 4) |
| Q7 | Dòng bản quyền: bố cục hẹp giữ chữ "© Mosaic Retail · Phiên bản Mobile" và điều kiện `!kIsWeb`; `LoginWide` ghi "© Mosaic Retail" ở đáy khối thương hiệu (cột form khi xếp dọc 840–899). Sửa prototype web trước (Task 2 Step 0); code `web/login.js` chép bên dưới là bản trước khi sửa | Người dùng chọn 2026-11-25: web không phải bản Mobile |
| Q8 | `LoginWide` ≥ 900 chia hai phần (42% trái); 840–899 khối thương hiệu là dải trên đầu | `t1-web.css:26` |
| Q9 | "Quên mật khẩu?" trên dòng nhãn Mật khẩu (web) là `VButton` link cỡ chữ 13 trong `SizedBox(height: 32)`; thứ tự Tab: Email → Mật khẩu → Quên mật khẩu? → Đăng nhập | `t1-web.css:22-24`; đặt link trước ô theo hình nhưng Tab không được chen giữa hai ô (`FocusTraversalOrder`) |
| Q10 | Màu prototype không có tên riêng trong `VColorScheme`: `icon-brand` → `textBrand`, `icon-secondary` → `textMuted`, `primary-800` → `VColors.primary800` | Cùng mã màu |
| Q11 | Trang công khai hẹp dùng `LayoutBuilder` làm chiều cao tối thiểu, thay `MediaQuery.size.height` | Bàn phím mở thì `Spacer` co lại thay vì đẩy dòng cuối ra ngoài |

## Ảnh

Nguồn: `tools/proto-final/`, chép 2026-11-25. Ảnh `verify__resend-failed` chụp lại ở Task 1. Cột Flutter: golden Task 2–5 (`img/10-8e/flutter-<ca>-{390,1280}.png`).

| Ca | 390 | 1280 |
|---|---|---|
| login__default | ![](img/10-8e/proto-login__default-390.png) | ![](img/10-8e/proto-login__default-1280.png) |
| login__wrong-credentials | ![](img/10-8e/proto-login__wrong-credentials-390.png) | ![](img/10-8e/proto-login__wrong-credentials-1280.png) |
| login__network | ![](img/10-8e/proto-login__network-390.png) | ![](img/10-8e/proto-login__network-1280.png) |
| login__joined | ![](img/10-8e/proto-login__joined-390.png) | ![](img/10-8e/proto-login__joined-1280.png) |
| login__submitting | ![](img/10-8e/proto-login__submitting-390.png) | ![](img/10-8e/proto-login__submitting-1280.png) |
| signup__account | ![](img/10-8e/proto-signup__account-390.png) | ![](img/10-8e/proto-signup__account-1280.png) |
| signup__account-errors | ![](img/10-8e/proto-signup__account-errors-390.png) | ![](img/10-8e/proto-signup__account-errors-1280.png) |
| signup__store | ![](img/10-8e/proto-signup__store-390.png) | ![](img/10-8e/proto-signup__store-1280.png) |
| signup__store-errors | ![](img/10-8e/proto-signup__store-errors-390.png) | ![](img/10-8e/proto-signup__store-errors-1280.png) |
| signup__server-error | ![](img/10-8e/proto-signup__server-error-390.png) | ![](img/10-8e/proto-signup__server-error-1280.png) |
| signup__email-exists | ![](img/10-8e/proto-signup__email-exists-390.png) | ![](img/10-8e/proto-signup__email-exists-1280.png) |
| signup__verify | ![](img/10-8e/proto-signup__verify-390.png) | ![](img/10-8e/proto-signup__verify-1280.png) |
| verify__default | ![](img/10-8e/proto-verify__default-390.png) | ![](img/10-8e/proto-verify__default-1280.png) |
| verify__countdown | ![](img/10-8e/proto-verify__countdown-390.png) | ![](img/10-8e/proto-verify__countdown-1280.png) |
| verify__resend-failed | ![](img/10-8e/proto-verify__resend-failed-390.png) | ![](img/10-8e/proto-verify__resend-failed-1280.png) |
| no-org__default | ![](img/10-8e/proto-no-org__default-390.png) | ![](img/10-8e/proto-no-org__default-1280.png) |

Lệch chấp nhận: icon Lucide thay Material (README prototype); font icon không nạp trong golden; chữ có thể lệch dưới 1 px do Inter.

## Code prototype (chép nguyên văn, token thay bằng giá trị)

### ID-01

`app/login.js:38-66`

```js
const entryRow = (ic, title, { ask = '', disabled = false } = {}) => `<button type="button" class="t1-login__row"${disabled ? ' disabled' : ''}>${icon(ic, 't1-login__rowic')}<span class="t1-login__rowtext">${ask ? `<small>${ask}</small>` : ''}<b>${title}</b></span>${icon('chevronRight', 't1-login__rowgo')}</button>`;

export function loginPage(v) {
  const s = { email: '', password: '', ...STATES[v.state] };
  const busy = !!s.submitting;
  const form = `<div class="t1-form">
      ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.emailError }), error: s.emailError })}
      ${field({ label: 'Mật khẩu', control: input({ value: s.password, hint: 'Nhập mật khẩu', password: true, invalid: !!s.passwordError }), error: s.passwordError })}
      ${s.formError ? banner('error', 'Đăng nhập thất bại', s.formError) : ''}
      ${button('Đăng nhập', { full: true, loading: busy, attrs: 'data-primary', cls: 't1-login__cta' })}
      <div class="t1-login__forgot">${button('Quên mật khẩu?', { variant: 'link', disabled: busy })}</div>
    </div>`;
  const body = `<div class="t1-login">
    <div class="t1-login__brand">
      <img class="t1-login__logo" src="assets/app-icon.png" alt="" width="64" height="64">
      <div><h1 class="t1-login__name">Mosaic Retail</h1><p class="t1-login__tagline">Quản trị bán hàng thuốc thú y</p></div>
    </div>
    ${s.resetSuccess ? `<div class="t1-login__banner">${banner('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.')}</div>` : ''}
    ${s.joined ? `<div class="t1-login__banner">${banner('success', 'Tham gia tổ chức thành công', joinedMessage(s.joined))}</div>` : ''}
    ${card(form, 't1-login__card')}
    ${card(entryRow('store', 'Đăng ký cửa hàng mới', { disabled: busy }) + entryRow('mail', 'Kích hoạt tài khoản', { ask: 'Bạn đã nhận được lời mời?', disabled: busy }), 't1-login__list')}
    <span class="t1-spacer"></span>
    <p class="t1-login__foot">© Mosaic Retail · Phiên bản Mobile</p>
  </div>`;
  return {
    page: `<div class="t1-page t1-page--canvas t1-page--login"><div class="t1-scroll"><div class="t1-col" style="max-width:${authColumn(v.width)}">${body}</div></div></div>`,
    overlay: s.toast ? toast('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.', { device: v.device }) : '',
  };
}
```

`app/web/login.js:5-42`

```js
export function loginPage(v) {
  const s = { email: '', password: '', ...STATES[v.state] };
  const busy = !!s.submitting;
  const banners = [
    s.resetSuccess ? banner('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.') : '',
    s.joined ? banner('success', 'Tham gia tổ chức thành công', joinedMessage(s.joined)) : '',
  ].join('');
  // "Quên mật khẩu?" nằm cùng dòng nhãn Mật khẩu.
  const password = `<div class="t1-field${s.passwordError ? ' is-invalid' : ''}">
        <div class="t1-wlogin__labelrow">${fieldLabel('Mật khẩu')}${button('Quên mật khẩu?', { variant: 'link', disabled: busy })}</div>
        ${input({ value: s.password, hint: 'Nhập mật khẩu', password: true, invalid: !!s.passwordError })}${s.passwordError ? fieldError(s.passwordError) : ''}
      </div>`;
  const foot = '<p class="t1-wlogin__foot">© Mosaic Retail · Phiên bản Mobile</p>';
  // Khối thương hiệu: dải nền surfaceBrand trên đầu (hẹp); cột trái 42% (≥ 900px), dòng bản quyền đáy cột.
  const page = `<div class="t1-page t1-page--surface t1-page--login"><div class="t1-scroll"><div class="t1-wlogin">
    <div class="t1-wlogin__panel">
      <div class="t1-wlogin__brand"><img class="t1-wlogin__logo" src="assets/app-icon.png" alt="" width="72" height="72"><div><h1 class="t1-wlogin__name">Mosaic Retail</h1><p class="t1-wlogin__tagline">Quản trị bán hàng thuốc thú y</p></div></div>
      ${foot}
    </div>
    <div class="t1-wlogin__main">
      <div class="t1-wlogin__form">
        ${banners ? `<div class="t1-wlogin__banners">${banners}</div>` : ''}
        ${field({ label: 'Email', control: input({ value: s.email, hint: 'Nhập email', invalid: !!s.emailError }), error: s.emailError })}
        ${password}
        ${s.formError ? banner('error', 'Đăng nhập thất bại', s.formError) : ''}
        ${button('Đăng nhập', { full: true, loading: busy, attrs: 'data-primary' })}
      </div>
      <div class="t1-wlogin__signup">${button('Đăng ký cửa hàng mới', { variant: 'secondary', full: true, disabled: busy })}</div>
      <div class="t1-wlogin__invite"><p>Bạn đã nhận được lời mời?</p>${button('Kích hoạt tài khoản', { variant: 'link', disabled: busy })}</div>
      <span class="t1-spacer"></span>
      ${foot}
    </div>
  </div></div></div>`;
  return {
    page,
    overlay: s.toast ? toast('success', 'Cập nhật mật khẩu thành công', 'Mật khẩu đã được đặt lại. Vui lòng đăng nhập lại.', { device: v.device }) : '',
  };
}
```

`styles/t1.css:137-166`

```css
/* ------------------------------------------------ Đăng nhập (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
/* Vùng thanh trạng thái cùng nền canvas với màn (SafeArea). */
.sh-app[data-device="iphone"]:has(.t1-page--login, .t1-page--vmail) > .app-statusbar { background: #F6F8F9 /*surface-canvas*/; }
/* Đệm đáy 34 = thanh Home. */
.t1-login { flex: 1 0 auto; display: flex; flex-direction: column; padding: 32px 16px 34px; }
.t1-login > * { flex: 0 0 auto; }
.t1-login > .t1-spacer { flex: 1 1 auto; }
.t1-login__brand { display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center; }
/* Icon app (apps/erp/assets/icon/app_icon.png, thu về 256); viền để tách khỏi nền canvas. */
.t1-login__logo { display: block; width: 64px; height: 64px; border: 1px solid #BDD9C2 /*border-brand*/; border-radius: 12px /*radius-4*/; }
.t1-login__name { margin: 0; font-size: 22px; line-height: 32px; font-weight: 700; letter-spacing: -0.3px; color: #0E1116 /*text-primary*/; }
.t1-login__tagline { margin: 0; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-login__banner { margin-top: 24px; }
.t1-login__card { margin-top: 24px; padding: 20px 16px 8px; }
.t1-login__banner + .t1-login__card { margin-top: 16px; }
.t1-login__cta { margin-top: 8px; }
.t1-login__forgot { display: flex; justify-content: center; margin-top: calc(-1 * 8px); }
.t1-login__list { margin-top: 16px; overflow: hidden; }
.t1-login__row { display: flex; align-items: center; gap: 12px; width: 100%; min-height: 60px; padding: 8px 16px; border: 0; background: transparent; text-align: left; color: #0E1116 /*text-primary*/; cursor: pointer; }
.t1-login__row + .t1-login__row { border-top: 1px solid #E5E8EB /*border-default*/; }
.t1-login__row:hover:not(:disabled) { background: #F8FAFB /*neutral-50*/; }
.t1-login__row:focus-visible { outline-offset: -2px; }
.t1-login__row:disabled > * { opacity: 0.4 /*opacity-disabled*/; }
.t1-login__row:disabled { cursor: default; }
.t1-login__rowic { font-size: 20px; color: #26612F /*icon-brand*/; }
.t1-login__rowgo { font-size: 18px; color: #6B7480 /*icon-secondary*/; }
.t1-login__rowtext { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.t1-login__rowtext b { font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 600; }
.t1-login__rowtext small { font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-login__foot { margin: 0; padding-top: 24px; text-align: center; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
```

`styles/t1-web.css:8-36`

```css
/* Đăng nhập: khối thương hiệu (surfaceBrand) + cột form 400. Hẹp: dải đầu màn; ≥ 900px: cột trái 42%. */
.t1-wlogin { flex: 1 0 auto; display: flex; flex-direction: column; }
.t1-wlogin__panel { display: flex; flex-direction: column; padding: 24px 20px; background: #EBF4EE /*surface-brand*/; color: #0E1116 /*text-primary*/; }
.t1-wlogin__brand { display: flex; align-items: center; gap: 12px; }
.t1-wlogin__logo { display: block; flex: none; width: 48px; height: 48px; border: 1px solid #BDD9C2 /*border-brand*/; border-radius: 12px /*radius-4*/; }
.t1-wlogin__name { margin: 0; font-size: 22px; line-height: 28px; font-weight: 700; }
.t1-wlogin__tagline { margin: 2px 0 0; font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 500; color: #1F4D26 /*primary-800*/; }
.t1-wlogin__panel .t1-wlogin__foot { display: none; }
.t1-wlogin__main { flex: 1 0 auto; display: flex; flex-direction: column; width: 100%; max-width: 400px; margin: 0 auto; padding: 32px 20px 16px; }
.t1-wlogin__form { display: flex; flex-direction: column; gap: 20px; }
.t1-wlogin__banners { display: flex; flex-direction: column; gap: 12px; }
.t1-wlogin__labelrow { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.t1-wlogin__labelrow .t1-label { margin: 0; }
.t1-wlogin__labelrow .t1-btn--link { min-height: 32px; font-size: 13px /*fs-sm*/; }
.t1-wlogin__signup { margin-top: 24px; }
.t1-wlogin__invite { display: flex; flex-wrap: wrap; align-items: center; justify-content: center; column-gap: 4px; margin-top: 16px; }
.t1-wlogin__invite p { margin: 0; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-wlogin__foot { margin: 24px 0 0; text-align: center; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #6B7480 /*text-muted*/; }
@media (min-width: 900px) {
  .t1-wlogin { flex-direction: row; }
  .t1-wlogin__panel { flex: 0 0 42%; justify-content: space-between; padding: 48px; }
  .t1-wlogin__brand { flex-direction: column; align-items: flex-start; gap: 24px; }
  .t1-wlogin__logo { width: 72px; height: 72px; }
  .t1-wlogin__name { font-size: 36px; line-height: 44px; letter-spacing: -0.01em; }
  .t1-wlogin__tagline { margin-top: 8px; font-size: 16px /*fs-lg*/; line-height: 24px; }
  .t1-wlogin__panel .t1-wlogin__foot { display: block; margin: 0; text-align: left; }
  .t1-wlogin__main { justify-content: center; padding: 48px 32px; }
  .t1-wlogin__main > .t1-wlogin__foot, .t1-wlogin__main > .t1-spacer { display: none; }
}
```


### ID-02

`app/signup.js:66-128`

```js
function accountStep(s) {
  const a = { ...EMPTY_ACCOUNT, ...s.account };
  const e = s.errors || {};
  const f = (label, key, ctl, { required = true, desc } = {}) => field({ label, required, control: ctl({ invalid: !!e[key] }), error: e[key], desc });
  return `<div class="t1-form">
    <div class="t1-signup__names">
      ${f('Họ và tên đệm', 'familyName', (o) => input({ ...o, value: a.familyName, hint: 'Nguyễn Thị' }))}
      ${f('Tên', 'givenName', (o) => input({ ...o, value: a.givenName, hint: 'Lan' }))}
    </div>
    ${f('Email', 'email', (o) => input({ ...o, value: a.email, hint: 'lan@example.com' }))}
    ${f('Số điện thoại', 'phone', (o) => input({ ...o, value: a.phone, hint: '0912 345 678' }), { required: false })}
    ${f('Mật khẩu', 'password', (o) => input({ ...o, value: a.password, hint: 'Nhập mật khẩu', password: true }), { desc: PASSWORD_RULE })}
    ${f('Nhập lại mật khẩu', 'confirmPassword', (o) => input({ ...o, value: a.confirmPassword, hint: 'Nhập lại mật khẩu', password: true }))}
  </div>
  <div class="t1-gap-lg"></div>
  ${button('Tiếp tục', { full: true })}
  <div class="t1-gap-xs"></div>
  <div class="t1-center-row">${button('Đã có tài khoản? Đăng nhập', { variant: 'link' })}</div>`;
}

/**
 * _AdministrativeUnitTouchField: cao 44, đệm ngang 12, viền 1 borderDefault (không phải borderInput như ô nhập), bo 8;
 * icon trước 18 textSecondary, chữ bodyDefault (gợi ý textSecondary), nút xoá 16 khi có giá trị, mũi tên xuống 20.
 * Tắt (chưa có tỉnh): nền surfaceAlt, viền borderDefault 50%, chữ / icon textMuted.
 */
function unitField({ value, hint, ic, enabled = true, invalid = false }) {
  const cls = ['t1-unit', enabled ? '' : 'is-disabled', invalid ? 'is-invalid' : '', value ? 'has-value' : ''].filter(Boolean).join(' ');
  return `<button type="button" class="${cls}"${enabled ? '' : ' disabled'}>${icon(ic, 't1-unit__lead')}<span class="t1-unit__text">${esc(value || hint)}</span>${value ? `<span class="t1-unit__clear" aria-label="Xoá">${icon('close')}</span>` : ''}${icon('chevronDown', 't1-unit__chev')}</button>`;
}

export function unitSection({ province = '', commune = '', provinceError, communeError, required = true }) {
  return `<div class="t1-form">
    ${field({ label: 'Tỉnh / thành phố', required, control: unitField({ value: province, hint: 'Chọn tỉnh / thành phố', ic: 'mapPin', invalid: !!provinceError }), error: provinceError })}
    ${field({ label: 'Xã / phường', required, control: unitField({ value: commune, hint: province ? 'Chọn xã / phường' : 'Chọn tỉnh / thành phố trước', ic: 'building', enabled: !!province, invalid: !!communeError }), error: communeError })}
  </div>`;
}

export function storeStep(s) {
  const st = { ...EMPTY_STORE, ...s.store };
  const e = s.errors || {};
  const busy = !!s.submitting;
  return `<div class="t1-form">
    ${field({ label: 'Tên cửa hàng', required: true, control: input({ value: st.name, hint: 'Thú y An Phát', invalid: !!e.storeName }), error: e.storeName })}
    ${field({ label: 'Số điện thoại cửa hàng', required: true, control: input({ value: st.contactPhone, hint: '0912 345 678', invalid: !!e.storePhone }), error: e.storePhone })}
    ${unitSection({ province: st.province, commune: st.commune, provinceError: e.province, communeError: e.commune })}
    ${field({ label: 'Địa chỉ chi tiết', required: true, control: input({ value: st.addressText, hint: 'Số nhà, tên đường...', invalid: !!e.address }), error: e.address })}
    ${field({ label: 'Email liên hệ', control: input({ value: st.contactEmail, hint: 'lan@example.com' }) })}
    <p class="t1-small">Thông tin pháp lý (mã số thuế) có thể bổ sung sau trong Hồ sơ tổ chức.</p>
  </div>
  <div class="t1-gap-lg"></div>
  <div class="t1-row2">
    ${button('Quay lại', { variant: 'secondary', disabled: busy })}
    ${button(busy ? 'Đang tạo...' : 'Tạo cửa hàng', { loading: busy })}
  </div>`;
}

export function emailExists() {
  return `<div class="t1-field is-invalid">${fieldError('Email đã được đăng ký')}</div>
  <div class="t1-gap-lg"></div>
  ${button('Đăng nhập', { full: true })}
  <div class="t1-gap-md"></div>
  ${button('Quên mật khẩu', { variant: 'link' })}`;
}
```

`app/signup.js:155-170`

```js
export function signupPage(v) {
  const s = STATES[v.state];
  let content;
  if (s.emailExists) content = emailExists();
  else if (s.step === 0) content = accountStep(s);
  else if (s.step === 1) content = storeStep(s);
  else content = verifyView(v, { state: s.verify, email: 'lan@anphat.vn', cooldown: 59 });
  const body = `<div class="t1-list t1-signup">
    ${progressBar(STEP_TITLES, s.emailExists ? 1 : s.step)}
    <div class="t1-gap-lg"></div>
    ${s.failure ? `${banner('error', s.failure)}<div class="t1-gap-md"></div>` : ''}
    ${content}
  </div>`;
  const overlay = s.picker ? adaptiveSheet(v.width, pickerBody(s.picker, Math.round(v.height * 0.75)), 'Khu vực hành chính') : '';
  return { page: plainScaffold({ appbar: appBar('Đăng ký cửa hàng', { back: true }), body, width: v.width }), overlay };
}
```

`app/web/signup.js:6-42`

```js
function accountStep(s) {
  const a = { ...EMPTY_ACCOUNT, ...s.account };
  const e = s.errors || {};
  const f = (label, key, ctl, { required = true, desc } = {}) => field({ label, required, control: ctl({ invalid: !!e[key] }), error: e[key], desc });
  return `<div class="t1-form">
    ${f('Họ và tên đệm', 'familyName', (o) => input({ ...o, value: a.familyName, hint: 'Nguyễn Thị' }))}
    ${f('Tên', 'givenName', (o) => input({ ...o, value: a.givenName, hint: 'Lan' }))}
    ${f('Email', 'email', (o) => input({ ...o, value: a.email, hint: 'lan@example.com' }))}
    ${f('Số điện thoại', 'phone', (o) => input({ ...o, value: a.phone, hint: '0912 345 678' }), { required: false })}
    ${f('Mật khẩu', 'password', (o) => input({ ...o, value: a.password, hint: 'Nhập mật khẩu', password: true }), { desc: PASSWORD_RULE })}
    ${f('Nhập lại mật khẩu', 'confirmPassword', (o) => input({ ...o, value: a.confirmPassword, hint: 'Nhập lại mật khẩu', password: true }))}
  </div>
  <div class="t1-gap-lg"></div>
  ${button('Tiếp tục', { full: true })}`;
}

export function signupPage(v) {
  const s = STATES[v.state];
  let content;
  if (s.emailExists) content = emailExists();
  else if (s.step === 0) content = accountStep(s);
  else if (s.step === 1) content = storeStep(s);
  else content = verifyView(v, { state: s.verify, email: 'lan@anphat.vn', cooldown: 59 });
  const cur = s.emailExists ? 1 : s.step;
  // Thanh tiến độ 3 đoạn + thẻ trắng trên nền canvas; tiêu đề thẻ = tên bước. Chọn qua impeccable live (2026-11-24).
  const body = `<div class="t1-stepcol">
    ${progressBar(STEP_TITLES, cur)}
    <div class="t1-stepcard">
      <h2 class="t1-stepcard__title">${esc(STEP_TITLES[cur])}</h2>
      ${s.failure ? `${banner('error', s.failure)}<div class="t1-gap-md"></div>` : ''}
      ${content}
    </div>
    ${cur === 0 && !s.emailExists ? `<div class="t1-center-row t1-stepcol__after">${button('Đã có tài khoản? Đăng nhập', { variant: 'link' })}</div>` : ''}
  </div>`;
  const overlay = s.picker ? adaptiveSheet(v.width, pickerBody(s.picker, Math.round(v.height * 0.75)), 'Khu vực hành chính') : '';
  return { page: `<div class="t1-page t1-page--canvas">${appBar('Đăng ký cửa hàng', { back: true })}<div class="t1-scroll">${body}</div></div>`, overlay };
}
```

`styles/t1.css:183-185`

```css
/* ------------------------------------------------ Đăng ký (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-signup { padding-bottom: 34px; }
.t1-signup__names { display: grid; grid-template-columns: minmax(0, 3fr) minmax(0, 2fr); align-items: start; gap: 12px; }
```

`styles/t1-web.css:38-42`

```css
/* Luồng nhiều bước (Đăng ký, Đặt lại mật khẩu): cột 520 trên nền canvas — thanh tiến độ 3 đoạn, thẻ trắng (viền borderDefault, bo card) chứa bước hiện tại. */
.t1-stepcol { width: 100%; max-width: 520px; margin: 0 auto; padding: 24px 16px 32px; }
.t1-stepcard { margin-top: 24px; padding: 24px 20px; border: 1px solid #E5E8EB /*border-default*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; }
.t1-stepcard__title { margin: 0 0 20px; font-size: 22px; line-height: 28px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-stepcol__after { margin-top: 16px; }
```


### ID-03, ID-05

`app/verify.js:33-81`

```js
function codeForm(v, { state = 'default', cooldown = 59 }) {
  // Cỡ ô (cao 56, chữ 18) tính theo cột 358; bề ngang ô do lưới chia đều.
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = state === 'error' ? '123456' : state === 'filled' || state === 'submitting' ? '482915' : '';
  const busy = state === 'submitting';
  const invalid = state === 'error' || state === 'resend-failed';
  const secs = state === 'can-resend' || state === 'resend-failed' ? 0 : cooldown;
  return `${field({ label: 'Mã xác minh', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, invalid, disabled: busy, focus: !busy && code.length < 6 }), error: state === 'resend-failed' ? RESEND_FAILED : invalid ? OTP_WRONG : null })}
    <div class="t1-gap-lg"></div>
    ${button('Xác minh', { full: true, loading: busy, attrs: 'data-primary' })}
    <div class="t1-verify__resend">${secs > 0 ? `<p class="t1-body2 t1-verify__wait">${resendLabel(secs)}</p>` : button(resendLabel(secs), { variant: 'link' })}</div>`;
}

/** Bước 3 Đăng ký: lời nhắc bodyDefault textSecondary → khe 24 → phần nhập mã. */
export function verifyView(v, { state = 'default', email, cooldown = 59 }) {
  return `<div class="t1-verify">
    <p class="t1-body2">Mã xác minh gồm 6 chữ số đã được gửi tới ${maskEmail(email)}.</p>
    <div class="t1-gap-lg"></div>
    ${codeForm(v, { state, cooldown })}
  </div>`;
}

/** VerifyEmailPage: nền canvas; ô biểu tượng thư 64 + tiêu đề + lời nhắc canh giữa; thẻ nhập mã; "Đăng xuất" (link) ở đáy màn. */
export function verifyPage(v) {
  const email = 'lan@anphat.vn';
  const state = v.state === 'default' ? 'can-resend' : v.state === 'countdown' ? 'default' : v.state;
  const body = `<div class="t1-vmail">
    <div class="t1-vmail__icon" aria-hidden="true">${icon('mail')}</div>
    <h2 class="t1-vmail__title">Xác minh email để tiếp tục</h2>
    <p class="t1-body2 t1-vmail__prompt">Mã 6 chữ số đã được gửi tới <b>${maskEmail(email)}</b>.</p>
    ${card(codeForm(v, { state, cooldown: 59 }), 't1-vmail__card')}
    <span class="t1-spacer"></span>
    <div class="t1-vmail__out">${button('Đăng xuất', { variant: 'link' })}</div>
  </div>`;
  return { page: `<div class="t1-page t1-page--canvas t1-page--vmail"><div class="t1-scroll"><div class="t1-col" style="max-width:${authColumn(v.width)}">${body}</div></div></div>` };
}

/** NoOrganizationPage: nền surface, cột 480; biểu tượng tòa nhà 64 + tiêu đề + mô tả canh giữa vùng trên; "Nhập mã lời mời" + "Đăng xuất" (link) ở đáy màn. */
export function noOrgPage(v) {
  const body = `<div class="t1-noorgm">
    <div class="t1-noorgm__mid">
      <div class="t1-vmail__icon" aria-hidden="true">${icon('building')}</div>
      <h2 class="t1-vmail__title">Bạn chưa thuộc tổ chức nào</h2>
      <p class="t1-body2 t1-noorgm__text">Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.</p>
    </div>
    <div class="t1-noorgm__actions">${button('Nhập mã lời mời', { full: true, attrs: 'data-primary' })}${button('Đăng xuất', { variant: 'link' })}</div>
  </div>`;
  return { page: plainScaffold({ body, width: v.width }) };
}
```

`app/web/verify.js:11-63`

```js
export function verifyView(v, { state = 'default', email, prompt, cooldown = 59, columnWidth }) {
  const col = columnWidth ?? Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = state === 'error' ? '123456' : state === 'filled' || state === 'submitting' ? '482915' : '';
  const busy = state === 'submitting';
  const invalid = state === 'error' || state === 'resend-failed';
  const secs = state === 'can-resend' || state === 'resend-failed' ? 0 : cooldown;
  const text = prompt || `Mã xác minh gồm 6 chữ số đã được gửi tới ${maskEmail(email)}.`;
  return `<div class="t1-verify">
    <p class="t1-body2">${text}</p>
    <div class="t1-gap-lg"></div>
    ${field({ label: 'Mã xác minh', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, invalid, disabled: busy, focus: !busy && code.length < 6 }), error: state === 'resend-failed' ? RESEND_FAILED : invalid ? OTP_WRONG : null })}
    <div class="t1-gap-lg"></div>
    ${button('Xác minh', { full: true, loading: busy })}
    <div class="t1-verify__resend">${secs > 0 ? `<p class="t1-body2 t1-verify__wait">${resendLabel(secs)}</p>` : button(resendLabel(secs), { variant: 'link' })}</div>
  </div>`;
}

/**
 * VerifyEmailPage: nền canvas; cột 520 canh giữa dọc; thẻ trắng (viền borderDefault, bo card, đệm 24/20):
 * ô biểu tượng thư 48 (surfaceBrand) → tiêu đề → VerifyEmailView; "Đăng xuất" (link) dưới thẻ. Chọn qua impeccable live (2026-11-24).
 */
export function verifyPage(v) {
  const email = 'lan@anphat.vn';
  const state = v.state === 'countdown' ? 'default' : v.state;
  const inner = Math.min(v.width, 520) - 32 - 40 - 2; // cột − đệm trang − đệm thẻ − viền
  const page = `<div class="t1-page t1-page--canvas"><div class="t1-scroll"><div class="t1-verify-page">
    <div class="t1-verify-page__card">
      <div class="t1-mailbox" aria-hidden="true">${icon('mail')}</div>
      <h2 class="t1-verify-page__title">Xác minh email để tiếp tục</h2>
      ${verifyView(v, { state: v.state === 'default' ? 'can-resend' : state, email, prompt: `Mã 6 chữ số đã được gửi tới ${maskEmail(email)}.`, cooldown: 59, columnWidth: inner })}
    </div>
    <div class="t1-center-row t1-verify-page__after">${button('Đăng xuất', { variant: 'link' })}</div>
  </div></div></div>`;
  return { page };
}

/**
 * NoOrganizationPage: nền canvas, cột 560 canh giữa dọc; thẻ ngang: ô biểu tượng toà nhà 48 (surfaceBrand) | tiêu đề + mô tả + hai nút
 * ("Nhập mã lời mời" chính, "Đăng xuất" viền; web cùng hàng — nút chính bên phải, iPhone xếp dọc). Chọn qua impeccable live (2026-11-24).
 */
export function noOrgPage(v) {
  const page = `<div class="t1-page t1-page--canvas"><div class="t1-scroll"><div class="t1-noorg">
    <div class="t1-noorg__card">
      <div class="t1-mailbox" aria-hidden="true">${icon('building')}</div>
      <div class="t1-noorg__main">
        <h2 class="t1-noorg__title">Bạn chưa thuộc tổ chức nào</h2>
        <p class="t1-body2">Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.</p>
        <div class="t1-noorg__actions">${button('Nhập mã lời mời', { full: true })}${button('Đăng xuất', { variant: 'secondary', full: true })}</div>
      </div>
    </div>
  </div></div></div>`;
  return { page };
}
```

`styles/t1.css:187-198`

```css
/* ------------------------------------------------ Xác minh email (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-vmail { flex: 1 0 auto; display: flex; flex-direction: column; align-items: center; padding: 32px 16px 34px; }
.t1-vmail__icon { display: grid; place-items: center; width: 64px; height: 64px; border: 1px solid #BDD9C2 /*border-brand*/; border-radius: 12px /*radius-icon-box*/; background: #EBF4EE /*surface-brand*/; color: #26612F /*icon-brand*/; font-size: 28px; }
.t1-vmail__icon--neutral { border-color: #D0D5DA /*border-strong*/; background: #F1F3F5 /*neutral-150*/; color: #2F3640 /*icon-primary*/; }
.t1-vmail__icon--warning { border-color: transparent; background: #F9F1E2 /*surface-warning*/; color: #935A0A /*icon-warning*/; }
.t1-vmail__title { margin: 16px 0 0; text-align: center; text-wrap: balance; font-size: 22px; line-height: 32px; font-weight: 700; letter-spacing: -0.3px; color: #0E1116 /*text-primary*/; }
.t1-vmail__prompt { margin-top: 4px; text-align: center; }
.t1-vmail__prompt b { font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-vmail__card { width: 100%; margin-top: 24px; padding: 20px 16px 8px; }
.t1-vmail__out { margin-top: 16px; }
.t1-verify__resend { display: grid; place-items: center; min-height: 44px; margin-top: 8px; }
.t1-verify__wait { font-variant-numeric: tabular-nums; }
```

`styles/t1.css:208-212`

```css
/* ------------------------------------------------ Chưa thuộc tổ chức (iPhone, impeccable live 2026-11-25; biểu tượng + tiêu đề dùng .t1-vmail__*; web ở t1-web.css) */
.t1-noorgm { flex: 1 0 auto; display: flex; flex-direction: column; padding: 0 16px 34px; }
.t1-noorgm__mid { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 24px 16px; text-align: center; }
.t1-noorgm__text { margin-top: 8px; text-wrap: pretty; }
.t1-noorgm__actions { display: flex; flex-direction: column; gap: 4px; }
```

`styles/t1-web.css:44-66`

```css
/* Xác minh email (/verify-email): cột 520 canh giữa dọc trên nền canvas, thẻ trắng, "Đăng xuất" dưới thẻ. */
.t1-verify-page { flex: 1 0 auto; display: flex; flex-direction: column; justify-content: center; width: 100%; max-width: 520px; margin: 0 auto; padding: 32px 16px; }
.t1-verify-page__card { padding: 24px 20px; border: 1px solid #E5E8EB /*border-default*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; }
.t1-mailbox { display: grid; place-items: center; width: 48px; height: 48px; border-radius: 12px /*radius-icon-box*/; background: #EBF4EE /*surface-brand*/; color: #26612F /*icon-brand*/; }
.t1-mailbox .icon { width: 24px; height: 24px; }
.t1-verify-page__title { margin: 16px 0 8px; font-size: 22px; line-height: 28px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-verify-page__after { margin-top: 16px; }
.t1-stepcard__title--icon { margin: 16px 0 8px; }
.t1-stepcard__rule { margin-top: 24px; padding: 16px; border-radius: 8px /*radius-3*/; background: #F6F8F9 /*surface-canvas*/; }

/* Chưa thuộc tổ chức: cột 560 canh giữa dọc trên nền canvas; thẻ ngang biểu tượng | nội dung; web: hai nút cùng hàng (nút chính bên phải). */
.t1-noorg { flex: 1 0 auto; display: flex; flex-direction: column; justify-content: center; width: 100%; max-width: 560px; margin: 0 auto; padding: 32px 16px; }
.t1-noorg__card { display: flex; gap: 16px; padding: 24px 20px; border: 1px solid #E5E8EB /*border-default*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; }
.t1-noorg__card > .t1-mailbox { flex: none; }
.t1-noorg__main { flex: 1; min-width: 0; }
.t1-noorg__title { margin: 0 0 8px; font-size: 20px; line-height: 28px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-noorg__actions { display: flex; flex-direction: column; gap: 12px; margin-top: 24px; }
@media (min-width: 600px) {
  .t1-noorg__actions { flex-direction: row-reverse; justify-content: flex-start; }
  .t1-noorg__actions .t1-btn--full { display: inline-flex; width: auto; }
}
.t1-stepcard--first { margin-top: 0; }
.t1-stepcard--near { margin-top: 16px; }
```


### Chung

`styles/t1.css:67-73`

```css
.t1-form { display: flex; flex-direction: column; gap: 16px; }   /* VGap.md giữa các ô */
.t1-field { display: flex; flex-direction: column; }
.t1-label { margin-bottom: 8px; font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-label i { font-style: normal; color: #B53232 /*text-danger*/; }
.t1-error, .t1-desc { margin-top: 8px; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; }
.t1-error { color: #B53232 /*text-danger*/; }
.t1-desc { color: #4A535E /*text-secondary*/; }
```

`styles/t1.css:134-135`

```css
.t1-card { border: 1px solid #D0D5DA /*border-strong*/; border-radius: 12px /*radius-card*/; background: #FFFFFF /*surface-default*/; }
.t1-card--pad { padding: 16px; }
```

`styles/t1.css:20-34`

```css
.t1-pad-h { padding: 0 16px; }           /* VPagePadding(horizontal: 16) */

.t1-gap-xs { height: 4px; } .t1-gap-sm { height: 8px; } .t1-gap-md { height: 16px; } .t1-gap-lg { height: 24px; } .t1-gap-xl { height: 32px; }
.t1-mt-xs { margin-top: 4px !important; }
.t1-spacer { flex: 1 1 auto; }
.t1-center-row { display: flex; justify-content: center; }
.t1-text-center { text-align: center; }
.t1-h3 { margin: 0; font-size: 18px /*fs-h3*/; line-height: 26px; font-weight: 700; color: #0E1116 /*text-primary*/; }
.t1-h4 { margin: 0; font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 700; color: #0E1116 /*text-primary*/; } /* headingH4 ép w700 */
.t1-h4--600 { font-weight: 600; } /* headingH4 gốc */
.t1-body2 { margin: 0; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-small { margin: 0; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }

/* ------------------------------------------------ VAppBar: 56 + gạch 1 borderDefault; leading 56 (nút 48 icon 24); tiêu đề H3 w700 cách 16 */
.t1-appbar { flex: 0 0 auto; display: flex; align-items: center; height: 57px; padding: 0 16px; background: #FFFFFF /*surface-default*/; border-bottom: 1px solid #E5E8EB /*border-default*/; }
```


### Ánh xạ phần tử → Flutter

| Prototype | Flutter |
|---|---|
| `.t1-page--canvas` / `--surface` | `Scaffold(backgroundColor: colors.background / colors.surface)` |
| `.t1-col` `authColumn` | `VContentWidth(maxWidth: authMaxWidth, alignment: topCenter)` |
| `.t1-login` + `.t1-spacer` | `LayoutBuilder` → `SingleChildScrollView` → `ConstrainedBox(minHeight)` → `IntrinsicHeight` → `Column` + `Spacer` |
| `.t1-login__logo` 64; `.t1-wlogin__logo` 48 / 72 | `AppLogo(size:)` (10-8d) |
| `.t1-login__name` 22/32 w700 −0,3 | `headingH2.copyWith(fontWeight: w700, letterSpacing: -0.3)`, `Semantics(header: true)` |
| `.t1-card` viền `border-strong` | `VCard(border: …borderStrong, padding: EdgeInsets.zero)`, đệm theo CSS |
| `.t1-stepcard`, `.t1-verify-page__card`, `.t1-noorg__card` viền `border-default` | `FlowCard` |
| `.t1-login__row` (icon 20, chữ, mũi tên 18, ≥ 60) | `_EntryRow` riêng của `LoginNarrow`: `InkWell` trong `Material`, `MergeSemantics` + `Semantics(button, enabled)` |
| `.t1-vmail__icon` 64 viền `border-brand`, icon 28 | `FlowIcon.large(icon)` |
| `.t1-mailbox` 48 không viền, icon 24 | `FlowIcon.medium(icon)` |
| `progressBar` | `VStepProgress(titles: ['Tài khoản', 'Cửa hàng', 'Xác minh email'], variant: …)` |
| `.t1-stepcol` 520, đệm 24 / 16 / 32 | `FlowColumn` |
| `.t1-signup__names` 3fr 2fr khe 12, canh trên | `Row(crossAxisAlignment: start)` `Expanded(flex: 3)`, 12, `Expanded(flex: 2)` |
| `codeField({ fill: true })` | `VVerificationCodeField(layout: VVerificationCodeLayout.fill)` |
| `.t1-verify__resend` | `ResendCountdown` |
| `.t1-noorg__actions` row-reverse | `Row(mainAxisAlignment: end)` [Đăng xuất, 12, Nhập mã lời mời]; tổng rộng không đủ thì `Wrap` |
| đệm đáy `34px` ở các màn iPhone | là thanh Home: để `SafeArea` lo, không cộng thêm 34 |
| icon `store`, `mail`, `building`, `chevronRight` | `VIcons.store`, `VIcons.mail`, `VIcons.apartment` (cho `building`), `VIcons.chevronRight` |

## Bảng "Đang làm gì"

| Thứ bị thay | Đang làm gì | Sau khi sửa | Test giữ hành vi |
|---|---|---|---|
| `LoginPage.build` | `needsVerification` → `/verify-email`; sai mật khẩu → lỗi dưới Email; lỗi khác → banner; thành công → `/` | Nguyên trong trang | có sẵn `login_error_mapping_test`, `wgt_th01_s0_login_test` |
| | Banner đổi mật khẩu, banner tham gia tổ chức (có / không tên) | Nguyên; iPhone trên thẻ, web đầu cột form | có sẵn `wgt_th01_s0_login_test` 6 ca |
| | Gõ lại ô → xoá lỗi ô và banner; Enter ở Mật khẩu → gửi | Nguyên | T0: `typing clears email error and banner`, `enter in password submits` |
| | Đang gửi: bốn lối bấm tắt | Nguyên, hai dòng lối vào iPhone cũng tắt | T0: `submitting disables every action` |
| | `prefilledEmail` đổi → cập nhật ô | Nguyên | T0: `prefilled email updates` |
| `SignupPage.build` | ← : bước Cửa hàng → về Tài khoản; còn lại pop hoặc `/login` | Nguyên | T0: `back from store step returns to account`, `back from account goes to login` |
| | Cuộn tới lỗi đầu tiên; cuộn tới banner lỗi máy chủ | Nguyên (`_fieldKeys`, `_bannerKey` giữ) | có sẵn `typing after account validation…`; T0: `server error banner is scrolled into view` |
| | Bước Cửa hàng: email liên hệ tự điền email tài khoản; đổi tỉnh xoá xã | Nguyên | T0: `contact email defaults to account email` |
| | Email đã đăng ký: lỗi + "Đăng nhập" (mang email) + "Quên mật khẩu" | Nguyên, web nằm trong thẻ | T0: `email exists: login carries the email` |
| | Hoàn tất: toast chào mừng, toast khác tên, `/` | Nguyên | có sẵn `signup_cubit_test`; T0: `completed shows welcome toast and goes home` |
| `VSteps` + nhãn "1/3 · Tài khoản" | Nhãn đọc màn hình | `VStepProgress` nhãn mặc định trùng chữ | có sẵn `signup walks account…` |
| `VerifyEmailView` | Đủ 6 số tự gửi một lần; đếm ngược; `deferSignedIn`; `initialResendCooldown` | Nguyên | có sẵn `verify_email_cubit_test` |
| | Gửi lại lỗi → `VFieldError` dưới ô mã | Toast (**đổi có chủ đích**, lỗi 2) | T1 mới |
| `VerifyEmailPage` "Đăng xuất" | `signOut` rồi `/login` | Nguyên | T0: `verify page sign out goes to login` |
| `NoOrganizationPage` | "Nhập mã lời mời" → `/invitation`; "Đăng xuất" → `/login`; cuộn được ở 320 chữ 2.0 | Nguyên; iPhone "Đăng xuất" thành link | có sẵn 2 ca; T0: `invite goes to invitation`, `sign out goes to login` |
| `w2_behavior_preservation_test` "7 màn công khai ở 1280 ≤ 480" | Bốn màn này rộng ≤ 480 ở 1280 | Bố cục web riêng (**đổi có chủ đích**) | Task 5 tách ca |

## Review Focus

1. **Kéo cửa sổ 900 → 700 → 900 khi đang gõ** ở Đăng nhập, Đăng ký bước 1, và đã gõ 3 số ở Xác minh: chữ, mã, đếm ngược còn nguyên, không gửi OTP lại. Test ở Task 2, 3, 4.
2. **iPhone xoay ngang 844 × 390:** Đăng nhập cuộn được tới "Kích hoạt tài khoản", không tràn. Test ở Task 2.
3. **Gửi lại mã lỗi hai lần liền cùng câu:** toast hiện cả hai lần; sau đó sai mã thì ô đỏ bình thường. Test ở Task 1.
4. **Tên tổ chức dài 80 ký tự** trong banner tham gia, **email dài 60 ký tự** ở lời nhắc xác minh: xuống dòng, không tràn ở 320. Test ở Task 2, 4.
5. **Chữ phóng 2.0 ở 320 × 568:** bốn màn không tràn. Test ở Task 2–5 (một ca mỗi màn).

---

### Task 0: Test giữ hành vi trên code cũ

**Files:**
- Modify: `apps/erp/test/features/auth/presentation/pages/login_page_test.dart`, `signup_page_test.dart`, `no_organization_page_test.dart`
- Create: `apps/erp/test/features/auth/presentation/pages/verify_email_page_test.dart`

**Interfaces:**
- Consumes: `ScriptedAuthRepository`, `loginSession` (`test/features/auth/support/scripted_auth.dart`).
- Produces: không.

- [ ] **Step 1: Viết các ca T0 trong bảng trên**, mỗi ca một `testWidgets` đúng tên ghi ở bảng, khổ 390 × 844, tìm widget bằng `Key` / chữ (không bằng kiểu widget bố cục). Điều hướng kiểm bằng `GoRouter` giả có trang `Text('LOGIN_PAGE')`, `Text('HOME_PAGE')`, `Text('INVITATION_PAGE')`, `Text('RESET_PAGE')`. Khẳng định chính:

```dart
// typing clears email error and banner: bấm Đăng nhập khi trống → gõ Email → find.text('Vui lòng nhập email') findsNothing
// submitting disables every action: signIn treo (Completer) → tap 'Đăng ký cửa hàng mới', 'Kích hoạt tài khoản', 'Quên mật khẩu?' không đổi trang
// email exists: login carries the email: router nhận extra['prefilledEmail'] == 'lan@example.com'
// completed shows welcome toast…: find.text('Cửa hàng Thú y An Phát đã sẵn sàng.') và 'HOME_PAGE'
```

- [ ] **Step 2: Chạy, phải xanh trên code cũ**

Run: `cd apps/erp && flutter test test/features/auth/presentation`
Expected: PASS; ghi tên ca vào mục Kết quả.

- [ ] **Step 3: Commit** `test(10-8e): test giữ hành vi bốn màn công khai`

### Task 1: Gửi lại mã (lỗi 2) + phần dùng chung

**Files:**
- Modify: `specs/themes/theme-01/03.design/prototype/html/app/verify.js`, `app/web/verify.js`, `app/cases.js` (ca `verify/resend-failed`), `tests/t1.test.mjs`
- Move: `features/auth/presentation/widgets/resend_countdown.dart` → `apps/erp/lib/core/widgets/flow/resend_countdown.dart`
- Create: `apps/erp/lib/core/widgets/flow/flow_layout.dart`
- Modify: `features/auth/logic/verify_email_{cubit,state}.dart`, `features/auth/presentation/widgets/verify_email_view.dart`
- Test: `test/features/auth/logic/verify_email_cubit_test.dart`, `test/core/widgets/flow/flow_layout_test.dart` (tạo)

**Interfaces:**
- Consumes: `VVerificationCodeLayout.fill` (10-8d).
- Produces (Task 3–5 và 10-8f dùng):

```dart
// core/widgets/flow/flow_layout.dart
class FlowColumn extends StatelessWidget {      // cột tối đa maxWidth, đệm 24 / 16 / 32, cuộn được, canh trên giữa
  const FlowColumn({super.key, required this.children, this.maxWidth = 520, this.centerVertically = false});
}
class FlowCard extends StatelessWidget {        // nền surface, viền borderDefault 1, bo card, đệm 24 / 20
  const FlowCard({super.key, required this.child, this.padding});
}
class FlowIcon extends StatelessWidget {
  const FlowIcon.large(this.icon, {super.key});   // 64, viền borderBrand, icon 28
  const FlowIcon.medium(this.icon, {super.key});  // 48, không viền, icon 24
}
// nền surfaceBrand, icon textBrand, bo VRadius.iconBox, ExcludeSemantics

// core/widgets/flow/resend_countdown.dart
class ResendCountdown { const ResendCountdown({super.key, required Duration remaining, required VoidCallback? onResend}); }

// VerifyEmailState: String? resendFailure, bool resending = false; copyWith(resendFailure, clearResendFailure = false, resending)
// VerifyEmailView: bool showPrompt = true
```

- [ ] **Step 1: Prototype** — `resend-failed`: `codeForm` / `verifyView` không `invalid`, không `error`; `verifyPage` (hai khung) trả `overlay: toast('danger', 'Không gửi được mã', RESEND_FAILED, { device: v.device })`; câu mô tả ca: "Gửi lại lỗi: toast đỏ, ô mã không đỏ, \"Gửi lại mã\" bấm lại được." Test node: HTML ca này không có `is-invalid`, có `t1-toast--danger`. Chạy `node --test` PASS; `node tools/capture.mjs verify__resend`; chép hai ảnh vào `img/10-8e/proto-verify__resend-failed-{390,1280}.png`.

- [ ] **Step 2: Viết test**

```dart
// verify_email_cubit_test.dart
test('resend failure is not a code failure', …)
  // resendError = AppException(AppErrorCode.network); allowImmediateResend → resend()
  // state.failure isNull; state.resendFailure isNotNull; canResend isTrue
test('verify and resend clear resendFailure', …)
testWidgets('resending keeps the code field and Xác minh usable', …)
  // resendSignupOtp treo (Completer): VButton 'Xác minh' isLoading == false và onPressed != null; ô mã enabled; link gửi lại tắt
testWidgets('resend failure shows a toast each time and keeps cells neutral', …)
  // bấm 'Gửi lại mã' hai lần (đóng toast giữa hai lần) → toast câu lỗi hiện lần 1 và lần 2; VFieldError findsNothing
testWidgets('countdown is text, then a link', …)
  // clock +0: find.text('Gửi lại mã sau 01:00'), không có VButton 'Gửi lại mã'; clock +60s, tick: VButton 'Gửi lại mã' bấm được
testWidgets('verify button comes before resend', …) // dy('Xác minh') < dy(gửi lại)
// flow_layout_test.dart
testWidgets('FlowColumn caps at 520 and keeps 16 gutters at 390', …) // 1280: rộng cột 520 (nội dung 488); 390: nội dung 358
```

- [ ] **Step 3: Chạy → FAIL**

Run: `cd apps/erp && flutter test test/features/auth/logic/verify_email_cubit_test.dart test/core/widgets/flow`
Expected: FAIL

- [ ] **Step 4: Cài đặt** Q3–Q6 (gồm Q5b) và `flow_layout.dart`.
- [ ] **Step 5: Chạy → PASS** (lệnh Step 3) và `flutter test test/features/auth/presentation`.
- [ ] **Step 6: Commit** `fix(10-8e): gửi lại mã lỗi hiện toast, tách phần dùng chung màn nhiều bước`

### Task 2: Đăng nhập

**Files:**
- Create: `apps/erp/lib/features/auth/presentation/widgets/login_narrow.dart`, `login_wide.dart`
- Modify: `apps/erp/lib/features/auth/presentation/pages/login_page.dart`
- Test: `login_page_test.dart`; Create: `apps/erp/test/features/auth/presentation/auth_golden_test.dart`

**Interfaces:**
- Consumes: `AppLogo`, `isWideLayout` (10-8d).
- Produces: hai widget cùng tham số:

```dart
const LoginNarrow({super.key, required Widget emailField, required Widget passwordInput, required String? passwordError,
  required List<Widget> banners, required String? formError, required bool isSubmitting,
  required VoidCallback onSubmit, onForgotPassword, onSignup, onActivate});
// LoginWide giống hệt. emailField = VField đủ nhãn + lỗi; passwordInput = VPasswordField trần (nhãn và lỗi do bố cục vẽ)
// LoginWide: Key('login_wide_panel') khối thương hiệu, Key('login_wide_form') cột 400
// auth_golden_test.dart: Future<void> captureAuth(WidgetTester, {required int width, required String name, required Widget page, Future<void> Function()? act})
//   390 → 390×844, view.padding top 30, bottom 34 (như thanh trạng thái / thanh Home của prototype); 1280 → 1280×800; ảnh img/10-8e/flutter-<name>-<width>.png
```

- [ ] **Step 0: Prototype** — `app/web/login.js`: `const foot` đổi chữ thành `© Mosaic Retail` (iPhone không đổi). Run: `cd specs/themes/theme-01/03.design/prototype/html && node --test` PASS; `node tools/capture.mjs login__`; chép lại năm ảnh web `login__*` vào `img/10-8e/proto-*-1280.png`; `git diff --stat` ảnh iPhone không cần chép lại.

- [ ] **Step 1: Viết test**

```dart
testWidgets('390 uses the narrow layout', …)          // Key('login_wide_panel') findsNothing; 'Đăng ký cửa hàng mới' là dòng cao ≥ 60
testWidgets('1280 footer reads © Mosaic Retail only', …) // find.text('© Mosaic Retail') một; find.textContaining('Phiên bản Mobile') không có
testWidgets('1280 splits 42 / 58', …)                 // panel rộng moreOrLessEquals(537.6, epsilon: 1), cao 800; form rộng 400 (nội dung 336), tâm ngang = giữa phần phải
testWidgets('860 stacks the brand strip', …)          // panel rộng 860, nằm trên form
testWidgets('844x390 landscape scrolls to the last action', …) // không có panel; ensureVisible 'Kích hoạt tài khoản'; takeException isNull
testWidgets('resizing 900 → 700 → 900 keeps typed text and password visibility', …)
testWidgets('wide: Tab order email, password, forgot, submit', …)
testWidgets('320 at text scale 2.0 does not overflow, long org name banner', …) // organizationName 80 ký tự
```

- [ ] **Step 2: Chạy → FAIL** — `cd apps/erp && flutter test test/features/auth/presentation/pages/login_page_test.dart`
- [ ] **Step 3: Cài đặt** theo code prototype + bảng ánh xạ. Sửa ca `auth links satisfy…` để chạy ở 390 và giữ hai `meetsGuideline`.
- [ ] **Step 4: Chạy → PASS** — `flutter test test/features/auth/presentation`
- [ ] **Step 5: Golden** ca `login__{default,wrong-credentials,network,joined,submitting}` × 390, 1280 (`submitting`: `pump(100ms)`, không settle). Run: `flutter test --update-goldens test/features/auth/presentation/auth_golden_test.dart` rồi chạy lại không cờ → PASS. Mở từng ảnh so ảnh prototype; lệch ghi vào Kết quả.
- [ ] **Step 6: Commit** `feat(10-8e): Đăng nhập theo prototype`

### Task 3: Đăng ký 3 bước

**Files:**
- Create: `apps/erp/lib/features/auth/presentation/widgets/signup_narrow.dart`, `signup_wide.dart`
- Modify: `apps/erp/lib/features/auth/presentation/pages/signup_page.dart`
- Test: `signup_page_test.dart`, `auth_golden_test.dart`

**Interfaces:**
- Consumes: `VStepProgress`, `FlowColumn`, `FlowCard`, `VerifyEmailView`.
- Produces:

```dart
const SignupNarrow({super.key, required int stepIndex, required Widget? banner, required Widget content});
const SignupWide({super.key, required int stepIndex, required Widget? banner, required Widget content, required Widget? footer});
// stepIndex: emailExists → 1, còn lại state.step.index. footer = link 'Đã có tài khoản? Đăng nhập' chỉ ở bước 0 khi không emailExists.
// Trang dựng content: _accountStep(wide), _storeStep, VerifyEmailView(key: _verifyKey), _emailExists.
// _accountStep(wide): false → họ + tên cùng hàng và link nằm cuối content (khe 4); true → hai hàng, không link.
// SignupWide: tiêu đề thẻ = ['Tài khoản','Cửa hàng','Xác minh email'][stepIndex], Semantics header; banner dưới tiêu đề
```

- [ ] **Step 1: Viết test**

```dart
testWidgets('390: names share a row 3 : 2', …)        // cùng dy; width(family)/width(given) ≈ 1.5 (trừ khe 12)
testWidgets('390: error under one name keeps the row aligned at top', …)
testWidgets('1280: card 488 wide, names stacked, login link under the card', …)
testWidgets('1280: step 2 and 3 have no login link', …)
testWidgets('resizing keeps typed values and the step', …)        // bước 2 đã nhập tên cửa hàng, 900 → 700 → 900
testWidgets('resizing at step 3 keeps the typed code and cooldown', …) // gõ '123', 900 → 700: ô còn '123', auth.resentEmails rỗng, đếm không về 01:00
testWidgets('320 at text scale 2.0 does not overflow', …)         // bước 1 và bước 2
```

- [ ] **Step 2: Chạy → FAIL** — `flutter test test/features/auth/presentation/pages/signup_page_test.dart`
- [ ] **Step 3: Cài đặt**. `Scaffold` hẹp nền `surface`, web nền `background`; `VAppBar` và ← giữ nguyên.
- [ ] **Step 4: Chạy → PASS** — `flutter test test/features/auth`
- [ ] **Step 5: Golden** ca `signup__{account,account-errors,store,store-errors,server-error,email-exists,verify}` × 2 (đồng hồ của `VerifyEmailView` cố định bằng `clock`). So ảnh, ghi lệch.
- [ ] **Step 6: Commit** `feat(10-8e): Đăng ký cửa hàng theo prototype`

### Task 4: Xác minh email

**Files:**
- Create: `apps/erp/lib/features/auth/presentation/widgets/verify_email_narrow.dart`, `verify_email_wide.dart`
- Modify: `apps/erp/lib/features/auth/presentation/pages/verify_email_page.dart`
- Test: `verify_email_page_test.dart`, `auth_golden_test.dart`

**Interfaces:**
- Consumes: `FlowIcon`, `FlowCard`, `FlowColumn(centerVertically: true)`, `VerifyEmailView(showPrompt:)`.
- Produces: `VerifyEmailNarrow({super.key, required String maskedEmail, required Widget form, required VoidCallback onSignOut})`; `VerifyEmailWide({super.key, required Widget form, required VoidCallback onSignOut})`; `VerifyEmailPage.clock` (`DateTime Function()?`, cho test).

- [ ] **Step 1: Viết test**

```dart
testWidgets('390: centered icon and title, sign out link at the bottom', …) // đáy nút ≤ 844 − 34
testWidgets('390: masked email is bold', …)                                 // RichText có span 'l***@example.com' w600
testWidgets('1280: card 488 wide, vertically centered, sign out under the card', …)
testWidgets('resizing 900 → 700 keeps typed digits', …)                     // '123' còn; auth.otpCodes rỗng
testWidgets('320 at text scale 2.0 and a 60-char email does not overflow', …)
```

- [ ] **Step 2: Chạy → FAIL** — `flutter test test/features/auth/presentation/pages/verify_email_page_test.dart`
- [ ] **Step 3: Cài đặt** theo Q2, Q3.
- [ ] **Step 4: Chạy → PASS** — `flutter test test/features/auth`
- [ ] **Step 5: Golden** ca `verify__{default,countdown,error,resend-failed}` × 2; ca `error` so với `img/10-8d/proto-verify__error-*`. Ghi lệch.
- [ ] **Step 6: Commit** `feat(10-8e): Xác minh email theo prototype`

### Task 5: Chưa thuộc tổ chức + dọn

**Files:**
- Create: `apps/erp/lib/features/auth/presentation/widgets/no_organization_narrow.dart`, `no_organization_wide.dart`
- Modify: `apps/erp/lib/features/auth/presentation/pages/no_organization_page.dart`, `apps/erp/test/features/iam/presentation_module/w2_behavior_preservation_test.dart:711-768`, `docs/refactor/PLAN.md`
- Test: `no_organization_page_test.dart`, `auth_golden_test.dart`

**Interfaces:**
- Consumes: `FlowIcon`, `FlowCard`, `FlowColumn(maxWidth: 560, centerVertically: true)`.
- Produces: hai widget `NoOrganizationNarrow` / `NoOrganizationWide` cùng `({super.key, required VoidCallback onEnterCode, required VoidCallback onSignOut})`.

- [ ] **Step 1: Viết test**

```dart
testWidgets('390: actions at the bottom, sign out is a link', …)  // Key no_organization_invite rộng 358; sign_out variant link
testWidgets('1280: card 528 wide, primary on the right of sign out', …) // left(invite) > right(sign_out)
```

`w2_behavior_preservation_test.dart`: ca "7 màn công khai…" đổi thành hai ca: "3 màn công khai (Lời mời ×2, Đặt lại mật khẩu) ở 1280 ≤ 480" (giữ thân cũ, 10-8f sửa tiếp) và "4 màn công khai ở 800 ≤ 480" (cùng thân, khổ 800).

- [ ] **Step 2: Chạy → FAIL** — `flutter test test/features/auth/presentation/pages/no_organization_page_test.dart`
- [ ] **Step 3: Cài đặt**.
- [ ] **Step 4: Chạy → PASS**

Run: `cd apps/erp && flutter test test/features/auth test/core/widgets test/features/iam/presentation_module/w2_behavior_preservation_test.dart && dart analyze lib test && dart run tool/check_feature_imports.dart`
Expected: PASS, không lỗi analyze mới, không vi phạm import mới

- [ ] **Step 5: Golden** ca `no-org__default` × 2; so ảnh.
- [ ] **Step 6: PLAN.md** dòng Theme 1: 10-8e đã làm. Commit `feat(10-8e): Chưa thuộc tổ chức theo prototype, tách test W-2`

## Kiểm tay (người dùng)

- [ ] iPhone: đăng nhập sai, mất mạng, đúng; Đăng ký đủ 3 bước; xác minh sai mã, gửi lại mã khi tắt mạng (toast, ô không đỏ).
- [ ] Web: cùng các luồng ở 1280; kéo cửa sổ xuống dưới 840 khi đang gõ; dùng Tab / Enter.
- [ ] iPhone xoay ngang ở Đăng nhập.
- [ ] CHECKLIST ID-01, ID-02, ID-03, ID-05 cột "Mới".

## Kết quả

Làm xong 2026-11-26 (commit `151ac74d9` … `7e81f92df`). Test chạy: `flutter test test/features/auth test/core/widgets test/features/iam/presentation_module/w2_behavior_preservation_test.dart` → 189 xanh; `my_account_page_test`, `route_guard_test` xanh; `node --test` (prototype) 21 xanh. `dart analyze lib test` 241 (không đổi so trước), `check_feature_imports` 18 R1 (không đổi).

- **T0** (74 ca trên code cũ): login 4, signup 6, verify 1, no-org 2 ca giữ hành vi.
- **Lỗi 2** (Q5, Q5b): `resendFailure`, `resending` trong `VerifyEmailState`; toast "Không gửi được mã", ô mã không đỏ; gửi lại không khoá "Xác minh". Prototype `verify__resend-failed` sửa + chụp lại.
- **Golden** `img/10-8e/flutter-*`: login 5, signup 7, verify 4 (`default`, `countdown`, `error`, `resend-failed`), no-org 1, mỗi ca 390 và 1280.
- Bản quyền web "© Mosaic Retail" (Q7): prototype `web/login.js` sửa, 5 ảnh web `proto-login__*-1280` chụp lại.

**Quyết định thêm khi làm (ngoài bảng Quyết định):**

| # | Quyết định | Lý do |
|---|---|---|
| R1 | `_emailExists` bọc `VField(invalid: true)` quanh `VFieldError` | Trên code cũ màn "Email đã được đăng ký" ném assertion `VFieldError must be used within a VField` (lỗi có sẵn, T0 lộ ra) |
| R2 | Họ / Tên cùng hàng 3 : 2 chỉ khi chữ phóng ≤ 1.3; hai nút bước Cửa hàng xếp dọc (nút chính trên) khi chữ phóng > 1.3 | `VFieldLabel` không xuống dòng; ca 320 × 2.0 bắt buộc không tràn |
| R3 | `VFieldLabel` (c45_design_system) bọc nhãn trong `Flexible`; ghi CHANGELOG `[Unreleased]` | Nhãn "Số điện thoại cửa hàng" tràn 55 px ở 320 × 2.0; chỉ đổi khi nhãn không vừa |
| R4 | `SignupPage.clock`, `VerifyEmailPage.clock` truyền xuống `VerifyEmailView` | Golden cố định đồng hồ đếm ngược |
| R5 | ID-03 iPhone, ID-05 iPhone dựng bằng `LayoutBuilder` + `ConstrainedBox(minHeight)` + `spaceBetween`, không `IntrinsicHeight` / `SliverFillRemaining` | `VVerificationCodeField(fill)` dùng `LayoutBuilder`, không hỗ trợ kích thước nội tại |
| R6 | "Quên mật khẩu?" web dùng `VButtonSize.small` | `VButton` không có cỡ chữ 13 |
| R7 | Test Tab kiểm thứ tự đi qua `[email, password, forgot, submit]` | Nút hiện mật khẩu nằm giữa ô và link, số lần Tab không cố định |
| R8 | Test toast chào mừng dùng tên cửa hàng trùng tên tổ chức của fake | `VToast` là SnackBar, toast thứ hai xoá toast đầu |

**Lệch so với prototype (chấp nhận):** icon không nạp trong golden (ô vuông); chữ đậm hơn nhẹ do Inter (giãn chữ đã sửa ở R1 G6); `VPasswordField` thêm ~2 px dưới ô nên khối form Đăng nhập iPhone thấp hơn ~2–4 px; link "Quên mật khẩu?" web chữ ~14 thay 13; đếm ngược golden 01:00 (đồng hồ cố định) thay 00:59; Đăng nhập iPhone ca `joined`, `network` cuộn được (nội dung dài hơn khung ở 844, prototype cũng cuộn).

PLAN.md dòng Theme 1: ✅ trước đó là trạng thái plan; trạng thái làm ghi khi xử lý R1 (G15).

## Review

Tự rà lại toàn bộ diff (không có subagent review, theo quy tắc phiên): không thấy lỗi Critical/Important còn lại. Việc cần người khác nhìn: R3 (đổi nhỏ ở `c45_design_system`) và R2 (xếp dọc khi chữ phóng).

### R1 (2026-11-26) — Cần sửa G1–G5; còn lại nhỏ hoặc chờ chọn

Commit xem: `151ac74d9` … `59869b023`.

**Đã kiểm:**
- Đọc toàn bộ diff `lib`, test, prototype; đối chiếu `LoginPage`, `SignupPage`, `VerifyEmailPage`, `NoOrganizationPage` với bản ở `433675dcc`. Điều hướng, câu lỗi, toast, `Key`, hint / autofill của từng ô giữ nguyên. `LoginCubit`, `SignupCubit` không đổi.
- Chạy lại: 189/189 (lệnh Task 5 Step 4, gồm golden khi chạy cả file); `node --test` 21/21; `dart analyze lib test` 241 mục. Design system: `test/components` + `test/patterns` 245/245, `dart analyze lib` sạch.
- Xem cạnh nhau ảnh prototype / Flutter (đủ 34 cặp).
- Test dò tạm (đã xoá) cho G1–G7; G8 chạy riêng một ca golden; G10 phóng to ảnh. G4 chỉ đo ở Đăng nhập, G6 chỉ đo ở mô tả ID-05; các chỗ còn lại đọc code / nhìn ảnh.

| # | Mức | Chỗ | Vấn đề | Đề xuất |
|---|---|---|---|---|
| G1 | **Nặng** | `login_wide.dart` `build` / `_main` | Web tràn đáy **ở cỡ chữ thường** khi cửa sổ thấp và có banner: 860×600 mất mạng 20 px, banner tham gia 20 px; 1280×500 mất mạng 20 px, tham gia 40 px; 1280×600 tên tổ chức dài 20 px, hai banner 60 px; 860×700 hai banner 40 px. Bản release cắt mất phần "Kích hoạt tài khoản" / bản quyền và không cuộn tới được. Nguyên nhân: `IntrinsicHeight` đo chiều cao theo cả cột (742–860 px) vì `ConstrainedBox(maxWidth: 400)` không kẹp bề rộng khi tính kích thước nội tại, nên banner được tính ít dòng hơn lúc vẽ. Test hiện có chỉ chạy 800 px cao, không banner | Giữ `IntrinsicHeight` (bỏ thì `Row` stretch và `Expanded` gặp chiều cao vô hạn). Thay `ConstrainedBox(maxWidth: 400)` bằng `Padding(horizontal: max(0, (rộng cột − 400) / 2))` bọc ngoài `Align`, rộng cột = 0,58 × `constraints.maxWidth` khi chia hai, = cả `constraints.maxWidth` khi xếp dọc; `Key('login_wide_form')` chuyển sang `Padding` đệm bên trong. Đã thử tạm (đã trả lại file): 30/30 ca dò hết tràn, `login_page_test` + golden 51/51 không đổi ảnh. Thêm test: (860×600, 1280×500, 1280×600) × (mất mạng, tham gia tên 80 ký tự, hai banner) không tràn và cuộn tới được "Kích hoạt tài khoản" |
| G2 | **Vừa** | `verify_email_view.dart` `listener` | Một `listener` lo hai việc nên lẫn nhau khi gửi lại và xác minh chồng nhau (Q5b mới cho phép): (a) mã đúng trước, gửi lại lỗi sau → `onVerified` gọi **lần hai** và hiện toast đỏ sau khi đã thành công; (b) gửi lại lỗi trong lúc đang xác minh, rồi mã đúng → toast "Không gửi được mã" hiện **lại**. Đăng ký không hỏng vì `completeAfterVerification` tự chặn; ID-03 gọi `go('/')` hai lần | Tách hai `BlocListener`, mỗi cái `listenWhen` riêng; trong `resend()` nếu `state.verified` thì không đặt `resendFailure`. Test cho (a) và (b) |
| G3 | **Vừa** | `verify_email_cubit.dart` `resend()` | Lùi so với bản cũ: gửi lại **không còn xoá `failure`**. Sai mã → bấm "Gửi lại mã" → gửi được → ô mã vẫn đỏ, vẫn báo "Mã xác minh không đúng…" cho tới lần xác minh sau. Q5 chỉ tách lỗi gửi lại, không bỏ việc xoá này | Thêm `clearFailure: true` ở `emit` đầu `resend()` (chỉ ở đầu, để không xoá lỗi của lượt xác minh chạy chồng). Test: sai mã → `resend()` → `failure` là `null` |
| G4 | Vừa | `login_narrow.dart`, `login_wide.dart`, `signup_page.dart` `AutofillGroup` | `AutofillGroup` không có `GlobalKey` nên kéo qua 840 (và 900 ở Đăng nhập) là huỷ nhóm → Flutter gọi `TextInput.finishAutofillContext(shouldSave: true)`: trình duyệt có thể hỏi lưu mật khẩu đang gõ dở. Đo được ở Đăng nhập khi 900→700 và 860→1000. Trái ràng buộc "`finishAutofillContext()` giữ như cũ" | Trang giữ một `GlobalKey` cho `AutofillGroup` (truyền vào hai bố cục, hoặc bọc `AutofillGroup` ở trang, ngoài bố cục). iPad xoay ngang / dọc (820↔1180) cũng qua mốc 840. Test: đổi 900→700→900 không có lời gọi `finishAutofillContext` |
| G5 | Vừa | `no_organization_narrow.dart`, `verify_email_narrow.dart`, `login_narrow.dart` | Máy / cửa sổ không có thanh Home (iPhone SE, Android nút, web < 840): phần cuối dính sát mép, đáy "Đăng xuất" = 667/667, dòng bản quyền cũng vậy. Trước đây ID-03, ID-05 có đệm 16, Đăng nhập có 16 dưới bản quyền. Plan ghi để `SafeArea` lo phần 34 nên sót ca này | `SafeArea(minimum: EdgeInsets.only(bottom: VSpacing.md))` ở ba bố cục; iPhone có thanh Home không đổi. Test ở 375×667 |
| G6 | Vừa (chung app, cần người dùng chọn) | `VTypography.bodyDefault`, `bodySmall`, `headingH4` | Kết quả ghi chữ lệch do Inter; phần lớn là `letterSpacing 0.25` thừa hưởng của Material (cùng nguyên nhân G1 của 10-8d). Làm đổi số dòng: mô tả ID-05 ở 390 là 3 dòng, lẻ chữ "hàng." (prototype 2 dòng, đo với 0 thì đúng 2). Cùng kiểu, chưa đo riêng: banner tham gia web 3 dòng thay 2; toast 390 3 thay 2; chú thích pháp lý bước Cửa hàng web 2 thay 1 | Đặt `letterSpacing: 0` trong `VTypography` (đúng token) thì ảnh golden toàn app đổi, nên làm thành việc riêng trước 10-8f. Ở đây chỉ sửa câu "Lệch" cho đúng nguyên nhân |
| G7 | Nhỏ | `login_wide.dart` `_passwordBlock` | `SizedBox(height: 32)` cứng: chữ phóng 2.0 nhãn "Mật khẩu" cần 40 nên bị cắt, và hàng tràn ngang (127,6 + 223,7 > 336) | `ConstrainedBox(minHeight: 32)` + `Wrap(alignment: spaceBetween)` |
| G8 | Nhỏ (test) | `auth_golden_test.dart` | Golden phụ thuộc thứ tự chạy: logo chưa nạp ở ca đầu (`login__default-*-390` thiếu logo), các ca sau có. Chạy riêng `login__network 390` đỏ, lệch 1,16% | `precacheImage` trong `tester.runAsync` trước khi chụp; chụp lại |
| G9 | Nhỏ (test) | Golden `signup__*` | Ca gọi thẳng cubit, không điền ô: `store`, `server-error`, `account-errors` trống; Tỉnh / Xã đang ở trạng thái **chưa nạp** (xám) nên viền đỏ ô Tỉnh và ô đã chọn chưa từng được so. Kết quả không ghi lệch này | Điền ô bằng `enterText`, nạp danh sách hành chính bằng `runAsync`, chọn tỉnh / xã rồi chụp lại |
| G10 | Nhỏ | `app_logo.dart` (10-8d) | Viền `borderBrand` mất ở bốn góc: ảnh vuông đè lên viền bo | Viền chuyển sang `foregroundDecoration` |
| G11 | Nhỏ | `signup_page.dart` `_emailExists` | "Quên mật khẩu" ở giữa; prototype (hai khung) canh trái. Kết quả không ghi | Người dùng chọn: giữ giữa (như app cũ) thì ghi vào "Lệch"; theo prototype thì `Align(centerLeft)` |
| G12 | Nhỏ | `flow_layout.dart` | `centerVertically` dùng đệm 24 / 32; prototype ID-03, ID-05 web đệm 32 / 32 nên cột lệch lên 4 px | Khi `centerVertically` thì đệm trên 32 |
| G13 | Nhỏ (test) | Test Task 1, 3, T0 | Thiếu so với plan: Review Focus 3 nửa sau (gửi lại lỗi rồi sai mã → ô đỏ); `resizing at step 3` chỉ tìm "Gửi lại mã sau", không khẳng định đếm không về 01:00 (dùng giờ thật); `typing clears email error and banner` không kiểm banner | Bổ sung khẳng định; ca bước 3 dùng `clock` (R4 đã mở) |
| G14 | Rất nhỏ | `login_narrow.dart`; `signup_{narrow,wide}.dart` | `0.4` ghi cứng (có `VOpacity.disabled` / `vDisabledOpacity`); `_titles` chép hai nơi; `setUp(() {})` thừa trong `login_page_test.dart`; import `resend_countdown` dạng `../../../../core` xếp cuối | Dọn |
| G15 | Rất nhỏ (tài liệu) | Kết quả, PLAN.md | Dấu ✅ của 10-8e ở PLAN.md nằm ở cột "Plan chuyển Flutter" (10-8f…k chưa làm cũng ✅), nên Step 6 "10-8e đã làm" chưa ghi. Ca `network` 390 cũng cuộn, Kết quả chỉ ghi `joined` | Ghi trạng thái làm của 10-8e vào PLAN.md; sửa câu "Lệch" |
| G16 | Ghi nhận (có từ trước) | `signup_page.dart` `completed`; `v_toast.dart:34` | `VToast.show` gọi `clearSnackBars()` trước, nên khi `nameDiffers` người dùng chỉ thấy toast "Thông báo", không thấy "Chào mừng…". R8 đổi test để né ca này; bảng "Đang làm gì" ghi giữ cả hai toast | Gộp hai câu vào một toast khi `nameDiffers`, thêm test; hoặc ghi lại là chấp nhận |

R1–R7 ở Kết quả: đồng ý; R8 xem G16. R1 (bọc `VField` ở màn email đã đăng ký) và R3 (`VFieldLabel` `Flexible`) đúng, `VFieldLabel` chỉ đổi khi nhãn không vừa. R6 chấp nhận.

**Xử lý R1 (2026-11-26, người dùng yêu cầu sửa luôn, chỗ cần chọn theo prototype):**
- G1: canh giữa form bằng `Padding`, giữ `IntrinsicHeight`; test 4 khổ × 3 loại banner (đỏ trước, xanh sau).
- G2: hai `BlocListener`; gửi lại lỗi sau khi đã xác minh thì bỏ qua; hai ca test.
- G3: `resend()` xoá `failure` lúc bắt đầu; một ca test.
- G4: `AutofillGroup` bọc ngoài hai bố cục (Đăng nhập; Đăng ký khi ở bước 1, 2); test không gọi `finishAutofillContext` khi đổi bố cục, vẫn gọi khi sang bước xác minh.
- G5: `SafeArea(minimum: bottom 16)` ở ba bố cục hẹp; test 375×667.
- G6: `VTypography` đặt `letterSpacing: 0` cho mọi vai chữ còn trống (CSS prototype là 0). Chữ toàn app hẹp lại nhẹ. 90 golden màn khác (10-8a, 10-8b, 10-8c, T6-2b, T6-2c, G5-2b, G5-6, G5-7) đang xanh đổi ảnh, đã chụp lại đúng 90 ca đó; 47 ca golden đỏ sẵn trước khi sửa không đụng tới.
- G7: hàng nhãn Mật khẩu web cao `max(32, 20 × cỡ chữ)`, không vừa thì link xuống dòng; test 2.0.
- G8, G9: golden nạp logo trước, điền ô bằng tay như người dùng, nạp danh sách tỉnh; chụp lại 34 ảnh. Lộ thêm: ô Xã khi tắt ở ảnh prototype mờ (từ `.is-disabled` của `shared/components.css`, 0.46) mà Flutter không → `AdministrativeUnitsFormSection` dùng `vDisabledOpacity` (0.4); hai màn hồ sơ tổ chức dùng chung nên cũng đổi.
- G10: viền logo vẽ ở `foregroundDecoration`.
- G11: "Quên mật khẩu" canh trái theo prototype.
- G12: đệm trên 32 khi canh giữa dọc.
- G13: thêm đủ khẳng định thiếu.
- G14: `vDisabledOpacity`, `signup_steps.dart`, dọn import / `setUp` thừa.
- G15: PLAN.md, câu "Lệch".
- G16: khi `nameDiffers`, một toast nối hai câu; sửa LUONG-DANG-KY-XAC-MINH-EMAIL.
- Chạy lại: app (`test/features/auth`, `test/core/widgets`, `test/features/iam`, `store_shell_test`) 486/486; golden các màn khác bằng mốc (47 đỏ sẵn); DS 533/534 (`v_overlay_menu_shell_test` đỏ sẵn); `dart analyze lib test` 241, `check_feature_imports` 18, bằng trước khi sửa. Không chạy toàn app.

**Trạng thái: done (2026-11-26).**
