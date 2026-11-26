// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, devicesFor, GROUPS, IPHONE_ONLY, SCREENS, WEB_NOTES } from '../app/cases.js';
import { codeField } from '../app/ds.js';
import { joinedMessage } from '../app/login.js';
import { accountErrors, storeErrors, policyError, PROVINCES } from '../app/signup.js';
import { maskEmail, resendLabel } from '../app/verify.js';
import { resetResendLabel } from '../app/reset.js';
import { entryFailureMessage, tokenFormatError } from '../app/invitation.js';
import { statusDetail } from '../app/admin-data.js';
import { filterSheet } from '../app/users.js';

test('maskEmail (password_reset_result.dart)', () => {
  assert.equal(maskEmail('lan@anphat.vn'), 'l***@anphat.vn');
  assert.equal(maskEmail('@x.vn'), '***');
  assert.equal(maskEmail('khong-co-a-cong'), '***');
});

test('ResendCountdown mm:ss; nút gửi lại của Đặt lại mật khẩu dùng mm:ss', () => {
  assert.equal(resendLabel(0), 'Gửi lại mã');
  assert.equal(resendLabel(59), 'Gửi lại mã sau 00:59');
  assert.equal(resendLabel(60), 'Gửi lại mã sau 01:00');
  assert.equal(resetResendLabel(60), 'Gửi lại mã sau 01:00');
  assert.equal(resetResendLabel(0), 'Gửi lại mã');
});

test('joinedMessage có / không tên tổ chức', () => {
  assert.match(joinedMessage('Thú y An Phát'), /"Thú y An Phát"/);
  assert.equal(joinedMessage('  '), 'Đã tham gia tổ chức thành công. Đăng nhập để vào Mosaic Retail.');
});

test('signup _accountErrors / _storeErrors', () => {
  const e = accountErrors({ familyName: '', givenName: '', email: 'lan@anphat', phone: '', password: 'abc', confirmPassword: '' });
  assert.deepEqual(Object.keys(e), ['familyName', 'givenName', 'email', 'password', 'confirmPassword']);
  assert.equal(e.password, 'Mật khẩu phải có ít nhất 8 ký tự');
  assert.equal(accountErrors({ familyName: 'A', givenName: 'B', email: 'a@b.vn', phone: '', password: 'abcdefgh', confirmPassword: 'abcdefgh' }).password, policyError('abcdefgh'));
  assert.deepEqual(accountErrors({ familyName: 'A', givenName: 'B', email: 'a@b.vn', phone: '0912345678', password: 'Abc@1234', confirmPassword: 'Abc@1234' }), {});
  assert.deepEqual(Object.keys(storeErrors({ name: '', contactPhone: '', provinceCode: '', communeCode: '', addressText: '' })), ['storeName', 'storePhone', 'province', 'commune', 'address']);
});

test('tỉnh sắp như Dart String.compareTo (theo mã ký tự)', () => {
  assert.deepEqual([...PROVINCES].sort(), PROVINCES);
});

test('form nhập mã lời mời', () => {
  assert.equal(tokenFormatError(''), 'Vui lòng nhập mã lời mời');
  assert.equal(tokenFormatError('K7M2'), 'Mã lời mời phải gồm 8 ký tự chữ hoặc số');
  assert.equal(tokenFormatError('k7m2qx9a'), 'Mã lời mời phải gồm 8 ký tự chữ hoặc số'); // ô tự viết HOA nên thực tế không gặp
  assert.equal(tokenFormatError('K7M2QX9A'), null);
  assert.equal(entryFailureMessage('LẠ'), 'Không thể xác thực mã. Kiểm tra kết nối và thử lại.');
});

test('VVerificationCodeField co ô khi hẹp', () => {
  assert.match(codeField({ length: 6, columnWidth: 448 }), /width:48px;height:56px/);
  assert.match(codeField({ length: 8, columnWidth: 358 }), /width:37\.75px;height:48px/);
});

test('codeField fill (web): ô chia đều, không đặt bề rộng', () => {
  assert.match(codeField({ length: 6, columnWidth: 446, fill: true }), /t1-code--fill.*style="height:56px;font-size:18px"/);
  assert.doesNotMatch(codeField({ length: 6, columnWidth: 446, fill: true }), /width:/);
});

test('mọi màn có nhóm hợp lệ', () => {
  const ids = GROUPS.map((g) => g.id);
  for (const s of SCREENS) assert.ok(ids.includes(s.group), s.id);
});

test('mọi ca vẽ được; màn công khai mở ngoài khung (không thanh bên / thanh dưới)', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) for (const d of devicesFor(screen, state)) {
    const html = render(screen, state, d);
    assert.match(html, /class="t1-page/, `${screen}/${state}/${d}`);
    assert.doesNotMatch(html, /class="sh-(bottom|side)"/, `${screen}/${state}/${d} khung`);
    assert.doesNotMatch(html, /undefined|NaN/, `${screen}/${state}/${d} giá trị lỗi`);
  }
});

