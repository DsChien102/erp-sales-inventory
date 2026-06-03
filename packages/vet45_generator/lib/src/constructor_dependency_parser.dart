import 'package:analyzer/dart/element/element.dart';

import 'handler_descriptor.dart';

abstract final class ConstructorDependencyParser {
  static List<ConstructorDependency> parse(ClassElement classElement) {
    final constructor = _primaryConstructor(classElement);
    if (constructor == null) {
      return const [];
    }

    final dependencies = <ConstructorDependency>[];
    for (final parameter in constructor.formalParameters) {
      if (!parameter.isRequired) {
        continue;
      }

      final name = parameter.name;
      if (name == null || name.isEmpty) {
        continue;
      }

      dependencies.add(
        ConstructorDependency(
          name: name,
          typeName: parameter.type.getDisplayString(),
        ),
      );
    }

    return dependencies;
  }

  static ConstructorElement? _primaryConstructor(ClassElement classElement) {
    for (final constructor in classElement.constructors) {
      if (!constructor.isFactory) {
        return constructor;
      }
    }

    return null;
  }
}
