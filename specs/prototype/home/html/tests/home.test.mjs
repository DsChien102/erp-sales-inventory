// Trang chủ "Bảng giá chợ": lời chào theo giờ (HomeHeader._greetingForHour) + mọi ca vẽ được + nội dung đã chốt.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { greetingForHour, render } from '../app/main.js';
import { CASES } from '../app/cases.js';

test('lời chào theo giờ như HomeHeader._greetingForHour', () => {
  for (const h of [0, 4, 18, 23]) assert.equal(greetingForHour(h), 'Chào buổi tối', String(h));
  for (const h of [5, 11]) assert.equal(greetingForHour(h), 'Chào buổi sáng', String(h));
  for (const h of [12, 17]) assert.equal(greetingForHour(h), 'Chào buổi chiều', String(h));
});

test('mọi ca vẽ được ở cả hai khổ, trong khung', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) {
    assert.match(render(screen, state, 'iphone'), /class="sh-bottom"/, `${state}/iphone`);
    assert.match(render(screen, state, 'web'), /class="sh-side"/, `${state}/web`);
    for (const d of ['iphone', 'web']) assert.match(render(screen, state, d), /class="hm-page bz/, `${state}/${d}`);
  }
});

test('nội dung đã chốt: doanh thu, 7 ngày, ba hộp; không banner, không nút thao tác', () => {
  for (const d of ['iphone', 'web']) {
    const html = render('home', 'owner', d);
    for (const label of ['Doanh thu', 'Đơn hôm nay', 'Chưa xuất hoá đơn', 'Tiền đã thu hôm nay', 'Công nợ phải thu']) assert.ok(html.includes(label), `${d}: ${label}`);
    assert.match(html, /class="bz-week"/, `${d}: biểu đồ 7 ngày`);
    assert.doesNotMatch(html, /Bổ sung hồ sơ pháp lý|Tạo đơn|Nhập hàng/, `${d}: không banner / nút thao tác`);
  }
});

test('Hỏi Mosaic Retail: nút nổi thay nút đầu trang; khung chat chỉ mở ở ca ask-open', () => {
  for (const d of ['iphone', 'web']) {
    const html = render('home', 'owner', d);
    assert.doesNotMatch(html, /class="bz-ask"/, `${d}: không còn nút ở đầu trang`);
    assert.match(html, /class="bz-fab"[^>]*aria-expanded="false"/, `${d}: nút nổi đóng`);
    assert.doesNotMatch(html, /is-asking/, `${d}: khung chat đóng`);
    const open = render('home', 'ask-open', d);
    assert.match(open, /class="hm-page bz[^"]*is-asking/, `${d}: khung chat mở`);
    for (const t of ['Chào bạn! Mình giúp bạn xem nhanh số liệu cửa hàng. Thử hỏi:', 'Hôm nay bán được bao nhiêu?', 'Hỏi về doanh thu, tồn kho, công nợ…']) assert.ok(open.includes(t), `${d}: ${t}`);
  }
});
