import test from 'node:test';
import assert from 'node:assert/strict';
import { formatVnd, parseMoneyInput, dueLabel, customerDueLabel, overdueAmountMinor } from '../app/format.js';

const T = '2026-11-18';
test('formatVnd', () => {
  assert.equal(formatVnd(18000000), '18.000.000 ₫');
  assert.equal(formatVnd(0), '0 ₫');
  assert.equal(formatVnd(1234567890), '1.234.567.890 ₫');
});
test('parseMoneyInput chỉ giữ chữ số', () => {
  assert.equal(parseMoneyInput('10.000.000đ'), 10000000);
  assert.equal(parseMoneyInput('abc'), 0);
  assert.equal(parseMoneyInput(''), 0);
});
test('dueLabel', () => {
  assert.deepEqual(dueLabel('2026-11-10', T), { kind: 'overdue', days: 8, text: 'Quá hạn 8 ngày' });
  assert.deepEqual(dueLabel('2026-11-25', T), { kind: 'upcoming', text: 'Hẹn 25/11' });
  assert.deepEqual(dueLabel('2026-11-18', T), { kind: 'today', text: 'Đến hạn hôm nay' });
  assert.deepEqual(dueLabel(null, T), { kind: 'none', text: 'Không có hẹn' });
});
const tuan = [
  { outstandingMinor: 4e6, dueDate: '2026-11-10' },
  { outstandingMinor: 8e6, dueDate: '2026-11-15' },
  { outstandingMinor: 6e6, dueDate: '2026-11-30' },
];
test('customerDueLabel', () => {
  assert.equal(customerDueLabel(tuan, T).text, 'Quá hạn 8 ngày');
  assert.equal(customerDueLabel([{ outstandingMinor: 1e6, dueDate: '2026-11-18' }, { outstandingMinor: 1.5e6, dueDate: '2026-11-30' }], T).text, 'Đến hạn hôm nay');
  assert.equal(customerDueLabel([{ outstandingMinor: 6e6, dueDate: '2026-11-25' }], T).text, 'Hẹn 25/11');
  assert.equal(customerDueLabel([{ outstandingMinor: 6e6, dueDate: null }], T).text, 'Không có hẹn');
  assert.equal(customerDueLabel([{ outstandingMinor: 0, dueDate: '2026-11-01' }, { outstandingMinor: 5, dueDate: '2026-11-30' }], T).kind, 'upcoming');
});
test('overdueAmountMinor Tuấn = 12.000.000', () => {
  assert.equal(overdueAmountMinor(tuan, T), 12000000);
});
