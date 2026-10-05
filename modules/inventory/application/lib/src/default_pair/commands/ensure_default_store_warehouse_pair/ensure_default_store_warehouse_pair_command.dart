import 'package:vet45_inventory_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/ensure_default_store_warehouse_pair_result_dto.dart';

@RequiresPermission(InventoryPermissions.defaultPairEnsure)
final class EnsureDefaultStoreWarehousePairCommand
    extends CommandBase<EnsureDefaultStoreWarehousePairResultDto>
    implements ICommand<EnsureDefaultStoreWarehousePairResultDto> {
  EnsureDefaultStoreWarehousePairCommand({String? id}) : super(id);
}
