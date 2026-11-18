import test from 'node:test';
import assert from 'node:assert/strict';
import { customers, richCustomers } from '../app/data.js';
import { sortedByUrgency, summaryV, filterCustomers } from '../app/cn01.js';

const names = (l) => l.map((c) => c.displayName);

test('ô tổng ví dụ 2.3: quá hạn 12.000.000 ₫ (chỉ phần đơn đã quá hạn), 1 khách, lâu nhất 8 ngày', () => {
  assert.deepEqual(summaryV(customers), { totalMinor: 26500000, customerCount: 3, overdueMinor: 12000000, overdueCustomerCount: 1, oldestOverdueDays: 8 });
});
test('ô tổng 8 khách: quá hạn 21.450.000 ₫ từ 4 khách, lâu nhất 21 ngày', () => {
  const s = summaryV(richCustomers);
  assert.equal(s.totalMinor, 53250000);
  assert.equal(s.overdueMinor, 21450000);
  assert.equal(s.overdueCustomerCount, 4);
  assert.equal(s.oldestOverdueDays, 21);
});
test('mức khẩn: quá hạn lâu nhất → đến hạn hôm nay → hẹn gần nhất → không hẹn', () => {
  assert.deepEqual(names(sortedByUrgency(richCustomers)), [
    'Anh Bình', 'Anh Tuấn', 'Phòng khám thú y Đồng Xuân – Chi nhánh 2', 'Chị Mai',
    'Trại Hưng Phát', 'Chị Lan', 'Cửa hàng Minh Châu', 'Anh Nam',
  ]);
});
test('ví dụ 2.3: Tuấn (quá hạn) → Hưng Phát (hôm nay) → Lan (hẹn 25/11)', () => {
  assert.deepEqual(names(sortedByUrgency(customers)), ['Anh Tuấn', 'Trại Hưng Phát', 'Chị Lan']);
});
test('lọc Quá hạn chỉ giữ khách quá hạn; tìm bỏ dấu theo tên và SĐT', () => {
  assert.deepEqual(names(filterCustomers(richCustomers, { filter: 'overdue' })), ['Anh Bình', 'Anh Tuấn', 'Phòng khám thú y Đồng Xuân – Chi nhánh 2', 'Chị Mai']);
  assert.deepEqual(names(filterCustomers(richCustomers, { query: 'tuan' })), ['Anh Tuấn']);
  assert.deepEqual(names(filterCustomers(richCustomers, { query: '0912004880' })), ['Cửa hàng Minh Châu']);
});
