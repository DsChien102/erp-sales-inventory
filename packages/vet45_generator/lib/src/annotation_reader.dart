import 'package:analyzer/dart/element/element.dart';

/// Reads vet45_annotations metadata from analyzer elements.
abstract final class AnnotationReader {
  static String? readTypeField(
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

      final field = constant.getField(fieldName);
      if (field == null) {
        continue;
      }

      final typeValue = field.toTypeValue();
      final fromTypeValue = typeValue?.element?.name;
      if (fromTypeValue != null && fromTypeValue.isNotEmpty && fromTypeValue != 'Type') {
        return fromTypeValue;
      }

      final dartType = field.type;
      final fromFieldType = dartType?.element?.name;
      if (fromFieldType != null && fromFieldType.isNotEmpty && fromFieldType != 'Type') {
        return fromFieldType;
      }
    }

    return null;
  }

  static bool hasAnnotation(ClassElement classElement, String name) {
    for (final annotation in classElement.metadata.annotations) {
      final element = annotation.element;
      if (element is ConstructorElement && element.enclosingElement.name == name) {
        return true;
      }
    }
    return false;
  }
}
