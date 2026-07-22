import 'dart:typed_data';

import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart'
    hide
        CustomerPriceRuleImportMode,
        CustomerPriceRuleImportStatus,
        CustomerPriceRuleImportRowStatus;
import 'package:vet45_shared_application/application.dart';

/// Pricing module in-memory cho TH-04 EP02 — thay thế tạm PricingStartup
/// khi DB migrations pricing chưa được promote.
///
/// Hành vi theo SG:
/// - SG-03: tạo trùng rule → trả DUPLICATE_ACTIVE_RULE và giữ nguyên rule cũ;
///   sửa trùng vẫn theo policy authoritative riêng của update.
/// - SG-05: bật lại không validate duplicate — tự tắt rule trùng rồi bật.
///
/// TODO(TH-04): thay bằng PricingStartup khi infrastructure + migrations sẵn sàng.
final class InMemoryPricingModule implements IPricingModule {
  InMemoryPricingModule() {
    _seed();
  }

  static const _currency = 'VND';
  static const _actorName = 'Quản trị viên';
  static const _actorId = 'demo-user-1';

  final List<_RuleRecord> _rules = [];
  final Map<String, List<CustomerPriceRuleActivityDto>> _history = {};
  final Map<String, _ImportRecord> _imports = {};
  int _nextRuleSeq = 1;
  int _nextImportSeq = 1;
  int _nextActivitySeq = 1;

  /// Tra cứu giá advisory (list/sàn) theo productId — phục vụ D-05 create mode.
  ({
    int? listPriceMinor,
    int? floorPriceMinor,
    bool floorPriceHidden,
  })?
  lookupProductAdvisory(String productId) {
    for (final product in _products) {
      if (product.id != productId) continue;
      final floor = product.floorMinor;
      if (floor <= 0) {
        return (
          listPriceMinor: null,
          floorPriceMinor: null,
          floorPriceHidden: true,
        );
      }
      return (
        listPriceMinor: floor + (floor ~/ 5),
        floorPriceMinor: floor,
        floorPriceHidden: false,
      );
    }
    return null;
  }

  // ── Seed data ──

  static const _customers = [
    (id: 'KH000123', name: 'Trại Minh An'),
    (id: 'KH000456', name: 'Mai Phương Retail'),
    (id: 'KH000789', name: 'Long Biên Vet'),
    (id: 'KH000321', name: 'Vịt Thắng Farm'),
  ];

  /// floorMinor = giá sàn theo đơn vị đồng để tính cảnh báo below_floor.
  static const _products = [
    (
      id: 'product-1',
      name: 'Vaccine tai xanh THI-50',
      unitId: 'unit-1a',
      unitName: 'Lọ',
      floorMinor: 150000,
    ),
    (
      id: 'product-2',
      name: 'Kháng sinh ANK-500',
      unitId: 'unit-2a',
      unitName: 'Hộp',
      floorMinor: 90000,
    ),
    (
      id: 'product-3',
      name: 'Men tiêu hóa BIO-COLI',
      unitId: 'unit-3a',
      unitName: 'Gói',
      floorMinor: 70000,
    ),
  ];

  void _seed() {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    _createSeedRule(
      customer: _customers[0],
      product: _products[0],
      priceMinor: 180000,
      effectiveFrom: today.subtract(const Duration(days: 30)),
    );
    _createSeedRule(
      customer: _customers[1],
      product: _products[1],
      priceMinor: 85000, // dưới giá sàn → cảnh báo
      effectiveFrom: today.subtract(const Duration(days: 10)),
      effectiveTo: today.add(const Duration(days: 60)),
    );
    _createSeedRule(
      customer: _customers[2],
      product: _products[2],
      priceMinor: 75000,
      effectiveFrom: today.subtract(const Duration(days: 90)),
      disabled: true,
    );
    _createSeedRule(
      customer: _customers[3],
      product: _products[0],
      priceMinor: 175000,
      effectiveFrom: today.add(const Duration(days: 7)),
    );
  }

