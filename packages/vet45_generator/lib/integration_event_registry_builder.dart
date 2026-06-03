import 'dart:io';

import 'package:build/build.dart';

import 'src/codegen_module_config.dart';
import 'src/integration_event_registry_generator.dart';
import 'src/package_config_resolver.dart';

Builder cqrsIntegrationEventRegistryBuilder(BuilderOptions options) =>
    _CqrsIntegrationEventRegistryBuilder(options);

final class _CqrsIntegrationEventRegistryBuilder implements Builder {
  _CqrsIntegrationEventRegistryBuilder(this.options);

  final BuilderOptions options;
  late final CodegenModuleConfig _config = CodegenModuleConfig.fromBuilderOptions(
    options,
    defaultScanGlobs: CodegenModuleConfig.defaultIntegrationEventHandlerScanGlobs,
    requireIntegrationEventDispatchers: true,
  );

  @override
  Map<String, List<String>> get buildExtensions => {
    _config.integrationEventRegistryTriggerPath(): [
      _config.integrationEventRegistryOutputPath(),
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generated = await IntegrationEventRegistryGenerator.generate(
      packageRoot: PackageConfigResolver.findPackageRoot(
        packageName: buildStep.inputId.package,
        fromDirectory: Directory.current.path,
      ),
      config: _config,
    );

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.integrationEventRegistryOutputPath()),
      generated,
    );
  }
}
