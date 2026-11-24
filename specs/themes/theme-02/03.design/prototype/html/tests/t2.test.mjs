// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, SCREENS, GROUPS } from '../app/cases.js';
import { chipLabel, emptyCopy, localStockFilter, stockText, cfDisplay, filterLabel } from '../app/list.js';
import { dartDouble, pricePercentLabel, stepTitles, hasAnyData, matchUnits, createState } from '../app/create.js';
import { money } from '../app/data.js';

test('formatCatalogCurrency', () => {
  assert.equal(money(125000), '125.000 đ');
  assert.equal(money(1250000), '1.250.000 đ');
  assert.equal(money(104000.00000000001), '104.000 đ');
});

test('ProductCatalogFilterChips: nhãn có / không số', () => {
  assert.equal(chipLabel('all', { all: 48 }), 'Tất cả (48)');
  assert.equal(chipLabel('inStock', { all: 48 }), 'Còn hàng');
  assert.equal(chipLabel('deleted', { deleted: 0 }), 'Đã xóa (0)');
});

test('_ProductCatalogEmptyState: câu theo chip, không xét từ khoá', () => {
  assert.deepEqual(emptyCopy('deleted', true), ['Không có sản phẩm đã xóa.', null, false]);
  assert.deepEqual(emptyCopy('all', false), ['Chưa có sản phẩm nào được tạo', null, true]);
  assert.equal(emptyCopy('incomplete', true)[0], 'Không có sản phẩm "Thiếu dữ liệu"');
  assert.equal(emptyCopy('all', true)[0], 'Không tìm thấy sản phẩm');
  // chip "Đã xóa" thắng cả khi chưa có sản phẩm nào
  assert.equal(emptyCopy('deleted', false)[0], 'Không có sản phẩm đã xóa.');
  assert.equal(filterLabel('inactive'), 'Ngừng KD');
});

test('Lọc tồn cục bộ + ô tồn', () => {
  const items = [{ stock: 3 }, { stock: 0 }, { stock: null }];
  assert.equal(localStockFilter(items, 'inStock').length, 1);
  assert.equal(localStockFilter(items, 'outOfStock').length, 1);
  assert.equal(localStockFilter(items, 'all').length, 3);
  assert.deepEqual(stockText({ stock: null }), { text: 'Chưa TL tồn', kind: 'muted' });
  assert.equal(stockText({ stock: 5 }), null); // không có stockLabel → không vẽ gì
  assert.deepEqual(stockText({ stock: 24, stockLabel: '24' }), { text: '24', kind: 'normal' });
  assert.deepEqual(stockText({ stock: 0, stockLabel: '0 hộp' }), { text: 'Hết', kind: 'out' });
  assert.equal(cfDisplay('1500'), '1.500');
  assert.equal(cfDisplay('Viên nén'), 'Viên nén');
});

test('Dart double.toString trong nhãn gợi ý giá', () => {
  assert.equal(dartDouble(35), '35.0');
  assert.equal(dartDouble(12.5), '12.5');
  assert.equal(pricePercentLabel('Giá niêm yết gợi ý', 0.28 * 100), 'Giá niêm yết gợi ý (+28.000000000000004%)');
});

test('Bước tạo: số thứ tự, hasAnyData, gợi ý đơn vị', () => {
  assert.deepEqual(stepTitles([]).slice(-1), ['6. Ghi chú']);
  assert.deepEqual(stepTitles([{ name: 'Thông tin dược' }]).slice(5), ['6. Thông tin dược', '7. Ghi chú']);
  assert.equal(hasAnyData(createState('new')), false);
  assert.equal(hasAnyData({ ...createState('new'), lot: true }), false);
  assert.equal(hasAnyData(createState('name-error')), true);
  assert.deepEqual(matchUnits(['hộp', 'hũ', 'chai', 'lọ'], 'h'), ['hộp', 'hũ', 'chai']);
  assert.deepEqual(matchUnits(['hộp', 'lọ'], 'hop'), ['hộp']);
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
      }
    }
  }
});

