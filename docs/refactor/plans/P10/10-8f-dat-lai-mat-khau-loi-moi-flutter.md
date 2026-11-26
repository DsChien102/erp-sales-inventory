# 10-8f Đặt lại mật khẩu, Lời mời — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ID-04 / ID-23 Đặt lại mật khẩu và ID-06 / ID-07 Lời mời có bố cục iPhone và web đúng prototype Theme 1; sai mã báo dưới ô mã (lỗi 3), đếm ngược hết "00:60" (lỗi 4).

**Architecture:** Như 10-8e: trang / form giữ cubit, controller, kiểm lỗi; bố cục `Narrow` / `Wide` nhận widget ô nhập đã gắn `GlobalKey`. `PasswordResetState` thêm `codeError` tách khỏi `failure`. Dùng lại `FlowColumn`, `FlowCard`, `FlowIcon`, `ResendCountdown` ở `core/widgets/flow/`.

**Tech Stack:** Flutter, flutter_bloc, go_router, `c45_design_system` 1.10.0.

**Spec:** bản thiết kế "10-8: Theme 1 về Flutter" duyệt trong chat 2026-11-25, phần chung ở [10-8d](10-8d-nen-theme1-flutter.md#thiết-kế-đã-duyệt-phần-chung-cho-10-8dk). Nguồn hình: `specs/themes/theme-01/03.design/prototype/html/app/{reset,invitation}.js`, `app/web/{reset,invitation}.js`. **Làm sau 10-8e.**

## Global Constraints

- Chữ, câu lỗi, RPC, route, `Key` đang có (`invitation_*`) giữ nguyên, trừ điều ghi ở Quyết định. Tên lớp `ResetPasswordPage`, `InvitationTokenEntryForm`, `InvitationRegistrationForm`, `InvitationOutcomeView` giữ nguyên (test và router đang dùng).
- Không đổi `InvitationAcceptanceCubit`. Không in token / mật khẩu ra toast, log.
- `iam` không import thêm `auth/presentation`; `authMaxWidth` đang import sẵn thì giữ.
- Màu `context.vColors` / `VColors`, `VSpacing`, `VRadius`, `VTypography`.
- Chỉ chạy test liệt kê ở từng task; **không** chạy `flutter test` toàn app.

## Quyết định

| # | Quyết định | Lý do |
|---|---|---|
| Q1 | **Lỗi 3:** `verify()` ném `RESET_CODE_INVALID`, `RESET_CODE_EXPIRED`, `RESET_CODE_ATTEMPTS_EXCEEDED` → `codeError = <câu của IamUiFailureMapper>`, **không** đặt `failure` (không toast). Mã khác (mạng, hệ thống) → `failure` + toast "Không thể tiếp tục" như cũ, ô không đỏ | Lỗi mạng không phải lỗi mã |
| Q2 | `verified == false` (không ném lỗi) → `codeError = 'Mã xác nhận không đúng.'` | Hiện không báo gì cả (`password_reset_cubit.dart`, nhánh `!result.verified`) |
| Q3 | `codeError` xoá khi: sửa mã, bắt đầu `verify`, bắt đầu gửi lại mã, vào bước 2 | Không giữ lỗi cũ bên mã mới |
| Q4 | "Quay lại" từ bước 2 đặt `_code = ''` | Ô mã dựng lại rỗng nhưng `_code` cũ còn, nên "Xác nhận mã" đang sáng với ô trống |
| Q5 | **Lỗi 4:** dùng `ResendCountdown(remaining: Duration(seconds: state.resendSecondsRemaining))` → "Gửi lại mã sau 01:00". Nút viền cũ bỏ: còn đếm là chữ, hết là link | 10-8e Q6, hai khung prototype |
| Q6 | Đang gửi mã / lỗi gửi mã lúc vào màn: hẹp nền `surface`, web nền `background` (cột 480); nội dung giữ nguyên. **Sửa kèm:** lỗi gửi mã lúc vào màn chỉ hiện trong thân màn ("Không gửi được mã" + câu lỗi + "Thử lại"), bỏ toast cùng câu | `reset.js:75`, `web/reset.js`; README mục 20 |
| Q7 | Lớp phủ trắng 50% + vòng tải giữ nguyên; web thanh dưới cùng cột 520. **Sửa kèm:** thanh dưới bước 2 chỉ còn **một** gạch trên, cao hết bề ngang cửa sổ (trước đây hai gạch chồng, gạch trong chỉ rộng bằng cột) | README mục 23 |
| Q8 | `_ResetPasswordSampleBody` (không truyền repository) dùng chung bố cục mới, giữ hành vi | Test offline và W-2 đang dùng |
| Q9 | Email khoá ở form kích hoạt: iPhone là một dòng đọc (nhãn, email, icon khoá) mang `Key('invitation_locked_email')`, `Semantics(label: 'Email, <email>, không sửa được')`; web giữ `VEmailField(enabled: false)`. Hẹp không còn ô nhập email nên trình quản lý mật khẩu không tự gắn email | `invitation.js:84-105` |
| Q10 | Sheet xác nhận: nội dung chọn theo `isWideLayout` trong `build` của sheet; vỏ vẫn `showVAdaptiveSheet` (hộp thoại ≥ 1024). 840–1023 là sheet đáy với nội dung web | `app/invitation.js:69`, `web/invitation.js:57` |
| Q11 | Màn kết quả web giữ như hiện nay (chữ + nút, cột 480 canh trên); iPhone theo prototype mới, "Nhập mã khác" ở đáy. `onRetryLater` giữ tham số, vẫn không truyền | `web/invitation.js:74`; README mục 29 không thuộc 15 lỗi |
| Q12 | `FlowIcon` thêm `tone` (`brand` mặc định, `neutral`, `warning`) | `t1.css .t1-vmail__icon--*` |

## Ảnh

Nguồn: `tools/proto-final/`, chép 2026-11-25; `reset__{verify-wrong,resent-toast,request-failed,create,create-errors}` chụp lại ở Task 1. Cột Flutter: golden (`img/10-8f/flutter-<ca>-{390,1280}.png`).

| Ca | 390 | 1280 |
|---|---|---|
| reset__verify | ![](img/10-8f/proto-reset__verify-390.png) | ![](img/10-8f/proto-reset__verify-1280.png) |
| reset__verify-wrong | ![](img/10-8f/proto-reset__verify-wrong-390.png) | ![](img/10-8f/proto-reset__verify-wrong-1280.png) |
| reset__resend-ready | ![](img/10-8f/proto-reset__resend-ready-390.png) | ![](img/10-8f/proto-reset__resend-ready-1280.png) |
| reset__resent-toast | ![](img/10-8f/proto-reset__resent-toast-390.png) | ![](img/10-8f/proto-reset__resent-toast-1280.png) |
| reset__create | ![](img/10-8f/proto-reset__create-390.png) | ![](img/10-8f/proto-reset__create-1280.png) |
| reset__create-errors | ![](img/10-8f/proto-reset__create-errors-390.png) | ![](img/10-8f/proto-reset__create-errors-1280.png) |
| reset__request-failed | ![](img/10-8f/proto-reset__request-failed-390.png) | ![](img/10-8f/proto-reset__request-failed-1280.png) |
| invitation__entry | ![](img/10-8f/proto-invitation__entry-390.png) | ![](img/10-8f/proto-invitation__entry-1280.png) |
| invitation__entry-partial | ![](img/10-8f/proto-invitation__entry-partial-390.png) | ![](img/10-8f/proto-invitation__entry-partial-1280.png) |
| invitation__entry-invalid | ![](img/10-8f/proto-invitation__entry-invalid-390.png) | ![](img/10-8f/proto-invitation__entry-invalid-1280.png) |
| invitation__inspecting | ![](img/10-8f/proto-invitation__inspecting-390.png) | ![](img/10-8f/proto-invitation__inspecting-1280.png) |
| invitation__confirm | ![](img/10-8f/proto-invitation__confirm-390.png) | ![](img/10-8f/proto-invitation__confirm-1280.png) |
| invitation__register | ![](img/10-8f/proto-invitation__register-390.png) | ![](img/10-8f/proto-invitation__register-1280.png) |
| invitation__register-errors | ![](img/10-8f/proto-invitation__register-errors-390.png) | ![](img/10-8f/proto-invitation__register-errors-1280.png) |
| invitation__declined | ![](img/10-8f/proto-invitation__declined-390.png) | ![](img/10-8f/proto-invitation__declined-1280.png) |
| invitation__blocked | ![](img/10-8f/proto-invitation__blocked-390.png) | ![](img/10-8f/proto-invitation__blocked-1280.png) |

## Code prototype (chép nguyên văn, token thay bằng giá trị)

### ID-04 / ID-23

`app/reset.js:31-96`

```js
const RESET_STEPS = ['Xác minh email', 'Tạo mật khẩu mới']; // TH-01 FR-01

/**
 * Bước 1: thanh 2 bước → khe 24 → tiêu đề → lời nhắc → khe 24 → ô mã (sáu ô cao 56 trải hết bề ngang) → ghi chú 10 phút
 * → khe 24 → "Xác nhận mã" → khe 8 → gửi lại (giữa): còn đếm ngược là chữ textSecondary, hết là nút link.
 */
function verifyStep(s, v, email) {
  const col = Math.min(v.width, v.width >= 600 ? 480 : v.width) - 32;
  const code = s.code || '';
  const label = resetResendLabel(s.seconds);
  return `<div class="t1-list t1-reset">
    ${progressBar(RESET_STEPS, 0)}
    <h2 class="t1-reset__title">Xác minh email</h2>
    <p class="t1-body2 t1-reset__prompt">Mã 6 chữ số đã được gửi tới <b>${maskEmail(email)}</b>. Xác nhận mã để tạo mật khẩu mới.</p>
    ${field({ label: 'Mã xác nhận', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, disabled: !!s.busy, focus: !s.busy && code.length < 6 }) })}
    <div class="t1-gap-sm"></div>
    <p class="t1-small">Mã chỉ sử dụng một lần và hết hạn sau 10 phút.</p>
    <div class="t1-gap-lg"></div>
    ${button('Xác nhận mã', { full: true, disabled: code.length !== 6 || !!s.busy, attrs: 'data-primary' })}
    <div class="t1-reset__resend">${s.seconds > 0 ? `<p class="t1-body2 t1-reset__wait">${label}</p>` : button(label, { variant: 'link' })}</div>
  </div>`;
}

/** Bước 2: thanh 2 bước → tiêu đề → 2 ô mật khẩu (gợi ý ••••) → khe 24 → VCard "Quy tắc mật khẩu"; thanh dưới giữ nguyên. */
function createStep(s) {
  return `<div class="t1-list t1-reset">
    ${progressBar(RESET_STEPS, 1)}
    <h2 class="t1-reset__title">Tạo mật khẩu mới</h2>
    <div class="t1-gap-md"></div>
    <div class="t1-form">
      ${field({ label: 'Mật khẩu mới', required: true, control: input({ value: s.pw || '', hint: '••••••••••••', password: true, invalid: !!s.pwError }), error: s.pwError })}
      ${field({ label: 'Nhập lại mật khẩu mới', required: true, control: input({ value: s.confirm || '', hint: '••••••••••••', password: true, invalid: !!s.confirmError }), error: s.confirmError })}
    </div>
    <div class="t1-gap-lg"></div>
    ${card(`<h3 class="t1-h4">Quy tắc mật khẩu</h3><p class="t1-small t1-mt-xs">${PASSWORD_RULE}</p>`, 't1-card--pad')}
  </div>`;
}

/** _PasswordBottomBar: đệm 16, nền surface, gạch trên; "Quay lại" (secondary) | khe 8 | "Đặt lại mật khẩu" (tắt khi chưa nhập đủ hai ô). */
export function bottomBar(s) {
  const filled = !!(s.pw && s.confirm);
  return `<div class="t1-pwbar">${button('Quay lại', { variant: 'secondary', full: true, disabled: !!s.busy })}${button('Đặt lại mật khẩu', { full: true, disabled: !filled || !!s.busy })}</div>`;
}

export function resetPage(v) {
  const s = STATES[v.state];
  const email = s.account ? 'chien@anphat.vn' : 'lan@anphat.vn';
  let body; let bar = '';
  if (s.phase === 'requesting') body = centerLoading();
  else if (s.phase === 'request-failed') {
    body = `<div class="t1-center"><div class="t1-failed">
      <h2 class="t1-h4 t1-h4--600">Không gửi được mã</h2>
      <p class="t1-small t1-text-center">${s.toast[2]}</p>
      <div class="t1-gap-lg"></div>
      ${button('Thử lại')}
    </div></div>`;
  } else if (s.phase === 'verify') body = verifyStep(s, v, email);
  else { body = createStep(s); bar = bottomBar(s); }
  const col = `max-width:${authColumn(v.width)}`;
  const page = `<div class="t1-page t1-page--surface">${appBar('Đặt lại mật khẩu', { back: true })}
    <div class="t1-scroll"><div class="t1-col" style="${col}">${body}</div></div>
    ${bar ? `<footer class="t1-bottombar"><div class="t1-col" style="${col}">${bar}</div></footer>` : ''}
  </div>`;
  const overlay = (s.busy ? busyOverlay() : '') + (s.toast ? toast(...s.toast, { device: v.device, above: bar ? 78 : 0 }) : '');
  return { page, overlay };
}
```

