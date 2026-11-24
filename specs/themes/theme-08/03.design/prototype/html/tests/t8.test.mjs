// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, SCREENS, GROUPS } from '../app/cases.js';
import { checkedAt, syncedAt, updatedAt } from '../app/common.js';
import {
  automationSubtitle, completeTarget, connectionSubtitle, infoKind, issuanceSubtitle, maskAccount, notReadyDescription, overviewState,
  showsForm, statusValue, templateOptionLabel, templateSymbolValue,
} from '../app/setup.js';
import { TEMPLATES, DELIVERIES } from '../app/data.js';
import {
  allowsTapForIssuance, confirmLine1, confirmLine2, deliveryBadge, historyRows, isValidEmail, issuanceBadge, latestSummary, money, productIcon,
  safeFailureMessage, suggestionSource, templateDisplay,
} from '../app/order.js';

test('EInvoiceDateTimeCopy: "HH:mm, dd/MM/yyyy"', () => {
  const d = new Date(2026, 0, 5, 7, 3);
  assert.equal(checkedAt(d), 'Kiểm tra gần nhất: 07:03, 05/01/2026');
  assert.equal(syncedAt(d), 'Đồng bộ gần nhất: 07:03, 05/01/2026');
  assert.equal(updatedAt(d), 'Cập nhật gần nhất: 07:03, 05/01/2026');
});

test('HD-01: phụ đề ba mục', () => {
  assert.equal(connectionSubtitle('disconnected'), 'Chưa kết nối MISA meInvoice');
  assert.equal(connectionSubtitle('connected'), 'MISA meInvoice · Đã kết nối');
  assert.equal(connectionSubtitle('checkRequired'), 'Cần kiểm tra lại');
  assert.equal(connectionSubtitle('reconnectRequired'), 'Cần kết nối lại');
  assert.equal(issuanceSubtitle(null, TEMPLATES), 'Chưa chọn mẫu hóa đơn mặc định');
  assert.equal(issuanceSubtitle('', TEMPLATES), 'Chưa chọn mẫu hóa đơn mặc định');
  assert.equal(issuanceSubtitle(TEMPLATES[0].templateId, TEMPLATES), '1C26TAA · Có mã của cơ quan thuế');
  assert.equal(issuanceSubtitle(TEMPLATES[0].templateId, []), TEMPLATES[0].templateId);
  assert.equal(automationSubtitle(false, { autoIssue: true, autoSend: true }), 'Phát hành hóa đơn và gửi email tự động.');
  assert.equal(automationSubtitle(true, { autoIssue: true, autoSend: false }), 'Phát hành tự động · Gửi email thủ công');
  assert.equal(automationSubtitle(true, { autoIssue: false, autoSend: true }), 'Phát hành thủ công · Gửi email tự động');
  assert.equal(notReadyDescription(1), 'Còn 1 điều kiện cần hoàn tất trước khi có thể phát hành hóa đơn điện tử.');
});

test('HD-01: "Xem và hoàn tất" mở mục cần làm đầu tiên; mẫu chỉ có khi đã kết nối', () => {
  assert.equal(completeTarget({ isReady: true, connection: 'connected', templateId: 'x' }), null);
  assert.equal(completeTarget({ isReady: false, connection: 'checkRequired', templateId: 'x' }), 'connection');
  assert.equal(completeTarget({ isReady: false, connection: 'connected', templateId: null }), 'issuance');
  assert.equal(completeTarget({ isReady: false, connection: 'connected', templateId: 'x' }), 'automation');
  assert.equal(overviewState('check-required').templates.length, 0);
  assert.equal(overviewState('ready-manual').isReady, true);
  assert.equal(overviewState('not-ready').blockerCount, 1);
});

test('HD-02: trạng thái, che tài khoản, form / thẻ', () => {
  assert.equal(statusValue('connected'), 'Đã kết nối');
  assert.equal(statusValue('checkRequired'), 'Chờ kết nối');
  assert.equal(statusValue('reconnectRequired'), 'Lỗi kết nối');
  assert.equal(maskAccount('ketoan@anphat.vn'), 'ke***@anphat.vn');
  assert.equal(maskAccount('a@b.vn'), 'a@***'); // @ ở vị trí 1 → không giữ tên miền
  assert.equal(maskAccount('  admin '), 'ad***');
  assert.equal(maskAccount('ab'), '***');
  assert.equal(showsForm('disconnected'), true);
  assert.equal(showsForm('reconnectRequired', true), true);
  assert.equal(infoKind('connected'), 'connected');
  assert.equal(infoKind('checkRequired'), 'pending');
  assert.equal(infoKind('reconnectRequired'), 'error');
  assert.equal(infoKind('reconnectRequired', true), null);
});

