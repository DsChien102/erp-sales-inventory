import 'package:get_it/get_it.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/models.dart' as pricing;
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:erp/features/pricing/logic/pricing_error_messages.dart';
import 'package:vet45_sales_application/application.dart' as sales;
import 'package:erp/features/sales/presentation.dart';

import 'sales_pricing_ports.dart';

abstract final class SalesPricingLookup {
  static SalesPricingPreviewFn bindPreview([GetIt? container]) {
    final di = container ?? GetIt.instance;
    return (request) => _preview(di, request);
  }

  static SalesManualPriceEvaluateFn bindEvaluate([GetIt? container]) {
    final di = container ?? GetIt.instance;
    return (request) => _evaluate(di, request);
  }

  static SalesPrivatePriceSaveFn bindSavePrivate([GetIt? container]) {
    final di = container ?? GetIt.instance;
    return (request) => _savePrivate(di, request);
  }

  static Future<SalesPricingPreviewResult> _preview(
    GetIt di,
    SalesPricingPreviewRequest request,
  ) async {
    try {
      final storeId = await di<SessionController>().requireActiveStoreId();
      final result = await di<SalesPricingRepository>().preview(
        storeId: storeId,
        customerId: request.customerId,
        currencyCode: request.currencyCode,
        contextVersion: request.contextVersion,
        effectiveAt: request.effectiveAt,
        lines: [
          for (final line in request.lines)
            pricing.SalesPricingLineInput(
              localLineId: line.localLineId,
              productId: line.productId,
              productUnitId: line.productUnitId,
              quantityMicros: line.quantityMicros,
              manualUnitPriceMinor: line.manualUnitPriceMinor,
              manualDiscountMinor: line.manualDiscountMinor,
              manualDiscountBasisPoints: line.manualDiscountBasisPoints,
            ),
        ],
      );
      return SalesPricingPreviewResult(
        contextVersion: result.contextVersion,
        previewToken: result.previewToken,
        currencyCode: result.currencyCode,
        lines: [
          for (final line in result.lines)
            SalesPricingLineResult(
              localLineId: line.localLineId,
              appliedUnitPrice: _money(
                line.appliedUnitPriceMinor,
                result.currencyCode,
              ),
              discount: _money(line.discountMinor, result.currencyCode),
              lineTotal: _money(line.lineTotalMinor, result.currencyCode),
              sourceCode: line.sourceCode,
              listUnitPrice: _optionalMoney(
                line.listPriceMinor,
                result.currencyCode,
              ),
              floorUnitPrice: _optionalMoney(
                line.floorPriceMinor,
                result.currencyCode,
              ),
              warningCodes: line.warningCodes,
              blockingCodes: line.blockingCodes,
            ),
        ],
      );
    } on Object catch (error) {
      throw SalesExternalOperationException(_message(error));
    }
  }

  static Future<SalesManualPriceEvaluation> _evaluate(
    GetIt di,
    SalesManualPriceRequest request,
  ) async {
    try {
      final storeId = await di<SessionController>().requireActiveStoreId();
      final result = await di<SalesPricingRepository>().evaluateManualPrice(
        storeId: storeId,
        customerId: request.customerId,
        productId: request.productId,
        productUnitId: request.productUnitId,
        quantityMicros: request.quantityMicros,
        currencyCode: request.currencyCode,
        contextVersion: request.contextVersion,
        manualUnitPriceMinor: request.manualUnitPriceMinor,
        manualDiscountMinor: request.manualDiscountMinor,
        manualDiscountBasisPoints: request.manualDiscountBasisPoints,
        acknowledgeBelowFloor: request.acknowledgeBelowFloor,
      );
      return SalesManualPriceEvaluation(
        allowed: result.allowed,
        requiresAcknowledgement: result.requiresAcknowledgement,
        normalizedUnitPrice: _money(
          result.normalizedUnitPriceMinor,
          request.currencyCode,
        ),
        floorUnitPrice: _optionalMoney(
          result.floorPriceMinor,
          request.currencyCode,
        ),
        canViewFloor: result.canViewFloor,
        warningCodes: result.warningCodes,
        blockingCode: result.blockingCode,
        message: result.message,
      );
    } on Object catch (error) {
      throw SalesExternalOperationException(_message(error));
    }
  }

