import 'package:build/build.dart';

import 'src/codegen_module_config.dart';
import 'src/cqrs_infrastructure_generator.dart';

Builder cqrsInfrastructureBuilder(BuilderOptions options) =>
    _CqrsInfrastructureBuilder(options);

final class _CqrsInfrastructureBuilder implements Builder {
  _CqrsInfrastructureBuilder(this.options);

  final BuilderOptions options;
  late final CodegenModuleConfig _config = CodegenModuleConfig.fromBuilderOptions(
    options,
    defaultScanGlobs: const [],
  );

  @override
  Map<String, List<String>> get buildExtensions => {
    _config.infrastructureTriggerPath(): [
      _config.commandBusExtensionsOutputPath(),
      _config.commandRegistrationOutputPath(),
    ],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final commandBusExtensions =
        CqrsInfrastructureGenerator.generateCommandBusExtensions(_config);
    final commandRegistration =
        CqrsInfrastructureGenerator.generateCommandRegistration(_config);

    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.commandBusExtensionsOutputPath()),
      commandBusExtensions,
    );
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, _config.commandRegistrationOutputPath()),
      commandRegistration,
    );
  }
}