  void _createSeedRule({
    required ({String id, String name}) customer,
    required ({
      String id,
      String name,
      String unitId,
      String unitName,
      int floorMinor,
    })
    product,
    required int priceMinor,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    bool disabled = false,
  }) {
    final rule = _RuleRecord(
      id: 'rule-${_nextRuleSeq++}',
      customerId: customer.id,
      customerName: customer.name,
      productId: product.id,
      productName: product.name,
      productUnitId: product.unitId,
      unitName: product.unitName,
      priceMinor: priceMinor,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      sourceType: CustomerPriceRuleSourceType.manual,
      status: disabled ? CustomerPriceRuleStatus.disabled : CustomerPriceRuleStatus.active,
      version: 1,
      createdAt: effectiveFrom,
      updatedAt: effectiveFrom,
      disabledAt: disabled ? effectiveFrom.add(const Duration(days: 5)) : null,
      disabledReason: disabled ? 'Điều chỉnh chính sách giá' : null,
    );
    _rules.add(rule);
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.created,
      oldValue: null,
      newValue: {'rule_price_minor': priceMinor, 'version': 1},
    );
  }

  // ── IModuleMediator ──

  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    return switch (command) {
      CreateCustomerPriceRuleCommand value => _create<TResult>(value),
      UpdateCustomerPriceRuleCommand value => _update<TResult>(value),
      DisableCustomerPriceRuleCommand value => _disable<TResult>(value),
      DeleteCustomerPriceRuleCommand value => _delete<TResult>(value),
      ReenableCustomerPriceRuleCommand value => _reenable<TResult>(value),
      StartCustomerPriceRuleImportCommand value => _importStart<TResult>(value),
      ConfirmCustomerPriceRuleImportCommand value => _importConfirm<TResult>(value),
      CancelCustomerPriceRuleImportCommand value => _importCancel<TResult>(value),
      _ => throw UnsupportedError(
        'InMemoryPricingModule: unsupported command ${command.runtimeType}',
      ),
    };
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    return switch (query) {
      SearchCustomerPriceRulesQuery value => _search<TResult>(value),
      GetCustomerPriceRuleDetailQuery value => _detail<TResult>(value),
      ResolveApplicableCustomerPriceRuleQuery value =>
          _resolveApplicable<TResult>(value),
      PrecheckCustomerPriceRuleReenableQuery value => _reenablePrecheck<TResult>(value),
      GetCustomerPriceRuleHistoryQuery value => _historyQuery<TResult>(value),
      GetCustomerPriceRuleImportTemplateQuery value => _importTemplate<TResult>(value),
      GetCustomerPriceRuleImportQuery value => _importGet<TResult>(value),
      _ => throw UnsupportedError(
        'InMemoryPricingModule: unsupported query ${query.runtimeType}',
      ),
    };
  }

  // ── Queries ──

  Future<TResult> _search<TResult>(SearchCustomerPriceRulesQuery query) async {
    await _latency();
    final businessDate = query.businessDate;
    Iterable<_RuleRecord> result = _rules.where(
      (r) => r.status != CustomerPriceRuleStatus.deleted,
    );

    final q = query.q?.toLowerCase();
    if (q != null && q.isNotEmpty) {
      result = result.where(
        (r) => r.customerName.toLowerCase().contains(q) || r.productName.toLowerCase().contains(q),
      );
    }
    if (query.customerId != null) {
      result = result.where((r) => r.customerId == query.customerId);
    }
    if (query.productId != null) {
      result = result.where((r) => r.productId == query.productId);
    }
    switch (query.quickFilter) {
      case CustomerPriceRuleQuickFilter.applying:
        result = result.where(
          (r) => r.derivedStatus(businessDate) == CustomerPriceRuleDerivedStatus.applying,
        );
      case CustomerPriceRuleQuickFilter.belowFloor:
        result = result.where((r) => r.isBelowFloor);
      case CustomerPriceRuleQuickFilter.all:
        break;
    }
    if (query.statuses.isNotEmpty) {
      result = result.where(
        (r) => query.statuses.contains(r.derivedStatus(businessDate)),
      );
    }
    if (query.sources.isNotEmpty) {
      result = result.where((r) => query.sources.contains(r.sourceType));
    }

    final items = result.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return CustomerPriceRuleSearchResultDto(
          page: CursorPageDto(
            items: List.unmodifiable(
              items.map((r) => r.toListItem(businessDate)),
            ),
            hasMore: false,
          ),
          availableActions: const [
            PricingAvailableActions.createManual,
            PricingAvailableActions.import,
          ],
        )
        as TResult;
  }

  Future<TResult> _detail<TResult>(GetCustomerPriceRuleDetailQuery query) async {
    await _latency();
    final rule = _find(query.ruleId);
    return rule.toDetail(query.businessDate) as TResult;
  }

  Future<TResult> _reenablePrecheck<TResult>(
    PrecheckCustomerPriceRuleReenableQuery query,
  ) async {
    await _latency();
    // SG-05: không validate duplicate — precheck luôn valid.
    return CustomerPriceRuleReenablePrecheckDto(
          validationOutcome: const RuleValidationOutcomeDto(
            outcome: 'valid',
            warningCodes: [],
            blockingCodes: [],
            floorPriceHidden: true,
          ),
          precheckToken: 'in-memory-precheck-token',
          ruleVersion: query.expectedVersion,
          businessDate: query.businessDate,
        )
        as TResult;
  }

  Future<TResult> _historyQuery<TResult>(
    GetCustomerPriceRuleHistoryQuery query,
  ) async {
    await _latency();
    if (!_rules.any((r) => r.id == query.ruleId)) {
      throw const PricingBlockedException(PricingBlockedCodes.notFound);
    }
    final items = List.of(_history[query.ruleId] ?? const [])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return CursorPageDto<CustomerPriceRuleActivityDto>(
          items: List.unmodifiable(items),
          hasMore: false,
        )
        as TResult;
  }

  // ── Commands ──

  Future<TResult> _create<TResult>(CreateCustomerPriceRuleCommand command) async {
    await _latency();
    final duplicate = _findOverlapping(
      customerId: command.customerId,
      productUnitId: command.productUnitId,
      effectiveFrom: command.effectiveFrom,
      effectiveTo: command.effectiveTo,
    );

    if (duplicate != null) {
      throw PricingBlockedException(
        PricingBlockedCodes.duplicateActiveRule,
        details: {'conflictingRuleId': duplicate.id},
      );
    }

    final customer = _customers.firstWhere(
      (c) => c.id == command.customerId,
      orElse: () => (id: command.customerId, name: 'Khách hàng'),
    );
    final product = _products.firstWhere(
      (p) => p.id == command.productId,
      orElse: () => (
        id: command.productId,
        name: 'Sản phẩm',
        unitId: command.productUnitId,
        unitName: 'Đơn vị',
        floorMinor: 0,
      ),
    );

    final now = DateTime.now().toUtc();
    final rule = _RuleRecord(
      id: 'rule-${_nextRuleSeq++}',
      customerId: command.customerId,
      customerName: customer.name,
      productId: command.productId,
      productName: product.name,
      productUnitId: command.productUnitId,
      unitName: product.unitName,
      priceMinor: command.rulePriceMinor,
      effectiveFrom: _calendarDate(command.effectiveFrom),
      effectiveTo: command.effectiveTo == null ? null : _calendarDate(command.effectiveTo!),
      sourceType: CustomerPriceRuleSourceType.manual,
      status: CustomerPriceRuleStatus.active,
      version: 1,
      note: command.note,
      createdAt: now,
      updatedAt: now,
    );
    _rules.add(rule);
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.created,
      oldValue: null,
      newValue: {'rule_price_minor': rule.priceMinor, 'version': 1},
    );

    final warnings = rule.isBelowFloor
        ? const [RuleIssueDto(code: 'below_floor_price')]
        : const <RuleIssueDto>[];
    return CreateCustomerPriceRuleResult(
          rule: rule.toDetail(now),
          warnings: warnings,
        )
        as TResult;
  }

  Future<TResult> _update<TResult>(UpdateCustomerPriceRuleCommand command) async {
    await _latency();
    final rule = _find(command.ruleId);
    final duplicate = _findOverlapping(
      customerId: rule.customerId,
      productUnitId: rule.productUnitId,
      effectiveFrom: command.effectiveFrom,
      effectiveTo: command.effectiveTo,
      excludeRuleId: rule.id,
    );
    if (duplicate != null) {
      _disableInternal(duplicate, reason: 'Bị ghi đè bởi giá riêng mới');
    }

    final oldPrice = rule.priceMinor;
    rule
      ..priceMinor = command.rulePriceMinor
      ..effectiveFrom = _calendarDate(command.effectiveFrom)
      ..effectiveTo = command.effectiveTo == null ? null : _calendarDate(command.effectiveTo!)
      ..note = command.note
      ..version += 1
      ..updatedAt = DateTime.now().toUtc();
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.updated,
      oldValue: {'rule_price_minor': oldPrice, 'version': rule.version - 1},
      newValue: {'rule_price_minor': rule.priceMinor, 'version': rule.version},
    );
    return rule.toDetail(DateTime.now().toUtc()) as TResult;
  }

  Future<TResult> _disable<TResult>(DisableCustomerPriceRuleCommand command) async {
    await _latency();
    final rule = _find(command.ruleId);
    _disableInternal(rule, reason: command.reason);
    return rule.toDetail(DateTime.now().toUtc()) as TResult;
  }

  Future<TResult> _delete<TResult>(DeleteCustomerPriceRuleCommand command) async {
    await _latency();
    final rule = _find(command.ruleId);
    if (rule.status == CustomerPriceRuleStatus.deleted) {
      return rule.toDetail(DateTime.now().toUtc()) as TResult;
    }
    if (rule.status == CustomerPriceRuleStatus.disabled) {
      throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
    }
    if (rule.version != command.expectedVersion) {
      throw const PricingBlockedException(PricingBlockedCodes.stateChanged);
    }
    if (rule.status != CustomerPriceRuleStatus.active &&
        rule.status != CustomerPriceRuleStatus.needsReview) {
      throw const PricingBlockedException(PricingBlockedCodes.invalidStatus);
    }
    final now = DateTime.now().toUtc();
    rule
      ..status = CustomerPriceRuleStatus.deleted
      ..deletedAt = now
      ..version += 1
      ..updatedAt = now;
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.deleted,
      oldValue: {'status': 'active', 'version': rule.version - 1},
      newValue: {'status': 'deleted', 'version': rule.version},
    );
    return rule.toDetail(now) as TResult;
  }

  Future<TResult> _resolveApplicable<TResult>(
    ResolveApplicableCustomerPriceRuleQuery query,
  ) async {
    await _latency();
    final date = _calendarDate(query.businessDate);
    final matches = _rules.where((r) {
      if (r.status != CustomerPriceRuleStatus.active || r.deletedAt != null) {
        return false;
      }
      if (r.customerId != query.customerId ||
          r.productId != query.productId ||
          r.productUnitId != query.productUnitId) {
        return false;
      }
      if (r.effectiveFrom.isAfter(date)) return false;
      final to = r.effectiveTo;
      if (to != null && to.isBefore(date)) return false;
      return true;
    }).toList();
    if (matches.isEmpty) {
      return const ResolveApplicableCustomerPriceRuleResultDto() as TResult;
    }
    if (matches.length > 1) {
      throw const PricingBlockedException(PricingBlockedCodes.systemError);
    }
    final rule = matches.single;
    return ResolveApplicableCustomerPriceRuleResultDto(
          rule: ApplicableCustomerPriceRuleDto(
            ruleId: rule.id,
            price: MoneyDto(
              amountMinor: rule.priceMinor,
              currencyCode: _currency,
            ),
            effectivePeriod: EffectivePeriodDto(
              effectiveFrom: rule.effectiveFrom,
              effectiveTo: rule.effectiveTo,
            ),
            sourceType: rule.sourceType,
            version: rule.version,
          ),
        )
        as TResult;
  }

  Future<TResult> _reenable<TResult>(
    ReenableCustomerPriceRuleCommand command,
  ) async {
    await _latency();
    final rule = _find(command.ruleId);

    // SG-05: không validate duplicate — nếu có rule trùng đang bật thì tự tắt.
    final duplicate = _findOverlapping(
      customerId: rule.customerId,
      productUnitId: rule.productUnitId,
      effectiveFrom: rule.effectiveFrom,
      effectiveTo: rule.effectiveTo,
      excludeRuleId: rule.id,
    );
    if (duplicate != null) {
      _disableInternal(
        duplicate,
        reason: 'Tự động tắt khi bật lại giá riêng ${rule.id}',
      );
    }

    rule
      ..status = CustomerPriceRuleStatus.active
      ..disabledAt = null
      ..disabledReason = null
      ..version += 1
      ..updatedAt = DateTime.now().toUtc();
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.reenabled,
      oldValue: {'status': 'disabled', 'version': rule.version - 1},
      newValue: {'status': 'active', 'version': rule.version},
    );
    return rule.toDetail(DateTime.now().toUtc()) as TResult;
  }

  // ── Import ──

  Future<TResult> _importTemplate<TResult>(
    GetCustomerPriceRuleImportTemplateQuery query,
  ) async {
    await _latency();
    return CustomerPriceRuleImportTemplateDto(
          templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
          fileName: CustomerPriceRuleImportTemplateDto.fileNameV1,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          bytes: Uint8List.fromList(const [0x50, 0x4B, 0x03, 0x04]),
        )
        as TResult;
  }

  Future<TResult> _importStart<TResult>(
    StartCustomerPriceRuleImportCommand command,
  ) async {
    await _latency();
    final id = 'import-${_nextImportSeq++}';
    final rows = _buildImportRows(id);
    final record = _ImportRecord(
      id: id,
      fileName: command.originalFileName,
      rows: rows,
      status: CustomerPriceRuleImportStatus.readyToImport,
      version: 1,
      createdAt: DateTime.now().toUtc(),
    );
    _imports[id] = record;
    return record.toDetail() as TResult;
  }

  List<CustomerPriceRuleImportRowPreviewDto> _buildImportRows(String importId) {
    final rows = <CustomerPriceRuleImportRowPreviewDto>[];
    var rowNumber = 2;
    var index = 0;
    for (final entry in [
      (customer: _customers[0], product: _products[0], priceMinor: 160000),
      (customer: _customers[0], product: _products[1], priceMinor: 95000),
      (customer: _customers[1], product: _products[2], priceMinor: 72000),
    ]) {
      final duplicate = _findOverlapping(
        customerId: entry.customer.id,
        productUnitId: entry.product.unitId,
        effectiveFrom: DateTime.now().toUtc(),
      );
      rows.add(
        CustomerPriceRuleImportRowPreviewDto(
          id: '$importId-row-${index++}',
          rowNumber: rowNumber++,
          ruleId: null,
          customerId: entry.customer.id,
          productReferenceId: entry.product.id,
          price: '${entry.priceMinor}',
          effectiveFrom: null,
          effectiveTo: null,
          note: null,
          status: duplicate == null
              ? CustomerPriceRuleImportRowStatus.valid
              : CustomerPriceRuleImportRowStatus.error,
          action: duplicate == null
              ? CustomerPriceRuleImportAction.create
              : CustomerPriceRuleImportAction.skip,
          errorCodes: duplicate == null ? const [] : const ['DUPLICATE_ACTIVE_RULE'],
          warningCodes: const [],
          customerSnapshot: {'displayName': entry.customer.name},
          productSnapshot: {'productName': entry.product.name},
          normalizedPriceMinor: entry.priceMinor,
        ),
      );
    }
    // 1 dòng cảnh báo: thiếu ngày hiệu lực → mặc định hôm nay.
    rows.add(
      CustomerPriceRuleImportRowPreviewDto(
        id: '$importId-row-${index++}',
        rowNumber: rowNumber,
        ruleId: null,
        customerId: _customers[3].id,
        productReferenceId: _products[2].id,
        price: '68000',
        effectiveFrom: null,
        effectiveTo: null,
        note: null,
        status: CustomerPriceRuleImportRowStatus.warning,
        action: CustomerPriceRuleImportAction.create,
        errorCodes: const [],
        warningCodes: const ['EFFECTIVE_FROM_DEFAULTED'],
        customerSnapshot: {'displayName': _customers[3].name},
        productSnapshot: {'productName': _products[2].name},
        normalizedPriceMinor: 68000,
      ),
    );
    return rows;
  }

  Future<TResult> _importGet<TResult>(
    GetCustomerPriceRuleImportQuery query,
  ) async {
    await _latency();
    final record = _imports[query.importId];
    if (record == null) {
      throw const PricingBlockedException(PricingBlockedCodes.notFound);
    }
    return record.toDetail() as TResult;
  }

  Future<TResult> _importConfirm<TResult>(
    ConfirmCustomerPriceRuleImportCommand command,
  ) async {
    await _latency();
    final record = _imports[command.importId];
    if (record == null) {
      throw const PricingBlockedException(PricingBlockedCodes.notFound);
    }

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    for (final row in record.rows) {
      if (row.status == CustomerPriceRuleImportRowStatus.error) {
        skipped++;
        continue;
      }
      final isWarning = row.status == CustomerPriceRuleImportRowStatus.warning;
      if (isWarning && !command.acknowledgeWarningRows) {
        skipped++;
        continue;
      }
      if (_findImportConflict(row, command.businessDate) != null) {
        failed++;
        continue;
      }
      _importRow(row, command.businessDate);
      imported++;
    }

    record
      ..status = skipped > 0 || failed > 0
          ? CustomerPriceRuleImportStatus.completedWithErrors
          : CustomerPriceRuleImportStatus.completed
      ..importedRows = imported
      ..skippedRows = skipped
      ..failedRows = failed
      ..confirmedAt = DateTime.now().toUtc()
      ..version += 1;

    return CustomerPriceRuleImportResultDto(
          batch: record.toBatch(),
          processedAt: DateTime.now().toUtc(),
          isReplay: false,
        )
        as TResult;
  }

  void _importRow(
    CustomerPriceRuleImportRowPreviewDto row,
    DateTime businessDate,
  ) {
    final customer = _customers.firstWhere(
      (c) => c.id == row.customerId,
      orElse: () => (id: row.customerId ?? 'unknown', name: 'Khách hàng'),
    );
    final product = _products.firstWhere(
      (p) => p.id == row.productReferenceId,
      orElse: () => (
        id: row.productReferenceId ?? 'unknown',
        name: 'Sản phẩm',
        unitId: 'unit-x',
        unitName: 'Đơn vị',
        floorMinor: 0,
      ),
    );

    final now = DateTime.now().toUtc();
    final rule = _RuleRecord(
      id: 'rule-${_nextRuleSeq++}',
      customerId: customer.id,
      customerName: customer.name,
      productId: product.id,
      productName: product.name,
      productUnitId: product.unitId,
      unitName: product.unitName,
      priceMinor: row.normalizedPriceMinor ?? 0,
      effectiveFrom: _calendarDate(businessDate),
      effectiveTo: null,
      sourceType: CustomerPriceRuleSourceType.excelImport,
      status: CustomerPriceRuleStatus.active,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
    _rules.add(rule);
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.importCreated,
      oldValue: null,
      newValue: {'rule_price_minor': rule.priceMinor, 'version': 1},
    );
  }

  Future<TResult> _importCancel<TResult>(
    CancelCustomerPriceRuleImportCommand command,
  ) async {
    await _latency();
    final record = _imports[command.importId];
    if (record == null) {
      throw const PricingBlockedException(PricingBlockedCodes.notFound);
    }
    record
      ..status = CustomerPriceRuleImportStatus.canceled
      ..canceledAt = DateTime.now().toUtc()
      ..version += 1;
    return record.toBatch() as TResult;
  }

  // ── Helpers ──

  _RuleRecord _find(String ruleId) {
    for (final rule in _rules) {
      if (rule.id == ruleId) return rule;
    }
    throw const PricingBlockedException(PricingBlockedCodes.notFound);
  }

  _RuleRecord? _findOverlapping({
    required String customerId,
    required String productUnitId,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? excludeRuleId,
  }) {
    final from = _calendarDate(effectiveFrom);
    final to = effectiveTo == null ? null : _calendarDate(effectiveTo);
    for (final rule in _rules) {
      if (rule.id == excludeRuleId) continue;
      if (rule.status != CustomerPriceRuleStatus.active) continue;
      if (rule.customerId != customerId) continue;
      if (rule.productUnitId != productUnitId) continue;
      final ruleTo = rule.effectiveTo;
      final overlaps =
          (to == null || !rule.effectiveFrom.isAfter(to)) &&
          (ruleTo == null || !from.isAfter(ruleTo));
      if (overlaps) return rule;
    }
    return null;
  }

  _RuleRecord? _findImportConflict(
    CustomerPriceRuleImportRowPreviewDto row,
    DateTime businessDate,
  ) {
    final product = _products.where(
      (candidate) => candidate.id == row.productReferenceId,
    );
    if (row.customerId == null || product.isEmpty) return null;
    final resolvedProduct = product.first;
    return _findOverlapping(
      customerId: row.customerId!,
      productUnitId: resolvedProduct.unitId,
      effectiveFrom: row.normalizedEffectiveFrom ?? businessDate,
      effectiveTo: row.normalizedEffectiveTo,
      excludeRuleId: row.ruleId,
    );
  }

  void _disableInternal(_RuleRecord rule, {String? reason}) {
    if (rule.status == CustomerPriceRuleStatus.disabled) return;
    rule
      ..status = CustomerPriceRuleStatus.disabled
      ..disabledAt = DateTime.now().toUtc()
      ..disabledReason = reason
      ..version += 1
      ..updatedAt = DateTime.now().toUtc();
    _recordActivity(
      rule,
      CustomerPriceRuleActivityType.disabled,
      oldValue: {'status': 'active', 'version': rule.version - 1},
      newValue: {'status': 'disabled', 'version': rule.version},
      reason: reason,
    );
  }

  void _recordActivity(
    _RuleRecord rule,
    CustomerPriceRuleActivityType type, {
    required Map<String, Object?>? oldValue,
    required Map<String, Object?> newValue,
    String? reason,
  }) {
    (_history[rule.id] ??= []).add(
      CustomerPriceRuleActivityDto(
        id: 'activity-${_nextActivitySeq++}',
        activityType: type,
        actor: const CustomerPriceRuleActivityActorDto(
          actorId: _actorId,
          displayName: _actorName,
          isSystemActor: false,
        ),
        sourceType: rule.sourceType,
        oldValue: oldValue == null ? null : Map.unmodifiable(oldValue),
        newValue: Map.unmodifiable(newValue),
        reason: reason,
        sourceTrace: const CustomerPriceRuleActivitySourceTraceDto(),
        sensitiveValuesHidden: false,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  static DateTime _calendarDate(DateTime value) => DateTime.utc(value.year, value.month, value.day);

  static Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 150));
}

