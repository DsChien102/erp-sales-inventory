// Hàm thuần đối chiếu Dart + mọi ca vẽ được. Chạy: node --test (từ thư mục html/).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { render } from '../app/main.js';
import { CASES, SCREENS, GROUPS } from '../app/cases.js';
import { CUSTOMERS, LINES, customerSubtitle, draftTimestamp, money, moneyComma, phoneLabel, totals } from '../app/data.js';
import { creatorLabel, draftSummary, phoneLine } from '../app/drafts.js';
import { stockWarning, unitPriceLabel } from '../app/compose.js';
import { previewApplied, unitSubtitle } from '../app/sheets.js';
import { checkoutVm, digitsDot, mixedDefault, percentIndex } from '../app/checkout.js';
import { methodText } from '../app/result.js';

test('MoneyFormatter: "125.000đ"; VMoneyValidator: "125,000"', () => {
  assert.equal(money(125000), '125.000đ');
  assert.equal(money(0), '0đ');
  assert.equal(money(-12000), '-12.000đ');
  assert.equal(moneyComma(16000), '16,000');
  assert.equal(moneyComma(1250000), '1,250,000');
});

test('Thẻ nháp: mốc giờ, SĐT, người tạo', () => {
  assert.equal(draftTimestamp({ day: '2026-11-22', time: '10:24' }), '10:24');
  assert.equal(draftTimestamp({ day: '2026-11-21', time: '17:40' }), 'Hôm qua');
  assert.equal(draftTimestamp({ day: '2026-11-18', time: '15:12' }), '18/11');
  assert.equal(phoneLabel(null), 'Không có số điện thoại');
  assert.equal(creatorLabel('0909123456'), null);
  assert.equal(creatorLabel('7c9e6679-7425-40de-944b-e07fc1f90ae7'), null);
  assert.equal(creatorLabel(' Lê Quốc Bảo '), 'Lê Quốc Bảo');
  const d = { phone: '0905112233', creator: 'Lê Quốc Bảo' };
  assert.equal(phoneLine(d, false), '0905112233');
  assert.equal(phoneLine(d, true), '0905112233 · Tạo bởi: Lê Quốc Bảo');
  assert.equal(draftSummary({ lines: 3, total: 437000 }), '3 mặt hàng · 437.000đ');
});

test('Dòng hàng: cảnh báo tồn, nhãn giá, tổng', () => {
  assert.equal(stockWarning(null, 'Hộp'), null);
  assert.equal(stockWarning(3, 'Hộp'), null);
  assert.deepEqual(stockWarning(2, 'Chai'), { text: 'Chỉ còn 2 Chai', tone: 'warning' });
  assert.deepEqual(stockWarning(1, 'Chai'), { text: 'Chỉ còn 1 Chai', tone: 'danger' });
  assert.deepEqual(stockWarning(0, 'Chai'), { text: 'Hết hàng', tone: 'danger' });
  assert.equal(unitPriceLabel(LINES[1]), '16.000đ/Lon');
  assert.deepEqual(totals(LINES), { count: 3, merchandise: 453000, discount: 12000, net: 441000 });
});

test('SG-03 / SG-04 / SG-05: dòng phụ, giá xem trước', () => {
  assert.equal(unitSubtitle({ price: 18000, stock: 120 }), '18.000đ · Tồn 120');
  assert.equal(unitSubtitle({ price: 18000, stock: null }), '18.000đ');
  assert.equal(customerSubtitle(CUSTOMERS[0]), '0283 822 4567 · Khách hàng · MST 0312345678');
  assert.equal(customerSubtitle(CUSTOMERS[4]), '—');
  assert.equal(customerSubtitle(CUSTOMERS[5]), '0933445566 · Khách hàng · Không hoạt động');
  assert.equal(previewApplied('unit', 15000, 18000), 15000);
  assert.equal(previewApplied('amount', 3000, 18000), 15000);
  assert.equal(previewApplied('amount', 30000, 18000), 0);
  assert.equal(previewApplied('percent', 10, 18000), 16200);
  assert.equal(previewApplied('percent', 120, 18000), null);
  assert.equal(previewApplied('unit', null, 18000), null);
});

test('SG-06: tiền thừa, công nợ, điều kiện hoàn tất, kết hợp, %', () => {
  assert.equal(digitsDot(441000), '441.000');
  const full = checkoutVm({ total: 441000, cash: 441000 });
  assert.deepEqual([full.change, full.receivable, full.canFinalize], [0, 0, true]);
  const debt = checkoutVm({ total: 441000, cash: 220500 });
  assert.deepEqual([debt.receivable, debt.canFinalize], [220500, false]);
  assert.equal(checkoutVm({ total: 441000, cash: 220500, due: '30/11/2026' }).canFinalize, true);
  assert.equal(checkoutVm({ total: 441000, cash: 500000 }).change, 59000);
  assert.equal(checkoutVm({ total: 441000, cash: 500000, walkIn: true }).canFinalize, false);
  assert.equal(checkoutVm({ total: 441000, cash: 441000, walkIn: true }).canEditCash, false);
  assert.equal(checkoutVm({ total: 441000, bank: 441000, walkIn: true, mode: 'mixed' }).canEditBank, true);
  assert.deepEqual(mixedDefault(4850000), { cash: 2000000, bank: 2850000 });
  assert.deepEqual(mixedDefault(441000), { cash: 441000, bank: 0 });
  assert.deepEqual([percentIndex(100), percentIndex(75), percentIndex(50), percentIndex(24)], [2, 2, 1, 0]);
});

