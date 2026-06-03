import 'dart:io';

import 'package:build/build.dart';

import 'src/codegen_module_config.dart';
import 'src/internal_command_registry_generator.dart';
import 'src/package_config_resolver.dart';

Builder cqrsInternalRegistryBuilder(BuilderOptions options) =>
    _CqrsInternalRegistryBuilder(options);

final class _CqrsInternalRegistryBuilder implements Builder {
  _CqrsInternalRegistryBuilder(this.options);

  final BuilderOptions options;
  late final CodegenModuleConfig _config = CodegenModuleConfig.fromBuilderOptions(
    options,
    defaultScanGlobs: CodegenModuleConfig.defaultInternalCommandScanGlobs,
  );

  @override
  Map<String, List<String>> get buildExtensions => {
    _config.internalRegistryTriggerPath(): [_config.internalRegistryOutputPath()],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generated = await InternalCommandRegistryGenerator.generate(
      packageRoot: PackageConfigResolver.findPackageRoot(
        packageName: buildStep.inputId.package,
        fromDirectory: Directory.current.path,
      ),
      config: _config,
    );

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.internalRegistryOutputPath()),
      generated,
    );
  }
}
