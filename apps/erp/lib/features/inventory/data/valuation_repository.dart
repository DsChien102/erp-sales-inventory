import 'models/receipt_document_model.dart';
import 'models/valuation_cost_source.dart';
import 'models/valuation_direct_basis_draft.dart';
import 'models/valuation_group_item.dart';
import 'models/valuation_result_model.dart';
import 'models/valuation_work_item.dart';

class ReceiptValuationData {
  const ReceiptValuationData({
    required this.id,
    required this.receiptNumber,
    required this.supplierName,
    required this.receivedAt,
    required this.entryType,
    required this.groups,
    this.sourceVersion = 1,
  });

  final String id;
  final String receiptNumber;
  final String supplierName;
  final String receivedAt;
  final ValuationEntryType entryType;
  final List<ValuationGroupItem> groups;
  final int sourceVersion;

  ReceiptValuationData copyWith({
    String? id,
    String? receiptNumber,
    String? supplierName,
    String? receivedAt,
    ValuationEntryType? entryType,
    List<ValuationGroupItem>? groups,
    int? sourceVersion,
  }) {
    return ReceiptValuationData(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      supplierName: supplierName ?? this.supplierName,
      receivedAt: receivedAt ?? this.receivedAt,
      entryType: entryType ?? this.entryType,
      groups: groups ?? this.groups,
      sourceVersion: sourceVersion ?? this.sourceVersion,
    );
  }
}

class ValuationRepository {
  ValuationRepository() {
    _initFixtures();
  }

  final Map<String, ReceiptValuationData> _receipts = {};
  int _operationSeq = 1;

  void _initFixtures() {
    _receipts['VAL03-R1'] = const ReceiptValuationData(
      id: 'VAL03-R1',
      receiptNumber: 'PN-260816-04',
      supplierName: 'Minh Dũng',
      receivedAt: '16/08/2026',
      entryType: ValuationEntryType.document,
      sourceVersion: 3,
      groups: [
        ValuationGroupItem(
          id: 'VAL03-G1',
          productId: 'prod-00142',
          productName: 'Nobivac DHPPi',
          productCode: 'SP-00142',
          uom: 'hộp',
          tracking: 'LOT',
          pendingQty: 100,
          lotsCount: 2,
          status: ValuationGroupStatus.ready,
          sources: [
            ValuationCostSource(
              id: 'PO',
              label: 'Đơn mua PO-2608-041',
              unitPrice: 83000,
              currency: 'VND',
              fxRate: 1.0,
              unitLineDiscount: 1000,
              unitDocDiscount: 500,
              unitKnownCost: 200,
              unitNonDeductibleVat: 0,
            ),
          ],
          selectedSourceId: 'PO',
        ),
        ValuationGroupItem(
          id: 'VAL03-G2',
          productId: 'prod-00088',
          productName: 'Amoxicillin LA',
          productCode: 'SP-00088',
          uom: 'chai',
          tracking: 'NONE',
          pendingQty: 24,
          lotsCount: 0,
          status: ValuationGroupStatus.commercialConflict,
          sources: [
            ValuationCostSource(
              id: 'PO',
              label: 'Đơn mua PO-2608-041',
              unitPrice: 120000,
            ),
            ValuationCostSource(
              id: 'SUP',
              label: 'Xác nhận nhà cung cấp 02/09',
              unitPrice: 121000,
            ),
          ],
        ),
      ],
    );

    _receipts['VAL03-R2'] = const ReceiptValuationData(
      id: 'VAL03-R2',
      receiptNumber: 'PN-260816-02',
      supplierName: 'An Việt',
      receivedAt: '16/08/2026',
      entryType: ValuationEntryType.quick,
      sourceVersion: 1,
      groups: [
        ValuationGroupItem(
          id: 'VAL03-G3',
          productId: 'prod-00310',
          productName: 'Găng tay khám Nitrile',
          productCode: 'SP-00310',
          uom: 'hộp',
          tracking: 'NONE',
          pendingQty: 50,
          lotsCount: 0,
          status: ValuationGroupStatus.directMissing,
          sources: [],
        ),
      ],
    );

    _receipts['VAL03-R3'] = const ReceiptValuationData(
      id: 'VAL03-R3',
      receiptNumber: 'PN-260901-03',
      supplierName: 'Phương Nam',
      receivedAt: '01/09/2026',
      entryType: ValuationEntryType.document,
      sourceVersion: 2,
      groups: [
        ValuationGroupItem(
          id: 'VAL03-G4',
          productId: 'prod-00421',
          productName: 'Vaccine Canine X',
          productCode: 'SP-00421',
          uom: 'lọ',
          tracking: 'LOT',
          pendingQty: 10,
          lotsCount: 1,
          status: ValuationGroupStatus.ready,
          sources: [
            ValuationCostSource(
              id: 'SUP',
              label: 'Xác nhận nhà cung cấp 01/09',
              unitPrice: 100245,
              currency: 'VND',
              fxRate: 1.0,
            ),
          ],
          selectedSourceId: 'SUP',
        ),
      ],
    );

    _receipts['VAL03-R4'] = const ReceiptValuationData(
      id: 'VAL03-R4',
      receiptNumber: 'PN-260902-07',
      supplierName: 'VietVet',
      receivedAt: '02/09/2026',
      entryType: ValuationEntryType.document,
      sourceVersion: 1,
      groups: [
        ValuationGroupItem(
          id: 'VAL03-G5',
          productId: 'prod-00510',
          productName: 'Dung dịch sát khuẩn',
          productCode: 'SP-00510',
          uom: 'chai',
          tracking: 'NONE',
          pendingQty: 12,
          lotsCount: 0,
          status: ValuationGroupStatus.ready,
          sources: [
            ValuationCostSource(
              id: 'PO',
              label: 'Đơn mua PO-2609-008',
              unitPrice: 46000,
            ),
          ],
          selectedSourceId: 'PO',
        ),
        ValuationGroupItem(
          id: 'VAL03-G6',
          productId: 'prod-00511',
          productName: 'Bơm tiêm 5ml',
          productCode: 'SP-00511',
          uom: 'hộp',
          tracking: 'NONE',
          pendingQty: 8,
          lotsCount: 0,
          status: ValuationGroupStatus.commercialMissing,
          sources: [],
        ),
      ],
    );
  }

