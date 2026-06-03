import 'package:build/build.dart';
import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/module_naming.dart';

import 'package:test/test.dart';

void main() {
  group('ModuleNaming', () {
    test('converts snake_case module name to PascalCase', () {
      expect(ModuleNaming.toPascalCase('sales'), 'Sales');
      expect(ModuleNaming.toPascalCase('purchase_order'), 'PurchaseOrder');
    });

    test('derives sales symbols from module name', () {
      expect(ModuleNaming.applicationPackage('sales'), 'vet45_sales_application');
      expect(ModuleNaming.commandBusType('sales'), 'CommandBus');
      expect(ModuleNaming.queryBusType('sales'), 'QueryBus');
      expect(ModuleNaming.registerHandlersFunction('sales'), 'registerGeneratedSalesHandlers');
      expect(
        ModuleNaming.internalCommandSerializerFunction('sales'),
        'createGeneratedSalesInternalCommandSerializer',
      );
      expect(
        ModuleNaming.commandRegistrationImport('sales'),
        'sales_command_registration.g.dart',
      );
      expect(
        ModuleNaming.commandBusExtensionsImport('sales'),
        'sales_command_bus_extensions.g.dart',
      );
    });
  });

  group('CodegenModuleConfig', () {
    test('fromBuilderOptions requires module_name and scan_package', () {
      expect(
        () => CodegenModuleConfig.fromBuilderOptions(
          BuilderOptions({'scan_package': 'vet45_sales_application'}),
          defaultScanGlobs: CodegenModuleConfig.defaultHandlerScanGlobs,
        ),
        throwsArgumentError,
      );
    });

    test('applies conventions and overrides', () {
      final config = CodegenModuleConfig.fromBuilderOptions(
        BuilderOptions({
          'module_name': 'inventory',
          'scan_package': 'vet45_inventory_application',
          'command_bus_type': 'CustomCommandBus',
          'import_domain': false,
        }),
        defaultScanGlobs: CodegenModuleConfig.defaultHandlerScanGlobs,
      );

      expect(config.resolvedCommandBusType, 'CustomCommandBus');
      expect(config.resolvedQueryBusType, 'QueryBus');
      expect(config.importDomain, isFalse);
      expect(config.registerHandlersFunction(), 'registerGeneratedInventoryHandlers');
    });
  });
}
