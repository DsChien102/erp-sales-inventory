// Hàm thuần của Trang chủ đối chiếu Dart (HomeHeader._greetingForHour, điều kiện banner ở HomeTabPage + LegalProfileHomeBanner) + mọi ca vẽ được.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { greetingForHour, showLegalBanner, render } from '../app/main.js';
import { CASES } from '../app/cases.js';

test('lời chào theo giờ như HomeHeader._greetingForHour', () => {
  for (const h of [0, 4, 18, 23]) assert.equal(greetingForHour(h), 'Chào buổi tối', String(h));
  for (const h of [5, 11]) assert.equal(greetingForHour(h), 'Chào buổi sáng', String(h));
  for (const h of [12, 17]) assert.equal(greetingForHour(h), 'Chào buổi chiều', String(h));
});

test('banner hồ sơ pháp lý: chỉ chủ, chưa ẩn, chưa có hồ sơ', () => {
  assert.equal(showLegalBanner({ isOwner: true, bannerDismissed: false, hasLegalProfile: false }), true);
  assert.equal(showLegalBanner({ isOwner: false, bannerDismissed: false, hasLegalProfile: false }), false);
  assert.equal(showLegalBanner({ isOwner: true, bannerDismissed: true, hasLegalProfile: false }), false);
  assert.equal(showLegalBanner({ isOwner: true, bannerDismissed: false, hasLegalProfile: true }), false);
});

test('banner theo ca: owner (đã có hồ sơ) và staff không có', () => {
  for (const state of CASES.home) for (const d of ['iphone', 'web']) {
    assert.equal(/class="hm-banner"/.test(render('home', state, d)), !['owner', 'staff'].includes(state), `${state}/${d}`);
  }
});

test('mọi ca vẽ được ở cả hai khổ, trong khung', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) {
    assert.match(render(screen, state, 'iphone'), /class="sh-bottom"/, `${state}/iphone`);
    assert.match(render(screen, state, 'web'), /class="sh-side"/, `${state}/web`);
    assert.match(render(screen, state, 'web'), /class="hm-page"/, `${state}/web`);
  }
});