// ── Internal records ──

final class _RuleRecord {
  _RuleRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.productUnitId,
    required this.unitName,
    required this.priceMinor,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.sourceType,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.disabledAt,
    this.disabledReason,
    this.deletedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String productId;
  final String productName;
  final String productUnitId;
  final String unitName;
  int priceMinor;
  DateTime effectiveFrom;
  DateTime? effectiveTo;
  final CustomerPriceRuleSourceType sourceType;
  CustomerPriceRuleStatus status;
  int version;
  String? note;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? disabledAt;
  String? disabledReason;
  DateTime? deletedAt;

  int get _floorMinor {
    for (final product in InMemoryPricingModule._products) {
      if (product.id == productId) return product.floorMinor;
    }
    return 0;
  }

  bool get isBelowFloor => _floorMinor > 0 && priceMinor < _floorMinor;

  CustomerPriceRuleDerivedStatus derivedStatus(DateTime businessDate) {
    if (status == CustomerPriceRuleStatus.deleted) {
      return CustomerPriceRuleDerivedStatus.deleted;
    }
    if (status == CustomerPriceRuleStatus.disabled) {
      return CustomerPriceRuleDerivedStatus.disabled;
    }
    if (status == CustomerPriceRuleStatus.needsReview) {
      return CustomerPriceRuleDerivedStatus.needsReview;
    }
    final date = InMemoryPricingModule._calendarDate(businessDate);
    if (effectiveFrom.isAfter(date)) {
      return CustomerPriceRuleDerivedStatus.notYetEffective;
    }
    final to = effectiveTo;
    if (to != null && to.isBefore(date)) {
      return CustomerPriceRuleDerivedStatus.expired;
    }
    return CustomerPriceRuleDerivedStatus.applying;
  }

