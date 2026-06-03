import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';

import 'codegen_module_config.dart';
import 'constructor_dependency_parser.dart';
import 'handler_descriptor.dart';
import 'integration_event_dispatcher_config.dart';
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

    final dartFiles = PackageConfigResolver.listMatchingDartFiles(
      packageRoot: scanPackageRoot,
      scanGlobs: config.scanGlobs,
    );

    final includedPaths = <String>{
      scanPackageRoot,
      ...config.integrationEventDispatchers
          .expand((dispatcher) => dispatcher.eventPackages)
          .map(
            (packageName) => PackageConfigResolver.findPackageRoot(
              packageName: packageName,
              fromDirectory: packageRoot,
            ),
          ),
    };

    final collection = AnalysisContextCollection(
      includedPaths: includedPaths.toList(),
    );

    final descriptors = <IntegrationEventHandlerDescriptor>[];

    for (final filePath in dartFiles) {
      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final descriptor = _describeHandler(classElement, config);
        if (descriptor != null) {
          descriptors.add(descriptor);
        }
      }
    }

    descriptors.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    for (final descriptor in descriptors) {
      _resolveDispatcher(config.integrationEventDispatchers, descriptor);
    }

    return _emitRegistryFile(descriptors, config);
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

  static String _emitRegistryFile(
    List<IntegrationEventHandlerDescriptor> descriptors,
    CodegenModuleConfig config,
  ) {
    final handlersByDispatcher = <String, List<IntegrationEventHandlerDescriptor>>{};
    for (final dispatcher in config.integrationEventDispatchers) {
      handlersByDispatcher[dispatcher.id] = [];
    }

    for (final descriptor in descriptors) {
      final dispatcher = _resolveDispatcher(config.integrationEventDispatchers, descriptor);
      handlersByDispatcher[dispatcher.id]!.add(descriptor);
    }

    final integrationEventPackages = descriptors
        .map((descriptor) => descriptor.eventPackageName)
        .toSet()
      ..removeWhere((package) => package.isEmpty);

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:get_it/get_it.dart';")
      ..writeln(
        "import 'package:${config.resolvedApplicationPackage}/application.dart';",
      );

    for (final packageName in integrationEventPackages.toList()..sort()) {
      final dispatcher = config.integrationEventDispatchers.firstWhere(
        (entry) => entry.eventPackages.contains(packageName),
      );
      buffer.writeln("import '${dispatcher.integrationEventsImportForPackage(packageName)}';");
    }

    for (final dispatcher in config.integrationEventDispatchers) {
      buffer.writeln("import '${dispatcher.dispatcherImport}';");
    }

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
