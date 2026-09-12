import 'package:vet45_sales_application/application.dart';

typedef SalesDraftClock = DateTime Function();

final class InMemorySalesOrderDraftGateway implements ISalesOrderDraftGateway {
  InMemorySalesOrderDraftGateway({SalesDraftClock? clock}) : _clock = clock ?? DateTime.now;

  final SalesDraftClock _clock;
  final Map<String, _DraftRecord> _draftsById = <String, _DraftRecord>{};
  final Map<String, String> _saveIdempotency = <String, String>{};
  final Map<String, SalesOrderDraftDto> _mutationIdempotency = <String, SalesOrderDraftDto>{};
  var _nextDraftId = 1;
  var _nextLineId = 1;

  @override
  Future<SalesOrderDraftDto> save(SaveSalesOrderDraftCommand command) async {
    final idempotencyKey = _mutationKey(command.tenantId, command.idempotencyKey);
    final existingDraftId = _saveIdempotency[idempotencyKey];
    if (existingDraftId != null) {
      return SalesOrderDraftContractMapper.toDraftDto(_draftsById[existingDraftId]!.toRow());
    }

    final draftId = 'draft-${_nextDraftId++}';
    final record = _DraftRecord(
      tenantId: command.tenantId,
      draftId: draftId,
      version: 1,
      status: SalesDraftStatus.active,
      storeId: command.storeId,
      currencyCode: command.currencyCode.trim().toUpperCase(),
      savedAt: _clock().toUtc(),
      savedByActorId: command.actorId,
      lines: _lineRows(command.lines),
      customer: command.customer,
      orderNote: command.orderNote,
      pricingPreviewToken: command.pricingPreviewToken,
      needsRevalidation: command.needsRevalidation,
    );
    _draftsById[draftId] = record;
    _saveIdempotency[idempotencyKey] = draftId;
    return SalesOrderDraftContractMapper.toDraftDto(record.toRow());
  }

  @override
  Future<SalesOrderDraftDto> update(UpdateSalesOrderDraftCommand command) async {
    final idempotencyKey = _mutationKey(command.tenantId, command.idempotencyKey);
    final idempotentResult = _mutationIdempotency[idempotencyKey];
    if (idempotentResult != null) {
      return idempotentResult;
    }

    final record = _activeRecord(command.tenantId, command.draftId, storeId: command.storeId);
    _ensureExpectedVersion(record, command.expectedVersion);
    record
      ..version += 1
      ..currencyCode = command.currencyCode.trim().toUpperCase()
      ..customer = command.customer
      ..orderNote = command.orderNote
      ..pricingPreviewToken = command.pricingPreviewToken
      ..needsRevalidation = command.needsRevalidation
      ..savedAt = _clock().toUtc()
      ..savedByActorId = command.actorId
      ..lines = _lineRows(command.lines);
    final result = SalesOrderDraftContractMapper.toDraftDto(record.toRow());
    _mutationIdempotency[idempotencyKey] = result;
    return result;
  }

  @override
  Future<SalesOrderDraftDto> cancel(CancelSalesOrderDraftCommand command) async {
    final idempotencyKey = _mutationKey(command.tenantId, command.idempotencyKey);
    final idempotentResult = _mutationIdempotency[idempotencyKey];
    if (idempotentResult != null) {
      return idempotentResult;
    }

    final record = _activeRecord(command.tenantId, command.draftId, storeId: command.storeId);
    _ensureExpectedVersion(record, command.expectedVersion);
    record
      ..version += 1
      ..status = SalesDraftStatus.cancelled
      ..savedAt = _clock().toUtc()
      ..savedByActorId = command.actorId;
    final result = SalesOrderDraftContractMapper.toDraftDto(record.toRow());
    _mutationIdempotency[idempotencyKey] = result;
    return result;
  }

  @override
  Future<SalesOrderDraftForRestoreDto> getForRestore(
    GetSalesOrderDraftForRestoreQuery query,
  ) async {
    final record = _activeRecord(query.tenantId, query.draftId, storeId: query.storeId);
    if (query.expectedSourceVersion != null && query.expectedSourceVersion != record.version) {
      throw const SalesContractException(
        'STALE_DATA',
        message: 'Draft version has changed.',
      );
    }
    return SalesOrderDraftContractMapper.toRestoreDto(record.toRow());
  }