  /// Giá hiện tại (list) = giá sàn + 20% — đủ để UI D-01/SG-02 hiển thị.
  int get _listPriceMinor {
    final floor = _floorMinor;
    if (floor <= 0) return priceMinor;
    return floor + (floor ~/ 5);
  }

  RuleValidationOutcomeDto get _validationOutcome {
    final floor = _floorMinor;
    final list = _listPriceMinor;
    return RuleValidationOutcomeDto(
      outcome: isBelowFloor ? 'warning' : 'valid',
      warningCodes: isBelowFloor ? const ['below_floor_price'] : const [],
      blockingCodes: const [],
      listPrice: MoneyDto(
        amountMinor: list,
        currencyCode: InMemoryPricingModule._currency,
      ),
      floorPrice: floor > 0
          ? MoneyDto(
              amountMinor: floor,
              currencyCode: InMemoryPricingModule._currency,
            )
          : null,
      floorPriceHidden: false,
    );
  }

  CustomerRefDto get _customerRef => CustomerRefDto(
    customerId: customerId,
    displayName: customerName,
    status: 'active',
  );

  ProductUnitRefDto get _productUnitRef => ProductUnitRefDto(
    productId: productId,
    productName: productName,
    productUnitId: productUnitId,
    unitName: unitName,
    sellableStatus: 'active',
  );

