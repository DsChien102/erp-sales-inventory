import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import 'models/lot_date.dart';
import 'models/receipt_actor.dart';
import 'models/receipt_capability.dart';
import 'models/receipt_document_model.dart';
import 'models/receipt_header_draft.dart';
import 'models/receipt_item_draft.dart';
import 'models/receipt_lot_draft.dart';
import 'models/receipt_scenario.dart';
import 'valuation_repository.dart';

class ReceiptSupplierDto extends Equatable {
  const ReceiptSupplierDto({
    required this.id,
    required this.name,
    required this.code,
    this.phone = '',
  });

  final String id;
  final String name;
  final String code;
  final String phone;

  @override
  List<Object?> get props => [id, name, code, phone];
}

class ReceiptUnitDto extends Equatable {
  const ReceiptUnitDto({
    required this.id,
    required this.name,
    this.isBase = false,
  });

  final String id;
  final String name;
  final bool isBase;

  @override
  List<Object?> get props => [id, name, isBase];
}

class ReceiptProductDto extends Equatable {
  const ReceiptProductDto({
    required this.id,
    required this.name,
    required this.code,
    this.barcode = '',
    this.isLotTracked = false,
    this.requiresExpiry = false,
    this.units = const [],
    this.knownLotExpiry = const {},
  });

  final String id;
  final String name;
  final String code;
  final String barcode;
  final bool isLotTracked;
  final bool requiresExpiry;
  final List<ReceiptUnitDto> units;

  /// Lô đã có trong hệ thống (key viết hoa) → hạn dùng đã ghi nhận.
  final Map<String, LotDate> knownLotExpiry;

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        barcode,
        isLotTracked,
        requiresExpiry,
        units,
        knownLotExpiry,
      ];
}

class GoodsReceiptRepository {
  GoodsReceiptRepository({ValuationRepository? valuation}) : _valuation = valuation {
    _seed();
  }

  final ValuationRepository? _valuation;
  final Map<String, ReceiptDocumentModel> _receipts = {};
  final Map<String, int> _checks = {};
  int _seq = 0;
  bool _catalogChangeServed = false;

  /// Chỉ test và demo đặt; xem [ReceiptScenario].
  ReceiptScenario scenario = ReceiptScenario.normal;

  void _guard() {
    if (scenario == ReceiptScenario.permissionDenied) {
      throw const AppException(AppErrorCode.noPermission);
    }
  }

  Future<ReceiptCapability> getCapability() async {
    _guard();
    return ReceiptCapability(
      canQuickReceive: true,
      warehouseLocked: scenario == ReceiptScenario.warehouseLocked,
    );
  }

  void _seed() {
    final now = DateTime.now();
    _receipts['REC-240715-01'] = ReceiptDocumentModel(
      id: 'REC-240715-01',
      header: ReceiptHeaderDraft(
        supplierId: 'sup_01',
        supplierName: 'Minh Dũng',
        warehouseId: 'wh_default',
        warehouseName: 'Kho trung tâm',
        receiptDate: now,
        documentFileNames: const ['bien_ban_giao_nhan.pdf'],
      ),
      items: [
        ReceiptItemDraft(
          productId: 'prod_01',
          productName: 'Amox 500',
          productCode: 'AMX-500',
          unitId: 'u_hop',
          unitName: 'Hộp',
          isLotTracked: true,
          requiresExpiry: true,
          lots: [
            ReceiptLotDraft(
              lotCode: 'L2407-A',
              manufactureDate: const LotDate(year: 2026, month: 7),
              expiryDate: const LotDate(year: 2028, month: 7),
              accepted: 80.0,
              quarantine: 2.0,
              damaged: 1.0,
              rejected: 0.0,
            ),
          ],
        ),
      ],
      status: ReceiptStatus.pendingApproval,
      submittedById: 'fixture-maker',
      submittedByName: 'Nguyễn Văn An',
      submittedAt: now.subtract(const Duration(hours: 1)),
    );
  }

  String _nextId(DateTime now) {
    _seq++;
    String two(int v) => v.toString().padLeft(2, '0');
    return 'REC-${two(now.year % 100)}${two(now.month)}${two(now.day)}-${two(_seq)}';
  }

  Future<List<ReceiptSupplierDto>> getSuppliers() async {
    _guard();
    return const [
      ReceiptSupplierDto(
        id: 'sup_01',
        name: 'Minh Dũng',
        code: 'NCC-MD',
        phone: '0901234567',
      ),
      ReceiptSupplierDto(
        id: 'sup_02',
        name: 'An Việt',
        code: 'NCC-AV',
        phone: '0912345678',
      ),
      ReceiptSupplierDto(
        id: 'sup_03',
        name: 'Minh Phát',
        code: 'NCC-MP',
        phone: '0987654321',
      ),
    ];
  }

