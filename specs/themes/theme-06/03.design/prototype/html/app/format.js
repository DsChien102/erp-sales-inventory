export function formatVnd(minor) {
  const s = String(Math.round(Math.abs(minor))).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${minor < 0 ? '-' : ''}${s} ₫`;
}
export function parseMoneyInput(text) {
  const d = String(text ?? '').replace(/\D/g, '');
  return d ? Number(d) : 0;
}
const dayNum = (iso) => { const [y, m, d] = iso.split('-').map(Number); return Date.UTC(y, m - 1, d) / 86400000; };
export function dueLabel(dueDate, today) {
  if (!dueDate) return { kind: 'none', text: 'Không có hẹn' };
  const diff = dayNum(today) - dayNum(dueDate);
  if (diff > 0) return { kind: 'overdue', days: diff, text: `Quá hạn ${diff} ngày` };
  if (diff === 0) return { kind: 'today', text: 'Đến hạn hôm nay' };
  const [, m, d] = dueDate.split('-');
  return { kind: 'upcoming', text: `Hẹn ${d}/${m}` };
}
export function customerDueLabel(orders, today) {
  const open = orders.filter((o) => o.outstandingMinor > 0);
  const labels = open.map((o) => ({ o, l: dueLabel(o.dueDate, today) }));
  const overdue = labels.filter((x) => x.l.kind === 'overdue');
  if (overdue.length) { const days = Math.max(...overdue.map((x) => x.l.days)); return { kind: 'overdue', days, text: `Quá hạn ${days} ngày` }; }
  const todayL = labels.find((x) => x.l.kind === 'today');
  if (todayL) return todayL.l;
  const up = labels.filter((x) => x.l.kind === 'upcoming').sort((a, b) => a.o.dueDate.localeCompare(b.o.dueDate));
  if (up.length) return up[0].l;
  return { kind: 'none', text: 'Không có hẹn' };
}
export function overdueAmountMinor(orders, today) {
  return orders.filter((o) => o.outstandingMinor > 0 && dueLabel(o.dueDate, today).kind === 'overdue').reduce((s, o) => s + o.outstandingMinor, 0);
}
