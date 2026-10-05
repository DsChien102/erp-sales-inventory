import 'package:vet45_shared_application/application.dart';

import 'ensure_default_store_warehouse_pair_command.dart';

final class EnsureDefaultStoreWarehousePairCommandValidator
    implements ICommandValidator<EnsureDefaultStoreWarehousePairCommand> {
  const EnsureDefaultStoreWarehousePairCommandValidator();

  @override
  Future<void> validate(
    EnsureDefaultStoreWarehousePairCommand command,
  ) async {}
}
