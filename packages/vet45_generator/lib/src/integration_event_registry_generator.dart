import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'codegen_module_config.dart';
import 'constructor_dependency_parser.dart';
import 'handler_descriptor.dart';
import 'integration_event_dispatcher_config.dart';
import 'module_naming.dart';
import 'package_config_resolver.dart';

final class IntegrationEventHandlerDescriptor {
  const IntegrationEventHandlerDescriptor({
    required this.className,
    required this.eventTypeName,
    required this.eventPackageName,
    required this.dependencies,
  });

  final String className;
  final String eventTypeName;
  final String eventPackageName;
  final List<ConstructorDependency> dependencies;

  String get sortKey => '$eventTypeName::$className';
}

final class IntegrationEventDescriptor {
  const IntegrationEventDescriptor({
    required this.className,
    required this.eventType,
    required this.eventPackageName,
  });

  final String className;
  final String eventType;
  final String eventPackageName;

  String get sortKey => '$eventType::$className';
}

abstract final class IntegrationEventRegistryGenerator {
  static Future<String> generate({
    required String packageRoot,
    required CodegenModuleConfig config,
  }) async {
    if (config.integrationEventDispatchers.isEmpty) {
      throw ArgumentError(
        'integration_event_dispatchers must be non-empty for integration event registry codegen.',
      );
    }

    final scanPackageRoot = PackageConfigResolver.findPackageRoot(
      packageName: config.scanPackage,
      fromDirectory: packageRoot,
    );

    final handlerFiles = PackageConfigResolver.listMatchingDartFiles(
      packageRoot: scanPackageRoot,
      scanGlobs: config.scanGlobs,
    );

    final eventPackageNames = config.integrationEventDispatchers
        .expand((dispatcher) => dispatcher.eventPackages)
        .toSet();

    final eventPackageRoots = eventPackageNames
        .map(
          (packageName) => PackageConfigResolver.findPackageRoot(
            packageName: packageName,
            fromDirectory: packageRoot,
          ),
        )
        .toSet();

    final eventFiles = eventPackageRoots
        .expand(
          (eventPackageRoot) => PackageConfigResolver.listMatchingDartFiles(
            packageRoot: eventPackageRoot,
            scanGlobs: CodegenModuleConfig.defaultIntegrationEventScanGlobs,
          ),
        )
        .toSet();

    final includedPaths = <String>{
      scanPackageRoot,
      ...eventPackageRoots,
    };

    final collection = AnalysisContextCollection(
      includedPaths: includedPaths.toList(),
    );

    final handlerDescriptors = <IntegrationEventHandlerDescriptor>[];
    for (final filePath in handlerFiles) {
      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final descriptor = _describeHandler(classElement, config);
        if (descriptor != null) {
          handlerDescriptors.add(descriptor);
        }
      }
    }

