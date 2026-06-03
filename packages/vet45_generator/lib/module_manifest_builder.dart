import 'dart:io';

import 'package:build/build.dart';

import 'src/codegen_module_config.dart';
import 'src/module_manifest_generator.dart';
import 'src/package_config_resolver.dart';

Builder moduleManifestBuilder(BuilderOptions options) => _ModuleManifestBuilder(options);

final class _ModuleManifestBuilder implements Builder {
  _ModuleManifestBuilder(this.options);

  final BuilderOptions options;
  late final CodegenModuleConfig _config = CodegenModuleConfig.fromBuilderOptions(
    options,
    defaultScanGlobs: CodegenModuleConfig.defaultHandlerScanGlobs,
  );

  @override
  Map<String, List<String>> get buildExtensions => {
    'lib/src/configuration/processing/processing_module.dart': [
      _config.moduleManifestOutputPath(),
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generated = await ModuleManifestGenerator.generate(
      packageRoot: PackageConfigResolver.findPackageRoot(
        packageName: buildStep.inputId.package,
        fromDirectory: Directory.current.path,
      ),
      config: _config,
    );

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.moduleManifestOutputPath()),
      generated,
    );
  }
}
