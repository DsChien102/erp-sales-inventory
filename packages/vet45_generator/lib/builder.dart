import 'dart:io';

import 'package:build/build.dart';

import 'src/codegen_module_config.dart';
import 'src/cqrs_registrar_generator.dart';
import 'src/package_config_resolver.dart';

Builder cqrsRegistrarBuilder(BuilderOptions options) => _CqrsRegistrarBuilder(options);

final class _CqrsRegistrarBuilder implements Builder {
  _CqrsRegistrarBuilder(this.options);

  final BuilderOptions options;
  late final CodegenModuleConfig _config = CodegenModuleConfig.fromBuilderOptions(
    options,
    defaultScanGlobs: CodegenModuleConfig.defaultHandlerScanGlobs,
  );

  @override
  Map<String, List<String>> get buildExtensions => {
    _config.registrarTriggerPath(): [_config.registrarOutputPath()],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generated = await CqrsRegistrarGenerator.generate(
      packageRoot: PackageConfigResolver.findPackageRoot(
        packageName: buildStep.inputId.package,
        fromDirectory: Directory.current.path,
      ),
      config: _config,
    );

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.registrarOutputPath()),
      generated,
    );
  }
}
