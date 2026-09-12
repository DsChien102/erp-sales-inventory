import '../sales_order_cancellation/commands/confirm_sales_order_cancellation/confirm_sales_order_cancellation_command.dart';
import '../sales_order_cancellation/ports/i_sales_order_cancellation_gateway.dart';
import '../sales_order_cancellation/queries/get_sales_order_cancellation/get_sales_order_cancellation_query.dart';
import '../sales_order_cancellation/queries/list_sales_order_cancellation_reasons/list_sales_order_cancellation_reasons_query.dart';
import '../sales_order_cancellation/queries/precheck_sales_order_cancellation/precheck_sales_order_cancellation_query.dart';
import '../shared/cancellation_precheck_dto.dart';
import '../shared/cancellation_reason_dto.dart';
import '../shared/cancellation_reason_policy_dto.dart';
import '../shared/sales_blocker_dto.dart';
import '../shared/sales_contract_enums.dart';
import '../shared/sales_order_cancellation_detail_dto.dart';
import '../shared/sales_order_cancellation_result_dto.dart';

final class FakeSalesOrderCancellationGateway implements ISalesOrderCancellationGateway {
  FakeSalesOrderCancellationGateway({
    CancellationPrecheckDto? precheckResult,
    SalesOrderCancellationResultDto? confirmResult,
    SalesOrderCancellationDetailDto? detailResult,
    List<CancellationReasonPolicyDto>? reasonPolicies,
    this.error,
  }) : _precheckResult = precheckResult,
       _confirmResult = confirmResult,
       _detailResult = detailResult,
       _reasonPolicies = reasonPolicies;

  final CancellationPrecheckDto? _precheckResult;
  final SalesOrderCancellationResultDto? _confirmResult;
  final SalesOrderCancellationDetailDto? _detailResult;
  final List<CancellationReasonPolicyDto>? _reasonPolicies;
  final Object? error;

  int precheckCalls = 0;
  int confirmCalls = 0;
  int detailCalls = 0;
  int listReasonsCalls = 0;

  PrecheckSalesOrderCancellationQuery? lastPrecheckQuery;
  ConfirmSalesOrderCancellationCommand? lastConfirmCommand;
  GetSalesOrderCancellationQuery? lastDetailQuery;
  ListSalesOrderCancellationReasonsQuery? lastListReasonsQuery;

  @override
  Future<CancellationPrecheckDto> precheck(
    PrecheckSalesOrderCancellationQuery query,
  ) async {
    precheckCalls += 1;
    lastPrecheckQuery = query;
    if (error != null) throw error!;
    return _precheckResult ??
        CancellationPrecheckDto(
          allowed: true,
          sourceVersion: 1,
          sourceSettlementVersion: 1,
          blockers: const <SalesBlockerDto>[],
        );
  }

  @override
  Future<SalesOrderCancellationResultDto> confirm(
    ConfirmSalesOrderCancellationCommand command,
  ) async {
    confirmCalls += 1;
    lastConfirmCommand = command;
    if (error != null) throw error!;
    return _confirmResult ??
        const SalesOrderCancellationResultDto(
          cancellationId: 'cancellation-1',
          salesOrderId: 'order-1',
          salesOrderVersion: 2,
          status: SalesOrderCancellationStatus.confirmed,
        );
  }

  @override
  Future<SalesOrderCancellationDetailDto> getDetail(
    GetSalesOrderCancellationQuery query,
  ) async {
    detailCalls += 1;
    lastDetailQuery = query;
    if (error != null) throw error!;
    return _detailResult ??
        SalesOrderCancellationDetailDto(
          result: const SalesOrderCancellationResultDto(
            cancellationId: 'cancellation-1',
            salesOrderId: 'order-1',
            salesOrderVersion: 2,
            status: SalesOrderCancellationStatus.confirmed,
          ),
          reason: const CancellationReasonDto(
            reasonText: 'Customer request',
          ),
          cancelledAt: DateTime.utc(2026, 8, 10),
          cancelledByActorId: 'actor-1',
          netConfirmedCollectionMinor: 0,
        );
  }

  @override
  Future<List<CancellationReasonPolicyDto>> listReasons(
    ListSalesOrderCancellationReasonsQuery query,
  ) async {
    listReasonsCalls += 1;
    lastListReasonsQuery = query;
    if (error != null) throw error!;
    return _reasonPolicies ?? const <CancellationReasonPolicyDto>[];
  }
}
