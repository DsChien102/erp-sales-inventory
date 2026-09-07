import 'package:build/build.dart';

import 'integration_event_dispatcher_config.dart';
import 'module_naming.dart';

final class CodegenModuleConfig {
  const CodegenModuleConfig({
    required this.moduleName,
    required this.scanPackage,
    this.scanGlobs = defaultHandlerScanGlobs,
    this.importDomain = true,
    this.applicationPackage,
    this.domainPackage,
    this.commandBusType,
    this.queryBusType,
    this.registrationClass,
    this.internalCommandClientType,
    this.commandRegistrationImport,
    this.commandBusExtensionsImport,
    this.commandPipelineImport,
    this.commandPipelineClass,
    this.internalCommandClientImport,
    this.outputPath,
    this.triggerPath,
    this.integrationEventDispatchers = const [],
    this.accessScanGlobs = ModuleNaming.defaultAccessScanGlobs,
    this.accessScanPackage,
    this.handlerScanPackage,
    this.strictAccessMetadata = false,
    this.moduleManifestScanGlobs = ModuleNaming.defaultModuleManifestScanGlobs,
  });

  static const defaultHandlerScanGlobs = <String>[
    'lib/src/**/*_command_handler.dart',
    'lib/src/**/*_query_handler.dart',
    'lib/src/**/*_command_validator.dart',
  ];

  static const defaultInternalCommandScanGlobs = <String>[
    'lib/src/**/*_command.dart',
  ];

  static const defaultIntegrationEventHandlerScanGlobs = <String>[
    'lib/src/**/*_integration_event_handler.dart',
  ];

  static const defaultIntegrationEventScanGlobs = <String>[
    'lib/src/events/**/*_integration_event.dart',
    'lib/src/**/*_integration_event.dart',
  ];

  static const defaultModuleManifestScanGlobs = <String>[
    'lib/src/configuration/**/*_module_definition.dart',
    'lib/src/configuration/**/*_module.dart',
  ];

  final String moduleName;
  final String scanPackage;
  final List<String> scanGlobs;
  final bool importDomain;

  final String? applicationPackage;
  final String? domainPackage;
  final String? commandBusType;
  final String? queryBusType;
  final String? registrationClass;
  final String? internalCommandClientType;
  final String? commandRegistrationImport;
  final String? commandBusExtensionsImport;
  final String? commandPipelineImport;
  final String? commandPipelineClass;
  final String? internalCommandClientImport;
  final String? outputPath;
  final String? triggerPath;
  final List<IntegrationEventDispatcherConfig> integrationEventDispatchers;
  final List<String> accessScanGlobs;
  final String? accessScanPackage;
  final String? handlerScanPackage;
  final bool strictAccessMetadata;
  final List<String> moduleManifestScanGlobs;

  String get pascalCase => ModuleNaming.toPascalCase(moduleName);

  String get resolvedApplicationPackage =>
      applicationPackage ?? ModuleNaming.applicationPackage(moduleName);

  String get resolvedHandlerScanPackage =>
      handlerScanPackage ?? resolvedApplicationPackage;

  String get resolvedDomainPackage =>
      domainPackage ?? ModuleNaming.domainPackage(moduleName);

  String get resolvedCommandBusType =>
      commandBusType ?? ModuleNaming.commandBusType(moduleName);

  String get resolvedQueryBusType =>
      queryBusType ?? ModuleNaming.queryBusType(moduleName);

  String get resolvedRegistrationClass =>
      registrationClass ?? ModuleNaming.registrationClass(moduleName);

  String get resolvedInternalCommandClientType =>
      internalCommandClientType ?? ModuleNaming.internalCommandClientType(moduleName);

  String get resolvedCommandRegistrationImport =>
      commandRegistrationImport ?? ModuleNaming.commandRegistrationImport(moduleName);

  String get resolvedCommandBusExtensionsImport =>
      commandBusExtensionsImport ?? ModuleNaming.commandBusExtensionsImport(moduleName);

  String get resolvedCommandPipelineImport =>
      commandPipelineImport ?? ModuleNaming.commandPipelineImport(moduleName);

  String get resolvedCommandPipelineClass =>
      commandPipelineClass ?? ModuleNaming.commandPipelineClass(moduleName);

  String get resolvedInternalCommandClientImport =>
      internalCommandClientImport ?? ModuleNaming.internalCommandClientImport(moduleName);

  String registrarOutputPath() =>
      outputPath ?? ModuleNaming.registrarOutputPath(moduleName);

  String registrarTriggerPath() =>
      triggerPath ?? ModuleNaming.registrarTriggerPath(moduleName);

  String internalRegistryOutputPath() =>
      outputPath ?? ModuleNaming.internalRegistryOutputPath(moduleName);

