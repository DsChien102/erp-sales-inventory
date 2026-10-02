import '../../shared/return_exchange_detail_dto.dart';
import '../../shared/return_exchange_form_policy_dto.dart';
import '../../shared/return_exchange_precheck_dto.dart';
import '../../shared/return_exchange_pricing_preview_dto.dart';
import '../../shared/return_exchange_valuation_dto.dart';
import '../../shared/returnable_order_lines_dto.dart';
import '../queries/evaluate_return_pricing_impact/evaluate_return_pricing_impact_query.dart';
import '../queries/get_return_exchange_detail/get_return_exchange_detail_query.dart';
import '../queries/get_return_exchange_form_policy/get_return_exchange_form_policy_query.dart';
import '../queries/get_returnable_order_lines/get_returnable_order_lines_query.dart';
import '../queries/precheck_return_exchange/precheck_return_exchange_query.dart';
import '../queries/preview_return_exchange_pricing/preview_return_exchange_pricing_query.dart';
import '../shared/return_exchange_context.dart';
import 'i_return_exchange_reference_port.dart';

abstract interface class IReturnExchangeReadGateway {
  Future<ReturnExchangePrecheckDto> precheck(
    PrecheckReturnExchangeQuery query,
  );

  Future<ReturnableOrderLinesDto> getReturnableLines(
    GetReturnableOrderLinesQuery query,
  );

  Future<ReturnExchangeFormPolicyDto> getFormPolicy(
    GetReturnExchangeFormPolicyQuery query,
  );

  Future<ReturnExchangeDetailDto> getDetail(
    GetReturnExchangeDetailQuery query,
  );

  Future<ReturnExchangeContext> getContext({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
  });

  Future<ReturnExchangeValuationDto> evaluate(
    EvaluateReturnPricingImpactQuery query, {
    required ReturnExchangeReferenceDecision referenceDecision,
  });

  Future<ReturnExchangePricingPreviewDto> previewPricing(
    PreviewReturnExchangePricingQuery query,
  );
}
