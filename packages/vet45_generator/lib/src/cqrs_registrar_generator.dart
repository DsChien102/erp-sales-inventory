import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

import 'annotation_reader.dart';
import 'codegen_module_config.dart';
import 'constructor_dependency_parser.dart';
import 'handler_descriptor.dart';
import 'handler_registry_validator.dart';
import 'package_config_resolver.dart';

abstract final class CqrsRegistrarGenerator {
  static Future<String> generate({
    required String packageRoot,
    required CodegenModuleConfig config,
  }) async {
    final scanPackageRoot = p.normalize(
      PackageConfigResolver.findPackageRoot(
        packageName: config.scanPackage,
        fromDirectory: packageRoot,
      ),
    );

    final dartFiles = PackageConfigResolver.listMatchingDartFiles(
      packageRoot: scanPackageRoot,
      scanGlobs: config.scanGlobs,
    );

    final collection = AnalysisContextCollection(
      includedPaths: [scanPackageRoot],
    );

    final descriptors = <HandlerDescriptor>[];

    for (final filePath in dartFiles) {
      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final descriptor = _describeClass(classElement);
        if (descriptor != null) {
          descriptors.add(descriptor);
        }
      }
    }

    descriptors.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    HandlerRegistryValidator.validate(descriptors);
    return _emitRegistrationFile(
      descriptors,
      config,
      infrastructurePackageRoot: packageRoot,
    );
  }

  static HandlerDescriptor? _describeClass(ClassElement classElement) {
    if (classElement.isAbstract) {
      return null;
    }

    if (AnnotationReader.hasAnnotation(classElement, 'CqrsExclude')) {
      return null;
    }

    if (AnnotationReader.hasAnnotation(classElement, 'CqrsValidator') ||
        _interfaceTypeArgument(classElement, 'ICommandValidator', 0) != null) {
      final commandType = _interfaceTypeArgument(classElement, 'ICommandValidator', 0);
      if (commandType == null) {
        return null;
      }

      return HandlerDescriptor(
        kind: HandlerKind.validator,
        className: classElement.name!,
        commandTypeName: commandType,
      );
    }

    if (AnnotationReader.hasAnnotation(classElement, 'CqrsQueryHandler') ||
        AnnotationReader.hasAnnotation(classElement, 'QueryHandlerFor') ||
        _interfaceTypeArgument(classElement, 'IQueryHandler', 0) != null) {
      final annotatedQuery = AnnotationReader.readTypeField(
        classElement,
        'QueryHandlerFor',
        'queryType',
      );
      final queryType = _interfaceTypeArgument(classElement, 'IQueryHandler', 0);
      final resultType = _interfaceTypeArgument(classElement, 'IQueryHandler', 1);

      HandlerRegistryValidator.validateQueryHandlerForPresent(
        className: classElement.name!,
        annotatedType: annotatedQuery,
        interfaceType: queryType,
      );
      HandlerRegistryValidator.validateQueryHandlerAnnotation(
        className: classElement.name!,
        annotatedType: annotatedQuery,
        interfaceType: queryType,
      );

      final resolvedQuery = annotatedQuery ?? queryType;
      if (resolvedQuery == null || resultType == null) {
        return null;
      }

      return HandlerDescriptor(
        kind: HandlerKind.query,
        className: classElement.name!,
        commandTypeName: resolvedQuery,
        queryTypeName: resolvedQuery,
        resultTypeName: resultType,
        dependencies: ConstructorDependencyParser.parse(classElement),
      );
    }

    if (AnnotationReader.hasAnnotation(classElement, 'CqrsInternalHandler') ||
        AnnotationReader.hasAnnotation(classElement, 'CommandHandlerFor') ||
        _interfaceTypeArgument(classElement, 'ICommandHandler', 0) != null) {
      final annotatedCommand = AnnotationReader.readTypeField(
        classElement,
        'CommandHandlerFor',
        'commandType',
      );
      final commandType = _interfaceTypeArgument(classElement, 'ICommandHandler', 0);
      final resultType = _interfaceTypeArgument(classElement, 'ICommandHandler', 1);

      HandlerRegistryValidator.validateCommandHandlerForPresent(
        className: classElement.name!,
        annotatedType: annotatedCommand,
        interfaceType: commandType,
      );
      HandlerRegistryValidator.validateCommandHandlerAnnotation(
        className: classElement.name!,
        annotatedType: annotatedCommand,
        interfaceType: commandType,
      );

      final resolvedCommand = annotatedCommand ?? commandType;
      if (resolvedCommand == null || resultType == null) {
        return null;
      }

      if (AnnotationReader.hasAnnotation(classElement, 'CqrsInternalHandler')) {
        return HandlerDescriptor(
          kind: HandlerKind.internal,
          className: classElement.name!,
          commandTypeName: resolvedCommand,
          dependencies: ConstructorDependencyParser.parse(classElement),
        );
      }

      final commandClass = _resolveClassElement(classElement, resolvedCommand);
      final isInternal =
          commandClass != null && _extendsType(commandClass, 'InternalCommandBase');

      return HandlerDescriptor(
        kind: isInternal ? HandlerKind.internal : HandlerKind.business,
        className: classElement.name!,
        commandTypeName: resolvedCommand,
        resultTypeName: isInternal ? null : resultType,
        dependencies: ConstructorDependencyParser.parse(classElement),
      );
    }

    return null;
  }

  static String? _interfaceTypeArgument(
    ClassElement classElement,
    String interfaceName,
    int index,
  ) {
    for (final interface in classElement.interfaces) {
      final element = interface.element;
      if (element.name != interfaceName) {
        continue;
      }

      if (interface.typeArguments.length <= index) {
        return null;
      }

      return interface.typeArguments[index].getDisplayString();
    }

    return null;
  }

  static ClassElement? _resolveClassElement(
    ClassElement scope,
    String typeName,
  ) {
    final library = scope.library;
    for (final classElement in library.classes) {
      if (classElement.name == typeName) {
        return classElement;
      }
    }

    for (final fragment in library.fragments) {
      for (final import in fragment.libraryImports) {
        final importedLibrary = import.importedLibrary;
        if (importedLibrary == null) {
          continue;
        }

        for (final classElement in importedLibrary.classes) {
          if (classElement.name == typeName) {
            return classElement;
          }
        }
      }
    }

    return null;
  }

  static bool _extendsType(ClassElement classElement, String typeName) {
    for (final supertype in classElement.allSupertypes) {
      if (supertype.element.name == typeName) {
        return true;
      }
    }
    return false;
  }

  static String _emitRegistrationFile(
    List<HandlerDescriptor> descriptors,
    CodegenModuleConfig config, {
    required String infrastructurePackageRoot,
  }) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:get_it/get_it.dart';")
      ..writeln(
        "import 'package:${config.resolvedApplicationPackage}/application.dart';",
      )
      ..writeln("import 'package:vet45_shared_application/application.dart';");

    if (_requiresDomainImport(
      descriptors: descriptors,
      config: config,
      infrastructurePackageRoot: infrastructurePackageRoot,
    )) {
      buffer.writeln("import 'package:${config.resolvedDomainPackage}/domain.dart';");
    }

    buffer
      ..writeln("import 'package:vet45_shared_infrastructure/infrastructure.dart';")
      ..writeln()
      ..writeln("import '${config.resolvedInternalCommandClientImport}';")
      ..writeln("import '${config.resolvedCommandRegistrationImport}';")
      ..writeln();

    final validators = descriptors.where((d) => d.kind == HandlerKind.validator).toList();
    if (validators.isNotEmpty) {
      buffer.writeln('void ${config.registerValidatorsFunction()}(GetIt container) {');
      buffer.writeln('  container');
      for (final validator in validators) {
        buffer.writeln(
          '    ..registerFactory<ICommandValidator<${validator.commandTypeName}>>(',
        );
        buffer.writeln('      ${validator.className}.new,');
        buffer.writeln('    )');
      }
      buffer.writeln('    ;');
      buffer.writeln('}');
      buffer.writeln();
    }

    final businessHandlers =
        descriptors.where((d) => d.kind == HandlerKind.business).toList();
    final internalHandlers =
        descriptors.where((d) => d.kind == HandlerKind.internal).toList();

    buffer.writeln('void ${config.registerHandlersFunction()}({');
    buffer.writeln('  required ${config.resolvedCommandBusType} bus,');
    buffer.writeln('  required GetIt container,');
    buffer.writeln(
      '  required ${config.resolvedInternalCommandClientType} internalCommandClient,',
    );
    buffer.writeln('  ILogger? logger,');
    buffer.writeln('}) {');
    if (validators.isNotEmpty) {
      buffer.writeln('  ${config.registerValidatorsFunction()}(container);');
      buffer.writeln();
    }

    for (final handler in businessHandlers) {
      buffer.writeln(
        '  ${config.resolvedRegistrationClass}.registerBusinessHandler<'
        '${handler.commandTypeName}, ${handler.resultTypeName}, ${handler.className}>(',
      );
      buffer.writeln('    container: container,');
      buffer.writeln('    bus: bus,');
      buffer.writeln('    logger: logger,');
      buffer.writeln('    factory: ${_factoryExpression(handler)},');
      buffer.writeln('  );');
      buffer.writeln();
    }

    for (final handler in internalHandlers) {
      buffer.writeln(
        '  ${config.resolvedRegistrationClass}.registerInternalHandler<'
        '${handler.commandTypeName}, ${handler.className}>(',
      );
      buffer.writeln('    container: container,');
      buffer.writeln('    bus: bus,');
      buffer.writeln('    logger: logger,');
      buffer.writeln('    factory: ${_factoryExpression(handler)},');
      buffer.writeln(
        '    inner: (command) => container.get<${handler.className}>().handle(command),',
      );
      buffer.writeln('    commandClient: internalCommandClient,');
      buffer.writeln('  );');
      buffer.writeln();
    }

    buffer.writeln('}');
    buffer.writeln();

    final queryHandlers = descriptors.where((d) => d.kind == HandlerKind.query).toList();
    buffer.writeln('void ${config.registerQueriesFunction()}({');
    buffer.writeln('  required ${config.resolvedQueryBusType} bus,');
    buffer.writeln('  required GetIt container,');
    buffer.writeln('}) {');

    for (final handler in queryHandlers) {
      buffer.writeln(
        '  ${config.resolvedRegistrationClass}.registerQueryHandler<'
        '${handler.queryTypeName}, ${handler.resultTypeName}, ${handler.className}>(',
      );
      buffer.writeln('    bus: bus,');
      buffer.writeln('    factory: ${_factoryExpression(handler)},');
      buffer.writeln('    invoke: (query, handler) => handler.handle(query),');
      buffer.writeln('  );');
      buffer.writeln();
    }

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }

  static String _factoryExpression(HandlerDescriptor handler) {
    if (handler.dependencies.isEmpty) {
      return '() => ${handler.className}()';
    }

    final args = handler.dependencies
        .map((dep) => '${dep.name}: container.get<${dep.typeName}>()')
        .join(',\n      ');

    return '() => ${handler.className}(\n      $args,\n    )';
  }

  /// Domain barrel is imported only when a handler constructor dependency
  /// references a type declared in the module domain package.
  static bool _requiresDomainImport({
    required List<HandlerDescriptor> descriptors,
    required CodegenModuleConfig config,
    required String infrastructurePackageRoot,
  }) {
    if (!config.importDomain) {
      return false;
    }

    final domainTypes = _collectDomainTypeNames(
      infrastructurePackageRoot: infrastructurePackageRoot,
      config: config,
    );
    if (domainTypes.isEmpty) {
      return false;
    }

    for (final descriptor in descriptors) {
      for (final dependency in descriptor.dependencies) {
        if (domainTypes.contains(_baseTypeName(dependency.typeName))) {
          return true;
        }
      }
    }

    return false;
  }

  static String _baseTypeName(String typeName) {
    var normalized = typeName.trim();
    if (normalized.startsWith('List<') && normalized.endsWith('>')) {
      normalized = normalized.substring(5, normalized.length - 1);
    }
    return normalized.replaceAll('?', '');
  }

  static Set<String> _collectDomainTypeNames({
    required String infrastructurePackageRoot,
    required CodegenModuleConfig config,
  }) {
    try {
      final domainRoot = PackageConfigResolver.findPackageRoot(
        packageName: config.resolvedDomainPackage,
        fromDirectory: infrastructurePackageRoot,
      );
      final files = PackageConfigResolver.listMatchingDartFiles(
        packageRoot: domainRoot,
        scanGlobs: const ['lib/src/**/*.dart'],
      );

      final types = <String>{};
      final classPattern = RegExp(
        r'^(?:abstract\s+)?(?:final\s+)?(?:sealed\s+)?class\s+(\w+)',
      );
      final enumPattern = RegExp(r'^enum\s+(\w+)');

      for (final filePath in files) {
        for (final line in File(filePath).readAsLinesSync()) {
          final trimmed = line.trim();
          final classMatch = classPattern.firstMatch(trimmed);
          if (classMatch != null) {
            types.add(classMatch.group(1)!);
          }
          final enumMatch = enumPattern.firstMatch(trimmed);
          if (enumMatch != null) {
            types.add(enumMatch.group(1)!);
          }
        }
      }

      return types;
    } on Object {
      return {};
    }
  }
}
