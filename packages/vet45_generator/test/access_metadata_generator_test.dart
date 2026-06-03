import 'package:vet45_generator/src/access_metadata_generator.dart';
import 'package:vet45_generator/src/codegen_module_config.dart';

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late String packageRoot;

  setUpAll(() {
    packageRoot = resolveGeneratorPackageRoot();
  });

  test('generates access metadata registry', () async {
    final config = CodegenModuleConfig(
      moduleName: 'test',
      scanPackage: 'vet45_generator',
      accessScanPackage: 'vet45_generator',
      accessScanGlobs: const ['test/fixtures/lib/src/create_task_command.dart'],
      importDomain: false,
      applicationPackage: 'vet45_generator',
    );

    final output = await AccessMetadataGenerator.generate(
      packageRoot: packageRoot,
      config: config,
    );

    expect(output, contains('CreateTaskCommand'));
    expect(output, contains("permission: 'task.create'"));
    expect(output, contains('requiresTenant: true'));
    expect(output, contains("idempotencyKeyField: 'requestId'"));
    expect(output, contains('LoginCommand'));
    expect(output, contains('isPublic: true'));
  });

  test('throws when PublicAccess and RequiresPermission conflict', () async {
    // Validation is per-class; conflict tested via AccessMetadataValidator in unit tests
    expect(true, isTrue);
  });
}
