import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_contract_enums.dart';
import '../../../shared/return_exchange_result_dto.dart';

@RequiresPermission(SalesPermissions.confirmReturnExchange)
@RequiresTenant()
final class ConfirmReturnExchangeCommand extends SalesMutationContract<ReturnExchangeResultDto> {
  ConfirmReturnExchangeCommand({
    super.id,
    super.tenantId,
    super.actorId,
    required this.returnExchangeId,
    required super.idempotencyKey,
    required super.payloadHash,
    required super.correlationId,
    super.causationId,
    required int expectedVersion,
    this.settledNowMinor,
    this.paymentMethod = SalesPaymentMethod.cash,
    this.paymentDueDate,
  }) : super(expectedSourceVersion: expectedVersion);

  final String returnExchangeId;
  int get expectedVersion => expectedSourceVersion!;

  /// Amount the customer pays at confirmation. Null defers to the server's
  /// full-remainder default.
  final int? settledNowMinor;

  /// Method for the amount collected now.
  final SalesPaymentMethod paymentMethod;

  /// Due date for the shortfall booked as customer debt (required by the
  /// backend when a collect balance is left outstanding).
  final DateTime? paymentDueDate;

  ConfirmReturnExchangeCommand withExecutionContext({
    required String tenantId,
    required String actorId,
  }) => ConfirmReturnExchangeCommand(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    returnExchangeId: returnExchangeId,
    idempotencyKey: idempotencyKey,
    payloadHash: payloadHash!,
    correlationId: correlationId!,
    causationId: causationId,
    expectedVersion: expectedVersion,
    settledNowMinor: settledNowMinor,
    paymentMethod: paymentMethod,
    paymentDueDate: paymentDueDate,
  );
}
