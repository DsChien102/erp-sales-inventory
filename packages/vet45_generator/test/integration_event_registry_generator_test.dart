import 'package:test/test.dart';
import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/integration_event_dispatcher_config.dart';
import 'package:vet45_generator/src/integration_event_registry_generator.dart';

import 'test_helpers.dart';

void main() {
  late String packageRoot;

  setUpAll(() {
    packageRoot = resolveGeneratorPackageRoot();
  });

  group('IntegrationEventRegistryGenerator', () {
    test('generates dispatcher factories with routed handlers and DI deps', () async {
      final config = CodegenModuleConfig(
        moduleName: 'test',
        scanPackage: 'vet45_generator',
        scanGlobs: const [
          'test/fixtures/lib/src/**/*_integration_event_handler.dart',
        ],
        applicationPackage: 'vet45_generator',
        integrationEventDispatchers: [
          IntegrationEventDispatcherConfig(
            id: 'own',
            factoryFunction: 'createGeneratedTestOwnIntegrationEventDispatcher',
            dispatcherClass: 'TestOwnIntegrationEventDispatcher',
            dispatcherImport: '../test_integration_event_dispatchers.dart',
            eventPackages: const ['own_integration_events'],
          ),
          IntegrationEventDispatcherConfig(
            id: 'other',
            factoryFunction: 'createGeneratedTestOtherIntegrationEventDispatcher',
            dispatcherClass: 'TestOtherIntegrationEventDispatcher',
            dispatcherImport: '../test_integration_event_dispatchers.dart',
            eventPackages: const ['other_integration_events'],
          ),
        ],
      );

      final output = await IntegrationEventRegistryGenerator.generate(
        packageRoot: packageRoot,
        config: config,
      );

      expect(output, contains('createGeneratedTestOwnIntegrationEventDispatcher'));
      expect(output, contains('createGeneratedTestOtherIntegrationEventDispatcher'));
      expect(output, contains('register<OwnIntegrationEvent>'));
      expect(output, contains('register<OtherIntegrationEvent>'));
      expect(output, contains('ownGateway: container.get<OwnGateway>()'));
      expect(output, contains('OtherIntegrationEventHandler()'));
      expect(output, contains("import 'package:own_integration_events/integration_events.dart';"));
      expect(output, contains("import 'package:other_integration_events/integration_events.dart';"));
    });

    test('generates empty dispatcher when no handlers match bucket', () async {
      final config = CodegenModuleConfig(
        moduleName: 'empty',
        scanPackage: 'vet45_generator',
        scanGlobs: const [
          'test/fixtures/lib/src/nonexistent/**/*_integration_event_handler.dart',
        ],
        applicationPackage: 'vet45_generator',
        integrationEventDispatchers: [
          IntegrationEventDispatcherConfig(
            id: 'own',
            factoryFunction: 'createGeneratedEmptyIntegrationEventDispatcher',
            dispatcherClass: 'TestOwnIntegrationEventDispatcher',
            dispatcherImport: '../test_integration_event_dispatchers.dart',
            eventPackages: const ['own_integration_events'],
          ),
        ],
      );

      final output = await IntegrationEventRegistryGenerator.generate(
        packageRoot: packageRoot,
        config: config,
      );

      expect(output, contains('final dispatcher = TestOwnIntegrationEventDispatcher();'));
      expect(output, isNot(contains('dispatcher.register<')));
    });

    test('fails when handler event package is not mapped to a dispatcher', () async {
      final config = CodegenModuleConfig(
        moduleName: 'test',
        scanPackage: 'vet45_generator',
        scanGlobs: const [
          'test/fixtures/lib/src/**/*_integration_event_handler.dart',
        ],
        applicationPackage: 'vet45_generator',
        integrationEventDispatchers: [
          IntegrationEventDispatcherConfig(
            id: 'own',
            factoryFunction: 'createGeneratedTestOwnIntegrationEventDispatcher',
            dispatcherClass: 'TestOwnIntegrationEventDispatcher',
            dispatcherImport: '../test_integration_event_dispatchers.dart',
            eventPackages: const ['own_integration_events'],
          ),
        ],
      );

      expect(
        () => IntegrationEventRegistryGenerator.generate(
          packageRoot: packageRoot,
          config: config,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
