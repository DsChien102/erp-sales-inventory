import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/cqrs_registrar_generator.dart';

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late String packageRoot;

  setUpAll(() {
    packageRoot = resolveGeneratorPackageRoot();
  });

  test('registers handlers annotated with CommandHandlerFor and QueryHandlerFor', () async {
    final config = CodegenModuleConfig(
      moduleName: 'test',
      scanPackage: 'vet45_generator',
      scanGlobs: const [
        'test/fixtures/lib/src/create_task_command_handler.dart',
        'test/fixtures/lib/src/get_task_by_id_query_handler.dart',
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

    expect(output, contains('CreateTaskCommandHandler'));
    expect(output, contains('GetTaskByIdQueryHandler'));
    expect(output, contains('CreateTaskCommand'));
    expect(output, contains('GetTaskByIdQuery'));
  });
}
