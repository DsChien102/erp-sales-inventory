import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/cqrs_infrastructure_generator.dart';
import 'package:test/test.dart';

void main() {
  group('CqrsInfrastructureGenerator', () {
    late CodegenModuleConfig config;

    setUp(() {
      config = CodegenModuleConfig(
        moduleName: 'sales',
        scanPackage: 'vet45_sales_application',
        scanGlobs: const [],
        importDomain: false,
        applicationPackage: 'vet45_sales_application',
        internalCommandClientType: 'ISalesInternalCommandClient',
        commandRegistrationImport: 'sales_command_registration.g.dart',
        commandBusExtensionsImport: 'sales_command_bus_extensions.g.dart',
        commandPipelineImport: '../sales_command_pipeline.dart',
        commandPipelineClass: 'SalesCommandPipeline',
        internalCommandClientImport:
            '../internal_commands/supabase_sales_internal_command_client.dart',
      );
    });

    test('generates command registration helper', () {
      final output = CqrsInfrastructureGenerator.generateCommandRegistration(config);

      expect(output, contains('abstract final class SalesCommandRegistration'));
      expect(output, contains('registerBusinessHandler<'));
      expect(output, contains('registerInternalHandler<'));
      expect(output, contains('registerQueryHandler<'));
      expect(output, contains('ISalesInternalCommandClient commandClient'));
      expect(
        output,
        contains("import 'sales_command_bus_extensions.g.dart';"),
      );
      expect(output, isNot(contains('vet45_sales_application/application.dart')));
    });

    test('does not import module application barrel', () {
      final output = CqrsInfrastructureGenerator.generateCommandBusExtensions(config);

      expect(output, isNot(contains('vet45_sales_application/application.dart')));

      expect(output, contains('extension SalesCommandBusBusinessCommands on CommandBus'));
      expect(output, contains('extension SalesCommandBusInternalCommands on CommandBus'));
      expect(output, contains('SalesCommandPipeline.buildBusinessPipeline'));
      expect(output, contains('SalesCommandPipeline.buildInternalPipeline'));
      expect(output, contains('ISalesInternalCommandClient commandClient'));
    });
  });
}