// ---------------------------------------------------------------- đợt 2
test('Người dùng / Vai trò / Lịch sử: web là bảng toàn màn, chi tiết mở toàn màn (←); iPhone một màn, không bảng', () => {
  for (const [list, st, detail, dst] of [['users', 'members', 'member-detail', 'active'], ['roles', 'list', 'roles', 'detail'], ['audit', 'list', 'audit-detail', 'detail']]) {
    assert.match(render(list, st, 'web'), /class="t1-utable" role="table"/, list);
    assert.doesNotMatch(render(list, st, 'web'), /t1-split/, list);
    assert.doesNotMatch(render(list, st, 'iphone'), /t1-utable|t1-split/, list);
    assert.doesNotMatch(render(detail, dst, 'web'), /t1-split/, detail);
    assert.match(render(detail, dst, 'web'), /aria-label="Quay lại"/, detail);
  }
});

test('toast chi tiết thành viên (web) nằm trong màn chi tiết toàn màn', () => {
  const html = render('member-detail', 'toast-deactivated', 'web');
  assert.match(html, /Chi tiết thành viên/);
  assert.match(html, /t1-toast/);
});

test('web: nút thao tác nằm trong khối, không thanh dưới; iPhone giữ thanh Thao tác và sheet', () => {
  const web = render('member-detail', 'active', 'web');
  assert.match(web, /t1-invacts/); assert.match(web, /Tạm ngừng thành viên/); assert.doesNotMatch(web, /t1-bottombar/);
  assert.match(render('member-detail', 'suspended', 'web'), /Kích hoạt lại/);
  for (const st of ['owner', 'removed']) assert.doesNotMatch(render('member-detail', st, 'web'), /t1-invacts/);
  for (const [scr, st] of [['org-profile', 'no-legal'], ['invitation-detail', 'pending'], ['member-detail', 'active']]) {
    assert.match(render(scr, st, 'iphone'), /<span>Thao tác<\/span>/, scr);
    assert.doesNotMatch(render(scr, st, 'web'), /<span>Thao tác<\/span>/, scr);
  }
  // Tài khoản của tôi (2026-11-25): iPhone cũng không còn nút / sheet Thao tác, thao tác là dòng trong màn.
  const acc = render('account', 'owner', 'iphone');
  assert.doesNotMatch(acc, /<span>Thao tác<\/span>|t1-bottombar/);
  for (const l of ['Chỉnh sửa thông tin cá nhân', 'Đặt lại mật khẩu', 'Đăng xuất']) assert.match(acc, new RegExp(`<b>${l}</b>`));
  for (const [scr, sts] of Object.entries(IPHONE_ONLY)) for (const st of sts) { assert.ok(CASES[scr].includes(st), `${scr}/${st}`); assert.match(render(scr, st, 'iphone'), /Thao tác/); }
});