`app/web/reset.js:8-66`

```js
const RESET_STEPS = ['Xác minh email', 'Tạo mật khẩu mới'];

/** Bước 1 (thẻ): ô thư 48 → "Xác minh email" → lời nhắc → ô mã → "Xác nhận mã" → "Gửi lại mã…" (link); ghi chú 10 phút dưới thẻ. */
function verifyStep(s, v, email) {
  const col = Math.min(v.width, 520) - 32 - 40 - 2; // cột − đệm trang − đệm thẻ − viền
  const code = s.code || '';
  return `<div class="t1-stepcard">
      <div class="t1-mailbox" aria-hidden="true">${icon('mail')}</div>
      <h2 class="t1-stepcard__title t1-stepcard__title--icon">Xác minh email</h2>
      <p class="t1-body2">Mã 6 chữ số đã được gửi tới ${maskEmail(email)}. Xác nhận mã để tạo mật khẩu mới.</p>
      <div class="t1-gap-lg"></div>
      ${field({ label: 'Mã xác nhận', required: true, control: codeField({ fill: true, length: 6, value: code, columnWidth: col, disabled: !!s.busy, focus: !s.busy && code.length < 6 }) })}
      <div class="t1-gap-lg"></div>
      ${button('Xác nhận mã', { full: true, disabled: code.length !== 6 || !!s.busy })}
      <div class="t1-reset__resend">${s.seconds > 0 ? `<p class="t1-body2 t1-reset__wait">${resetResendLabel(s.seconds)}</p>` : button(resetResendLabel(s.seconds), { variant: 'link' })}</div>
    </div>
    <p class="t1-small t1-text-center t1-stepcol__after">Mã chỉ sử dụng một lần và hết hạn sau 10 phút.</p>`;
}

/** Bước 2 (thẻ): "Tạo mật khẩu mới" → 2 ô mật khẩu (gợi ý ••••) → quy tắc mật khẩu (ô nền canvas trong thẻ). */
function createStep(s) {
  return `<div class="t1-stepcard">
      <h2 class="t1-stepcard__title">Tạo mật khẩu mới</h2>
      <div class="t1-form">
        ${field({ label: 'Mật khẩu mới', required: true, control: input({ value: s.pw || '', hint: '••••••••••••', password: true, invalid: !!s.pwError }), error: s.pwError })}
        ${field({ label: 'Nhập lại mật khẩu mới', required: true, control: input({ value: s.confirm || '', hint: '••••••••••••', password: true, invalid: !!s.confirmError }), error: s.confirmError })}
      </div>
      <div class="t1-stepcard__rule"><h3 class="t1-h4">Quy tắc mật khẩu</h3><p class="t1-small t1-mt-xs">${PASSWORD_RULE}</p></div>
    </div>`;
}

export function resetPage(v) {
  const s = STATES[v.state];
  const email = s.account ? 'chien@anphat.vn' : 'lan@anphat.vn';
  let body; let bar = '';
  if (s.phase === 'requesting') body = centerLoading();
  else if (s.phase === 'request-failed') {
    body = `<div class="t1-center"><div class="t1-failed">
      <h2 class="t1-h4 t1-h4--600">Không gửi được mã</h2>
      <p class="t1-small t1-text-center">${s.toast[2]}</p>
      <div class="t1-gap-lg"></div>
      ${button('Thử lại')}
    </div></div>`;
  } else if (s.phase === 'verify') body = verifyStep(s, v, email);
  else { body = createStep(s); bar = bottomBar(s); }
  let page;
  if (s.phase === 'verify' || s.phase === 'create') {
    // Thanh 2 bước + thẻ trên nền canvas (cột 520), cùng mẫu với Đăng ký. Chọn qua impeccable live (2026-11-24).
    const col = v.width >= 600 ? 'max-width:520px' : '';
    page = `<div class="t1-page t1-page--canvas">${appBar('Đặt lại mật khẩu', { back: true })}
    <div class="t1-scroll"><div class="t1-stepcol">${progressBar(RESET_STEPS, s.phase === 'verify' ? 0 : 1)}${body}</div></div>
    ${bar ? `<footer class="t1-bottombar"><div class="t1-col" style="${col}">${bar}</div></footer>` : ''}
  </div>`;
  } else {
    page = pageScaffold({ title: 'Đặt lại mật khẩu', body, width: v.width });
  }
  const overlay = (s.busy ? busyOverlay() : '') + (s.toast ? toast(...s.toast, { device: v.device, above: bar ? 78 : 0 }) : '');
  return { page, overlay };
}
```

