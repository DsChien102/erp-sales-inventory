// ignore_for_file: depend_on_referenced_packages

import 'package:erp/features/sales/data/models/sales_draft_list_page.dart';
import 'package:erp/features/sales/data/sales_draft_repository.dart';
import 'package:erp/features/sales/data/models.dart';

class SalesDraftSaveCall {
  SalesDraftSaveCall({
    required this.storeId,
    required this.customer,
    required this.currencyCode,
    required this.orderNote,
    required this.pricingPreviewToken,
    required this.needsRevalidation,
    required this.lines,
    required this.idempotencyKey,
    required this.payloadHash,
  });
  final String storeId;
  final CustomerSnapshotDto? customer;
  final String currencyCode;
  final String? orderNote;
  final String? pricingPreviewToken;
  final bool needsRevalidation;
  final List<SalesOrderDraftLineInput> lines;
  final String idempotencyKey;
  final String? payloadHash;
}

class SalesDraftUpdateCall extends SalesDraftSaveCall {
  SalesDraftUpdateCall({
    required this.draftId,
    required this.expectedVersion,
    required super.storeId,
    required super.customer,
    required super.currencyCode,
    required super.orderNote,
    required super.pricingPreviewToken,
    required super.needsRevalidation,
    required super.lines,
    required super.idempotencyKey,
    required super.payloadHash,
  });
  final String draftId;
  final int expectedVersion;
}

class SalesDraftCancelCall {
  SalesDraftCancelCall(this.draftId, this.storeId, this.expectedVersion, this.idempotencyKey);
  final String draftId;
  final String storeId;
  final int expectedVersion;
  final String idempotencyKey;
}

class SalesDraftListCall {
  SalesDraftListCall(
    this.storeId,
    this.cursor,
    this.pageSize, {
    this.search,
    this.createdByUserId,
  });
  final String storeId;
  final String? cursor;
  final int pageSize;
  final String? search;
  final String? createdByUserId;
}

class SalesDraftRestoreCall {
  SalesDraftRestoreCall(this.draftId, this.storeId, this.expectedVersion);
  final String draftId;
  final String storeId;
  final int? expectedVersion;
}

class FakeSalesDraftRepository implements SalesDraftRepository {
  final saveCalls = <SalesDraftSaveCall>[];
  final updateCalls = <SalesDraftUpdateCall>[];
  final cancelCalls = <SalesDraftCancelCall>[];
  final listCalls = <SalesDraftListCall>[];
  final restoreCalls = <SalesDraftRestoreCall>[];

  List<SalesOrderDraftDto> listItems = const [];
  List<SalesDraftListEntry>? listEntries;
  bool hasMore = false;
  int? totalCount;
  String? nextCursor;
  SalesDraftListPage Function(SalesDraftListCall call)? onListPage;
  SalesOrderDraftForRestoreDto? restoreDto;
  Object? saveError;
  Object? updateError;
  Object? cancelError;
  Object? listError;
  Object? restoreError;
  Duration? cancelDelay;

  /// Nếu đặt, quyết định kết quả của save / update (nhận số lần gọi 1-based).
  SalesOrderDraftDto Function(SalesDraftSaveCall call)? onSave;
  SalesOrderDraftDto Function(SalesDraftUpdateCall call)? onUpdate;

  static SalesOrderDraftDto _echo(
    SalesDraftSaveCall call, {
    String draftId = 'draft-saved-1',
    int version = 1,
    bool withLines = true,
  }) => SalesOrderDraftDto(
    draftId: draftId,
    version: version,
    status: SalesDraftStatus.active,
    storeId: call.storeId,
    savedAt: DateTime.utc(2026, 8, 11, 5),
    savedByActorId: 'user-1',
    customer: call.customer,
    orderNote: call.orderNote,
    pricingPreviewToken: call.pricingPreviewToken,
    needsRevalidation: call.needsRevalidation,
    lines: withLines
        ? [
            for (final line in call.lines)
              SalesOrderDraftLineDto(
                lineId: 'line-persisted',
                productId: line.productId,
                productSku: line.productSku,
                productName: line.productName,
                productUnitId: line.productUnitId,
                unitCode: line.unitCode,
                unitName: line.unitName,
                quantity: line.quantity,
                appliedUnitPrice: line.appliedUnitPrice,
                lineTotal: line.lineTotal,
                listUnitPrice: line.listUnitPrice,
                needsRevalidation: line.needsRevalidation,
              ),
          ]
        : const [],
    total: MoneyDto(
      amountMinor: withLines
          ? call.lines.fold<int>(0, (sum, line) => sum + line.lineTotal.amountMinor)
          : 0,
      currencyCode: call.currencyCode,
    ),
  );

