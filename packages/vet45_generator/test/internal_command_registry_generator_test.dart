import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/internal_command_registry_generator.dart';

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late String packageRoot;

  setUpAll(() {
    packageRoot = resolveGeneratorPackageRoot();
  });

  test('generates internal command serializer registry entries', () async {
    final config = CodegenModuleConfig(
      moduleName: 'test',
      scanPackage: 'vet45_generator',
      scanGlobs: const [
        'test/fixtures/lib/src/**/*_command.dart',
      ],
      applicationPackage: 'vet45_generator',
    );

    final output = await InternalCommandRegistryGenerator.generate(
      packageRoot: packageRoot,
      config: config,
    );

    expect(output, contains("..['sales.test.attach_customer'] = AttachCustomerCommand;"));
    expect(output, contains('AttachCustomerCommand.fromJson'));
    expect(output, contains('createGeneratedTestInternalCommandSerializer'));
  });

  test('omits the application import when no internal commands exist', () async {
    final config = CodegenModuleConfig(
      moduleName: 'test',
      scanPackage: 'vet45_generator',
      scanGlobs: const ['test/fixtures/lib/src/**/*_missing_command.dart'],
      applicationPackage: 'vet45_generator',
    );

    final output = await InternalCommandRegistryGenerator.generate(
      packageRoot: packageRoot,
      config: config,
    );

    expect(output, isNot(contains("package:vet45_generator/application.dart")));
  });
}