`styles/t1.css:200-206`

```css
/* ------------------------------------------------ Đặt lại mật khẩu (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-reset { padding-bottom: 34px; }
.t1-reset__title { margin: 24px 0 0; font-size: 22px; line-height: 32px; font-weight: 700; letter-spacing: -0.3px; color: #0E1116 /*text-primary*/; }
.t1-reset__prompt { margin: 4px 0 24px; text-wrap: pretty; }
.t1-reset__prompt b { font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-reset__resend { display: grid; place-items: center; min-height: 44px; margin-top: 8px; }
.t1-reset__wait { font-variant-numeric: tabular-nums; }
```

`styles/t1.css:40-45`

```css
/* ------------------------------------------------ VPageScaffold.bottomBar: nền surface + gạch trên 1 borderDefault, cùng cột */
.t1-bottombar { flex: 0 0 auto; background: #FFFFFF /*surface-default*/; border-top: 1px solid #E5E8EB /*border-default*/; }
.sh-app[data-device="iphone"] .t1-bottombar { padding-bottom: 34px; }      /* SafeArea(top: false) */
.t1-bar-pad { padding: 16px; }
/* _PasswordBottomBar tự vẽ thêm nền + gạch trên + đệm 16 bên trong bottomBar → hai gạch chồng nhau */
.t1-pwbar { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; padding: 16px; background: #FFFFFF /*surface-default*/; border-top: 1px solid #E5E8EB /*border-default*/; }
```

`styles/t1-web.css:51-52`

```css
.t1-stepcard__title--icon { margin: 16px 0 8px; }
.t1-stepcard__rule { margin-top: 24px; padding: 16px; border-radius: 8px /*radius-3*/; background: #F6F8F9 /*surface-canvas*/; }
```


### ID-06 / ID-07

`app/invitation.js:49-131`

```js
/**
 * InvitationTokenEntryForm: nền surface, VAppBar "Kích hoạt tài khoản" + nút ← (về /login); tiêu đề → hướng dẫn → khe 24 → ô mã 8 ký tự (nhóm 4 + 4, + lỗi | mô tả)
 * → khe 24 → "Tiếp tục" ngay dưới (không còn thanh dưới). Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25); chữ giữ nguyên Flutter.
 */
function entryView(v, s) {
  const token = s.token || '';
  const body = `<div class="t1-invite">
    <h2 class="t1-invite__title">Nhập mã lời mời</h2>
    <p class="t1-body2 t1-invite__text">Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.</p>
    ${field({ label: 'Mã lời mời', required: true, control: codeField({ split: true, length: 8, value: token, columnWidth: v.width - 32, invalid: !!s.error, disabled: !!s.busy, focus: !s.busy && !s.sheet && token.length < 8 }), error: s.error, desc: 'Mã không phân biệt chữ hoa và chữ thường.' })}
    <div class="t1-gap-lg"></div>
    ${button('Tiếp tục', { full: true, loading: !!s.busy, attrs: 'data-primary' })}
  </div>`;
  return plainScaffold({ appbar: appBar('Kích hoạt tài khoản', { back: true, backDisabled: !!s.busy }), body, width: v.width });
}

/**
 * _InvitationConfirmSheetContent (iPhone, impeccable live 2026-11-25; web giữ bản cũ ở web/invitation.js): đệm 16; tiêu đề 20/28 w700 → dấu tích + "Mã lời mời hợp lệ."
 * → khối nền canvas 3 dòng (nhãn ↔ giá trị w600 phải) → khe 20 → Xác nhận / khe 8 / Từ chối.
 */
function confirmSheet() {
  const row = (l, val) => `<div class="t1-invconf__row"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
  return `<div class="t1-confirm t1-invconf">
    <h2 class="t1-invconf__title">Xác nhận lời mời tham gia tổ chức?</h2>
    <p class="t1-invconf__ok">${icon('checkCircle')}Mã lời mời hợp lệ.</p>
    <div class="t1-invconf__box">${row('Tổ chức', INSPECTION.tenantName)}${row('Vai trò', INSPECTION.role)}${row('Email', INSPECTION.email)}</div>
    <div class="t1-invconf__acts">${button('Xác nhận', { full: true, attrs: 'data-primary' })}${button('Từ chối', { variant: 'secondary', full: true })}</div>
  </div>`;
}