  CustomerPriceRuleListItemDto toListItem(DateTime businessDate) => CustomerPriceRuleListItemDto(
    id: id,
    customer: _customerRef,
    productUnit: _productUnitRef,
    price: MoneyDto(
      amountMinor: priceMinor,
      currencyCode: InMemoryPricingModule._currency,
    ),
    effectivePeriod: EffectivePeriodDto(
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
    ),
    ruleType: CustomerPriceRuleType.specialPrice,
    sourceType: sourceType,
    persistedStatus: status,
    derivedStatus: derivedStatus(businessDate),
    validationOutcome: _validationOutcome,
    updatedAt: updatedAt,
  );

  CustomerPriceRuleDetailDto toDetail(DateTime businessDate) {
    final isDeleted = status == CustomerPriceRuleStatus.deleted;
    final isDisabled = status == CustomerPriceRuleStatus.disabled;
    return CustomerPriceRuleDetailDto(
      id: id,
      customer: _customerRef,
      productUnit: _productUnitRef,
      price: MoneyDto(
        amountMinor: priceMinor,
        currencyCode: InMemoryPricingModule._currency,
      ),
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
      ),
      ruleType: CustomerPriceRuleType.specialPrice,
      sourceType: sourceType,
      persistedStatus: status,
      derivedStatus: derivedStatus(businessDate),
      note: note,
      validationOutcome: _validationOutcome,
      referenceHealth: const CustomerPriceRuleReferenceHealthDto(
        customerState: CustomerPriceRuleReferenceState.valid,
        productUnitState: CustomerPriceRuleReferenceState.valid,
        priceBandState: CustomerPriceRulePriceBandState.current,
        issueCodes: [],
        usedStoredPriceBandSnapshot: false,
      ),
      sourceTrace: const CustomerPriceRuleSourceTraceDto(hidden: false),
      createdBy: InMemoryPricingModule._actorId,
      createdAt: createdAt,
      updatedBy: InMemoryPricingModule._actorId,
      updatedAt: updatedAt,
      version: version,
      availableActions: isDeleted
          ? const []
          : isDisabled
          ? const [
              CustomerPriceRuleAvailableActions.edit,
              CustomerPriceRuleAvailableActions.reenable,
              CustomerPriceRuleAvailableActions.history,
            ]
          : const [
              CustomerPriceRuleAvailableActions.edit,
              CustomerPriceRuleAvailableActions.disable,
              CustomerPriceRuleAvailableActions.history,
            ],
      disabledAt: disabledAt,
      disabledBy: isDisabled ? InMemoryPricingModule._actorId : null,
      disabledReason: disabledReason,
      deletedAt: deletedAt,
    );
  }
}

