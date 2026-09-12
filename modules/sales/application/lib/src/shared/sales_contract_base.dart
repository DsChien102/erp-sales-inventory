import 'package:vet45_shared_application/application.dart';

abstract class SalesMutationContract<TResult> extends CommandBase<TResult>
    implements ICommand<TResult>, ITenantScopedCommand {
  SalesMutationContract({
    String? id,
    this.tenantId = '',
    this.actorId = '',
    required this.idempotencyKey,
    this.payloadHash,
    this.correlationId,
    this.causationId,
    this.expectedSourceVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String idempotencyKey;
  final String? payloadHash;
  final String? correlationId;
  final String? causationId;
  final int? expectedSourceVersion;
}

abstract class SalesReadContract<TResult> extends QueryBase<TResult>
    implements IQuery<TResult>, ITenantScopedCommand {
  SalesReadContract({
    String? id,
    this.tenantId = '',
    this.actorId = '',
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
}