  ValuationWorkItemStatus _computeReceiptStatus(ReceiptValuationData r) {
    final pending = r.groups.where((g) => g.pendingQty > 0).toList();
    if (pending.isEmpty) return ValuationWorkItemStatus.ready;
    if (pending.any((g) => g.status == ValuationGroupStatus.commercialConflict)) {
      return ValuationWorkItemStatus.conflict;
    }
    if (pending.every((g) =>
        g.status == ValuationGroupStatus.commercialMissing ||
        g.status == ValuationGroupStatus.directMissing)) {
      return ValuationWorkItemStatus.missing;
    }
    return ValuationWorkItemStatus.ready;
  }

  Future<List<ValuationWorkItem>> getQueue({
    String? query,
    String filter = 'ALL',
  }) async {
    final q = (query ?? '').trim().toLowerCase();
    final items = <ValuationWorkItem>[];

    for (final r in _receipts.values) {
      final pendingCount = r.groups.where((g) => g.pendingQty > 0).length;
      if (pendingCount == 0) continue;

      final status = _computeReceiptStatus(r);

      // Search match
      if (q.isNotEmpty) {
        final match = r.receiptNumber.toLowerCase().contains(q) ||
            r.supplierName.toLowerCase().contains(q);
        if (!match) continue;
      }

      // Filter match
      if (filter == 'READY' && status != ValuationWorkItemStatus.ready) continue;
      if (filter == 'ISSUE' && status == ValuationWorkItemStatus.ready) continue;

      items.add(
        ValuationWorkItem(
          id: r.id,
          receiptNumber: r.receiptNumber,
          supplierName: r.supplierName,
          entryType: r.entryType,
          pendingLinesCount: pendingCount,
          receivedAt: r.receivedAt,
          status: status,
        ),
      );
    }

    return items;
  }

  Future<ReceiptValuationData> getReceiptValuation(String receiptId) async {
    final r = _receipts[receiptId];
    if (r == null) {
      throw Exception('Không tìm thấy phiếu nhận $receiptId');
    }
    return r;
  }

