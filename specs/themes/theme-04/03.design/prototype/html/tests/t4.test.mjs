// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, SCREENS, GROUPS } from '../app/cases.js';
import { activeCount, bodyBranch, effectiveText, sortLabel } from '../app/list.js';
import { diffWithPercent, isBelowFloor, isLongValue, isValid, showSummary, unitSubtitle } from '../app/form.js';
import { dong, money, ACTIVITIES } from '../app/data.js';
import { activitySummary, detailDiff } from '../app/detail.js';
import { actorOptions, calendarDate, diffMoney, filterActivities, withinDays } from '../app/history.js';

test('MoneyFormatter.formatMinor: "95.000đ", không dấu cách', () => {
  assert.equal(money(95000), '95.000đ');
  assert.equal(money(1250000), '1.250.000đ');
  assert.equal(money(-990000), '-990.000đ');
  assert.equal(money(0), '0đ');
  assert.equal(dong(115741), '115.741đ');
});

test('_formatDiffWithPercent: chênh âm mất dấu trừ ở phần tiền', () => {
  assert.equal(diffWithPercent(105000 - 115741, 115741), '10.741đ (-9,3%)');
  assert.equal(diffWithPercent(105000 - 90741, 90741), '+14.259đ (+15,7%)');
  assert.equal(diffWithPercent(0, 100), '0đ (0,0%)');
  assert.equal(diffWithPercent(5000, 0), '+5.000đ');
  assert.equal(isLongValue('+1.140.000đ (+9.500,0%)'), true);
});

test('Điều kiện form: bảng so sánh, dưới sàn, hợp lệ', () => {
  assert.equal(showSummary({ price: 1, list: null, floor: 5, floorHidden: true }), false);
  assert.equal(showSummary({ price: 1, list: 2, floor: null, floorHidden: true }), true);
  assert.equal(showSummary({ price: 0, list: 2 }), false);
  assert.equal(isBelowFloor({ price: 8, floor: 9, floorHidden: false }), true);
  assert.equal(isBelowFloor({ price: 8, floor: 9, floorHidden: true }), false);
  assert.equal(isValid({ customer: 'a', product: 'b', unit: 'c', price: 1, from: '' }), false);
  assert.equal(isValid({ customer: 'a', product: 'b', unit: 'c', price: 1, from: '01/01/2026' }), true);
});

test('Danh sách: nhánh thân, số bộ lọc, nhãn', () => {
  assert.equal(bodyBranch({ kind: 'error', items: 0 }), 'page-error');
  assert.equal(bodyBranch({ kind: 'error', items: 3 }), 'list');
  assert.equal(bodyBranch({ kind: 'loaded', items: 0 }), 'empty');
  assert.equal(bodyBranch({ kind: 'no-permission', items: 0 }), 'no-permission');
  assert.equal(activeCount({ status: 'disabled', warning: null, source: 'manual', updatedWithin: null }), 2);
  assert.equal(effectiveText('01/07/2026', null), '01/07/2026 – Không giới hạn');
  assert.equal(sortLabel('warningsFirst'), 'Cảnh báo cần xử lý trước');
});

test('Chọn đơn vị: dòng giá', () => {
  assert.equal(unitSubtitle({ list: null, floor: null, floorHidden: false }), '');
  assert.match(unitSubtitle({ list: null, floor: 4000, floorHidden: false }), /--.*Giá sàn/);
  assert.doesNotMatch(unitSubtitle({ list: 100, floor: 50, floorHidden: true }), /Giá sàn/);
});

test('Chi tiết: chênh lệch, tóm tắt hoạt động', () => {
  assert.equal(detailDiff(-20000, 125000), '20.000đ (-16,0%)');
  assert.equal(detailDiff(5000, 100000), '+5.000đ (+5,0%)');
  assert.equal(detailDiff(5000, null), '+5.000đ');
  assert.equal(activitySummary(ACTIVITIES[0]), 'Giá đổi từ 110.000đ → 105.000đ');
  assert.equal(activitySummary(ACTIVITIES[2]), 'Lý do: Khách tạm ngưng nhập hàng');
  assert.equal(activitySummary(ACTIVITIES[1]), 'Giá áp dụng: 110.000đ');
});

test('Lịch sử: lọc cục bộ, ngày, người thực hiện', () => {
  assert.equal(filterActivities(ACTIVITIES, { quick: 'priceEdit' }).length, 3);
  assert.equal(filterActivities(ACTIVITIES, { q: 'đức' }).length, 2);
  assert.equal(filterActivities(ACTIVITIES, { q: 'giá sàn' }).length, 0);
  assert.equal(filterActivities(ACTIVITIES, { newestFirst: false })[0].type, 'created');
  assert.equal(filterActivities(ACTIVITIES, { type: 'Sửa giá', time: '90 ngày gần đây' }).length, 1);
  assert.equal(withinDays('05/10/2026 10:21', 30), false);
  assert.deepEqual(actorOptions(ACTIVITIES), ['Nguyễn Thị Lan', 'Trần Minh Đức', 'Tất cả']);
  assert.equal(calendarDate(null), 'Không giới hạn');
  assert.equal(calendarDate('2026-07-01'), '01/07/2026');
  assert.equal(diffMoney(null), '-');
  assert.equal(diffMoney(-7000), '-7.000đ');
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
      }
    }
  }
});
