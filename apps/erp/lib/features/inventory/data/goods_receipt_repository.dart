import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import 'models/lot_date.dart';
import 'models/receipt_actor.dart';
import 'models/receipt_document_model.dart';
import 'models/receipt_header_draft.dart';
import 'models/receipt_item_draft.dart';
import 'models/receipt_lot_draft.dart';
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
  int _seq = 0;

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
    return _receipts[id];
  }

  Future<ReceiptDocumentModel> approveReceipt(
    String id, {
    required ReceiptActor approver,
  }) async {
    final doc = _receipts[id];
    if (doc == null) throw const AppException(AppErrorCode.notFound);
    if (doc.status != ReceiptStatus.pendingApproval) {
      throw const AppException('APPROVAL_ALREADY_DECIDED');
    }
    if (doc.submittedById == approver.id) {
      throw const AppException('SELF_APPROVAL_NOT_ALLOWED');
    }

    final approved = doc.copyWith(
      status: ReceiptStatus.completed,
      decidedById: approver.id,
      decidedByName: approver.name,
      decidedAt: DateTime.now(),
    );
    _receipts[id] = approved;
    _valuation?.addQuickReceipt(approved);
    return approved;
  }

  Future<ReceiptDocumentModel> rejectReceipt(
    String id, {
    required ReceiptActor approver,
    required String reason,
  }) async {
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