test('HD-02 / HD-03: ca "error" là thẻ lỗi kết nối, không phải lỗi tải', () => {
  for (const [screen, state] of [['connection', 'error'], ['disconnect', 'from-error']]) {
    const html = render(screen, state, 'iphone');
    assert.ok(html.includes('Lỗi kết nối'), `${screen}/${state}`);
    assert.ok(!html.includes('Không thể tải dữ liệu'), `${screen}/${state}`);
  }
});

test('HD-04: nhãn lựa chọn và ký hiệu', () => {
  assert.equal(templateOptionLabel(TEMPLATES[0]), '1C26TAA');
  assert.equal(templateOptionLabel({ symbol: '  ', name: 'Hóa đơn bán hàng' }), 'Hóa đơn bán hàng');
  assert.equal(templateSymbolValue({ symbol: null, serial: 'C26TAA', templateId: 'g' }), 'C26TAA');
  assert.equal(templateSymbolValue({ symbol: null, serial: null, templateId: 'g' }), 'g');
});

test('HD-06 / HD-09: nhãn badge, bấm được', () => {
  assert.deepEqual(issuanceBadge('processing'), ['Đang xử lý', 'primary']);
  assert.deepEqual(issuanceBadge('failed'), ['Phát hành lỗi', 'danger']);
  assert.equal(allowsTapForIssuance('processing'), false);
  assert.equal(allowsTapForIssuance('failed'), true);
  assert.deepEqual(deliveryBadge('unknown'), ['Không xác định kết quả', 'warning']);
  assert.equal(money(5199232), '5.199.232đ');
  assert.equal(money(0), '0đ');
  assert.equal(productIcon('Lọ'), 'tag');
  assert.equal(productIcon('Hộp'), 'inventory');
});

test('HD-07 / HD-08: thông điệp lỗi, dòng xác nhận', () => {
  assert.equal(safeFailureMessage('COMMAND_INTEGRITY', 'x'), 'Dữ liệu đơn hàng hoặc cấu hình không khớp. Vui lòng kiểm tra lại.');
  assert.equal(safeFailureMessage('PROVIDER_REJECTED', '  MISA nói  '), 'MISA nói');
  assert.equal(safeFailureMessage('PROVIDER_REJECTED', ''), 'Nhà cung cấp từ chối phát hành hóa đơn điện tử.');
  assert.match(safeFailureMessage(null, null), /^Đã xảy ra lỗi/);
  const d = templateDisplay({ serial: 'C26TAA', symbol: '1C26TAA' }, 'hsm');
  assert.equal(confirmLine2(d), 'Mẫu C26TAA · Ký hiệu 1C26TAA · Có mã CQT');
  assert.equal(confirmLine2(templateDisplay({ serial: '', symbol: null }, null)), 'Mẫu — · Ký hiệu — · —');
  assert.equal(templateDisplay({ serial: 'C26TAA', symbol: ' ' }, 'mtt').symbol, 'C26TAA');
  assert.equal(confirmLine1('#DH-1', '10đ'), 'Đơn hàng #DH-1 · Tổng tiền 10đ');
});

test('HD-11 / HD-12 / HD-13: email, nguồn gợi ý, lần gửi', () => {
  assert.equal(isValidEmail(' a@b.vn '), true);
  assert.equal(isValidEmail('a@b'), false);
  assert.equal(isValidEmail(''), false);
  assert.equal(suggestionSource('userInput'), null);
  assert.equal(suggestionSource('buyerInvoiceSnapshot'), 'Thông tin người mua trên hóa đơn');
  assert.equal(latestSummary(DELIVERIES), 'Đã gửi gần nhất đến ketoan@thuyanphat.vn · 07/10/2026, 14:36');
  assert.equal(latestSummary(DELIVERIES.filter((d) => d.status !== 'succeeded')), null);
  const rows = historyRows(DELIVERIES);
  assert.equal(rows[0].title, 'Không xác định kết quả · mua.hang@thuyanphat.vn');
  assert.equal(rows[0].meta, '08/10/2026 · 09:10 · Người dùng');
  assert.equal(rows[2].meta, '07/10/2026 · 14:36 · Tự động');
});

test('Mọi màn thuộc một đợt; mọi ca vẽ được ở cả hai khổ', () => {
  const groups = new Set(GROUPS.map((g) => g.id));
  for (const s of SCREENS) assert.ok(groups.has(s.group), s.id);
  for (const [screen, states] of Object.entries(CASES)) {
    for (const state of states) {
      for (const device of ['iphone', 'web']) {
        const html = render(screen, state, device);
        assert.ok(html.length > 500, `${screen}/${state}/${device}`);
        assert.ok(!html.includes('undefined'), `undefined trong ${screen}/${state}/${device}`);
        assert.ok(!html.includes('NaN'), `NaN trong ${screen}/${state}/${device}`);
        assert.ok(!html.includes('[object'), `[object trong ${screen}/${state}/${device}`);
        assert.ok(!html.includes('null'), `null trong ${screen}/${state}/${device}`);
      }
    }
  }
});
