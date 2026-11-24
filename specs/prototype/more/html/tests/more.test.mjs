// Hàm thuần đối chiếu Dart (MoreEntry.isVisible / isInteractive, _MoreView, _UsersAndRolesView) + mọi ca vẽ được.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { moreItems, hubItems, columnMax, render } from '../app/main.js';
import { CASES } from '../app/cases.js';

const ids = (xs) => xs.map((x) => x.id);
const on = (xs) => xs.filter((x) => x.isEnabled).map((x) => x.id);

test('Thêm — chủ: 10 mục, 3 mục tắt, Đăng xuất bấm được', () => {
  const xs = moreItems({ isOwner: true, isBlocked: false });
  assert.equal(xs.length, 10);
  assert.deepEqual(xs.filter((x) => !x.isEnabled).map((x) => x.id), ['customers', 'purchase_orders', 'reports']);
  assert.ok(on(xs).includes('logout'));
});

test('Thêm — không phải chủ: ẩn Người dùng & vai trò', () => {
  const xs = moreItems({ isOwner: false, isBlocked: false });
  assert.equal(xs.length, 9);
  assert.ok(!ids(xs).includes('users_and_roles'));
});

test('Thêm — tổ chức bị chặn: mục chỉ chủ vẫn hiện, mục cần tổ chức hoạt động tắt', () => {
  const xs = moreItems({ isOwner: false, isBlocked: true });
  assert.equal(xs.length, 10);
  assert.deepEqual(on(xs), ['my_account', 'logout']);
});

test('Người dùng & vai trò theo quyền', () => {
  assert.deepEqual(ids(hubItems(['tenant.view', 'tenant.member.view', 'tenant.audit.view'])), ['org', 'users', 'roles', 'audit']);
  assert.deepEqual(ids(hubItems(['tenant.member.view'])), ['users', 'roles']);
  assert.deepEqual(ids(hubItems([])), []);
});

test('VPageScaffold: cột 720 / 640 / tràn', () => {
  assert.equal(columnMax(1280), '720px');
  assert.equal(columnMax(800), '640px');
  assert.equal(columnMax(390), '100%');
});

test('mọi ca vẽ được; Thêm trong khung, Thiết lập / Người dùng & vai trò ngoài khung', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) for (const d of ['iphone', 'web']) {
    const html = render(screen, state, d);
    assert.match(html, /class="mr-page/, `${screen}/${state}/${d}`);
    const inside = screen === 'more';
    assert.equal(/class="sh-(bottom|side)"/.test(html), inside, `${screen}/${state}/${d} khung`);
  }
});

