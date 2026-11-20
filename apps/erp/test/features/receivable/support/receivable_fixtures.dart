import 'package:erp/features/receivable/data/receivable_models.dart';

/// Dữ liệu ví dụ TH-06 2.3 (giống `data.js` của prototype T6-2a).
final today = DateTime(2026, 11, 18);

final _ts = DateTime(2026, 11, 6, 14, 20);

const tuanId = 'c-tuan';
const hungId = 'c-hung';
const lanId = 'c-lan';

OpenReceivableOrder _order(
  String id,
  String code,
  String completed,
  int payable,
  int outstanding,
  String? due,
  int overdue,
) => OpenReceivableOrder(
  salesOrderId: id,
  orderCode: code,
  completedAt: DateTime.parse(completed),
  payableMinor: payable,
  outstandingMinor: outstanding,
  dueDate: due == null ? null : DateTime.parse(due),
  overdueDays: overdue,
  settlementVersion: 1,
);

final List<OpenReceivableOrder> tuanOrders = [
  _order('so-001', 'DH-001', '2026-11-01T09:00:00', 4000000, 4000000, '2026-11-10', 8),
  _order('so-002', 'DH-002', '2026-11-05T09:00:00', 10000000, 8000000, '2026-11-15', 3),
  _order('so-003', 'DH-003', '2026-11-12T09:00:00', 6000000, 6000000, '2026-11-30', 0),
];

const tuanCustomer = ReceivableCustomer(
  customerId: tuanId,
  displayName: 'Anh Tuấn',
  phone: '0901 234 567',
  isActive: true,
);

final CustomerReceivableDetail tuanDetail = CustomerReceivableDetail(
  customer: tuanCustomer,
  outstandingMinor: 18000000,
  openOrderCount: 3,
  overdueOrderCount: 2,
  maxOverdueDays: 8,
  openOrders: tuanOrders,
);

final ReceivableHistoryItem tuanHistoryItem = ReceivableHistoryItem(
  kind: ReceivableHistoryKind.customerCollection,
  occurredAt: _ts,
  amountMinor: 2000000,
  paymentMethodCode: 'cash',
  actorDisplayName: 'Nguyễn An',
  allocations: const [HistoryAllocation(orderCode: 'DH-002', amountMinor: 2000000)],
);

final List<ReceivableHistoryItem> tuanHistoryBefore = [tuanHistoryItem];

const summaryBefore = ReceivableSummary(
  totalOutstandingMinor: 26500000,
  customerCount: 3,
  overdueCustomerCount: 1,
  overdueAmountMinor: 12000000,
  maxOverdueDays: 8,
);

final List<CustomerReceivableRow> rowsBefore = [
  CustomerReceivableRow(
    customerId: tuanId,
    displayName: 'Anh Tuấn',
    phone: '0901 234 567',
    isActive: true,
    outstandingMinor: 18000000,
    openOrderCount: 3,
    overdueOrderCount: 2,
    overdueAmountMinor: 12000000,
    maxOverdueDays: 8,
    nextDueDate: DateTime.parse('2026-11-30'),
  ),
  CustomerReceivableRow(
    customerId: hungId,
    displayName: 'Trại Hưng Phát',
    phone: '0987 654 321',
    isActive: true,
    outstandingMinor: 2500000,
    openOrderCount: 2,
    overdueOrderCount: 0,
    overdueAmountMinor: 0,
    maxOverdueDays: 0,
    nextDueDate: DateTime.parse('2026-11-18'),
  ),
  CustomerReceivableRow(
    customerId: lanId,
    displayName: 'Chị Lan',
    phone: '0912 345 678',
    isActive: true,
    outstandingMinor: 6000000,
    openOrderCount: 1,
    overdueOrderCount: 0,
    overdueAmountMinor: 0,
    maxOverdueDays: 0,
    nextDueDate: DateTime.parse('2026-11-25'),
  ),
];

final CustomerReceivablePage pageBefore = CustomerReceivablePage(
  summary: summaryBefore,
  items: rowsBefore,
  nextCursor: null,
);

// ---- JSON server tương ứng -------------------------------------------------

Map<String, dynamic> get listJson => {
  'summary': {
    'totalOutstandingMinor': 26500000,
    'customerCount': 3,
    'overdueCustomerCount': 1,
    'overdueAmountMinor': 12000000,
    'maxOverdueDays': 8,
  },
  'items': [
    for (final r in rowsBefore)
      {
        'customerId': r.customerId,
        'displayName': r.displayName,
        'phone': r.phone,
        'isActive': r.isActive,
        'outstandingMinor': r.outstandingMinor,
        'openOrderCount': r.openOrderCount,
        'overdueOrderCount': r.overdueOrderCount,
        'overdueAmountMinor': r.overdueAmountMinor,
        'maxOverdueDays': r.maxOverdueDays,
        'nextDueDate': r.nextDueDate?.toIso8601String().substring(0, 10),
      },
  ],
  'nextCursor': null,
};

Map<String, dynamic> get tuanDetailJson => {
  'customer': {
    'customerId': tuanId,
    'displayName': 'Anh Tuấn',
    'phone': '0901 234 567',
    'isActive': true,
  },
  'outstandingMinor': 18000000,
  'openOrderCount': 3,
  'overdueOrderCount': 2,
  'maxOverdueDays': 8,
  'openOrders': [
    for (final o in tuanOrders)
      {
        'salesOrderId': o.salesOrderId,
        'orderCode': o.orderCode,
        'completedAt': o.completedAt.toIso8601String(),
        'payableMinor': o.payableMinor,
        'outstandingMinor': o.outstandingMinor,
        'dueDate': o.dueDate?.toIso8601String().substring(0, 10),
        'overdueDays': o.overdueDays,
        'settlementVersion': o.settlementVersion,
      },
  ],
};

Map<String, dynamic> get historyJson => {
  'items': [
    {
      'kind': 'customer_collection',
      'occurredAt': _ts.toIso8601String(),
      'amountMinor': 2000000,
      'paymentMethodCode': 'cash',
      'externalReference': null,
      'actorId': 'u-1',
      'actorDisplayName': 'Nguyễn An',
      'salesOrderId': null,
      'orderCode': null,
      'allocations': [
        {'orderCode': 'DH-002', 'amountMinor': 2000000},
      ],
      'sourceOrderCode': null,
      'targetOrderCode': null,
      'returnExchangeReference': null,
    },
  ],
  'nextCursor': null,
};
