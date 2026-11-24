import test from 'node:test';
import assert from 'node:assert/strict';
import { TODAY, customers, edgeCustomers, tuanAt, summaryOf } from '../app/data.js';
import { customerDueLabel } from '../app/format.js';

const sum = (orders) => orders.reduce((s, o) => s + o.outstandingMinor, 0);
const byName = (n) => [...customers, ...edgeCustomers].find((c) => c.displayName === n);

test('tổng hợp 3 khách chuẩn', () => {
  assert.deepEqual(summaryOf(customers), { totalOutstandingMinor: 26500000, customerCount: 3, overdueCustomerCount: 1 });
});
test('Tuấn: 18tr, quá hạn 8 ngày, 3 đơn', () => {
  const t = byName('Anh Tuấn');
  assert.equal(sum(t.orders), 18000000);
  assert.equal(t.orders.length, 3);
  assert.equal(customerDueLabel(t.orders, TODAY).text, 'Quá hạn 8 ngày');
});
test('Tuấn theo từng thời điểm của ví dụ 2.3', () => {
  assert.equal(sum(tuanAt('before').orders), 18000000);
  assert.equal(sum(tuanAt('afterCollect').orders), 8000000);
  assert.equal(sum(tuanAt('afterOffset').orders), 7500000);
  assert.equal(sum(tuanAt('paidOff').orders), 0);
  assert.ok(!tuanAt('afterOffset').orders.some((o) => o.code === 'DH-001'));
});
test('mọi lần thu: Σ phân bổ = số tiền', () => {
  for (const m of ['before', 'afterCollect', 'afterOffset', 'paidOff'])
    for (const h of tuanAt(m).history.filter((x) => x.kind === 'collection'))
      assert.equal(h.allocations.reduce((s, a) => s + a.amount, 0), h.amount);
});
test('Cô Hoa nợ 1.500.000, ngừng hoạt động', () => {
  const h = byName('Cô Hoa');
  assert.equal(sum(h.orders), 1500000);
  assert.equal(h.isActive, false);
});

import { cn02Model } from '../app/cn02.js';
test('CN-02: Σ đơn hiện = số Còn nợ ở mọi state', () => {
  for (const st of ['full', 'after-offset', 'block-error', 'paid-off', 'inactive', 'no-history']) {
    const m = cn02Model(st);
    assert.equal(m.orders.reduce((s, o) => s + o.outstandingMinor, 0), m.total, st);
  }
  assert.equal(cn02Model('after-offset').total, 7500000);
  assert.equal(cn02Model('after-offset').overdueCount, 1);
  assert.equal(cn02Model('paid-off').total, 0);
});

import { sg13Model } from '../app/sg13.js';
test('SG-13: các ca đúng kế hoạch', () => {
  assert.equal(sg13Model('all-selected').plan.refund, 0);
  assert.equal(sg13Model('none-selected').plan.refund, 500000);
  assert.deepEqual(sg13Model('one-unchecked').plan.offsets.map((o) => o.amountMinor), [0, 500000]);
  const mx = sg13Model('mixed').plan;
  assert.deepEqual([mx.reduceOwnDebt, mx.offsets[0].amountMinor, mx.refund], [400000, 2e6, 600000]);
  assert.equal(sg13Model('source-has-debt').plan.showOffsetBlock, false);
  assert.equal(sg13Model('no-other-debt').plan.refund, 500000);
});
