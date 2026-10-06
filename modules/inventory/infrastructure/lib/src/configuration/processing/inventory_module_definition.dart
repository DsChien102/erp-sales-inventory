import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_inventory_domain/domain.dart';

@ModuleManifest(
  name: 'inventory',
  permissions: [
    InventoryPermissions.defaultPairEnsure,
    InventoryPermissions.defaultPairRead,
  ],
)
final class InventoryModuleDefinition {}