  Future<List<ReceiptProductDto>> getProducts() async {
    _guard();
    if (scenario == ReceiptScenario.catalogChanged && !_catalogChangeServed) {
      _catalogChangeServed = true;
      throw const AppException(AppErrorCode.stateChanged);
    }
    return const [
      ReceiptProductDto(
        id: 'prod_01',
        name: 'Amox 500',
        code: 'AMX-500',
        barcode: '8938500004068',
        isLotTracked: true,
        requiresExpiry: true,
        units: [
          ReceiptUnitDto(id: 'u_hop', name: 'Hộp', isBase: true),
          ReceiptUnitDto(id: 'u_vi', name: 'Vỉ'),
          ReceiptUnitDto(id: 'u_vien', name: 'Viên'),
        ],
        knownLotExpiry: {'L2407-A': LotDate(year: 2028, month: 7)},
      ),
      ReceiptProductDto(
        id: 'prod_02',
        name: 'Cefa-Vet 100ml',
        code: 'CFV-100',
        barcode: '8938500002011',
        isLotTracked: true,
        requiresExpiry: true,
        units: [
          ReceiptUnitDto(id: 'u_chai', name: 'Chai', isBase: true),
          ReceiptUnitDto(id: 'u_thung', name: 'Thùng'),
        ],
      ),
      ReceiptProductDto(
        id: 'prod_03',
        name: 'Bơm kim tiêm 5ml',
        code: 'BKT-05',
        barcode: '8938500003025',
        units: [
          ReceiptUnitDto(id: 'u_hop_bkt', name: 'Hộp', isBase: true),
          ReceiptUnitDto(id: 'u_cai', name: 'Cái'),
        ],
      ),
      ReceiptProductDto(
        id: 'prod_04',
        name: 'Găng tay khám Nitrile',
        code: 'GLOVE-N',
        barcode: '8938500003100',
        units: [
          ReceiptUnitDto(id: 'u_hop_glove', name: 'Hộp', isBase: true),
        ],
      ),
    ];
  }

  Future<ReceiptDocumentModel> submitQuickReceipt(
    ReceiptHeaderDraft header,
    List<ReceiptItemDraft> items, {
    required ReceiptActor maker,
  }) async {
    _guard();
    if (scenario == ReceiptScenario.approverMissing) {
      // UC-02-02 EF-B: không tạo phiếu, không cấp receiptId.
      throw const AppException('APPROVER_CONFIGURATION_MISSING');
    }
    final now = DateTime.now();
    final id = _nextId(now);

    final doc = ReceiptDocumentModel(
      id: id,
      header: header,
      items: items,
      status: ReceiptStatus.pendingApproval,
      submittedById: maker.id,
      submittedByName: maker.name,
      submittedAt: now,
    );

    _receipts[id] = doc;
    return doc;
  }

  Future<ReceiptDocumentModel?> getReceiptById(String id) async {
    _guard();
    return _receipts[id];
  }

  Future<ReceiptDocumentModel> approveReceipt(
    String id, {
    required ReceiptActor approver,
  }) async {
    _guard();
    final doc = _receipts[id];
    if (doc == null) throw const AppException(AppErrorCode.notFound);
    if (doc.status != ReceiptStatus.pendingApproval) {
      throw const AppException('APPROVAL_ALREADY_DECIDED');
    }
    if (doc.submittedById == approver.id) {
      throw const AppException('SELF_APPROVAL_NOT_ALLOWED');
    }

    final executed = switch (scenario) {
      ReceiptScenario.executionProcessing => ReceiptStatus.processing,
      ReceiptScenario.executionUnknown ||
      ReceiptScenario.executionUnknownStuck =>
        ReceiptStatus.executionUnknown,
      ReceiptScenario.executionRejected => ReceiptStatus.executionRejected,
      _ => ReceiptStatus.completed,
    };
    final now = DateTime.now();
    final approved = doc.copyWith(
      status: executed,
      decidedById: approver.id,
      decidedByName: approver.name,
      decidedAt: now,
      executedAt: switch (executed) {
        ReceiptStatus.completed || ReceiptStatus.executionRejected => now,
        _ => null,
      },
    );
    _receipts[id] = approved;
    // Chỉ `completed` mới có hàng để định giá (UC-02-04).
    if (executed == ReceiptStatus.completed) {
      _valuation?.addQuickReceipt(approved);
    }
    return approved;
  }

  /// UC-02-05: hỏi lại kết quả bằng cùng định danh; không tạo thao tác mới.
  Future<ReceiptDocumentModel?> checkReceiptResult(String id) async {
    _guard();
    final doc = _receipts[id];
    if (doc == null) return null;
    final n = (_checks[id] ?? 0) + 1;
    _checks[id] = n;
    final resolves = switch (doc.status) {
      ReceiptStatus.processing => n >= 2,
      ReceiptStatus.executionUnknown =>
        scenario != ReceiptScenario.executionUnknownStuck && n >= 2,
      _ => false,
    };
    if (!resolves) return doc;
    final done = doc.copyWith(
      status: ReceiptStatus.completed,
      executedAt: DateTime.now(),
    );
    _receipts[id] = done;
    _valuation?.addQuickReceipt(done);
    return done;
  }

  Future<ReceiptDocumentModel> rejectReceipt(
    String id, {
    required ReceiptActor approver,
    required String reason,
  }) async {
    _guard();
    final doc = _receipts[id];
    if (doc == null) throw const AppException(AppErrorCode.notFound);
    if (doc.status != ReceiptStatus.pendingApproval) {
      throw const AppException('APPROVAL_ALREADY_DECIDED');
    }
    if (doc.submittedById == approver.id) {
      throw const AppException('SELF_APPROVAL_NOT_ALLOWED');
    }

    final rejected = doc.copyWith(
      status: ReceiptStatus.rejected,
      decidedById: approver.id,
      decidedByName: approver.name,
      decidedAt: DateTime.now(),
      rejectReason: reason,
    );
    _receipts[id] = rejected;
    return rejected;
  }
}