/**
 * InvitationRegistrationForm: nền surface, VAppBar "Kích hoạt tài khoản" + ← (về nhập mã); dấu tích + "Mã lời mời hợp lệ" → lời nhắc → khe 20
 * → form (họ + tên cùng hàng 3 : 2; email khoá là một dòng đọc rõ + biểu tượng khoá) → khe 24 → "Kích hoạt tài khoản" ngay dưới (không còn thanh dưới).
 * Bố cục iPhone thiết kế lại qua impeccable live (2026-11-25); chữ, trạng thái giữ nguyên Flutter.
 */
function registerView(v, s) {
  const x = { family: '', given: '', phone: '', pw: '', confirm: '', ...s.values };
  const e = s.errors || {};
  const busy = !!s.busy;
  const body = `<div class="t1-invreg">
    <p class="t1-invreg__ok">${icon('checkCircle')}<b>Mã lời mời hợp lệ</b></p>
    <p class="t1-body2 t1-invreg__text">Kích hoạt tài khoản để tiếp nhận lời mời và vào <b>${esc(INSPECTION.tenantName)}</b>.</p>
    <div class="t1-form">
      <div class="t1-signup__names">
        ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.family, hint: 'Nhập họ và tên đệm', invalid: !!e.familyName, disabled: busy }), error: e.familyName })}
        ${field({ label: 'Tên', required: true, control: input({ value: x.given, hint: 'Nhập tên', invalid: !!e.givenName, disabled: busy }), error: e.givenName })}
      </div>
      <div class="t1-invreg__mail"><span>Email</span><b>${esc(INSPECTION.email)}</b>${icon('lock')}</div>
      ${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại', disabled: busy }) })}
      ${field({ label: 'Mật khẩu', required: true, control: input({ value: x.pw, hint: 'Nhập mật khẩu', password: true, invalid: !!e.password, disabled: busy }), error: e.password, desc: PASSWORD_RULE })}
      ${field({ label: 'Xác nhận mật khẩu', required: true, control: input({ value: x.confirm, hint: 'Nhập lại mật khẩu', password: true, invalid: !!e.confirm, disabled: busy }), error: e.confirm })}
    </div>
    <div class="t1-gap-lg"></div>
    ${button('Kích hoạt tài khoản', { full: true, loading: busy, attrs: 'data-primary' })}
  </div>`;
  return plainScaffold({ appbar: appBar('Kích hoạt tài khoản', { back: true, backDisabled: busy }), body, width: v.width });
}

/**
 * InvitationOutcomeView (iPhone, impeccable live 2026-11-25; web giữ bản cũ ở web/invitation.js): Scaffold nền surface; biểu tượng 64 + tiêu đề + câu canh giữa;
 * "Nhập mã khác" ở đáy màn. Đã từ chối → × xám; không thể tiếp tục → cảnh báo vàng. onRetryLater không được truyền → không có "Thử lại sau".
 */
function outcomeView(v, s) {
  const declined = s.step === 'declined';
  const title = declined ? 'Đã từ chối lời mời' : 'Không thể tiếp tục';
  const text = s.message || (declined ? 'Lời mời đã được từ chối.' : 'Mã lời mời không dùng được. Bạn có thể nhập mã khác.');
  const body = `<div class="t1-noorgm">
    <div class="t1-noorgm__mid">
      <div class="t1-vmail__icon ${declined ? 't1-vmail__icon--neutral' : 't1-vmail__icon--warning'}" aria-hidden="true">${icon(declined ? 'close' : 'alert')}</div>
      <h2 class="t1-vmail__title">${esc(title)}</h2>
      <p class="t1-body2 t1-noorgm__text">${esc(text)}</p>
    </div>
    <div class="t1-noorgm__actions">${button('Nhập mã khác', { full: true, attrs: 'data-primary' })}</div>
  </div>`;
  return plainScaffold({ body, width: v.width });
}

export function invitationPage(v) {
  const s = STATES[v.state];
  const page = s.view === 'register' ? registerView(v, s) : s.view === 'outcome' ? outcomeView(v, s) : entryView(v, s);
  const overlay = (s.sheet ? adaptiveSheet(v.width, confirmSheet(), 'Xác nhận lời mời') : '') + (s.toast ? toast(...s.toast, { device: v.device }) : '');
  return { page, overlay };
}
```

`app/web/invitation.js:7-89`

```js
/**
 * Nhập mã lời mời: nền canvas, VAppBar "Kích hoạt tài khoản" + ← (về /login); cột 520 canh trên; thẻ trắng: ô thư 48 → "Nhập mã lời mời"
 * → hướng dẫn → ô mã 8 ký tự (+ lỗi | mô tả) → "Tiếp tục" trong thẻ (không còn thanh dưới). Chọn qua impeccable live (2026-11-24).
 */
function entryView(v, s) {
  const col = Math.min(v.width, 520) - 32 - 40 - 2; // cột − đệm trang − đệm thẻ − viền
  const token = s.token || '';
  return `<div class="t1-page t1-page--canvas">${appBar('Kích hoạt tài khoản', { back: true, backDisabled: !!s.busy })}
    <div class="t1-scroll"><div class="t1-stepcol">
      <div class="t1-stepcard t1-stepcard--first">
        <div class="t1-mailbox" aria-hidden="true">${icon('mail')}</div>
        <h2 class="t1-stepcard__title t1-stepcard__title--icon">Nhập mã lời mời</h2>
        <p class="t1-body2">Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.</p>
        <div class="t1-gap-lg"></div>
        ${field({ label: 'Mã lời mời', required: true, control: codeField({ fill: true, length: 8, value: token, columnWidth: col, invalid: !!s.error, disabled: !!s.busy, focus: !s.busy && !s.sheet && token.length < 8 }), error: s.error, desc: 'Mã không phân biệt chữ hoa và chữ thường.' })}
        <div class="t1-gap-lg"></div>
        ${button('Tiếp tục', { full: true, loading: !!s.busy })}
      </div>
    </div></div>
  </div>`;
}

/**
 * Đăng ký theo lời mời: nền canvas, VAppBar "Kích hoạt tài khoản" + ← (về nhập mã); cột 520: banner success → thẻ trắng 6 ô (email khoá)
 * → thanh dưới "Kích hoạt tài khoản" (cùng cột 520). Chọn qua impeccable live (2026-11-24).
 */