  @override
  Future<PagedSalesOrderDraftListDto> list(ListSalesOrderDraftsQuery query) async {
    final pageSize = query.pageSize <= 0 ? 25 : query.pageSize;
    final offset = int.tryParse(query.cursor ?? '') ?? 0;
    final rows = _draftsById.values
        .where(
          (record) =>
              record.tenantId == query.tenantId &&
              record.storeId == query.storeId &&
              record.status == SalesDraftStatus.active,
        )
        .skip(offset)
        .take(pageSize + 1)
        .toList(growable: false);
    final pageRows = rows.take(pageSize).map((record) => record.toRow()).toList(growable: false);
    final hasMore = rows.length > pageSize;
    return SalesOrderDraftContractMapper.toPageDto(
      rows: pageRows,
      hasMore: hasMore,
      nextCursor: hasMore ? '${offset + pageRows.length}' : null,
    );
  }

  _DraftRecord _activeRecord(String tenantId, String draftId, {required String storeId}) {
    final record = _draftsById[draftId];
    if (record == null || record.tenantId != tenantId || record.storeId != storeId) {
      throw const SalesContractException(
        'REFERENCE_UNAVAILABLE',
        message: 'Sales order draft was not found.',
      );
    }
    if (record.status != SalesDraftStatus.active) {
      throw const SalesContractException(
        'STALE_DATA',
        message: 'Sales order draft is no longer active.',
      );
    }
    return record;
  }

  void _ensureExpectedVersion(_DraftRecord record, int expectedVersion) {
    if (record.version != expectedVersion) {
      throw const SalesContractException(
        'STALE_DATA',
        message: 'Draft version has changed.',
      );
    }
  }

  List<SalesOrderDraftLineReadRow> _lineRows(List<SalesOrderDraftLineInput> inputs) {
    return [
      for (final input in inputs)
        SalesOrderDraftLineReadRow(
          lineId: 'line-${_nextLineId++}',
          productId: input.productId,
          productSku: input.productSku,
          productName: input.productName,
          productUnitId: input.productUnitId,
          unitCode: input.unitCode,
          unitName: input.unitName,
          quantity: input.quantity,
          appliedUnitPrice: input.appliedUnitPrice,
          lineTotal: input.lineTotal,
          listUnitPrice: input.listUnitPrice,
          manualUnitPriceMinor: input.manualUnitPriceMinor,
          manualDiscountMinor: input.manualDiscountMinor,
          manualDiscountBasisPoints: input.manualDiscountBasisPoints,
          pricingSourceCode: input.pricingSourceCode,
          pricingWarningCodes: input.pricingWarningCodes,
          pricingBlockingCodes: input.pricingBlockingCodes,
          note: input.note,
          needsRevalidation: input.needsRevalidation,
        ),
    ];
  }

  static String _mutationKey(String tenantId, String idempotencyKey) {
    return '${tenantId.trim()}::${idempotencyKey.trim()}';
  }
}

final class _DraftRecord {
  _DraftRecord({
    required this.tenantId,
    required this.draftId,
    required this.version,
    required this.status,
    required this.storeId,
    required this.currencyCode,
    required this.savedAt,
    required this.savedByActorId,
    required this.lines,
    this.customer,
    this.orderNote,
    this.pricingPreviewToken,
    this.needsRevalidation = false,
  });

  final String tenantId;
  final String draftId;
  final String storeId;
  int version;
  SalesDraftStatus status;
  String currencyCode;
  DateTime savedAt;
  String savedByActorId;
  CustomerSnapshotDto? customer;
  String? orderNote;
  String? pricingPreviewToken;
  bool needsRevalidation;
  List<SalesOrderDraftLineReadRow> lines;

  SalesOrderDraftReadRow toRow() {
    return SalesOrderDraftReadRow(
      draftId: draftId,
      version: version,
      status: status,
      storeId: storeId,
      currencyCode: currencyCode,
      savedAt: savedAt,
      savedByActorId: savedByActorId,
      customer: customer,
      orderNote: orderNote,
      pricingPreviewToken: pricingPreviewToken,
      needsRevalidation: needsRevalidation,
      lines: lines,
    );
  }
}