  /// Hàm chặn trước khi list trả (để dựng ca tải song song).
  Future<void> Function()? onListGate;

  @override
  Future<SalesOrderDraftDto> save({
    required String storeId,
    CustomerSnapshotDto? customer,
    required String currencyCode,
    String? orderNote,
    String? pricingPreviewToken,
    bool needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines,
    required String idempotencyKey,
    String? payloadHash,
  }) async {
    final call = SalesDraftSaveCall(
      storeId: storeId,
      customer: customer,
      currencyCode: currencyCode,
      orderNote: orderNote,
      pricingPreviewToken: pricingPreviewToken,
      needsRevalidation: needsRevalidation,
      lines: lines,
      idempotencyKey: idempotencyKey,
      payloadHash: payloadHash,
    );
    saveCalls.add(call);
    final error = saveError;
    if (error != null) throw error;
    return (onSave ?? _echo)(call);
  }

  @override
  Future<SalesOrderDraftDto> update({
    required String draftId,
    required int expectedVersion,
    required String storeId,
    CustomerSnapshotDto? customer,
    required String currencyCode,
    String? orderNote,
    String? pricingPreviewToken,
    bool needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines,
    required String idempotencyKey,
    String? payloadHash,
  }) async {
    final call = SalesDraftUpdateCall(
      draftId: draftId,
      expectedVersion: expectedVersion,
      storeId: storeId,
      customer: customer,
      currencyCode: currencyCode,
      orderNote: orderNote,
      pricingPreviewToken: pricingPreviewToken,
      needsRevalidation: needsRevalidation,
      lines: lines,
      idempotencyKey: idempotencyKey,
      payloadHash: payloadHash,
    );
    updateCalls.add(call);
    final error = updateError;
    if (error != null) throw error;
    return (onUpdate ??
        (c) =>
            _echo(c, draftId: c.draftId, version: c.expectedVersion + 1, withLines: false))(call);
  }

  @override
  Future<SalesOrderDraftDto> cancel({
    required String draftId,
    required String storeId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    cancelCalls.add(SalesDraftCancelCall(draftId, storeId, expectedVersion, idempotencyKey));
    final delay = cancelDelay;
    if (delay != null) await Future<void>.delayed(delay);
    final error = cancelError;
    if (error != null) throw error;
    return listItems.firstWhere((d) => d.draftId == draftId);
  }

  @override
  Future<SalesDraftListPage> list({
    required String storeId,
    String? cursor,
    int pageSize = 25,
    String? search,
    String? createdByUserId,
  }) async {
    final call = SalesDraftListCall(
      storeId,
      cursor,
      pageSize,
      search: search,
      createdByUserId: createdByUserId,
    );
    listCalls.add(call);
    final gate = onListGate;
    if (gate != null) await gate();
    final error = listError;
    if (error != null) throw error;
    if (onListPage != null) return onListPage!(call);
    var entries = listEntries ??
        listItems
            .map(
              (d) => SalesDraftListEntry(
                draft: d,
                createdByUserId: d.savedByActorId,
                createdByName: null,
              ),
            )
            .toList();
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      entries = entries
          .where((e) {
            final d = e.draft;
            final text = [
              d.customer?.displayName ?? '',
              d.customer?.phoneNumber ?? '',
              d.orderNote ?? '',
              d.draftId,
            ].join(' ').toLowerCase();
            return text.contains(q);
          })
          .toList();
    }
    final total = totalCount ?? (listEntries?.length ?? listItems.length);
    return SalesDraftListPage(
      items: entries,
      hasMore: hasMore,
      totalCount: total,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<SalesOrderDraftForRestoreDto> getForRestore({
    required String draftId,
    required String storeId,
    int? expectedVersion,
  }) async {
    restoreCalls.add(SalesDraftRestoreCall(draftId, storeId, expectedVersion));
    final error = restoreError;
    if (error != null) throw error;
    return restoreDto!;
  }
}
