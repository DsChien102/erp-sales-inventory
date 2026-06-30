import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

import 'access_annotation_reader.dart';
import 'codegen_module_config.dart';
import 'handler_descriptor.dart';
import 'module_manifest_data.dart';
import 'module_manifest_reader.dart';
import 'package_config_resolver.dart';

abstract final class ModuleManifestGenerator {
  static Future<String> generate({
    required String packageRoot,
    required CodegenModuleConfig config,
  }) async {
    final infraRoot = p.normalize(
      PackageConfigResolver.findPackageRoot(
        packageName: config.scanPackage,
        fromDirectory: packageRoot,
      ),
    );

    final manifest = await _readManifest(infraRoot, config);
    final handlers = await _readHandlers(packageRoot, config);
    final accessPermissions = await _readAccessPermissions(packageRoot, config);

    final commandTypes = handlers
        .where((d) => d.kind == HandlerKind.business || d.kind == HandlerKind.internal)
        .map((d) => d.commandTypeName)
        .toSet()
        .toList()
      ..sort();

    final queryTypes = handlers
        .where((d) => d.kind == HandlerKind.query)
        .map((d) => d.queryTypeName!)
        .toSet()
        .toList()
      ..sort();

    final permissions = {
      ...manifest.permissions,
      ...accessPermissions,
    }.toList()
      ..sort();

    return _emit(
      config: config,
      manifest: manifest,
      commandTypes: commandTypes,
      queryTypes: queryTypes,
      permissions: permissions,
    );
  }

  static Future<ModuleManifestData> _readManifest(
    String infraRoot,
    CodegenModuleConfig config,
  ) async {
    final dartFiles = PackageConfigResolver.listMatchingDartFiles(
      packageRoot: infraRoot,
      scanGlobs: config.moduleManifestScanGlobs,
    );

    final collection = AnalysisContextCollection(includedPaths: [infraRoot]);
    ModuleManifestData? found;

    for (final filePath in dartFiles) {
      final result = await collection.contextFor(filePath).currentSession.getResolvedLibrary(
        filePath,
      );
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final data = ModuleManifestReader.read(classElement);
        if (data == null) {
          continue;
        }
        if (found != null) {
          throw ArgumentError(
            'vet45_generator:MF: Multiple @ModuleManifest definitions: '
            '${found.className} and ${data.className}',
          );
        }
        found = data;
      }
    }

    if (found == null) {
      throw ArgumentError(
        'vet45_generator:MF: No @ModuleManifest found in ${config.scanPackage}',
      );
    }

    return found;
  }

  static Future<List<HandlerDescriptor>> _readHandlers(
    String packageRoot,
    CodegenModuleConfig config,
  ) async {
    final scanPackageRoot = p.normalize(
      PackageConfigResolver.findPackageRoot(
        packageName: config.resolvedHandlerScanPackage,
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
      final result = await collection.contextFor(filePath).currentSession.getResolvedLibrary(
        filePath,
      );
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        if (classElement.isAbstract) {
          continue;
        }

        final queryType = _interfaceArg(classElement, 'IQueryHandler', 0);
        if (queryType != null) {
          descriptors.add(
            HandlerDescriptor(
              kind: HandlerKind.query,
              className: classElement.name!,
              commandTypeName: queryType,
              queryTypeName: queryType,
              resultTypeName: _interfaceArg(classElement, 'IQueryHandler', 1),
            ),
          );
          continue;
        }

        final commandType = _interfaceArg(classElement, 'ICommandHandler', 0);
        if (commandType != null) {
          descriptors.add(
            HandlerDescriptor(
              kind: HandlerKind.business,
              className: classElement.name!,
              commandTypeName: commandType,
              resultTypeName: _interfaceArg(classElement, 'ICommandHandler', 1),
            ),
          );
        }
      }
    }

    return descriptors;
  }

  static Future<Set<String>> _readAccessPermissions(
    String packageRoot,
    CodegenModuleConfig config,
  ) async {
    final scanPackageRoot = p.normalize(
      PackageConfigResolver.findPackageRoot(
        packageName: config.accessScanPackage ?? config.resolvedApplicationPackage,
        fromDirectory: packageRoot,
      ),
    );

    final dartFiles = PackageConfigResolver.listMatchingDartFiles(
      packageRoot: scanPackageRoot,
      scanGlobs: config.accessScanGlobs,
    );

    final collection = AnalysisContextCollection(
      includedPaths: [scanPackageRoot],
    );

    final permissions = <String>{};
    for (final filePath in dartFiles) {
      final result = await collection.contextFor(filePath).currentSession.getResolvedLibrary(
        filePath,
      );
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        final permission = AccessAnnotationReader.permission(classElement);
        if (permission != null && permission.isNotEmpty) {
          permissions.add(permission);
        }
      }
    }

    return permissions;
  }

  static String? _interfaceArg(ClassElement classElement, String iface, int index) {
    for (final interface in classElement.interfaces) {
      if (interface.element.name != iface) {
        continue;
      }
      if (interface.typeArguments.length <= index) {
        return null;
      }
      return interface.typeArguments[index].getDisplayString();
    }
    return null;
  }

  static String _emit({
    required CodegenModuleConfig config,
    required ModuleManifestData manifest,
    required List<String> commandTypes,
    required List<String> queryTypes,
    required List<String> permissions,
  }) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:${config.resolvedApplicationPackage}/application.dart';")
      ..writeln("import 'package:vet45_shared_application/application.dart';")
      ..writeln()
      ..writeln('final ${config.moduleManifestVariable()} = GeneratedModuleManifest(')
      ..writeln("  name: '${manifest.name}',")
      ..writeln('  permissions: [');
    for (final permission in permissions) {
      buffer.writeln("    '$permission',");
    }
    buffer.writeln('  ],');
    buffer.writeln('  commandTypes: [');
    for (final type in commandTypes) {
      buffer.writeln('    $type,');
    }
    buffer.writeln('  ],');
    buffer.writeln('  queryTypes: [');
    for (final type in queryTypes) {
      buffer.writeln('    $type,');
    }
    buffer.writeln('  ],');
    if (manifest.version != null) {
      buffer.writeln("  version: '${manifest.version}',");
    }
    buffer.writeln(');');
    buffer.writeln();
    return buffer.toString();
  }
}
