import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';

import 'codegen_module_config.dart';
import 'package_config_resolver.dart';

final class InternalCommandDescriptor {
  const InternalCommandDescriptor({
    required this.className,
    required this.commandType,
  });

  final String className;
  final String commandType;
}

abstract final class InternalCommandRegistryGenerator {
  static Future<String> generate({
    required String packageRoot,
    required CodegenModuleConfig config,
  }) async {
    final scanPackageRoot = PackageConfigResolver.findPackageRoot(
      packageName: config.scanPackage,
      fromDirectory: packageRoot,
    );

    final dartFiles = PackageConfigResolver.listMatchingDartFiles(
      packageRoot: scanPackageRoot,
      scanGlobs: config.scanGlobs,
    );

    final collection = AnalysisContextCollection(
      includedPaths: [scanPackageRoot],
    );

    final descriptors = <InternalCommandDescriptor>[];

    for (final filePath in dartFiles) {
      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final descriptor = _describeInternalCommand(classElement);
        if (descriptor != null) {
          descriptors.add(descriptor);
        }
      }
    }

    descriptors.sort((a, b) => a.className.compareTo(b.className));
    return _emitRegistryFile(descriptors, config);
  }

  static InternalCommandDescriptor? _describeInternalCommand(ClassElement classElement) {
    if (classElement.isAbstract) {
      return null;
    }

    if (!_implementsInterface(classElement, 'ISerializableInternalCommand')) {
      return null;
    }

    final commandType = _readStaticTypeConstant(classElement);
    if (commandType == null) {
      return null;
    }

    if (!_hasFromJsonFactory(classElement)) {
      return null;
    }

    return InternalCommandDescriptor(
      className: classElement.name!,
      commandType: commandType,
    );
  }

  static bool _implementsInterface(ClassElement classElement, String interfaceName) {
    for (final interface in classElement.interfaces) {
      if (interface.element.name == interfaceName) {
        return true;
      }
    }
    return false;
  }

  static bool _hasFromJsonFactory(ClassElement classElement) {
    for (final constructor in classElement.constructors) {
      if (constructor.isFactory && constructor.name == 'fromJson') {
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
      final commandType = value?.toStringValue();
      if (commandType != null && commandType.isNotEmpty) {
        return commandType;
      }
    }

    return null;
  }

  static String _emitRegistryFile(
    List<InternalCommandDescriptor> descriptors,
    CodegenModuleConfig config,
  ) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:quiver/collection.dart';");
    if (descriptors.isNotEmpty) {
      buffer.writeln(
        "import 'package:${config.resolvedApplicationPackage}/application.dart';",
      );
    }
    buffer
      ..writeln("import 'package:vet45_shared_infrastructure/infrastructure.dart';")
      ..writeln()
      ..writeln('InternalCommandSerializer ${config.internalCommandSerializerFunction()}() {');

    if (descriptors.isEmpty) {
      buffer
        ..writeln('  return InternalCommandSerializer(')
        ..writeln('    mapper: InternalCommandMapper(internalCommandMap: BiMap<String, Type>()),')
        ..writeln('    deserializers: const {},')
        ..writeln('  );');
    } else {
      buffer.writeln('  final commandTypes = BiMap<String, Type>()');
      for (var index = 0; index < descriptors.length; index++) {
        final descriptor = descriptors[index];
        final suffix = index == descriptors.length - 1 ? ';' : '';
        buffer.writeln(
          "    ..['${descriptor.commandType}'] = ${descriptor.className}$suffix",
        );
      }
      buffer
        ..writeln()
        ..writeln('  return InternalCommandSerializer(')
        ..writeln('    mapper: InternalCommandMapper(internalCommandMap: commandTypes),')
        ..writeln('    deserializers: {');
      for (final descriptor in descriptors) {
        buffer.writeln(
          "      '${descriptor.commandType}': ${descriptor.className}.fromJson,",
        );
      }
      buffer
        ..writeln('    },')
        ..writeln('  );');
    }

    buffer.writeln('}');
    return buffer.toString();
  }
}
