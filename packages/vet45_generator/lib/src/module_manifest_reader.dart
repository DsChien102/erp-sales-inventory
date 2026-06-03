import 'package:analyzer/dart/element/element.dart';

import 'module_manifest_data.dart';

abstract final class ModuleManifestReader {
  static ModuleManifestData? read(ClassElement classElement) {
    for (final annotation in classElement.metadata.annotations) {
      final element = annotation.element;
      if (element is! ConstructorElement) {
        continue;
      }
      if (element.enclosingElement.name != 'ModuleManifest') {
        continue;
      }

      final constant = annotation.computeConstantValue();
      if (constant == null) {
        continue;
      }

      final name = constant.getField('name')?.toStringValue();
      if (name == null || name.isEmpty) {
        throw ArgumentError(
          'vet45_generator:MF: @ModuleManifest on ${classElement.name} requires non-empty name',
        );
      }

      final permissions = <String>[];
      final rawPermissions = constant.getField('permissions')?.toListValue();
      if (rawPermissions != null) {
        for (final item in rawPermissions) {
          final value = item.toStringValue();
          if (value != null && value.isNotEmpty) {
            permissions.add(value);
          }
        }
      }

      return ModuleManifestData(
        className: classElement.name!,
        name: name,
        permissions: permissions,
        version: constant.getField('version')?.toStringValue(),
      );
    }

    return null;
  }
}