import { evaluate, statusBadge, priceBandSubtitle, profileStockText, valueLine, ctaLabel } from '../app/pcc.js';

test('ProductReadinessEvaluator + nhãn PCC', () => {
  const full = { unit: 'hộp', images: 3, basePrice: 1, band: {}, cfMissing: false };
  assert.deepEqual(evaluate(full), { ready: true, blockers: [] });
  const noImg = evaluate({ ...full, images: 0 });
  assert.equal(noImg.ready, true);
  assert.deepEqual(noImg.blockers, ['missing_image']); // vẫn đếm vào "Cần bổ sung (1)"
  assert.deepEqual(evaluate({ images: 0, basePrice: null }).blockers, ['missing_base_unit', 'missing_image', 'missing_price', 'missing_price_band']);
  assert.deepEqual(statusBadge({ deleted: false, ready: false }), ['Thiếu dữ liệu', 'danger']);
  assert.deepEqual(statusBadge({ deleted: true, ready: true }), ['Đã xóa', 'neutral']);
});

test('Chữ phụ thẻ PCC + lịch sử', () => {
  assert.equal(priceBandSubtitle({ list: 125000, floor: 110000, rule: 'Khung giá mặc định' }, 'hộp'), 'Niêm yết: 125.000 đ · Sàn: 110.000 đ · Đơn vị: hộp · Khung giá mặc định');
  assert.equal(priceBandSubtitle({ list: 18000, floor: 15000, custom: true, rule: 'X' }, 'lon'), 'Niêm yết: 18.000 đ · Sàn: 15.000 đ · Đơn vị: lon · Giá riêng');
  assert.equal(priceBandSubtitle(null, 'Hộp'), 'Thiếu khung giá bán');
  assert.equal(profileStockText(0, null), 'Tồn (cơ sở): 0 (Hết hàng)');
  assert.equal(profileStockText(24, 'hộp'), 'Tồn (hộp): 24');
  assert.equal(valueLine({ before: 'active', after: 'inactive' }), 'active — inactive');
  assert.equal(valueLine({ masked: true, before: 'a', after: 'b' }), '*** — ***');
  assert.equal(valueLine({}), '');
  assert.equal(ctaLabel('missing_price_band'), 'Thiết lập giá');
});

import { ratioText, unitsSaveEnabled, formatRate } from '../app/sub.js';

test('Màn con: tỉ lệ khung cửa hàng, nút lưu màn đơn vị', () => {
  assert.equal(ratioText(102400, 80000), '28%');
  assert.equal(ratioText(null, 80000), '—');
  assert.equal(ratioText(1, 0), '—');
  assert.equal(unitsSaveEnabled({ persisted: false, editingBase: false }), false);
  assert.equal(unitsSaveEnabled({ persisted: false, editingBase: true, input: 'Hộp', base: '' }), true);
  assert.equal(unitsSaveEnabled({ persisted: false, editingBase: true, input: 'HỘP', base: 'hộp' }), false);
  assert.equal(formatRate(20), '20');
  assert.equal(formatRate(2.5), '2.5');
});

import { ruleValues, deltaText, fieldMeta } from '../app/settings.js';

test('Cài đặt: tỉ lệ khung giá cửa hàng, dòng phụ trường', () => {
  assert.deepEqual(ruleValues({ list: 0.28, floor: 0.14 }), ['+28.0%', '14.0%']);
  assert.deepEqual(ruleValues(null), ['—', '—']);
  assert.equal(deltaText(0.25, 0.28, '+'), '(+25.0% → +28.0%)');
  assert.equal(deltaText(null, 0.2), null);
  assert.equal(fieldMeta({ type: 'singleSelect', required: true, search: true, filter: true, list: true }), 'Single select • Bắt buộc • Tìm kiếm • Lọc • Hiển thị');
  assert.equal(fieldMeta({ type: 'text' }), 'Text');
});