  static Future<SalesPrivatePriceSaveResult> _savePrivate(
    GetIt di,
    SalesPrivatePriceSaveRequest request,
  ) async {
    final customerId = request.customerId?.trim();
    if (customerId == null || customerId.isEmpty) {
      throw const SalesExternalOperationException(
        'Chọn khách hàng trước khi lưu giá riêng.',
      );
    }
    try {
      final session = di<SessionController>();
      final tenantId = await session.requireTenantId();
      final storeId = await session.requireActiveStoreId();
      final rules = di<CustomerPriceRuleRepository>();
      final existing = await _resolve(rules, request, customerId);
      if (existing != null && !request.confirmOverwrite) {
        return SalesPrivatePriceSaveResult(
          ruleId: existing.ruleId,
          version: existing.version,
          created: false,
          acceptedUnitPrice: request.acceptedUnitPrice,
          overwriteConfirmationRequired: true,
        );
      }
      if (existing != null) {
        return await _update(rules, request, customerId, existing);
      }
      final key = [
        'sales-private-price-v1',
        tenantId,
        storeId,
        request.composeSessionId,
        request.sourceLineId,
        request.manualIntentRevision,
        customerId,
        request.productId,
        request.productUnitId,
        request.currencyCode,
        request.acceptedUnitPrice.amountMinor,
        _date(request.effectiveFrom),
      ].join(':');
      return await _create(rules, request, customerId, key);
    } on SalesExternalOperationException {
      rethrow;
    } on Object catch (error) {
      throw SalesExternalOperationException(_message(error));
    }
  }

  static Future<pricing.ApplicableCustomerPriceRuleDto?> _resolve(
    CustomerPriceRuleRepository rules,
    SalesPrivatePriceSaveRequest request,
    String customerId,
  ) async {
    final result = await rules.resolveApplicable(
      customerId: customerId,
      productId: request.productId,
      productUnitId: request.productUnitId,
      businessDate: request.effectiveFrom,
    );
    return result.rule;
  }

  static Future<SalesPrivatePriceSaveResult> _create(
    CustomerPriceRuleRepository rules,
    SalesPrivatePriceSaveRequest request,
    String customerId,
    String key,
  ) async {
    Future<pricing.CreateCustomerPriceRuleResult> send() => rules.create(
      customerId: customerId,
      productId: request.productId,
      productUnitId: request.productUnitId,
      rulePriceMinor: request.acceptedUnitPrice.amountMinor,
      currencyCode: request.currencyCode,
      effectiveFrom: _calendarDate(request.effectiveFrom),
      acknowledgeFloorWarning: request.acknowledgeFloorWarning,
      idempotencyKey: key,
    );
    try {
      final result = await send();
      return _saved(result.rule, created: true);
    } on Object {
      final recovered = await _resolve(rules, request, customerId);
      if (_matches(recovered, request)) {
        return _savedApplicable(recovered!, created: true);
      }
      if (recovered != null) rethrow;
      final retried = await send();
      return _saved(retried.rule, created: true);
    }
  }

  static Future<SalesPrivatePriceSaveResult> _update(
    CustomerPriceRuleRepository rules,
    SalesPrivatePriceSaveRequest request,
    String customerId,
    pricing.ApplicableCustomerPriceRuleDto existing,
  ) async {
    try {
      final result = await rules.update(
        ruleId: existing.ruleId,
        expectedVersion: existing.version,
        rulePriceMinor: request.acceptedUnitPrice.amountMinor,
        effectiveFrom: _calendarDate(request.effectiveFrom),
        acknowledgeFloorWarning: request.acknowledgeFloorWarning,
        acknowledgeOverwrite: true,
      );
      return _saved(result, created: false);
    } on Object {
      final recovered = await _resolve(rules, request, customerId);
      if (_matches(recovered, request) && recovered!.version > existing.version) {
        return _savedApplicable(recovered, created: false);
      }
      rethrow;
    }
  }

  static bool _matches(
    pricing.ApplicableCustomerPriceRuleDto? rule,
    SalesPrivatePriceSaveRequest request,
  ) =>
      rule != null &&
      rule.price.amountMinor == request.acceptedUnitPrice.amountMinor &&
      rule.price.currencyCode == request.currencyCode;

  static SalesPrivatePriceSaveResult _saved(
    pricing.CustomerPriceRuleDetailDto rule, {
    required bool created,
  }) => SalesPrivatePriceSaveResult(
    ruleId: rule.id,
    version: rule.version,
    created: created,
    acceptedUnitPrice: _money(
      rule.price.amountMinor,
      rule.price.currencyCode,
    ),
  );

  static SalesPrivatePriceSaveResult _savedApplicable(
    pricing.ApplicableCustomerPriceRuleDto rule, {
    required bool created,
  }) => SalesPrivatePriceSaveResult(
    ruleId: rule.ruleId,
    version: rule.version,
    created: created,
    acceptedUnitPrice: _money(
      rule.price.amountMinor,
      rule.price.currencyCode,
    ),
  );

  static sales.MoneyDto _money(int amount, String currency) =>
      sales.MoneyDto(amountMinor: amount, currencyCode: currency);

  static sales.MoneyDto? _optionalMoney(int? amount, String currency) =>
      amount == null ? null : _money(amount, currency);

  static DateTime _calendarDate(DateTime value) => DateTime.utc(value.year, value.month, value.day);

  static String _date(DateTime value) => _calendarDate(value).toIso8601String().substring(0, 10);

  static String _message(Object error) => error is AppException
      ? pricingErrorMessage(error, fallback: 'Thao tác giá bị từ chối.')
      : 'Không thể kết nối dịch vụ giá. Vui lòng thử lại.';
}
