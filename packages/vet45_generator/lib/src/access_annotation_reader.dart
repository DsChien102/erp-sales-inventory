import 'package:analyzer/dart/element/element.dart';

import 'access_metadata_entry.dart';
import 'annotation_reader.dart';

abstract final class AccessAnnotationReader {
  static String? permission(ClassElement classElement) {
    return _readStringField(classElement, 'RequiresPermission', 'code');
  }

  static bool isPublic(ClassElement classElement) {
    return AnnotationReader.hasAnnotation(classElement, 'PublicAccess');
  }

  static bool requiresTenant(ClassElement classElement) {
    return AnnotationReader.hasAnnotation(classElement, 'RequiresTenant');
  }

  static String? idempotencyKeyField(ClassElement classElement) {
    if (!AnnotationReader.hasAnnotation(classElement, 'Idempotent')) {
      return null;
    }
    return _readStringField(classElement, 'Idempotent', 'keyField');
  }

  static bool hasAnyAccessAnnotation(ClassElement classElement) {
    return isPublic(classElement) ||
        requiresTenant(classElement) ||
        permission(classElement) != null ||
        AnnotationReader.hasAnnotation(classElement, 'Idempotent');
  }

  static String? _readStringField(
    ClassElement classElement,
    String annotationName,
    String fieldName,
  ) {
    for (final annotation in classElement.metadata.annotations) {
      final element = annotation.element;
      if (element is! ConstructorElement) {
        continue;
      }
      if (element.enclosingElement.name != annotationName) {
        continue;
      }

      final constant = annotation.computeConstantValue();
      if (constant == null) {
        continue;
      }

      final value = constant.getField(fieldName)?.toStringValue();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}

abstract final class AccessMetadataValidator {
  static void validate(ClassElement classElement, AccessMetadataEntry entry) {
    final name = classElement.name!;
    if (entry.isPublic && entry.permission != null) {
      throw ArgumentError(
        'vet45_generator:AC: $name cannot have both @PublicAccess and @RequiresPermission',
      );
    }
    if (entry.permission != null && entry.permission!.isEmpty) {
      throw ArgumentError(
        'vet45_generator:AC: $name @RequiresPermission code must not be empty',
      );
    }
    if (entry.idempotencyKeyField != null) {
      final hasField = classElement.fields.any(
        (field) => field.name == entry.idempotencyKeyField,
      );
      if (!hasField) {
        throw ArgumentError(
          'vet45_generator:AC: $name @Idempotent keyField '
          '"${entry.idempotencyKeyField}" not found on class',
        );
      }
    }
  }
}
