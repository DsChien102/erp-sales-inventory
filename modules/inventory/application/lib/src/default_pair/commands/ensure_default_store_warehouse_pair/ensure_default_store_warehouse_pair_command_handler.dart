import 'package:vet45_shared_application/application.dart';

import '../../ports/i_default_store_warehouse_pair_port.dart';
import '../../shared/ensure_default_store_warehouse_pair_result_dto.dart';
import 'ensure_default_store_warehouse_pair_command.dart';

@CommandHandlerFor(EnsureDefaultStoreWarehousePairCommand)
final class EnsureDefaultStoreWarehousePairCommandHandler
    implements
        ICommandHandler<
          EnsureDefaultStoreWarehousePairCommand,
          EnsureDefaultStoreWarehousePairResultDto
        > {
  EnsureDefaultStoreWarehousePairCommandHandler({
    required IExecutionContext executionContext,
    required IDefaultStoreWarehousePairPort defaultStoreWarehousePairPort,
  }) : _executionContext = executionContext,
       _port = defaultStoreWarehousePairPort;

  final IExecutionContext _executionContext;
  final IDefaultStoreWarehousePairPort _port;

  @override
  Future<EnsureDefaultStoreWarehousePairResultDto> handle(
    EnsureDefaultStoreWarehousePairCommand command,
  ) async {
    final tenantId = await _executionContext.requireTenantId();
    return _port.ensure(
      tenantId: tenantId,
      correlationId: _executionContext.correlationId,
    );
  }
}