  Future<ReceiptValuationData> saveDirectBasis({
    required String receiptId,
    required String groupId,
    required ValuationDirectBasisDraft draft,
  }) async {
    final r = _receipts[receiptId];
    if (r == null) {
      throw Exception('Không tìm thấy phiếu nhận $receiptId');
    }

    final newGroups = r.groups.map((g) {
      if (g.id != groupId) return g;

      final sourceId = 'DIRECT-${g.id}-${DateTime.now().millisecondsSinceEpoch}';
      final formattedDate = draft.date != null
          ? '${draft.date!.day.toString().padLeft(2, '0')}/${draft.date!.month.toString().padLeft(2, '0')}/${draft.date!.year}'
          : '';

      final source = ValuationCostSource(
        id: sourceId,
        label: '${draft.source} · $formattedDate',
        unitPrice: draft.unitPrice,
        unitNonDeductibleVat:
            draft.taxMode == ValuationTaxMode.excluded ? draft.taxAmount : 0,
        directReason: draft.reason,
        taxMode: draft.taxMode == ValuationTaxMode.included ? 'INCLUDED' : 'EXCLUDED',
        sourceDate: formattedDate,
        reference: draft.reference,
      );

      return g.copyWith(
        status: ValuationGroupStatus.ready,
        sources: [source],
        selectedSourceId: sourceId,
        isSelected: true,
      );
    }).toList();

    final updatedReceipt = r.copyWith(
      groups: newGroups,
      sourceVersion: r.sourceVersion + 1,
    );
    _receipts[receiptId] = updatedReceipt;
    return updatedReceipt;
  }

  Future<ValuationResultModel> confirmValuation({
    required String receiptId,
    required List<String> selectedGroupIds,
  }) async {
    final r = _receipts[receiptId];
    if (r == null) {
      throw Exception('Không tìm thấy phiếu nhận $receiptId');
    }

    final evaluatedLines = <ValuationResultLine>[];
    var totalVal = 0.0;
    var totalQ = 0.0;
    final dirtyScope = <String>[];

    final updatedGroups = r.groups.map((g) {
      if (!selectedGroupIds.contains(g.id)) return g;

      final unitAct = g.unitActual ?? 0.0;
      final lineVal = unitAct * g.pendingQty;

      evaluatedLines.add(
        ValuationResultLine(
          productName: g.productName,
          productCode: g.productCode,
          qty: g.pendingQty,
          uom: g.uom,
          unitInitial: unitAct,
          totalValue: lineVal,
        ),
      );

      totalVal += lineVal;
      totalQ += g.pendingQty;
      dirtyScope.add('${g.productName} · kỳ ${r.receivedAt.substring(3)}');

      // Once evaluated, pending qty is zero
      return g.copyWith(
        pendingQty: 0,
        isSelected: false,
      );
    }).toList();

    final remainingPending =
        updatedGroups.where((g) => g.pendingQty > 0).length;

    _receipts[receiptId] = r.copyWith(
      groups: updatedGroups,
      sourceVersion: r.sourceVersion + 1,
    );

    final opId =
        'VAL-260925-${_operationSeq.toString().padLeft(3, '0')}';
    _operationSeq++;

    return ValuationResultModel(
      operationId: opId,
      receiptNumber: r.receiptNumber,
      supplierName: r.supplierName,
      businessDate: r.receivedAt,
      lines: evaluatedLines,
      totalValue: totalVal,
      totalQty: totalQ,
      dirtyScope: dirtyScope,
      remainingPendingCount: remainingPending,
    );
  }

  /// Fixture thay cho backend: phiếu nhập nhanh được duyệt → thêm mục chờ xác lập giá trị.
  void addQuickReceipt(ReceiptDocumentModel doc) {
    _receipts[doc.id] = ReceiptValuationData(
      id: doc.id,
      receiptNumber: doc.id,
      supplierName: doc.header.supplierName,
      receivedAt: _formatDate(doc.header.receiptDate),
      entryType: ValuationEntryType.quick,
      groups: [
        for (final item in doc.items)
          if (item.totalPhysicalStock > 0)
            ValuationGroupItem(
              id: '${doc.id}-${item.productId}-${item.unitId}',
              productId: item.productId,
              productName: item.productName,
              productCode: item.productCode,
              uom: item.unitName,
              tracking: item.isLotTracked ? 'LOT' : 'NONE',
              pendingQty: item.totalPhysicalStock,
              lotsCount: item.isLotTracked ? item.lots.length : 0,
              status: ValuationGroupStatus.directMissing,
              sources: const [],
            ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