function registerView(v, s) {
  const x = { family: '', given: '', phone: '', pw: '', confirm: '', ...s.values };
  const e = s.errors || {};
  const busy = !!s.busy;
  const col = v.width >= 600 ? 'max-width:520px' : '';
  return `<div class="t1-page t1-page--canvas">${appBar('Kích hoạt tài khoản', { back: true, backDisabled: busy })}
    <div class="t1-scroll"><div class="t1-stepcol">
      ${banner('success', 'Mã lời mời hợp lệ', `Kích hoạt tài khoản để tiếp nhận lời mời và vào ${INSPECTION.tenantName}.`)}
      <div class="t1-stepcard t1-stepcard--near">
        <div class="t1-form">
          ${field({ label: 'Họ và tên đệm', required: true, control: input({ value: x.family, hint: 'Nhập họ và tên đệm', invalid: !!e.familyName, disabled: busy }), error: e.familyName })}
          ${field({ label: 'Tên', required: true, control: input({ value: x.given, hint: 'Nhập tên', invalid: !!e.givenName, disabled: busy }), error: e.givenName })}
          ${field({ label: 'Email', control: input({ value: INSPECTION.email, disabled: true }) })}
          ${field({ label: 'Số điện thoại', control: input({ value: x.phone, hint: 'Nhập số điện thoại', disabled: busy }) })}
          ${field({ label: 'Mật khẩu', required: true, control: input({ value: x.pw, hint: 'Nhập mật khẩu', password: true, invalid: !!e.password, disabled: busy }), error: e.password, desc: PASSWORD_RULE })}
          ${field({ label: 'Xác nhận mật khẩu', required: true, control: input({ value: x.confirm, hint: 'Nhập lại mật khẩu', password: true, invalid: !!e.confirm, disabled: busy }), error: e.confirm })}
        </div>
      </div>
    </div></div>
    <footer class="t1-bottombar"><div class="t1-col" style="${col}"><div class="t1-bar-pad">${button('Kích hoạt tài khoản', { full: true, loading: busy })}</div></div></footer>
  </div>`;
}

/** _InvitationConfirmSheetContent: đệm 16 / 16; tiêu đề H3 w700 → khe 8 → "Mã lời mời hợp lệ." → khe 16 → 3 dòng (nhãn 72 bodySmall + giá trị labelDefault) → khe 32 → Xác nhận / khe 16 / Từ chối → khe 8. */
function confirmSheet() {
  const row = (l, val) => `<div class="t1-inforow"><span>${esc(l)}</span><b>${esc(val)}</b></div>`;
  return `<div class="t1-confirm">
    <h2 class="t1-h3">Xác nhận lời mời tham gia tổ chức?</h2>
    <div class="t1-gap-sm"></div>
    <p class="t1-body2">Mã lời mời hợp lệ.</p>
    <div class="t1-gap-md"></div>
    ${row('Tổ chức', INSPECTION.tenantName)}${row('Vai trò', INSPECTION.role)}${row('Email', INSPECTION.email)}
    <div class="t1-gap-xl"></div>
    ${button('Xác nhận', { full: true })}
    <div class="t1-gap-md"></div>
    ${button('Từ chối', { variant: 'secondary', full: true })}
    <div class="t1-gap-sm"></div>
  </div>`;
}

/** InvitationOutcomeView trong Scaffold nền surface, cột 480 đệm 16 (canh trên). onRetryLater không được truyền → không có "Thử lại sau". */
function outcomeView(v, s) {
  const declined = s.step === 'declined';
  const title = declined ? 'Đã từ chối lời mời' : 'Không thể tiếp tục';
  const body = s.message || (declined ? 'Lời mời đã được từ chối.' : 'Mã lời mời không dùng được. Bạn có thể nhập mã khác.');
  return plainScaffold({
    width: v.width,
    body: `<div class="t1-list"><h2 class="t1-h3">${esc(title)}</h2><div class="t1-gap-sm"></div><p class="t1-body2">${esc(body)}</p><div class="t1-gap-lg"></div>${button('Nhập mã khác', { full: true })}</div>`,
  });
}

export function invitationPage(v) {
  const s = STATES[v.state];
  const page = s.view === 'register' ? registerView(v, s) : s.view === 'outcome' ? outcomeView(v, s) : entryView(v, s);
  const overlay = (s.sheet ? adaptiveSheet(v.width, confirmSheet(), 'Xác nhận lời mời') : '') + (s.toast ? toast(...s.toast, { device: v.device, above: s.view === 'register' ? 77 : 0 }) : '');
  return { page, overlay };
}
```

`styles/t1.css:214-229`

```css
/* ------------------------------------------------ Nhập mã lời mời (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-invite { padding: 24px 16px 34px; }
.t1-invite__title { margin: 0; font-size: 22px; line-height: 32px; font-weight: 700; letter-spacing: -0.3px; color: #0E1116 /*text-primary*/; }
.t1-invite__text { margin: 4px 0 24px; text-wrap: pretty; }

