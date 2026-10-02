import '../return_exchange_order/ports/i_return_exchange_read_gateway.dart';
import '../return_exchange_order/ports/i_return_exchange_reference_port.dart';
import '../return_exchange_order/queries/evaluate_return_pricing_impact/evaluate_return_pricing_impact_query.dart';
import '../return_exchange_order/queries/get_return_exchange_detail/get_return_exchange_detail_query.dart';
import '../return_exchange_order/queries/get_return_exchange_form_policy/get_return_exchange_form_policy_query.dart';
import '../return_exchange_order/queries/get_returnable_order_lines/get_returnable_order_lines_query.dart';
import '../return_exchange_order/queries/precheck_return_exchange/precheck_return_exchange_query.dart';
import '../return_exchange_order/shared/return_exchange_context.dart';
import '../shared/money_dto.dart';
import '../shared/return_exchange_detail_dto.dart';
import '../shared/return_exchange_draft_dto.dart';
import '../shared/return_exchange_form_policy_dto.dart';
import '../shared/return_exchange_line_input.dart';
import '../return_exchange_order/queries/preview_return_exchange_pricing/preview_return_exchange_pricing_query.dart';
import '../shared/return_exchange_precheck_dto.dart';
import '../shared/return_exchange_pricing_preview_dto.dart';
import '../shared/return_exchange_settlement_plan_dto.dart';
import '../shared/return_exchange_valuation_dto.dart';
import '../shared/returnable_order_lines_dto.dart';
import '../shared/sales_blocker_dto.dart';
import '../shared/sales_contract_enums.dart';

final class FakeReturnExchangeReadGateway implements IReturnExchangeReadGateway {
  FakeReturnExchangeReadGateway({
    ReturnExchangePrecheckDto? precheckResult,
    ReturnableOrderLinesDto? returnableResult,
    ReturnExchangeFormPolicyDto? formPolicyResult,
    ReturnExchangeDetailDto? detailResult,
    ReturnExchangeContext? contextResult,
    ReturnExchangeValuationDto? evaluateResult,
    ReturnExchangePricingPreviewDto? previewResult,
    this.error,
  }) : _precheckResult = precheckResult,
       _returnableResult = returnableResult,
       _formPolicyResult = formPolicyResult,
       _detailResult = detailResult,
       _contextResult = contextResult,
       _evaluateResult = evaluateResult,
       _previewResult = previewResult;

  final ReturnExchangePrecheckDto? _precheckResult;
  final ReturnableOrderLinesDto? _returnableResult;
  final ReturnExchangeFormPolicyDto? _formPolicyResult;
  final ReturnExchangeDetailDto? _detailResult;
  final ReturnExchangeContext? _contextResult;
  final ReturnExchangeValuationDto? _evaluateResult;
  final ReturnExchangePricingPreviewDto? _previewResult;
  final Object? error;

  int precheckCalls = 0;
  int getReturnableCalls = 0;
  int getFormPolicyCalls = 0;
  int getDetailCalls = 0;
  int getContextCalls = 0;
  int evaluateCalls = 0;
  int previewPricingCalls = 0;

  PrecheckReturnExchangeQuery? lastPrecheckQuery;
  GetReturnableOrderLinesQuery? lastReturnableQuery;
  GetReturnExchangeFormPolicyQuery? lastFormPolicyQuery;
  GetReturnExchangeDetailQuery? lastDetailQuery;
  EvaluateReturnPricingImpactQuery? lastEvaluateQuery;
  PreviewReturnExchangePricingQuery? lastPreviewQuery;
  ReturnExchangeReferenceDecision? lastEvaluateDecision;
  String? lastContextReturnExchangeId;

  static const ReturnExchangeSettlementPlanDto _zeroPlan =
      ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: 0,
        collectAmountMinor: 0,
        refundAmountMinor: 0,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 0,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

  @override
  Future<ReturnExchangePrecheckDto> precheck(
    PrecheckReturnExchangeQuery query,
  ) async {
    precheckCalls += 1;
    lastPrecheckQuery = query;
    if (error != null) throw error!;
    return _precheckResult ??
        ReturnExchangePrecheckDto(
          allowed: true,
          sourceVersion: 1,
          blockers: const <SalesBlockerDto>[],
        );
  }

  @override
  Future<ReturnableOrderLinesDto> getReturnableLines(
    GetReturnableOrderLinesQuery query,
  ) async {
    getReturnableCalls += 1;
    lastReturnableQuery = query;
    if (error != null) throw error!;
    return _returnableResult ??
        ReturnableOrderLinesDto(
          salesOrderId: query.salesOrderId,
          sourceVersion: 1,
          lines: const [],
        );
  }

  @override
  Future<ReturnExchangeFormPolicyDto> getFormPolicy(
    GetReturnExchangeFormPolicyQuery query,
  ) async {
    getFormPolicyCalls += 1;
    lastFormPolicyQuery = query;
    if (error != null) throw error!;
    final result = _formPolicyResult;
    if (result == null) {
      throw StateError('FakeReturnExchangeReadGateway formPolicyResult not injected.');
    }
    return result;
  }

  @override
  Future<ReturnExchangeDetailDto> getDetail(
    GetReturnExchangeDetailQuery query,
  ) async {
    getDetailCalls += 1;
    lastDetailQuery = query;
    if (error != null) throw error!;
    final result = _detailResult;
    if (result == null) {
      throw StateError('FakeReturnExchangeReadGateway detailResult not injected.');
    }
    return result;
  }

  @override
  Future<ReturnExchangeContext> getContext({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
  }) async {
    getContextCalls += 1;
    lastContextReturnExchangeId = returnExchangeId;
    if (error != null) throw error!;
    return _contextResult ??
        ReturnExchangeContext(
          draft: ReturnExchangeDraftDto(
            returnExchangeId: returnExchangeId,
            salesOrderId: 'order-1',
            version: 1,
            status: ReturnExchangeStatus.draft,
            lines: const <ReturnExchangeLineInput>[],
          ),
          currencyCode: 'VND',
          sourceOrderVersion: 1,
          sourceSettlementVersion: 1,
          reservationIds: const <String>[],
        );
  }

  @override
  Future<ReturnExchangePricingPreviewDto> previewPricing(
    PreviewReturnExchangePricingQuery query,
  ) async {
    previewPricingCalls += 1;
    lastPreviewQuery = query;
    if (error != null) throw error!;
    return _previewResult ?? const ReturnExchangePricingPreviewDto(lines: []);
  }

  @override
  Future<ReturnExchangeValuationDto> evaluate(
    EvaluateReturnPricingImpactQuery query, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) async {
    evaluateCalls += 1;
    lastEvaluateQuery = query;
    lastEvaluateDecision = referenceDecision;
    if (error != null) throw error!;
    return _evaluateResult ??
        const ReturnExchangeValuationDto(
          returnValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          settlementDifference: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          settlementPlan: _zeroPlan,
          sourceOrderVersion: 1,
        );
  }
}