test('SG-07: phương thức trên dòng meta', () => {
  assert.equal(methodText({ cash: 1, bank: 1 }), 'Tiền mặt + chuyển khoản');
  assert.equal(methodText({ bank: 1 }), 'Chuyển khoản');
  assert.equal(methodText({ cash: 1 }), 'Tiền mặt');
  assert.equal(methodText({}), 'Chưa thanh toán');
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

test('Route /sales/* nằm ngoài khung (không thanh bên / thanh dưới)', () => {
  assert.match(render('drafts', 'loaded', 'web'), /data-layout="bare"/);
  assert.match(render('compose', 'filled', 'iphone'), /data-layout="bare"/);
});

test('Mọi class t5-* dùng trong ca đều có rule trong styles/t5.css', async () => {
  const fs = await import('node:fs');
  const css = fs.readFileSync(new URL('../styles/t5.css', import.meta.url), 'utf8');
  const used = new Set();
  for (const [screen, states] of Object.entries(CASES)) {
    for (const state of states) {
      for (const device of ['iphone', 'web']) {
        for (const m of render(screen, state, device).matchAll(/class="([^"]*)"/g)) {
          for (const c of m[1].split(/\s+/)) if (c.startsWith('t5-')) used.add(c);
        }
      }
    }
  }
  const missing = [...used].filter((c) => !new RegExp(`\\.${c.replace(/[-]/g, '\\-')}(?![\\w-])`).test(css)).sort();
  assert.deepEqual(missing, []);
});

// ---------------------------------------------------------------- đợt 3
import { orderMetaLine } from '../app/data.js';
import { activeFilterCount, listCustomerLabel, noResultDescription } from '../app/orders.js';
import { cancelImpact, cancelSubtitle, diffText, productIcon, DETAIL_ORDERS } from '../app/detail.js';
import { SETTLEMENT_LABEL, displayActorName, paidMethodRows, transactionLabel } from '../app/subpages.js';

test('SG-08: dòng phụ thẻ đơn, khách lẻ, đếm bộ lọc, câu không kết quả', () => {
  assert.equal(orderMetaLine('0912345678'), '0912345678 · Mosaic Retail Demo');
  assert.equal(orderMetaLine(null), 'Mosaic Retail Demo');
  assert.equal(orderMetaLine(null, ''), null);
  assert.equal(listCustomerLabel({ customer: null }), 'Khách Lẻ');
  assert.equal(activeFilterCount({}), 0);
  assert.equal(activeFilterCount({ preset: 1 }), 1);
  assert.equal(activeFilterCount({ time: 1, lifecycle: 1 }), 2);
  assert.equal(noResultDescription(' xyz '), 'Không có đơn phù hợp với “xyz”\ntrong phạm vi hiện tại.');
  assert.equal(noResultDescription(''), 'Không có đơn phù hợp trong phạm vi hiện tại.');
});

test('SG-09 / SG-10: icon dòng hàng, chênh lệch phiếu, tác động huỷ', () => {
  assert.equal(productIcon('Hộp'), 'box');
  assert.equal(productIcon('Chai'), 'tag');
  assert.equal(productIcon('Lon'), 'tag'); // "lon" chứa "lo"
  assert.equal(diffText(23000), 'Khách trả thêm 23.000đ');
  assert.equal(diffText(-95000), 'Hoàn lại 95.000đ');
  assert.equal(diffText(0), 'Không chênh lệch');
  assert.deepEqual(cancelImpact(DETAIL_ORDERS.o2), { stock: 'Hoàn lại 9 mặt hàng', debt: 'Giảm 441.000đ' });
  assert.equal(cancelSubtitle({ by: ' ', at: '21/11/2026 15:40' }), '21/11/2026 15:40');
});

test('SG-09b / SG-09c: dòng đã thanh toán, nhãn giao dịch, người thực hiện', () => {
  assert.equal(SETTLEMENT_LABEL.partiallyPaid, 'Còn phải thu');
  assert.deepEqual(paidMethodRows({ cash: 0, bank: 0, paid: 0 }), [['Đã thanh toán', 0, 'primary']]);
  assert.deepEqual(paidMethodRows({ cash: 1, bank: 2 }).map((r) => r[0]), ['Đã thanh toán (TM)', 'Đã thanh toán (CK)']);
  assert.equal(transactionLabel({ kind: 'collection', method: 'cash' }), 'Thu tiền · Tiền mặt');
  assert.equal(transactionLabel({ kind: 'refund', method: 'bank' }), 'Hoàn tiền · Chuyển khoản');
  assert.equal(transactionLabel({ kind: 'collection', method: 'offset', counterpart: 'DH-000118' }), 'Cấn trừ · từ DH-000118');
  assert.equal(transactionLabel({ kind: 'refund', method: 'offset', counterpart: 'DH-000118' }), 'Cấn trừ · sang DH-000118');
  assert.equal(displayActorName('Không rõ', 'Phạm Thu Hà'), 'Phạm Thu Hà');
  assert.equal(displayActorName('7c9e6679-7425-40de-944b-e07fc1f90ae7'), 'Nhân viên');
  assert.equal(displayActorName(' Lê Quốc Bảo '), 'Lê Quốc Bảo');
});

test('SG-08 /orders nằm TRONG khung; SG-09 và màn con ngoài khung', () => {
  assert.match(render('orders', 'loaded', 'web'), /data-layout="desktop"/);
  assert.match(render('orders', 'loaded', 'iphone'), /data-layout="mobile"/);
  assert.match(render('detail', 'paid', 'web'), /data-layout="bare"/);
  assert.match(render('payment-debt', 'paid', 'iphone'), /data-layout="bare"/);
  // Sheet lọc nằm trong vùng nội dung (t5-area), không phải overlay phủ thanh bên.
  const web = render('orders-filter', 'default', 'web');
  assert.ok(web.indexOf('sh-scrim') > web.indexOf('t5-area') && web.indexOf('sh-scrim') < web.lastIndexOf('</main>'));
});
