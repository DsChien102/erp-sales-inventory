// Hàm thuần của khung: đối chiếu với Dart (ErpTab.fromLocation, kSideNavSubEntries, selectedMoreEntry, MoreEntry.isInteractive, router).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { tabFromLocation, SIDE_SUB_ENTRIES, visibleSubEntries, selectedMoreEntry, isInteractive, insideShell, renderShell } from '../shared/shell.js';
import { filterOrgs, ORGS } from '../app/org.js';
import { CASES } from '../app/cases.js';
import { render } from '../app/main.js';

test('tabFromLocation như ErpTab.fromLocation', () => {
  assert.equal(tabFromLocation('/'), 'home');
  assert.equal(tabFromLocation('/orders'), 'orders');
  assert.equal(tabFromLocation('/sales/drafts'), 'orders');
  assert.equal(tabFromLocation('/products/items/p1'), 'products');
  assert.equal(tabFromLocation('/partner/x'), 'partners');
  for (const p of ['/more', '/more/settings', '/inventory/x', '/warehouse', '/pricing/r1']) assert.equal(tabFromLocation(p), 'more');
  assert.equal(tabFromLocation('/ask'), 'home');
});

test('thanh bên có 6 mục con, đúng thứ tự', () => {
  assert.deepEqual(SIDE_SUB_ENTRIES.map((e) => e.id), ['receivables', 'inventory', 'pricing', 'users_and_roles', 'my_account', 'settings']);
});

test('người không phải chủ không thấy Người dùng & vai trò, trừ khi bị chặn', () => {
  assert.equal(visibleSubEntries({ isOwner: false }).some((e) => e.id === 'users_and_roles'), false);
  assert.equal(visibleSubEntries({ isOwner: false, isBlocked: true }).some((e) => e.id === 'users_and_roles'), true);
});

test('bị chặn: chỉ Tài khoản của tôi còn bấm được', () => {
  const on = SIDE_SUB_ENTRIES.filter((e) => isInteractive(e, { isBlocked: true })).map((e) => e.id);
  assert.deepEqual(on, ['my_account']);
});

test('selectedMoreEntry khớp tiền tố', () => {
  assert.equal(selectedMoreEntry('/more'), null);
  assert.equal(selectedMoreEntry('/warehouse/area/a1').id, 'inventory');
  assert.equal(selectedMoreEntry('/more/roles/x').id, 'users_and_roles');
  assert.equal(selectedMoreEntry('/more/einvoice').id, 'settings');
  assert.equal(selectedMoreEntry('/more/receivablesX'), null);
});

test('insideShell theo app_router.dart', () => {
  for (const p of ['/', '/orders', '/products/items', '/products/items/p1', '/partner', '/partner/p1', '/more', '/warehouse', '/warehouse/area/a1']) assert.equal(insideShell(p), true, p);
  for (const p of ['/more/receivables', '/pricing', '/more/settings', '/more/users-and-roles', '/more/my-account', '/partner/new', '/products/items/new', '/products/items/p1/view', '/sales/x']) assert.equal(insideShell(p), false, p);
});

test('renderShell: ≥ 1024 thanh bên, < 1024 thanh dưới, ngoài khung không có gì', () => {
  assert.match(renderShell({ device: 'web', location: '/' }), /class="sh-side"/);
  assert.doesNotMatch(renderShell({ device: 'web', location: '/' }), /class="sh-bottom"/);
  assert.match(renderShell({ device: 'web', width: 1023, location: '/' }), /class="sh-bottom"/);
  assert.match(renderShell({ device: 'iphone', location: '/' }), /padding-bottom:34px/);
  assert.match(renderShell({ device: 'web', width: 900, location: '/' }), /padding-bottom:12px/);
  const bare = renderShell({ device: 'web', location: '/pricing' });
  assert.doesNotMatch(bare, /sh-side|sh-bottom/);
  assert.doesNotMatch(renderShell({ device: 'web', location: '/', gate: 'error' }), /sh-side/);
});

test('lọc tổ chức theo tên hoặc mã, không phân biệt hoa thường', () => {
  assert.equal(filterOrgs(ORGS, 'minh').length, 1);
  assert.equal(filterOrgs(ORGS, 'hungphat').length, 1);
  assert.equal(filterOrgs(ORGS, 'xyz').length, 0);
  assert.equal(filterOrgs(ORGS, '  ').length, ORGS.length);
});

test('mọi ca vẽ được ở cả hai khổ', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) for (const d of ['iphone', 'web']) {
    const html = render(screen, state, d);
    assert.match(html, /class="sh-app"/, `${screen}/${state}/${d}`);
  }
});
