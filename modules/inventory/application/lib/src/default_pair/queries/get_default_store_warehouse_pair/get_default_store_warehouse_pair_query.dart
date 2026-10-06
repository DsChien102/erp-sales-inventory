import 'package:vet45_inventory_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/default_store_warehouse_pair_dto.dart';

@RequiresPermission(InventoryPermissions.defaultPairRead)
final class GetDefaultStoreWarehousePairQuery extends QueryBase<DefaultStoreWarehousePairDto>
    implements IQuery<DefaultStoreWarehousePairDto> {
  GetDefaultStoreWarehousePairQuery({String? id}) : super(id);
}