/* ------------------------------------------------ Kích hoạt tài khoản theo lời mời (iPhone, impeccable live 2026-11-25; web ở t1-web.css) */
.t1-invreg { padding: 20px 16px 34px; }
.t1-invreg__ok { display: flex; align-items: center; gap: 8px; margin: 0; font-size: 18px /*fs-h3*/; line-height: 26px; color: #0E1116 /*text-primary*/; }
.t1-invreg__ok b { font-weight: 700; letter-spacing: -0.2px; }
.t1-invreg__ok .icon { font-size: 22px; color: #2F7A3A /*icon-success*/; }
.t1-invreg__text { margin: 4px 0 20px; text-wrap: pretty; }
.t1-invreg__text b { font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-invreg__mail { display: flex; align-items: center; gap: 12px; min-height: 44px; padding: 8px 12px; border-radius: 8px /*radius-input*/; background: #F6F8F9 /*surface-canvas*/; font-size: 14px /*fs-md*/; line-height: 20px; }
.t1-invreg__mail span { font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-invreg__mail b { flex: 1; min-width: 0; overflow-wrap: anywhere; text-align: right; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-invreg__mail .icon { font-size: 16px; color: #6B7480 /*icon-secondary*/; }
```

`styles/t1.css:401-409`

```css
/* ------------------------------------------------ Sheet xác nhận lời mời (iPhone, impeccable live 2026-11-25; web dùng .t1-inforow) */
.t1-invconf__title { margin: 0; text-wrap: balance; font-size: 20px /*fs-xl*/; line-height: 28px; font-weight: 700; letter-spacing: -0.2px; color: #0E1116 /*text-primary*/; }
.t1-invconf__ok { display: flex; align-items: center; gap: 6px; margin: 4px 0 16px; font-size: 14px /*fs-md*/; line-height: 22px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-invconf__ok .icon { font-size: 18px; color: #2F7A3A /*icon-success*/; }
.t1-invconf__box { display: flex; flex-direction: column; gap: 10px; padding: 16px; border-radius: 12px /*radius-card*/; background: #F6F8F9 /*surface-canvas*/; }
.t1-invconf__row { display: flex; justify-content: space-between; gap: 16px; font-size: 14px /*fs-md*/; line-height: 22px; }
.t1-invconf__row span { flex: none; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-invconf__row b { min-width: 0; overflow-wrap: anywhere; text-align: right; font-weight: 600; color: #0E1116 /*text-primary*/; }
.t1-invconf__acts { display: flex; flex-direction: column; gap: 8px; margin-top: 20px; }
```

`styles/t1.css:417-421`

```css
/* ------------------------------------------------ Lời mời: sheet xác nhận */
.t1-confirm { padding: 16px; }
.t1-inforow { display: flex; align-items: flex-start; padding: 4px 0; }
.t1-inforow span { flex: 0 0 72px; font-size: 13px /*fs-sm*/; line-height: 20px; font-weight: 500; color: #4A535E /*text-secondary*/; }
.t1-inforow b { flex: 1; min-width: 0; font-size: 14px /*fs-md*/; line-height: 20px; font-weight: 600; color: #0E1116 /*text-primary*/; }
```

`styles/t1-web.css:65-66`

```css
.t1-stepcard--first { margin-top: 0; }
.t1-stepcard--near { margin-top: 16px; }
```


CSS đã có ở plan 10-8e: `.t1-stepcol`, `.t1-stepcard*`, `.t1-mailbox`, `.t1-vmail__icon*`, `.t1-vmail__title`, `.t1-noorgm*`, `.t1-signup__names`, `.t1-form`, `.t1-label`, `.t1-error`, `.t1-desc`.

### Ánh xạ phần tử → Flutter

| Prototype | Flutter |
|---|---|
| `progressBar(RESET_STEPS, n)` | `VStepProgress(titles: ['Xác minh email', 'Tạo mật khẩu mới'], …)`, `mobile` ở hẹp, `standard` ở web |
| `codeField fill` (6), `codeField fill` 8 (web), `codeField split` 8 (iPhone) | `VVerificationCodeLayout.fill` / `.split4` (10-8d) |
| `.t1-reset__title` 22/32 w700 −0,3 | `headingH2.copyWith(w700, letterSpacing: -0.3)`, `Semantics(header: true)` |
| email che in đậm | `Text.rich` (test cũ tìm bằng `textContaining` vẫn khớp) |
| `.t1-stepcard__rule` | khối nền `background`, bo `VRadius.r8`, đệm 16 |
| `.t1-invreg__ok` | `Row` icon 22 `success` + chữ 18 w700 −0,2 |
| `.t1-invreg__mail` | `Container` nền `background`, bo input, đệm 8 / 12, cao ≥ 44 |
| `.t1-invconf__box` | khối nền `background`, bo card, đệm 16, hàng cách 10 |
| icon `close`, `alert`, `checkCircle`, `lock`, `mail` | `VIcons.close`, `VIcons.warning`, `VIcons.success`, `VIcons.lock`, `VIcons.mail` (tên đúng xem `v_icons.dart`) |
| đệm đáy 34 | `SafeArea`, không cộng thêm |

## Bảng "Đang làm gì"

| Thứ bị thay | Đang làm gì | Sau khi sửa | Test giữ hành vi |
|---|---|---|---|
| `ResetPasswordPage` | Vào màn gửi mã ngay; lỗi → "Không gửi được mã" + "Thử lại" + toast | Nguyên | T0: `request failure shows retry`; toast bỏ (**đổi có chủ đích**, Q6) |
| | Đủ 6 số tự xác nhận; "Xác nhận mã" bật khi đủ 6 | Nguyên | có sẵn `offline validation flow`, T0: `six digits verify once` |
| | Sai mã → toast | Báo dưới ô mã (**đổi có chủ đích**, lỗi 3) | T1 mới |
| | Gửi lại: toast "Đã gửi lại mã xác nhận."; lỗi → toast | Nguyên | có sẵn `…then resends` (đổi kỳ vọng "00:60" → "01:00"), T0: `resend failure shows a toast` |
| | Bước 2: kiểm mật khẩu, lỗi dưới ô + toast; xong `pop(true)` | Nguyên | có sẵn `completes with typed result and pops true`, `offline validation flow` |
| | "Quay lại" về bước 1 | Nguyên, ô và `_code` cùng rỗng (Q4) | T1 mới |
| | Lớp phủ khi đang gửi | Nguyên | T0: `submitting shows the overlay` |
| `InvitationTokenEntryForm` | Kiểm tại chỗ hai câu; lỗi máy chủ dưới ô; gõ lại xoá lỗi; đủ 8 tự gửi; ← tắt khi đang gửi, về `/login` | Nguyên | có sẵn 6 ca; T0: `back is disabled while inspecting`, `typing clears the server error` |
| `InvitationConfirmBottomSheet` | Xác nhận / Từ chối / đóng → `true` / `false` / `null` | Nguyên cả hai nội dung | có sẵn `existing account…`, `closing confirmation sheet…`; T0: `decline shows outcome` |
| `InvitationRegistrationForm` | Điền sẵn từ lời mời; kiểm lỗi; xoá mật khẩu sau khi gửi; ← về nhập mã | Nguyên | có sẵn `pre-fills…`, `registration_phone_test`; T0: `passwords are cleared after a failed submit`, `back returns to token entry` |
| | Ô email khoá là `TextField` tắt | iPhone là dòng đọc (**đổi có chủ đích**, Q9) | có sẵn, đổi kỳ vọng khổ hẹp; web giữ kỳ vọng cũ |
| | Nút ở thanh dưới | iPhone ngay dưới form; web giữ thanh dưới cột 520 | có sẵn `H13` (tìm theo `Key`) |
| `InvitationOutcomeView` | Tiêu đề, câu, "Nhập mã khác" → `cubit.reset` | Nguyên | T0: `enter other token returns to entry` |

## Review Focus

1. **Kéo cửa sổ 900 → 700 khi đã gõ 5/8 ký tự mã lời mời hoặc 3/6 số**: ký tự còn nguyên, không tự gửi. Test ở Task 1, 2.
2. **Sai mã rồi mất mạng khi gửi lại:** dòng lỗi mã mất ngay khi bấm gửi lại, lỗi mạng chỉ là toast; không hiện hai lỗi cùng lúc. Test ở Task 1.
3. **Nhập sai quá số lần:** câu "Bạn đã nhập sai mã quá nhiều lần." dưới ô mã, "Gửi lại mã" vẫn bấm được khi hết đếm. Test ở Task 1.
4. **Form kích hoạt ở iPhone khi bàn phím mở:** nút "Kích hoạt tài khoản" cuộn tới được (không còn thanh dưới). Test ở Task 3.
5. **Tên tổ chức 80 ký tự, email 60 ký tự, chữ 2.0, 320 × 568:** ba màn và sheet không tràn. Test ở Task 1–4.

---

### Task 0: Test giữ hành vi trên code cũ

**Files:**
- Modify: `apps/erp/test/features/iam/presentation_module/widgets/reset_password_page_test.dart`, `apps/erp/test/features/auth/presentation/invitation/invitation_token_page_test.dart`

**Interfaces:**
- Consumes: `RecordingAuthRepository`, `scripted_invitations.dart` (có sẵn).
- Produces: không.

- [x] **Step 1: Viết các ca T0 trong bảng**, mỗi ca một `testWidgets` đúng tên, khổ 390 × 844, tìm bằng `Key` / chữ. Khẳng định chính:

```dart
// request failure…: find.text('Không gửi được mã') trong thân và 'Thử lại'; tap 'Thử lại' → auth.calls có 'requestMy' hai lần
// six digits verify once: auth.calls đếm 'verifyMy' == 1
// submitting shows the overlay: repository treo → find.byType(VLoading) findsOneWidget; tap 'Xác nhận mã' không gọi thêm
// passwords are cleared…: hai ô mật khẩu rỗng, họ / tên / SĐT còn
```

- [x] **Step 2: Chạy, phải xanh trên code cũ** — `cd apps/erp && flutter test test/features/iam/presentation_module/widgets/reset_password_page_test.dart test/features/auth/presentation/invitation`
- [x] **Step 3: Commit** `test(10-8f): test giữ hành vi Đặt lại mật khẩu, Lời mời`

### Task 1: Đặt lại mật khẩu (lỗi 3, 4)

**Files:**
- Modify: prototype `app/reset.js`, `app/web/reset.js`, `app/cases.js`, `tests/t1.test.mjs`, `README.md` (mục 21, 22 thêm "Đã sửa 10-8f")
- Modify: `apps/erp/lib/features/iam/logic/password_reset_{cubit,state}.dart`, `presentation/users/views/reset_password_page.dart`
- Create: `apps/erp/lib/features/iam/presentation/users/widgets/reset_password_narrow.dart`, `reset_password_wide.dart`
- Delete: `…/widgets/reset_password_verify_code_step.dart`, `reset_password_create_password_step.dart`
- Test: `reset_password_page_test.dart`; Create: `apps/erp/test/features/iam/presentation_module/reset_password_golden_test.dart`

**Interfaces:**
- Consumes: `VStepProgress`, `VVerificationCodeLayout.fill`, `FlowColumn`, `FlowCard`, `FlowIcon.medium`, `ResendCountdown`, `isWideLayout`.
- Produces:

```dart
// PasswordResetState: String? codeError; copyWith(codeError, clearCodeError = false)
// PasswordResetCubit: void clearCodeError()
const ResetVerifyNarrow({super.key, required String maskedEmail, required Widget codeField, required bool canSubmit,
  required Duration remaining, required VoidCallback onVerify, required VoidCallback? onResend});
// ResetVerifyWide cùng tham số
const ResetCreateNarrow({super.key, required Widget newPasswordField, required Widget confirmPasswordField});
// ResetCreateWide cùng tham số
// codeField = VField(nhãn 'Mã xác nhận' *, ô mã layout fill, VFieldError khi codeError != null)
```

- [x] **Step 1: Prototype** — `resetResendLabel(s)` trả như `resendLabel(s)` (`mm:ss`); ca `verify-wrong`: bỏ `toast`, thêm `codeError: 'Mã xác nhận không đúng.'`, `codeField({ invalid: !!s.codeError })` + `field({ error: s.codeError })` ở hai khung; ca `resent-toast` nhãn "01:00"; sửa câu mô tả hai ca; sửa test node (`resetResendLabel(60) === 'Gửi lại mã sau 01:00'`). Ca `request-failed`: thay `toast` bằng `message` (thân màn đọc `s.message`), không còn toast. `t1.css .t1-pwbar`: bỏ `border-top` và `background`; `toast(… above)` của bước 2 đổi 78 → 77. `node --test` PASS; `node tools/capture.mjs reset__verify`, `node tools/capture.mjs reset__re`, `node tools/capture.mjs reset__create`; chép lại ảnh `reset__{verify-wrong,resent-toast,request-failed,create,create-errors}` hai khung.

- [x] **Step 2: Viết test**

```dart
test('wrong, expired, exceeded codes set codeError without failure', …) // 3 mã → 3 câu của mapper; failure isNull
test('network error while verifying sets failure only', …)
test('verified=false sets codeError', …)                                // 'Mã xác nhận không đúng.'
test('codeError clears on edit, verify start, resend start, step 2', …)
testWidgets('wrong code shows the error under the cells, no toast', …)  // VFieldError một; không có VToast; 6 ô viền danger
testWidgets('resend failure after a wrong code shows one toast and no inline error', …) // VFieldError findsNothing, 6 ô viền không danger
testWidgets('exceeded attempts keeps resend available', …)
testWidgets('request failure shows no toast', …)                        // find.byType(VToast) findsNothing
testWidgets('step 2 bottom bar has a single top border', …)              // 1280: một BoxDecoration có viền trên, rộng 1280
testWidgets('countdown starts at 01:00', …)                             // sửa ca cũ: 'Gửi lại mã sau 01:00'; hết → link
testWidgets('back from step 2 clears the code and disables confirm', …)
testWidgets('390: note sits right under the cells; 1280: note under the card', …)
testWidgets('1280: card 488 wide, bottom bar content 488 wide at step 2', …)
testWidgets('resizing 900 → 700 keeps 3 typed digits', …)               // auth.calls không có 'verifyMy'
testWidgets('320 at text scale 2.0 does not overflow', …)               // bước 1, bước 2
```

- [x] **Step 3: Chạy → FAIL** — `cd apps/erp && flutter test test/features/iam/presentation_module/widgets/reset_password_page_test.dart`
- [x] **Step 4: Cài đặt** Q1–Q8. Hẹp: `Scaffold(backgroundColor: surface, appBar: VAppBar(title: 'Đặt lại mật khẩu'))`; web: nền `background`.
- [x] **Step 5: Chạy → PASS** — `flutter test test/features/iam/presentation_module/widgets/reset_password_page_test.dart test/features/auth/presentation/wgt_th01_s0_login_test.dart test/features/my_account test/features/iam/presentation_module/widgets/my_account_page_test.dart`
- [x] **Step 6: Golden** ca `reset__{verify,verify-wrong,resend-ready,create,create-errors,request-failed}` × 2 (khổ như `captureAuth` 10-8e, `clock` cố định). So ảnh, ghi lệch.
- [x] **Step 7: Commit** `feat(10-8f): Đặt lại mật khẩu theo prototype, sai mã báo tại ô`

### Task 2: Nhập mã lời mời

**Files:**
- Create: `apps/erp/lib/features/auth/presentation/widgets/invitation_entry_narrow.dart`, `invitation_entry_wide.dart`
- Modify: `…/widgets/invitation_token_entry_form.dart`
- Test: `invitation_token_page_test.dart`; `test/features/auth/presentation/auth_golden_test.dart`

**Interfaces:**
- Consumes: `VVerificationCodeLayout.split4` / `.fill`, `FlowColumn`, `FlowCard`, `FlowIcon.medium`.
- Produces: hai widget cùng `({super.key, required Widget codeField, required bool isSubmitting, required VoidCallback onSubmit, required VoidCallback? onBack})`. `codeField` gồm `KeyedSubtree(key: Key('invitation_token_input'))`, `GlobalKey` trên `VVerificationCodeField`; `layout` đổi theo `isWideLayout`, `State` ô mã giữ nguyên.

- [x] **Step 1: Viết test**

```dart
testWidgets('390: split 4 + 4 cells, continue right under the hint', …)  // Key v-code-cell-0 cao 52; không có bottomNavigationBar
testWidgets('1280: card 488 wide, 8 cells fill 446, continue inside the card', …)
testWidgets('resizing 900 → 700 keeps 5 typed characters and does not submit', …) // onInspect không gọi
testWidgets('320 at text scale 2.0 does not overflow', …)
```

- [x] **Step 2: Chạy → FAIL** — `flutter test test/features/auth/presentation/invitation`
- [x] **Step 3: Cài đặt**
- [x] **Step 4: Chạy → PASS** — lệnh Step 2 và `flutter test test/features/invitations`
- [x] **Step 5: Golden** ca `invitation__{entry,entry-partial,entry-invalid,inspecting}` × 2 (`inspecting`: `pump(100ms)`). So ảnh.
- [x] **Step 6: Commit** `feat(10-8f): Nhập mã lời mời theo prototype`

### Task 3: Kích hoạt tài khoản theo lời mời

**Files:**
- Create: `apps/erp/lib/features/auth/presentation/widgets/invitation_register_narrow.dart`, `invitation_register_wide.dart`
- Modify: `…/widgets/invitation_registration_form.dart`
- Test: `invitation_token_page_test.dart` (ca `pre-fills…` dòng 370–394), `invitation_registration_phone_test.dart`, `auth_golden_test.dart`

**Interfaces:**
- Consumes: `FlowColumn`, `FlowCard`.
- Produces: hai widget cùng `({super.key, required String tenantName, required String email, required Widget familyField, givenField, emailField, phoneField, passwordField, confirmField, required bool isSubmitting, required VoidCallback onSubmit, required VoidCallback? onBack})`; `InvitationRegisterNarrow` không dùng `emailField` (tự vẽ dòng Q9).

- [x] **Step 1: Viết test**

```dart
testWidgets('390: locked email is a read-only row', …)   // Key invitation_locked_email chứa Text email; không có TextField bên trong; semantics 'Email, …, không sửa được'
testWidgets('1280: locked email is a disabled field', …) // giữ hai khẳng định cũ dòng 370–394
testWidgets('390: names share a row 3 : 2, submit right under the form', …)
testWidgets('390: keyboard open, submit can be scrolled into view', …) // viewInsets.bottom 327, ensureVisible, hitTestable
testWidgets('1280: banner then card 488, bottom bar content 488', …)
testWidgets('resizing keeps every typed value', …)
testWidgets('320 at text scale 2.0, 80-char tenant and 60-char email do not overflow', …)
```

- [x] **Step 2: Chạy → FAIL** — `flutter test test/features/auth/presentation/invitation`
- [x] **Step 3: Cài đặt** Q9; `AutofillGroup` bọc form ở cả hai bố cục.
- [x] **Step 4: Chạy → PASS** (lệnh Step 2)
- [x] **Step 5: Golden** ca `invitation__{register,register-errors}` × 2. So ảnh.
- [x] **Step 6: Commit** `feat(10-8f): Kích hoạt tài khoản theo lời mời theo prototype`

### Task 4: Sheet xác nhận, màn kết quả, dọn

**Files:**
- Modify: `apps/erp/lib/core/widgets/flow/flow_layout.dart` (Q12), `…/widgets/invitation_confirm_bottom_sheet.dart`, `…/widgets/invitation_outcome_view.dart`, `…/pages/invitation_token_page.dart`
- Modify: `apps/erp/test/features/iam/presentation_module/w2_behavior_preservation_test.dart`, `docs/requirements/TH-01-to-chuc-va-nguoi-dung.md` (US-02.3), `docs/refactor/PLAN.md`
- Test: `invitation_token_page_test.dart`, `auth_golden_test.dart`

**Interfaces:**
- Consumes: `FlowIcon`.
- Produces: `enum FlowIconTone { brand, neutral, warning }`; `FlowIcon.large(icon, {tone = FlowIconTone.brand})`. `InvitationOutcomeView` tự dựng cả `Scaffold` (trang không bọc nữa).

- [x] **Step 1: Viết test**

```dart
testWidgets('390: confirm sheet shows a filled box with three rows', …)  // nền background; giá trị canh phải
testWidgets('1280: confirm dialog keeps the 72-wide labels', …)
testWidgets('390: declined uses the neutral icon, blocked the warning icon, action at the bottom', …)
testWidgets('1280: outcome is top aligned within 480', …)
testWidgets('320 at text scale 2.0: confirm sheet scrolls to decline', …)
```

`w2_behavior_preservation_test.dart`: xoá ca "3 màn công khai … ở 1280 ≤ 480" (10-8e Task 5 để lại); ca "ở 800 ≤ 480" thêm lại ba màn này thành 7.

- [x] **Step 2: Chạy → FAIL** — `flutter test test/features/auth/presentation/invitation`
- [x] **Step 3: Cài đặt** Q10–Q12.
- [x] **Step 4: TH-01 US-02.3** — FR-02 thêm: "Mã sai / hết hạn / nhập sai quá số lần báo dưới ô mã, không toast (10-8f)"; "Gửi lại mã sau 00:ss" → "Gửi lại mã sau mm:ss".
- [x] **Step 5: Chạy → PASS**

Run: `cd apps/erp && flutter test test/features/auth test/features/invitations test/core/widgets test/features/iam/presentation_module/widgets/reset_password_page_test.dart test/features/iam/presentation_module/w2_behavior_preservation_test.dart && dart analyze lib test && dart run tool/check_feature_imports.dart`
Expected: PASS, không lỗi analyze mới, không vi phạm import mới

- [x] **Step 6: Golden** ca `invitation__{confirm,declined,blocked}` × 2. So ảnh.
- [x] **Step 7: PLAN.md** dòng Theme 1: 10-8f đã làm. Commit `feat(10-8f): sheet xác nhận và kết quả lời mời theo prototype`

## Kiểm tay (người dùng)

- [ ] Quên mật khẩu: sai mã, gửi lại, "Quay lại" từ bước 2, đặt lại xong; cùng luồng từ Tài khoản của tôi (web ≥ 1024 còn thanh bên).
- [ ] Lời mời: mã sai, từ chối, kích hoạt tài khoản mới, tài khoản đã có; iPhone và web.
- [ ] iPhone: form kích hoạt khi bàn phím mở; trình quản lý mật khẩu vẫn gợi ý mật khẩu mới.
- [ ] CHECKLIST ID-04, ID-06, ID-07, ID-23 cột "Mới".

## Kết quả

Làm xong 2026-11-26, 5 commit (`11647b6a1` … `405cf44db`). Test trong phạm vi plan: 296 ca xanh (`reset_password_page_test`, `reset_password_golden_test`, `test/features/auth`, `test/features/invitations`, `test/core/widgets`, `w2_behavior_preservation_test`). `check_feature_imports` không có vi phạm mới ở `iam/presentation`, `auth/presentation`, `core/widgets`.

- Lỗi 3: sai / hết hạn / quá số lần báo dưới ô mã bằng `PasswordResetState.codeError`, không toast; lỗi mạng vẫn là toast.
- Lỗi 4: đếm ngược "Gửi lại mã sau 01:00" qua `ResendCountdown`.
- Lời mời: nhập mã, kích hoạt tài khoản, sheet xác nhận, màn kết quả có bố cục hẹp / rộng riêng; email khoá ở hẹp là dòng đọc (Q9).
- Docs: TH-01 US-02.3 và README prototype (mục 21, 22) đã cập nhật; `PLAN.md` ghi 10-8f.

**Lệch golden so với prototype (chấp nhận):**
- Golden thiếu mũi tên ← ở app bar: harness không có route để pop.
- Icon hiện ô vuông (font Ahem của test), không phải lỗi bố cục.
- Không có thanh trạng thái 09:41 / LTE của khung iPhone prototype.
- Email, tên tổ chức trong golden là dữ liệu mẫu của test, không trùng ảnh prototype.

## Review

Review 2026-11-26: không có lỗi chặn. **Trạng thái: done.**

- R1 (đã xử lý): hai import thừa ở `reset_password_page_test.dart` (`iam_ui_failure_mapper.dart`, `password_reset_cubit.dart`) gây 2 cảnh báo `unnecessary_import`; đã xoá, analyze sạch, 27 ca xanh.
- R2 (đã xử lý): nhánh `catch` của `PasswordResetCubit.verify` truyền cặp `failure` / `clearFailure` và `codeError` / `clearCodeError` trùng ý; tách thành hai `copyWith` (lỗi mã / lỗi khác), hành vi giữ nguyên, 39 ca reset xanh.
- R3 (rủi ro đã chấp nhận, kiểm tay): form kích hoạt khổ hẹp không còn ô email nhập được (Q9), trình quản lý mật khẩu không tự ghép email với mật khẩu mới. Xem mục Kiểm tay.
- Đã đối chiếu Q1–Q12 và 5 Review Focus với code và test: đủ.
