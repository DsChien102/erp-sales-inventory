import 'dart:io';

import 'package:build/build.dart';

import 'src/access_metadata_generator.dart';
import 'src/codegen_module_config.dart';
import 'src/package_config_resolver.dart';

Builder accessMetadataBuilder(BuilderOptions options) => _AccessMetadataBuilder(options);

final class _AccessMetadataBuilder implements Builder {
  _AccessMetadataBuilder(this.options);

  final BuilderOptions options;
  late final CodegenModuleConfig _config = CodegenModuleConfig.fromBuilderOptions(
    options,
    defaultScanGlobs: CodegenModuleConfig.defaultHandlerScanGlobs,
  );

  @override
  Map<String, List<String>> get buildExtensions => {
    'lib/src/configuration/processing/processing_module.dart': [
      _config.accessMetadataOutputPath(),
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generated = await AccessMetadataGenerator.generate(
      packageRoot: PackageConfigResolver.findPackageRoot(
        packageName: buildStep.inputId.package,
        fromDirectory: Directory.current.path,
      ),
      config: _config,
      strict: _config.strictAccessMetadata,
    );

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.accessMetadataOutputPath()),
      generated,
    );
  }
}
