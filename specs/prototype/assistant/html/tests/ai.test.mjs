// Hàm thuần đối chiếu Dart (assistant_cell_format.dart, assistant_open_target.dart, màu bong bóng, AssistantFooter, cubit) + mọi ca vẽ được.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { drawable, formatCell, isLocked, isNumeric, openLocation, remainingOf, replyTone, showRemaining, tableWidth } from '../app/ask.js';
import { CASES } from '../app/cases.js';
import { render } from '../app/main.js';

test('formatCell như formatAssistantCell', () => {
  assert.equal(formatCell('chu', null), '—');
  assert.equal(formatCell('tien', null), '—');
  assert.equal(formatCell('chu', 'Sữa'), 'Sữa');
  assert.equal(formatCell('tien', 1245000), '1.245.000đ');
  assert.equal(formatCell('tien', -990000), '-990.000đ');
  assert.equal(formatCell('tien', 999.5), '1.000đ');
  assert.equal(formatCell('tien', -2.5), '-3đ'); // int.round() của Dart: nửa ra xa số 0
  assert.equal(formatCell('tien', 'abc'), 'abc');
  assert.equal(formatCell('so', 12), '12');
  assert.equal(formatCell('so', 36.5), '36,5');
  assert.equal(formatCell('so', 6.44), '6,4');
  assert.equal(formatCell('so', 1234567.25), '1.234.567,3');
  assert.equal(formatCell('so', -1.5), '-1,5');
  assert.equal(formatCell('so', -0.5), '-0,5');
  assert.equal(formatCell('so', 0), '0');
  assert.equal(formatCell('phan_tram', 12.34), '12,3%');
  assert.equal(formatCell('ngay', '2026-11-22T09:12:00+07:00'), '22/11/2026');
  assert.equal(formatCell('ngay', '22/11'), '22/11');
  assert.equal(formatCell('ngay', 5), '5');
});

test('cột số canh phải: tien / so / phan_tram', () => {
  assert.deepEqual(['chu', 'tien', 'so', 'ngay', 'phan_tram'].map(isNumeric), [false, true, true, false, true]);
});

test('openLocation như assistantOpenLocation', () => {
  assert.equal(openLocation({ loai: 'san_pham', id: 'p 1' }), '/products/items/p%201/view');
  assert.equal(openLocation({ loai: 'khach_hang', id: 'c1' }), '/partner/c1');
  assert.equal(openLocation({ loai: 'don_ban', id: ' o1 ' }), '/sales/orders/o1');
  assert.equal(openLocation({ loai: 'don_ban', id: '  ' }), null);
  assert.equal(openLocation({ loai: 'kho', id: 'k1' }), null);
  assert.equal(openLocation(null), null);
});

test('màu bong bóng theo trạng thái', () => {
  assert.equal(replyTone('ok'), 'plain');
  assert.equal(replyTone('tro_chuyen'), 'plain');
  assert.equal(replyTone('loi'), 'danger');
  assert.equal(replyTone('la_lung'), 'danger'); // _statusFrom: lạ → loi
  for (const s of ['ngoai_pham_vi', 'chua_ho_tro', 'tu_choi', 'khong_quyen', 'het_luot', 'ban']) assert.equal(replyTone(s), 'warning', s);
});

test('chân: số lượt khi ≤ 10; khoá khi het_luot; remaining giữ giá trị gần nhất khác null', () => {
  assert.equal(showRemaining(null), false);
  assert.equal(showRemaining(11), false);
  assert.equal(showRemaining(10), true);
  assert.equal(showRemaining(0), true);
  const a = (status, remaining) => ({ kind: 'assistant', reply: { status, text: '', blocks: [], remaining } });
  assert.equal(remainingOf([a('ok', 5), a('ban', null)]), 5);
  assert.equal(isLocked([a('ok', 5)]), false);
  assert.equal(isLocked([a('het_luot', 0), a('ok', 1)]), true);
});

test('bảng: lưới khi khung bảng ≥ 600, thẻ khi hẹp; bỏ bảng rỗng', () => {
  assert.equal(tableWidth(390), 332);
  assert.equal(tableWidth(1280), 782);
  assert.equal(drawable({ columns: [{}], rows: [] }), false);
  assert.match(render('answer', 'forecast', 'iphone'), /class="ai-card is-open"/);
  assert.doesNotMatch(render('answer', 'forecast', 'iphone'), /class="ai-table"/);
  assert.match(render('answer', 'forecast', 'web'), /class="ai-table"/);
  assert.doesNotMatch(render('answer', 'empty-table', 'web'), /ai-result/);
});

test('Thử lại chỉ ở tin lỗi cuối; hết lượt khoá ô nhập', () => {
  assert.equal((render('problem', 'error', 'iphone').match(/Thử lại/g) || []).length, 1);
  assert.doesNotMatch(render('problem', 'error-earlier', 'iphone'), /Thử lại/);
  assert.doesNotMatch(render('problem', 'slow', 'iphone'), />Thử lại</);
  const limit = render('problem', 'limit', 'web');
  assert.match(limit, /placeholder="Đã hết lượt hôm nay" maxlength="500" disabled/);
  assert.match(limit, /Còn 0 câu hỏi hôm nay\./);
});

test('mọi ca vẽ được ở cả hai khổ, ngoài khung', () => {
  for (const [screen, states] of Object.entries(CASES)) for (const state of states) for (const d of ['iphone', 'web']) {
    const html = render(screen, state, d);
    assert.match(html, /data-layout="bare"/, `${screen}/${state}/${d}`);
    assert.match(html, /class="ai-page"/, `${screen}/${state}/${d}`);
    assert.doesNotMatch(html, /undefined|NaN/, `${screen}/${state}/${d}`);
  }
});
