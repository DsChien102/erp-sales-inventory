import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

import 'access_annotation_reader.dart';
import 'access_metadata_entry.dart';
import 'codegen_module_config.dart';
import 'package_config_resolver.dart';

abstract final class AccessMetadataGenerator {
  static Future<String> generate({
    required String packageRoot,
    required CodegenModuleConfig config,
    bool strict = false,
  }) async {
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

    final entries = <AccessMetadataEntry>[];
    final warnings = <String>[];

    for (final filePath in dartFiles) {
      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedLibrary(filePath);
      if (result is! ResolvedLibraryResult) {
        continue;
      }

      for (final classElement in result.element.classes) {
        if (classElement.isAbstract) {
          continue;
        }

        if (!_isMessageType(classElement)) {
          continue;
        }

        final hasAccess = AccessAnnotationReader.hasAnyAccessAnnotation(classElement);
        if (!hasAccess) {
          if (strict) {
            warnings.add(
              'vet45_generator:AC: ${classElement.name} implements ICommand/IQuery '
              'but has no access annotations',
            );
          }
          continue;
        }

        final entry = AccessMetadataEntry(
          typeName: classElement.name!,
          permission: AccessAnnotationReader.permission(classElement),
          isPublic: AccessAnnotationReader.isPublic(classElement),
          requiresTenant: AccessAnnotationReader.requiresTenant(classElement),
          idempotencyKeyField: AccessAnnotationReader.idempotencyKeyField(classElement),
        );
        AccessMetadataValidator.validate(classElement, entry);
        entries.add(entry);
      }
    }

    if (strict && warnings.isNotEmpty) {
      throw ArgumentError(warnings.join('\n'));
    }

    entries.sort((a, b) => a.typeName.compareTo(b.typeName));
    return _emit(config, entries);
  }

  static bool _isMessageType(ClassElement classElement) {
    for (final interface in classElement.interfaces) {
      final name = interface.element.name;
      if (name == 'ICommand' || name == 'IQuery') {
        return true;
      }
    }
    return false;
  }

  static String _emit(CodegenModuleConfig config, List<AccessMetadataEntry> entries) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// ignore_for_file: type=lint')
      ..writeln()
      ..writeln("import 'package:${config.resolvedApplicationPackage}/application.dart';")
      ..writeln("import 'package:vet45_shared_application/application.dart';")
      ..writeln("import 'package:vet45_shared_infrastructure/infrastructure.dart';")
      ..writeln()
      ..writeln(
        'final ${config.accessMetadataRegistryVariable()} = AccessMetadataRegistry({',
      );

    for (final entry in entries) {
      buffer.writeln('  ${entry.typeName}: AccessMetadata(');
      if (entry.permission != null) {
        buffer.writeln("    permission: '${entry.permission}',");
      }
      if (entry.isPublic) {
        buffer.writeln('    isPublic: true,');
      }
      if (entry.requiresTenant) {
        buffer.writeln('    requiresTenant: true,');
      }
      if (entry.idempotencyKeyField != null) {
        buffer.writeln("    idempotencyKeyField: '${entry.idempotencyKeyField}',");
      }
      buffer.writeln('  ),');
    }

    buffer.writeln('});');
    buffer.writeln();
    return buffer.toString();
  }
}