test('bố cục web không lọt sang iPhone: lớp chỉ khai ở t1-web.css không xuất hiện trong HTML iPhone', async () => {
  const { readFileSync } = await import('node:fs');
  const read = (f) => readFileSync(new URL(`../${f}`, import.meta.url), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '');
  const classes = (css) => new Set([...css.matchAll(/\.(t1-[\w-]+)/g)].map((m) => m[1]));
  const base = classes(read('styles/t1.css'));
  const webOnly = [...classes(read('styles/t1-web.css'))].filter((c) => !base.has(c));
  assert.ok(webOnly.length > 50);
  for (const [scr, sts] of Object.entries(CASES)) for (const st of sts) {
    const used = new Set([...render(scr, st, 'iphone').matchAll(/class="([^"]*)"/g)].flatMap((m) => m[1].split(/\s+/)));
    assert.deepEqual(webOnly.filter((c) => used.has(c)), [], `${scr}/${st}`);
  }
  for (const k of Object.keys(WEB_NOTES)) assert.ok(CASES[k], k);
});

test('VPageScaffold mặc định: cột 720 (web toàn màn) / 640 (cột phải 919) / không giới hạn (iPhone)', async () => {
  const { columnMax, detailWidth } = await import('../app/ds.js');
  assert.equal(columnMax(1280), 720);
  assert.equal(columnMax(detailWidth(1280)), 640);
  assert.equal(columnMax(390), Infinity);
});

test('chủ sở hữu duy nhất / đã loại: không có thanh Thao tác', () => {
  assert.doesNotMatch(render('member-detail', 'owner', 'iphone'), /t1-bottombar/);
  assert.doesNotMatch(render('member-detail', 'removed', 'iphone'), /t1-bottombar/);
  assert.match(render('member-detail', 'active', 'iphone'), /t1-bottombar/);
});

// ---------------------------------------------------------------- đợt 3
test('VAvatar initials + tài khoản: nhãn Chủ sở hữu chỉ với chủ, "(chưa có)" khi thiếu số điện thoại', async () => {
  const { initials } = await import('../app/account.js');
  assert.equal(initials('Nguyễn Thị Lan'), 'NL');
  assert.equal(initials('Lan'), 'L');
  assert.equal(initials('  '), '?');
  assert.match(render('account', 'owner', 'iphone'), /Chủ sở hữu/);
  assert.doesNotMatch(render('account', 'staff', 'iphone'), /Chủ sở hữu/);
  assert.match(render('account', 'no-phone', 'web'), /\(chưa có\)/);
});

test('AuditDetailRow (web): giá trị > 24 ký tự xếp dọc; mã theo dõi rút gọn 12…8 vẫn một hàng', () => {
  const html = render('audit-detail', 'actor-unavailable', 'web');
  assert.match(html, /t1-drow t1-drow--block"><div class="t1-drow__head"><span>Người thực hiện/);
  assert.match(render('audit-detail', 'detail', 'web'), /<div class="t1-drow"><span>Mã theo dõi<\/span><b>req_7f3a9c21…c8d19f02/);
});

test('Chi tiết hoạt động (iPhone): một thẻ, "Dữ liệu thay đổi" đứng đầu; mã theo dõi rút gọn 12…8 + nút sao chép', () => {
  const html = render('audit-detail', 'detail', 'iphone');
  assert.ok(html.indexOf('Dữ liệu thay đổi') < html.indexOf('Ngữ cảnh'));
  assert.match(html, /<span>Mã theo dõi<\/span><b>req_7f3a9c21…c8d19f02<\/b>/);
  assert.match(html, /aria-label="Sao chép mã theo dõi"/);
  assert.doesNotMatch(render('audit-detail', 'actor-unavailable', 'iphone'), /Dữ liệu thay đổi/);
});

test('codeField invalid: class is-invalid trên thẻ ngoài', () => {
  assert.match(codeField({ length: 6, columnWidth: 358, fill: true, invalid: true }), /class="t1-code t1-code--fill is-invalid"/);
  assert.doesNotMatch(codeField({ length: 6, columnWidth: 358, fill: true }), /is-invalid/);
});

test('verify resend-failed: toast đỏ, ô mã không đỏ (10-8e, lỗi 2)', () => {
  for (const d of ['iphone', 'web']) {
    const html = render('verify', 'resend-failed', d);
    assert.doesNotMatch(html, /is-invalid/, d);
    assert.match(html, /t1-toast--danger/, d);
    assert.match(html, /Không thể kết nối đến máy chủ/, d);
  }
});

test('10-8h: bộ lọc lời mời — "Thu hồi" thuộc Trạng thái, không thuộc Kết quả gửi (Q3)', () => {
  const html = filterSheet('invitations');
  const [status, send] = html.split('Kết quả gửi');
  assert.match(status, /Thu hồi/);
  assert.doesNotMatch(send.split('Thời gian')[0], /Thu hồi/);
});

test('10-8h: lời mời kết thúc không ghi hạn; mã gửi lạ → — (Q20)', () => {
  assert.equal(statusDetail({ role: 'Kế toán', expiry: '', delivery: 'sent' }), 'Kế toán · Đã gửi email');
  assert.equal(statusDetail({ role: 'Kế toán', expiry: 'Hết hạn sau 2 ngày', delivery: 'unknown' }), 'Kế toán · Hết hạn sau 2 ngày · —');
});

test('10-8h: chữ mới ở Người dùng (Q4, Q5, Q6, Q18, Q21)', () => {
  for (const d of ['iphone', 'web']) {
    const invite = render('invite', 'empty-submit', d);
    assert.equal(invite.match(/Vui lòng nhập email và chọn vai trò\./g).length, 2, d);
    assert.match(render('invite', 'empty', d), /nhanvien@example\.com/, d);
    assert.match(render('member-detail', 'active', d), /Thành viên/, d);
    assert.doesNotMatch(render('member-detail', 'active', d), /Danh tính|Chỉ đọc/, d);
    assert.doesNotMatch(render('select-role', 'default', d), /Danh tính|Chỉ đọc/, d);
    const confirm = render('select-role', 'confirm', d);
    assert.match(confirm, /Đổi vai trò của Trần Văn Minh\?/, d);
    assert.match(confirm, /Vai trò Nhân viên bán hàng → Thủ kho\./, d);
    assert.match(confirm, /Xác nhận thay đổi/, d);
    assert.match(render('users', 'invitations-empty', d), /Chưa có lời mời nào/, d);
  }
  assert.match(render('invitation-detail', 'revoke', 'iphone'), /Lý do thu hồi[\s\S]{0,200}\*/);
});
