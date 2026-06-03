abstract final class ModuleNaming {
  static String toPascalCase(String moduleName) {
    if (moduleName.isEmpty) {
      throw ArgumentError.value(moduleName, 'moduleName', 'must not be empty');
    }

    return moduleName
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join();
  }

  static String applicationPackage(String moduleName) => 'vet45_${moduleName}_application';

  static String domainPackage(String moduleName) => 'vet45_${moduleName}_domain';

  static String commandBusType(String moduleName) => 'CommandBus';

  static String queryBusType(String moduleName) => 'QueryBus';

  static String registrationClass(String moduleName) =>
      '${toPascalCase(moduleName)}CommandRegistration';

  static String internalCommandClientType(String moduleName) =>
      'I${toPascalCase(moduleName)}InternalCommandClient';

  static String registrarTriggerPath(String moduleName) =>
      'lib/src/configuration/mediation/mediation_module.dart';

  static String registrarOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_cqrs_registrar.g.dart';

  static String internalRegistryTriggerPath(String moduleName) =>
      'lib/src/configuration/processing/processing_module.dart';

  static String internalRegistryOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_internal_command_registry.g.dart';

  static String integrationEventRegistryTriggerPath(String moduleName) =>
      'lib/src/configuration/processing/processing_module.dart';

  static String integrationEventRegistryOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_integration_event_registry.g.dart';

  static String registerValidatorsFunction(String moduleName) =>
      'registerGenerated${toPascalCase(moduleName)}Validators';

  static String registerHandlersFunction(String moduleName) =>
      'registerGenerated${toPascalCase(moduleName)}Handlers';

  static String registerQueriesFunction(String moduleName) =>
      'registerGenerated${toPascalCase(moduleName)}Queries';

  static String internalCommandSerializerFunction(String moduleName) =>
      'createGenerated${toPascalCase(moduleName)}InternalCommandSerializer';

  static String commandRegistrationImport(String moduleName) =>
      '${moduleName}_command_registration.g.dart';

  static String commandBusExtensionsImport(String moduleName) =>
      '${moduleName}_command_bus_extensions.g.dart';

  static String commandPipelineImport(String moduleName) =>
      '../${moduleName}_command_pipeline.dart';

  static String commandPipelineClass(String moduleName) =>
      '${toPascalCase(moduleName)}CommandPipeline';

  static String infrastructureTriggerPath(String moduleName) =>
      'lib/src/configuration/processing/${moduleName}_command_pipeline.dart';

  static String commandRegistrationOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_command_registration.g.dart';

  static String commandBusExtensionsOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_command_bus_extensions.g.dart';

  static String internalCommandClientImport(String moduleName) =>
      '../internal_commands/supabase_${moduleName}_internal_command_client.dart';

  static const defaultAccessScanGlobs = <String>[
    'lib/src/**/*_command.dart',
    'lib/src/**/*_query.dart',
  ];

  static const defaultModuleManifestScanGlobs = <String>[
    'lib/src/configuration/**/*_module_definition.dart',
    'lib/src/configuration/**/*_module.dart',
  ];

  static String accessMetadataOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_access_metadata.g.dart';

  static String accessMetadataRegistryVariable(String moduleName) =>
      '${moduleName}AccessMetadataRegistry';

  static String moduleManifestOutputPath(String moduleName) =>
      'lib/src/configuration/processing/generated/${moduleName}_module_manifest.g.dart';

  static String moduleManifestVariable(String moduleName) =>
      '${moduleName}ModuleManifest';
}
