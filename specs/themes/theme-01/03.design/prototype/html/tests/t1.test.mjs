// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, SCREENS, GROUPS } from '../app/cases.js';
import { codeField } from '../app/ds.js';
import { joinedMessage } from '../app/login.js';
import { accountErrors, storeErrors, policyError, PROVINCES } from '../app/signup.js';
import { maskEmail, resendLabel } from '../app/verify.js';
import { resetResendLabel } from '../app/reset.js';
import { entryFailureMessage, tokenFormatError } from '../app/invitation.js';

test('maskEmail (password_reset_result.dart)', () => {
  assert.equal(maskEmail('lan@anphat.vn'), 'l***@anphat.vn');
  assert.equal(maskEmail('@x.vn'), '***');
  assert.equal(maskEmail('khong-co-a-cong'), '***');
});

test('ResendCountdown mm:ss; nút gửi lại của Đặt lại mật khẩu luôn 00:ss', () => {
  assert.equal(resendLabel(0), 'Gửi lại mã');
  assert.equal(resendLabel(59), 'Gửi lại mã sau 00:59');
  assert.equal(resendLabel(60), 'Gửi lại mã sau 01:00');
  assert.equal(resetResendLabel(60), 'Gửi lại mã sau 00:60');
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

test('VVerificationCodeField: ô chia đều cột, thấp lại khi ô hẹp', () => {
  assert.match(codeField({ length: 6, columnWidth: 448 }), /style="height:56px;font-size:18px"/);
  assert.match(codeField({ length: 8, columnWidth: 358 }), /style="height:48px;font-size:14px"/);
});

test('mọi màn có nhóm hợp lệ', () => {
  const ids = GROUPS.map((g) => g.id);
  for (const s of SCREENS) assert.ok(ids.includes(s.group), s.id);
});

test('mọi ca vẽ được; màn công khai mở ngoài khung (không thanh bên / thanh dưới)', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) for (const d of ['iphone', 'web']) {
    const html = render(screen, state, d);
    assert.match(html, /class="t1-page/, `${screen}/${state}/${d}`);
    assert.doesNotMatch(html, /class="sh-(bottom|side)"/, `${screen}/${state}/${d} khung`);
    assert.doesNotMatch(html, /undefined|NaN/, `${screen}/${state}/${d} giá trị lỗi`);
  }
});

// ---------------------------------------------------------------- đợt 2
test('Người dùng / Vai trò: web là bảng toàn màn, chi tiết mở toàn màn (←)', () => {
  const web = render('users', 'members', 'web');
  assert.match(web, /class="t1-utable" role="table"/);
  assert.doesNotMatch(web, /t1-split/);
  assert.doesNotMatch(render('users', 'members', 'iphone'), /t1-utable|t1-split/);
  const detail = render('member-detail', 'active', 'web');
  assert.doesNotMatch(detail, /t1-split/);
  assert.match(detail, /t1-appbar__back/);
  assert.match(render('roles', 'list', 'web'), /aria-label="Vai trò hệ thống"/);
  assert.doesNotMatch(render('roles', 'detail', 'web'), /t1-split/);
});

test('toast của chi tiết thành viên nằm trong màn chi tiết (web toàn màn)', () => {
  const html = render('member-detail', 'toast-deactivated', 'web');
  assert.match(html, /Chi tiết thành viên/);
  assert.match(html, /t1-toast/);
});

test('VPageScaffold mặc định: cột 720 (web toàn màn) / 640 (cột phải 919) / không giới hạn (iPhone)', async () => {
  const { columnMax, detailWidth } = await import('../app/ds.js');
  assert.equal(columnMax(1280), 720);
  assert.equal(columnMax(detailWidth(1280)), 640);
  assert.equal(columnMax(390), Infinity);
});

test('chi tiết thành viên: nút thao tác nằm trong khối; chủ sở hữu duy nhất / đã loại không có nút', () => {
  assert.doesNotMatch(render('member-detail', 'owner', 'iphone'), /t1-invacts/);
  assert.doesNotMatch(render('member-detail', 'removed', 'iphone'), /t1-invacts/);
  const active = render('member-detail', 'active', 'iphone');
  assert.match(active, /t1-invacts/);
  assert.match(active, /Tạm ngừng thành viên/);
  assert.match(render('member-detail', 'suspended', 'iphone'), /Kích hoạt lại/);
  assert.doesNotMatch(active, /t1-bottombar/);
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

test('AuditDetailRow: giá trị > 24 ký tự xếp dọc; mã theo dõi rút gọn 12…8 vẫn một hàng', () => {
  const html = render('audit-detail', 'actor-unavailable', 'iphone');
  assert.match(html, /t1-drow t1-drow--block"><div class="t1-drow__head"><span>Người thực hiện/);
  assert.match(render('audit-detail', 'detail', 'iphone'), /<div class="t1-drow"><span>Mã theo dõi<\/span><b>req_7f3a9c21…c8d19f02/);
});
