import 'package:vet45_generator/src/codegen_module_config.dart';
import 'package:vet45_generator/src/module_manifest_generator.dart';

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late String packageRoot;

  setUpAll(() {
    packageRoot = resolveGeneratorPackageRoot();
  });

  test('generates module manifest from annotation and handlers', () async {
    final config = CodegenModuleConfig(
      moduleName: 'test',
      scanPackage: 'vet45_generator',
      scanGlobs: const [
        'test/fixtures/lib/src/create_task_command_handler.dart',
        'test/fixtures/lib/src/get_task_by_id_query_handler.dart',
      ],
      accessScanPackage: 'vet45_generator',
      accessScanGlobs: const ['test/fixtures/lib/src/create_task_command.dart'],
      moduleManifestScanGlobs: const [
        'test/fixtures/lib/src/configuration/test_module_definition.dart',
      ],
      importDomain: false,
      applicationPackage: 'vet45_generator',
    );

    final output = await ModuleManifestGenerator.generate(
      packageRoot: packageRoot,
      config: config,
    );

    expect(output, contains("name: 'test'"));
    expect(output, contains('task.create'));
    expect(output, contains('CreateTaskCommand'));
    expect(output, contains('GetTaskByIdQuery'));
  });
}