    final eventDescriptors = <IntegrationEventDescriptor>[];
    for (final filePath in eventFiles) {
      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final descriptor = _describeIntegrationEvent(classElement, eventPackageNames);
        if (descriptor != null) {
          eventDescriptors.add(descriptor);
        }
      }
    }

    handlerDescriptors.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    eventDescriptors.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    for (final descriptor in handlerDescriptors) {
      _resolveDispatcher(config.integrationEventDispatchers, descriptor);
    }

    _validateHandlerEventsHaveContracts(handlerDescriptors, eventDescriptors);

    return _emitRegistryFile(
      handlerDescriptors: handlerDescriptors,
      eventDescriptors: eventDescriptors,
      config: config,
    );
  }

  static IntegrationEventHandlerDescriptor? _describeHandler(
    ClassElement classElement,
    CodegenModuleConfig config,
  ) {
    if (classElement.isAbstract) {
      return null;
    }

    if (_hasAnnotation(classElement, 'CqrsExclude')) {
      return null;
    }

    final eventTypeElement = _integrationEventTypeElement(classElement);
    if (eventTypeElement == null) {
      return null;
    }

    final eventTypeName = eventTypeElement.name!;
    final configuredPackages = config.integrationEventDispatchers
        .expand((dispatcher) => dispatcher.eventPackages)
        .toSet();
    final eventPackageName =
        _matchConfiguredPackage(eventTypeElement.library.uri.toString(), configuredPackages) ??
        PackageConfigResolver.packageNameFromImportUri(eventTypeElement.library.uri);

    if (eventPackageName == null || eventPackageName.isEmpty) {
      throw StateError(
        'Unable to resolve integration event package for handler ${classElement.name} '
        'and event type $eventTypeName.',
      );
    }

    return IntegrationEventHandlerDescriptor(
      className: classElement.name!,
      eventTypeName: eventTypeName,
      eventPackageName: eventPackageName,
      dependencies: ConstructorDependencyParser.parse(classElement),
    );
  }

  static IntegrationEventDescriptor? _describeIntegrationEvent(
    ClassElement classElement,
    Set<String> configuredEventPackages,
  ) {
    if (classElement.isAbstract) {
      return null;
    }

    if (!_extendsTenantScopedIntegrationEvent(classElement)) {
      return null;
    }

    final eventType = _readStaticTypeConstant(classElement);
    if (eventType == null) {
      return null;
    }

    if (!_hasFromPayloadFactory(classElement)) {
      return null;
    }

    final eventPackageName =
        _matchConfiguredPackage(classElement.library.uri.toString(), configuredEventPackages) ??
        PackageConfigResolver.packageNameFromImportUri(classElement.library.uri);

    if (eventPackageName == null || eventPackageName.isEmpty) {
      throw StateError(
        'Unable to resolve integration event package for event ${classElement.name}.',
      );
    }

    return IntegrationEventDescriptor(
      className: classElement.name!,
      eventType: eventType,
      eventPackageName: eventPackageName,
    );
  }

  static ClassElement? _integrationEventTypeElement(ClassElement classElement) {
    for (final interface in classElement.interfaces) {
      if (interface.element.name != 'IIntegrationEventNotificationHandler') {
        continue;
      }

      if (interface.typeArguments.isEmpty) {
        return null;
      }

      final element = interface.typeArguments[0].element;
      if (element is ClassElement) {
        return element;
      }
    }

    return null;
  }

  static bool _extendsTenantScopedIntegrationEvent(ClassElement classElement) {
    InterfaceType? current = classElement.thisType;
    while (current != null) {
      if (current.element.name == 'TenantScopedIntegrationEvent') {
        return true;
      }
      current = current.superclass;
    }
    return false;
  }

  static bool _hasFromPayloadFactory(ClassElement classElement) {
    for (final constructor in classElement.constructors) {
      if (constructor.isFactory && constructor.name == 'fromPayload') {
        return true;
      }
    }
    return false;
  }

  static String? _readStaticTypeConstant(ClassElement classElement) {
    for (final field in classElement.fields) {
      if (!field.isStatic || field.name != 'type') {
        continue;
      }

      final value = field.computeConstantValue();
      final eventType = value?.toStringValue();
      if (eventType != null && eventType.isNotEmpty) {
        return eventType;
      }
    }

    return null;
  }

  static IntegrationEventDispatcherConfig _resolveDispatcher(
    List<IntegrationEventDispatcherConfig> dispatchers,
    IntegrationEventHandlerDescriptor descriptor,
  ) {
    final matches = dispatchers
        .where((dispatcher) => dispatcher.eventPackages.contains(descriptor.eventPackageName))
        .toList();

    if (matches.isEmpty) {
      throw StateError(
        'No integration event dispatcher configured for handler ${descriptor.className} '
        '(event ${descriptor.eventTypeName} from ${descriptor.eventPackageName}). '
        'Add matching event_packages in build.yaml dispatchers.',
      );
    }

    if (matches.length > 1) {
      throw StateError(
        'Multiple integration event dispatchers match handler ${descriptor.className} '
        '(event package ${descriptor.eventPackageName}). '
        'Ensure event_packages are unique across dispatchers.',
      );
    }

    return matches.first;
  }

  static void _validateHandlerEventsHaveContracts(
    List<IntegrationEventHandlerDescriptor> handlers,
    List<IntegrationEventDescriptor> events,
  ) {
    final eventClasses = events.map((event) => event.className).toSet();
    for (final handler in handlers) {
      if (!eventClasses.contains(handler.eventTypeName)) {
        throw StateError(
          'Handler ${handler.className} references ${handler.eventTypeName}, '
          'but no matching integration event contract was discovered in event_packages. '
          'Ensure the event class extends TenantScopedIntegrationEvent, '
          'declares static const type, and provides fromPayload().',
        );
      }
    }
  }

  static String? _matchConfiguredPackage(
    String importUriText,
    Set<String> configuredEventPackages,
  ) {
    for (final packageName in configuredEventPackages) {
      if (importUriText.contains(packageName)) {
        return packageName;
      }
    }

    return null;
  }

  static bool _hasAnnotation(ClassElement classElement, String name) {
    for (final annotation in classElement.metadata.annotations) {
      final element = annotation.element;
      if (element is ConstructorElement && element.enclosingElement.name == name) {
        return true;
      }
    }
    return false;
  }

  static String _emitRegistryFile({
    required List<IntegrationEventHandlerDescriptor> handlerDescriptors,
    required List<IntegrationEventDescriptor> eventDescriptors,
    required CodegenModuleConfig config,
  }) {
    final modulePascal = ModuleNaming.toPascalCase(config.moduleName);
    final registryClass = ModuleNaming.integrationEventRegistryClass(config.moduleName);
    final outboxSerializerClass = ModuleNaming.outboxEventSerializerClass(config.moduleName);
    final outboxModuleFactory = ModuleNaming.outboxModuleFactoryFunction(config.moduleName);
    final subscriptionsFunction =
        ModuleNaming.integrationEventSubscriptionsFunction(config.moduleName);

    final handlersByDispatcher = <String, List<IntegrationEventHandlerDescriptor>>{};
    for (final dispatcher in config.integrationEventDispatchers) {
      handlersByDispatcher[dispatcher.id] = [];
    }

    for (final descriptor in handlerDescriptors) {
      final dispatcher = _resolveDispatcher(config.integrationEventDispatchers, descriptor);
      handlersByDispatcher[dispatcher.id]!.add(descriptor);
    }

    final integrationEventPackages = {
      ...handlerDescriptors.map((descriptor) => descriptor.eventPackageName),
      ...eventDescriptors.map((descriptor) => descriptor.eventPackageName),
    }..removeWhere((package) => package.isEmpty);

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:get_it/get_it.dart';")
      ..writeln("import 'package:quiver/collection.dart';")
      ..writeln(
        "import 'package:${config.resolvedApplicationPackage}/application.dart';",
      )
      ..writeln("import 'package:vet45_shared_infrastructure/infrastructure.dart';");

    for (final packageName in integrationEventPackages.toList()..sort()) {
      final dispatcher = config.integrationEventDispatchers.firstWhere(
        (entry) => entry.eventPackages.contains(packageName),
      );
      buffer.writeln("import '${dispatcher.integrationEventsImportForPackage(packageName)}';");
    }

    for (final dispatcher in config.integrationEventDispatchers) {
      buffer.writeln("import '${dispatcher.dispatcherImport}';");
    }

    final genericHandlerClass = '${modulePascal}IntegrationEventGenericHandler';
    final inboxClientType = 'I${modulePascal}InboxClient';

    buffer
      ..writeln("import '../../events_bus/${config.moduleName}_integration_event_generic_handler.dart';")
      ..writeln("import '../../outbox/outbox_module.dart';")
      ..writeln("import '../inbox/i_${config.moduleName}_inbox_client.dart';")
      ..writeln()
      ..writeln('/// Deserialize integration events from inbox/outbox payloads.')
      ..writeln('abstract final class $registryClass {')
      ..writeln('  static const eventTypes = <Type, String>{');

    for (final event in eventDescriptors) {
      buffer.writeln('    ${event.className}: ${event.className}.type,');
    }

    buffer
      ..writeln('  };')
      ..writeln()
      ..writeln('  static TenantScopedIntegrationEvent? fromJson({')
      ..writeln('    required String eventType,')
      ..writeln('    required Map<String, dynamic> payload,')
      ..writeln('  }) {');

    for (final event in eventDescriptors) {
      buffer.writeln('    if (eventType == ${event.className}.type) {');
      buffer.writeln('      return ${event.className}.fromPayload(payload);');
      buffer.writeln('    }');
    }

    buffer
      ..writeln('    return null;')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('/// Deserializes outbox payloads into $modulePascal integration events.')
      ..writeln('abstract final class $outboxSerializerClass {')
      ..writeln('  static TenantScopedIntegrationEvent fromPayload({')
      ..writeln('    required Type type,')
      ..writeln('    required Map<String, dynamic> payload,')
      ..writeln('  }) {');

    for (final event in eventDescriptors) {
      buffer.writeln('    if (type == ${event.className}) {');
      buffer.writeln('      return ${event.className}.fromPayload(payload);');
      buffer.writeln('    }');
    }

    buffer
      ..writeln("    throw StateError('Unsupported outbox event type: \$type');")
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('OutboxModule $outboxModuleFactory() {')
      ..writeln('  final map = BiMap<String, Type>();');

    for (final event in eventDescriptors) {
      buffer.writeln('  map[${event.className}.type] = ${event.className};');
    }

    buffer
      ..writeln('  return OutboxModule(map);')
      ..writeln('}')
      ..writeln()
      ..writeln('void $subscriptionsFunction({')
      ..writeln('  required IEventsBus eventBus,')
      ..writeln('  required $inboxClientType inboxClient,')
      ..writeln('  required ILogger logger,')
      ..writeln('}) {')
      ..writeln('  IntegrationEventTypeRegistry.registerAll($registryClass.eventTypes);');

    for (final event in eventDescriptors) {
      buffer
        ..writeln("  logger.info('Subscribe to inbound ${event.eventType}');")
        ..writeln('  eventBus.subscribe(')
        ..writeln('    $genericHandlerClass<${event.className}>(inboxClient: inboxClient),')
        ..writeln('  );');
    }

    buffer.writeln('}');
    buffer.writeln();

    for (final dispatcher in config.integrationEventDispatchers) {
      final handlers = handlersByDispatcher[dispatcher.id]!
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

      buffer.writeln(
        '${dispatcher.dispatcherClass} ${dispatcher.factoryFunction}(GetIt container) {',
      );
      buffer.writeln('  final dispatcher = ${dispatcher.dispatcherClass}();');

      for (final handler in handlers) {
        buffer.writeln('  dispatcher.register<${handler.eventTypeName}>(');
        buffer.writeln('    ${_handlerExpression(handler)},');
        buffer.writeln('  );');
      }

      buffer
        ..writeln('  return dispatcher;')
        ..writeln('}')
        ..writeln();
    }

    return buffer.toString();
  }

  static String _handlerExpression(IntegrationEventHandlerDescriptor handler) {
    if (handler.dependencies.isEmpty) {
      return '${handler.className}()';
    }

    final args = handler.dependencies
        .map((dep) => '${dep.name}: container.get<${dep.typeName}>()')
        .join(',\n      ');

    return '${handler.className}(\n      $args,\n    )';
  }
}
