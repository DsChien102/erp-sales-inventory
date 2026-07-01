import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/cqrs_registrar_generator.dart';
import 'package:vet45_generator/src/package_config_resolver.dart';

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late String packageRoot;

  setUpAll(() {
    packageRoot = resolveGeneratorPackageRoot();
  });

  group('PackageConfigResolver', () {
    test('matches handler file globs and excludes configuration interfaces', () {
      final files = PackageConfigResolver.listMatchingDartFiles(
        packageRoot: packageRoot,
        scanGlobs: const [
          'test/fixtures/lib/src/**/*_command_handler.dart',
        ],
      );

      expect(files, hasLength(3));
      expect(files.any((path) => path.endsWith('checkout_command_handler.dart')), isTrue);
      expect(files.any((path) => path.endsWith('attach_customer_command_handler.dart')), isTrue);
      expect(files.any((path) => path.endsWith('create_task_command_handler.dart')), isTrue);
    });
  });

  group('CqrsRegistrarGenerator', () {
    test('generates business, internal, query, and validator registrations', () async {
      final config = CodegenModuleConfig(
        moduleName: 'test',
        scanPackage: 'vet45_generator',
        scanGlobs: const [
          'test/fixtures/lib/src/**/*_command_handler.dart',
          'test/fixtures/lib/src/**/*_query_handler.dart',
          'test/fixtures/lib/src/**/*_command_validator.dart',
        ],
        importDomain: false,
        applicationPackage: 'vet45_generator',
        commandBusType: 'TestCommandBus',
        queryBusType: 'TestQueryBus',
        registrationClass: 'TestCommandRegistration',
        internalCommandClientType: 'ITestInternalCommandClient',
        commandRegistrationImport: '../test_command_registration.dart',
        internalCommandClientImport: '../../processing/internal_commands/supabase_test_internal_command_client.dart',
      );

      final output = await CqrsRegistrarGenerator.generate(
        packageRoot: packageRoot,
        config: config,
      );

      expect(output, contains('registerGeneratedTestValidators'));
      expect(
        output,
        contains(
          'registerFactory<ICommandValidator<CheckoutCommand>>('
          '\n      CheckoutCommandValidator.new,',
        ),
      );
      expect(output, contains('registerBusinessHandler<CheckoutCommand, String, CheckoutHandler>'));
      expect(output, contains('registerInternalHandler<AttachCustomerCommand, AttachCustomerHandler>'));
      expect(output, contains('registerQueryHandler<GetOrdersQuery, OrdersDto, GetOrdersQueryHandler>'));
      expect(output, contains('draftRepository: container.get<DraftRepository>()'));
      expect(output, contains("import 'package:vet45_shared_infrastructure/infrastructure.dart';"));
      expect(output, contains('required TestCommandBus bus'));
      expect(output, isNot(contains('uuid:')));
      expect(output, isNot(contains('/domain.dart')));
    });
  });
}
