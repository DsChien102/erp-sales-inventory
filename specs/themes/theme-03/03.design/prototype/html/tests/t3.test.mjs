// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, SCREENS, GROUPS } from '../app/cases.js';
import { initials, columnMax, fabGutter } from '../app/ds.js';
import { roleLabel, itemSubtitle, filterCount, headerLabel, emptyKind } from '../app/list.js';
import { sections, sectionTitle, formTitle, canSubmit, phoneError, invoiceWarning, sectionSummary, filterProvinces, formState } from '../app/form.js';
import { foldVietnamese } from '../app/data.js';

test('VAvatar._initialsFrom', () => {
  assert.equal(initials('Nguyễn Văn Hùng'), 'NH');
  assert.equal(initials('Mua lẻ / khác'), 'MK');
  assert.equal(initials('An'), 'A');
  assert.equal(initials('   '), '?');
});

test('VPageScaffold: cột theo chỗ đặt, gutter nút nổi theo cửa sổ', () => {
  assert.equal(columnMax(360), Infinity);
  assert.equal(columnMax(679), 640);
  assert.equal(columnMax(1280), 720);
  assert.equal(fabGutter(390), 0);
  assert.equal(fabGutter(1280), 280);
});

test('PartnerListItemTile._roleLabel / _subtitle', () => {
  assert.equal(roleLabel(['customer', 'supplier']), 'KH & NCC');
  assert.equal(roleLabel(['supplier']), 'Nhà cung cấp');
  assert.equal(roleLabel([]), 'Chưa có vai trò');
  assert.equal(itemSubtitle({ type: 'person', roles: ['customer'] }), 'Cá nhân · Khách hàng');
});

test('Danh sách: số trên nút lọc, tiêu đề đầu danh sách, loại rỗng', () => {
  assert.equal(filterCount({ role: 'customer' }), 1);
  assert.equal(filterCount({ role: 'customer', type: 'organization', status: 'active', updated: 7 }), 4);
  assert.equal(headerLabel({ query: null }, 48), 'Danh sách đối tác');
  assert.equal(headerLabel({ query: null, status: 'active' }, 0), '0 kết quả phù hợp');
  assert.equal(emptyKind({ query: null, status: 'inactive' }), 'empty');
  assert.equal(emptyKind({ query: 'abc' }), 'no-result');
});

test('PartnerCreateState.sections + số thứ tự mục', () => {
  assert.deepEqual(sections('organization', false), ['role', 'main', 'primaryContact', 'invoice', 'delivery', 'note']);
  assert.deepEqual(sections('organization', true), ['role', 'main', 'invoice', 'delivery', 'note']);
  assert.equal(sectionTitle('invoice', 'organization', false), '5. Hóa đơn / thuế');
  assert.equal(sectionTitle('invoice', 'organization', true), '4. Hóa đơn / thuế');
  assert.equal(sectionTitle('note', 'person', false), '6. Ghi chú');
});

test('Tiêu đề form (lúc tải bản sửa luôn "cá nhân")', () => {
  assert.equal(formTitle({ edit: true, type: 'organization', loading: true }), 'Chỉnh sửa cá nhân');
  assert.equal(formTitle({ edit: true, type: 'organization', loading: false }), 'Chỉnh sửa tổ chức');
  assert.equal(formTitle({ edit: false, type: 'organization', loading: false }), 'Tạo tổ chức');
});

test('canSubmit', () => {
  assert.equal(canSubmit(formState('person-new')), false);
  assert.equal(canSubmit(formState('person-main-filled')), true);
  assert.equal(canSubmit(formState('edit')), false);
  assert.equal(canSubmit(formState('edit-dirty')), true);
  assert.equal(canSubmit(formState('blocked')), false);
});

test('VPhoneValidator', () => {
  assert.equal(phoneError('', true), 'Vui lòng nhập số điện thoại');
  assert.equal(phoneError(''), null);
  assert.equal(phoneError('0912 34'), 'Số điện thoại không hợp lệ');
  assert.equal(phoneError('0912 345 678'), null);
  assert.equal(phoneError('+84912345678'), 'Số điện thoại không hợp lệ');
});

test('_organizationInvoiceWarning', () => {
  assert.equal(invoiceWarning({ type: 'person' }), null);
  assert.equal(invoiceWarning({ type: 'organization' }), 'Thiếu MST, tên xuất hóa đơn và địa chỉ hóa đơn. Vui lòng kiểm tra lại trước khi lưu.');
  assert.equal(invoiceWarning({ type: 'organization', taxCode: '0312345678' }), 'Thiếu tên xuất hóa đơn và địa chỉ hóa đơn. Vui lòng kiểm tra lại trước khi lưu.');
  assert.equal(invoiceWarning({ type: 'organization', taxCode: '1', invoiceName: 'a', invoiceAddress: 'b' }), null);
});

test('Chữ phụ khi mục đóng', () => {
  const s = formState('person-new');
  assert.equal(sectionSummary('role', s), null);
  assert.equal(sectionSummary('delivery', s), 'Tùy chọn');
  assert.equal(sectionSummary('primaryContact', { ...s, primaryContactEnabled: true }), 'Đã bật');
  assert.equal(sectionSummary('role', { ...s, roles: ['customer', 'supplier'] }), 'KH & NCC');
});

test('Sheet khu vực: sắp theo mã ký tự, tìm bỏ dấu', () => {
  const names = filterProvinces().map(([n]) => n);
  assert.equal(names.length, 34);
  assert.equal(names[0], 'Thành phố Cần Thơ');
  assert.ok(names.indexOf('Thành phố Đà Nẵng') > names.indexOf('Thành phố Hồ Chí Minh'));
  assert.equal(names[names.length - 1], 'Tỉnh Đồng Tháp');
  assert.equal(foldVietnamese('Đà Nẵng'), 'da nang');
  assert.deepEqual(filterProvinces('can tho').map(([n]) => n), ['Thành phố Cần Thơ']);
});

test('Mọi màn thuộc một đợt có khai báo', () => {
  const ids = GROUPS.map((g) => g.id);
  for (const s of SCREENS) assert.ok(ids.includes(s.group), s.id);
});

test('mọi ca vẽ được ở cả hai khổ', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) for (const device of ['iphone', 'web']) {
    const html = render(screen, state, device);
    assert.ok(html.includes('sh-app'), `${screen}/${state}/${device}`);
    assert.ok(!html.includes('undefined'), `undefined trong ${screen}/${state}/${device}`);
  }
});