final class _ImportRecord {
  _ImportRecord({
    required this.id,
    required this.fileName,
    required this.rows,
    required this.status,
    required this.version,
    required this.createdAt,
  });

  final String id;
  final String fileName;
  final List<CustomerPriceRuleImportRowPreviewDto> rows;
  CustomerPriceRuleImportStatus status;
  int version;
  final DateTime createdAt;
  int importedRows = 0;
  int skippedRows = 0;
  int failedRows = 0;
  DateTime? confirmedAt;
  DateTime? canceledAt;

  int get _warningRows =>
      rows.where((r) => r.status == CustomerPriceRuleImportRowStatus.warning).length;

  int get _errorRows =>
      rows.where((r) => r.status == CustomerPriceRuleImportRowStatus.error).length;

  CustomerPriceRuleImportDto toBatch() => CustomerPriceRuleImportDto(
    id: id,
    templateVersion: CustomerPriceRuleImportTemplateDto.versionV1,
    originalFileName: fileName,
    importMode: CustomerPriceRuleImportMode.upsert,
    status: status,
    version: version,
    totalRows: rows.length,
    validRows: rows.length - _warningRows - _errorRows,
    warningRows: _warningRows,
    errorRows: _errorRows,
    importedRows: importedRows,
    skippedRows: skippedRows,
    failedRows: failedRows,
    fileErrorCodes: const [],
    createdAt: createdAt,
    confirmedAt: confirmedAt,
    canceledAt: canceledAt,
  );

  CustomerPriceRuleImportDetailDto toDetail() => CustomerPriceRuleImportDetailDto(
    batch: toBatch(),
    rows: CursorPageDto(items: List.unmodifiable(rows), hasMore: false),
  );
}
