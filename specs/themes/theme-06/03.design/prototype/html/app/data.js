import { customerDueLabel, dueLabel } from './format.js';

export const TODAY = '2026-11-18';

const ord = (code, completedAt, payableMinor, outstandingMinor, dueDate) => ({ id: code, code, completedAt, payableMinor, outstandingMinor, dueDate });

const C2 = { kind: 'collection', amount: 2e6, method: 'cash', at: '2026-11-06T14:20', by: 'Nguyễn An', allocations: [{ code: 'DH-002', amount: 2e6 }] };
const C10 = { kind: 'collection', amount: 10e6, method: 'cash', at: '2026-11-18T09:30', by: 'Nguyễn An', allocations: [{ code: 'DH-001', amount: 4e6 }, { code: 'DH-002', amount: 6e6 }] };
const O500 = { kind: 'offset', amount: 500000, fromOrder: 'DH-001', returnCode: '#DT-0001', toOrder: 'DH-002', at: '2026-11-18T10:15', by: 'Nguyễn An' };
const C18 = { kind: 'collection', amount: 18e6, method: 'cash', at: '2026-11-18T09:30', by: 'Nguyễn An', allocations: [{ code: 'DH-001', amount: 4e6 }, { code: 'DH-002', amount: 8e6 }, { code: 'DH-003', amount: 6e6 }] };

/** Anh Tuấn ở một thời điểm của ví dụ 2.3. Chỉ đơn còn nợ (> 0). Lịch sử mới nhất trước. */
export function tuanAt(moment) {
  switch (moment) {
    case 'before': return { orders: [ord('DH-001', '2026-11-01', 4e6, 4e6, '2026-11-10'), ord('DH-002', '2026-11-05', 10e6, 8e6, '2026-11-15'), ord('DH-003', '2026-11-12', 6e6, 6e6, '2026-11-30')], history: [C2] };
    case 'afterCollect': return { orders: [ord('DH-002', '2026-11-05', 10e6, 2e6, '2026-11-15'), ord('DH-003', '2026-11-12', 6e6, 6e6, '2026-11-30')], history: [C10, C2] };
    case 'afterOffset': return { orders: [ord('DH-002', '2026-11-05', 10e6, 1.5e6, '2026-11-15'), ord('DH-003', '2026-11-12', 6e6, 6e6, '2026-11-30')], history: [O500, C10, C2] };
    case 'paidOff': return { orders: [], history: [C18, C2] };
    default: throw new Error(`moment? ${moment}`);
  }
}

const tuan = { id: 'c-tuan', displayName: 'Anh Tuấn', phone: '0901 234 567', isActive: true, ...tuanAt('before') };
const lan = { id: 'c-lan', displayName: 'Chị Lan', phone: '0912 345 678', isActive: true, orders: [ord('DH-020', '2026-11-10', 6e6, 6e6, '2026-11-25')], history: [] };
const hung = { id: 'c-hung', displayName: 'Trại Hưng Phát', phone: '0987 654 321', isActive: true, orders: [ord('DH-021', '2026-11-08', 1e6, 1e6, '2026-11-18'), ord('DH-022', '2026-11-12', 1.5e6, 1.5e6, '2026-11-30')], history: [] };

export const customers = [tuan, lan, hung];

export const edgeCustomers = [
  { id: 'c-long', displayName: 'Công ty TNHH Thuốc Thú Y và Vật Tư Chăn Nuôi Đồng Bằng Sông Cửu Long', phone: null, isActive: true, orders: [ord('DH-040', '2026-11-10', 1234567890, 1234567890, '2026-11-30')], history: [] },
  {
    id: 'c-hoa', displayName: 'Cô Hoa', phone: '0933 111 222', isActive: false,
    orders: [ord('DH-030', '2026-11-12', 2e6, 1.5e6, '2026-11-30')],
    history: [
      { kind: 'order_payment', amount: 500000, orderCode: 'DH-030', at: '2026-11-12T09:10' },
      { kind: 'refund', amount: 200000, orderCode: 'DH-029', at: '2026-11-03T16:00' },
    ],
  },
];

/** 8 khách cho ba phương án CN-01 (varA/varB/varC): đủ quá hạn / đến hạn / chưa đến hạn / không hẹn. Cùng TODAY. */
const mk = (id, displayName, phone, orders) => ({ id, displayName, phone, isActive: true, orders, history: [] });
export const richCustomers = [
  tuan, lan, hung,
  mk('c-binh', 'Anh Bình', '0905 118 227', [ord('DH-050', '2026-10-20', 850000, 850000, '2026-10-28')]),
  mk('c-mai', 'Chị Mai', '0908 765 432', [ord('DH-051', '2026-11-08', 3.2e6, 3.2e6, '2026-11-15')]),
  mk('c-khoa', 'Phòng khám thú y Đồng Xuân – Chi nhánh 2', '0283 555 0142', [ord('DH-052', '2026-11-02', 5.4e6, 5.4e6, '2026-11-12'), ord('DH-053', '2026-11-14', 2e6, 2e6, '2026-12-02')]),
  mk('c-chau', 'Cửa hàng Minh Châu', '0912 004 880', [ord('DH-054', '2026-11-11', 14.2e6, 14.2e6, '2026-11-28')]),
  mk('c-nam', 'Anh Nam', '0977 222 111', [ord('DH-055', '2026-11-13', 1.1e6, 1.1e6, null)]),
];

export const totalOf =(c) => c.orders.reduce((s, o) => s + o.outstandingMinor, 0);

export function summaryOf(list) {
  return {
    totalOutstandingMinor: list.reduce((s, c) => s + totalOf(c), 0),
    customerCount: list.length,
    overdueCustomerCount: list.filter((c) => customerDueLabel(c.orders, TODAY).kind === 'overdue').length,
  };
}

export { dueLabel };

/** Dữ liệu SG-13 (khách được hưởng). base = ví dụ 2.3 bước 2; còn lại là ca riêng (không thuộc 2.3). */
const afterCollect = tuanAt('afterCollect').orders;
const cand = (o) => ({ id: o.id, code: o.code, outstandingMinor: o.outstandingMinor, dueDate: o.dueDate });
export const sg13Cases = {
  base: { orderCode: 'DH-001', customer: 'Anh Tuấn', returnValue: 500000, exchangeValue: 0, entitled: 500000, sourceOutstanding: 0, candidates: afterCollect.map(cand) },
  mixed: { orderCode: 'DH-010', customer: 'Anh Tuấn', returnValue: 3e6, exchangeValue: 0, entitled: 3e6, sourceOutstanding: 400000, candidates: [cand(afterCollect[0])] },
  'source-has-debt': { orderCode: 'DH-010', customer: 'Anh Tuấn', returnValue: 600000, exchangeValue: 0, entitled: 600000, sourceOutstanding: 600000, candidates: [cand(afterCollect[0])] },
  'no-other-debt': { orderCode: 'DH-001', customer: 'Anh Tuấn', returnValue: 500000, exchangeValue: 0, entitled: 500000, sourceOutstanding: 0, candidates: [] },
};