  String internalRegistryTriggerPath() =>
      triggerPath ?? ModuleNaming.internalRegistryTriggerPath(moduleName);

  String infrastructureTriggerPath() =>
      triggerPath ?? ModuleNaming.infrastructureTriggerPath(moduleName);

  String commandRegistrationOutputPath() =>
      outputPath ?? ModuleNaming.commandRegistrationOutputPath(moduleName);

  String commandBusExtensionsOutputPath() =>
      ModuleNaming.commandBusExtensionsOutputPath(moduleName);

  String registerValidatorsFunction() =>
      ModuleNaming.registerValidatorsFunction(moduleName);

  String registerHandlersFunction() =>
      ModuleNaming.registerHandlersFunction(moduleName);

  String registerQueriesFunction() =>
      ModuleNaming.registerQueriesFunction(moduleName);

  String internalCommandSerializerFunction() =>
      ModuleNaming.internalCommandSerializerFunction(moduleName);

  String integrationEventRegistryOutputPath() =>
      outputPath ?? ModuleNaming.integrationEventRegistryOutputPath(moduleName);

  String integrationEventRegistryTriggerPath() =>
      triggerPath ?? ModuleNaming.integrationEventRegistryTriggerPath(moduleName);

  String accessMetadataOutputPath() =>
      ModuleNaming.accessMetadataOutputPath(moduleName);

  String accessMetadataRegistryVariable() =>
      ModuleNaming.accessMetadataRegistryVariable(moduleName);

  String moduleManifestOutputPath() =>
      ModuleNaming.moduleManifestOutputPath(moduleName);

  String moduleManifestVariable() =>
      ModuleNaming.moduleManifestVariable(moduleName);

  factory CodegenModuleConfig.fromBuilderOptions(
    BuilderOptions options, {
    required List<String> defaultScanGlobs,
    bool requireIntegrationEventDispatchers = false,
  }) {
    final config = options.config;
    final moduleName = config['module_name'] as String?;
    if (moduleName == null || moduleName.isEmpty) {
      throw ArgumentError(
        'build.yaml options must include non-empty module_name for vet45_generator.',
      );
    }

    final scanPackage = config['scan_package'] as String?;
    if (scanPackage == null || scanPackage.isEmpty) {
      throw ArgumentError(
        'build.yaml options must include non-empty scan_package for vet45_generator.',
      );
    }

    final dispatchers = _parseIntegrationEventDispatchers(config['dispatchers']);
    if (requireIntegrationEventDispatchers && dispatchers.isEmpty) {
      throw ArgumentError(
        'build.yaml options must include non-empty dispatchers for cqrs_integration_event_registry.',
      );
    }

    return CodegenModuleConfig(
      moduleName: moduleName,
      scanPackage: scanPackage,
      scanGlobs: (config['scan_globs'] as List?)?.cast<String>() ?? defaultScanGlobs,
      importDomain: config['import_domain'] as bool? ?? true,
      applicationPackage: config['application_package'] as String?,
      domainPackage: config['domain_package'] as String?,
      commandBusType: config['command_bus_type'] as String?,
      queryBusType: config['query_bus_type'] as String?,
      registrationClass: config['registration_class'] as String?,
      internalCommandClientType: config['internal_command_client_type'] as String?,
      commandRegistrationImport: config['command_registration_import'] as String?,
      commandBusExtensionsImport: config['command_bus_extensions_import'] as String?,
      commandPipelineImport: config['command_pipeline_import'] as String?,
      commandPipelineClass: config['command_pipeline_class'] as String?,
      internalCommandClientImport: config['internal_command_client_import'] as String?,
      outputPath: config['output'] as String?,
      triggerPath: config['trigger'] as String?,
      integrationEventDispatchers: dispatchers,
      accessScanGlobs:
          (config['access_scan_globs'] as List?)?.cast<String>() ??
          ModuleNaming.defaultAccessScanGlobs,
      accessScanPackage: config['access_scan_package'] as String?,
      handlerScanPackage: config['handler_scan_package'] as String?,
      strictAccessMetadata: config['strict_access_metadata'] as bool? ?? false,
      moduleManifestScanGlobs:
          (config['module_manifest_scan_globs'] as List?)?.cast<String>() ??
          ModuleNaming.defaultModuleManifestScanGlobs,
    );
  }

  static List<IntegrationEventDispatcherConfig> _parseIntegrationEventDispatchers(
    Object? raw,
  ) {
    if (raw == null) {
      return const [];
    }

    if (raw is! List) {
      throw ArgumentError('dispatchers must be a list when provided.');
    }

    return raw
        .map((item) => IntegrationEventDispatcherConfig.fromMap(item as Map<dynamic, dynamic>))
        .toList(growable: false);
  }
}
