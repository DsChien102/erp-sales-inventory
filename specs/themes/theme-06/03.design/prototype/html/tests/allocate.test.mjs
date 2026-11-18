import test from 'node:test';
import assert from 'node:assert/strict';
import { allocateOldestFirst, planReturnSettlement } from '../app/allocate.js';

const orders = [{ id: 'DH-001', outstandingMinor: 4e6 }, { id: 'DH-002', outstandingMinor: 8e6 }];
test('chia cũ trước 10tr', () => {
  assert.deepEqual(allocateOldestFirst(orders, 10e6), [
    { id: 'DH-001', allocatedMinor: 4e6, outstandingAfterMinor: 0 },
    { id: 'DH-002', allocatedMinor: 6e6, outstandingAfterMinor: 2e6 },
  ]);
});
test('amount 0 → []', () => assert.deepEqual(allocateOldestFirst(orders, 0), []));
test('amount = tổng → hết nợ', () => {
  assert.ok(allocateOldestFirst(orders, 12e6).every((x) => x.outstandingAfterMinor === 0));
});

const cands = [{ id: 'DH-002', outstandingMinor: 2e6 }, { id: 'DH-003', outstandingMinor: 6e6 }];
const plan = (o) => planReturnSettlement(o);
test('AC-01 US-03.1: cấn trừ 500k vào DH-002, hoàn 0', () => {
  const r = plan({ entitled: 500000, sourceOutstanding: 0, candidates: cands, selectedIds: ['DH-002', 'DH-003'] });
  assert.deepEqual(r.offsets, [{ id: 'DH-002', amountMinor: 500000 }, { id: 'DH-003', amountMinor: 0 }]);
  assert.equal(r.refund, 0); assert.equal(r.reduceOwnDebt, 0); assert.equal(r.showOffsetBlock, true);
});
test('FR-04: bỏ DH-002 → DH-003 nhận', () => {
  const r = plan({ entitled: 500000, sourceOutstanding: 0, candidates: cands, selectedIds: ['DH-003'] });
  assert.deepEqual(r.offsets, [{ id: 'DH-002', amountMinor: 0 }, { id: 'DH-003', amountMinor: 500000 }]);
  assert.equal(r.refund, 0);
});
test('AC-02: bỏ hết → hoàn 500k', () => {
  const r = plan({ entitled: 500000, sourceOutstanding: 0, candidates: cands, selectedIds: [] });
  assert.ok(r.offsets.every((o) => o.amountMinor === 0));
  assert.equal(r.refund, 500000);
});
test('AC-03: giảm nợ hết → ẩn khối', () => {
  const r = plan({ entitled: 600000, sourceOutstanding: 600000, candidates: [cands[0]], selectedIds: ['DH-002'] });
  assert.equal(r.reduceOwnDebt, 600000); assert.equal(r.remaining, 0); assert.equal(r.refund, 0); assert.equal(r.showOffsetBlock, false);
});
test('AC-02 US-03.2: 3tr, nợ khác 2tr → cấn 2tr hoàn 1tr', () => {
  const r = plan({ entitled: 3e6, sourceOutstanding: 0, candidates: [cands[0]], selectedIds: ['DH-002'] });
  assert.deepEqual(r.offsets, [{ id: 'DH-002', amountMinor: 2e6 }]); assert.equal(r.refund, 1e6);
});
test('mixed: giảm nợ 400k, cấn 2tr, hoàn 600k', () => {
  const r = plan({ entitled: 3e6, sourceOutstanding: 400000, candidates: [cands[0]], selectedIds: ['DH-002'] });
  assert.equal(r.reduceOwnDebt, 400000); assert.equal(r.remaining, 2600000);
  assert.deepEqual(r.offsets, [{ id: 'DH-002', amountMinor: 2e6 }]); assert.equal(r.refund, 600000);
});
test('không đơn khác', () => {
  const r = plan({ entitled: 500000, sourceOutstanding: 0, candidates: [], selectedIds: [] });
  assert.equal(r.showOffsetBlock, false); assert.equal(r.refund, 500000);
});

import { cn03Scope, cn03Calc } from '../app/cn03.js';
import { tuanAt } from '../app/data.js';
const tuanOrders = tuanAt('before').orders;
const calcOf = (ids, amount) => { const s = cn03Scope(tuanOrders, ids); return { s, c: cn03Calc(amount, s.applicable, s.scopeTotal, s.customerTotal) }; };
test('tick tất cả = trả hết: số tiền mặc định 18tr, cả 3 đơn hết nợ (AC-02)', () => {
  const { s, c } = calcOf(['DH-001', 'DH-002', 'DH-003'], 18e6);
  assert.equal(s.scopeTotal, 18e6); assert.ok(c.alloc.every((a) => a.outstandingAfterMinor === 0)); assert.equal(c.after, 0);
});
test('tick cả 3 rồi nhập 10tr = chia cũ trước (như ví dụ 2.3)', () => {
  const { c } = calcOf(['DH-001', 'DH-002', 'DH-003'], 10e6);
  assert.deepEqual(c.alloc.map((a) => [a.id, a.allocatedMinor, a.outstandingAfterMinor]), [['DH-001', 4e6, 0], ['DH-002', 6e6, 2e6]]);
});
test('AC-07: tick DH-002, thu 8tr → hết nợ DH-002, khách còn 10tr', () => {
  const { c } = calcOf(['DH-002'], 8e6);
  assert.deepEqual(c.alloc, [{ id: 'DH-002', allocatedMinor: 8e6, outstandingAfterMinor: 0 }]);
  assert.equal(c.after, 10e6); assert.equal(c.canSubmit, true);
});
test('AC-08: tick DH-001 + DH-003, thu 5tr → DH-001 hết, DH-003 còn 5tr, DH-002 không đổi', () => {
  const { c } = calcOf(['DH-003', 'DH-001'], 5e6);
  assert.deepEqual(c.alloc.map((a) => [a.id, a.allocatedMinor, a.outstandingAfterMinor]), [['DH-001', 4e6, 0], ['DH-003', 1e6, 5e6]]);
});
test('AC-09: chưa tick đơn nào, hoặc vượt Σ đơn tick → không gửi được', () => {
  assert.equal(calcOf([], 1e6).c.canSubmit, false);
  assert.equal(calcOf(['DH-002'], 8000001).c.over, true);
});
