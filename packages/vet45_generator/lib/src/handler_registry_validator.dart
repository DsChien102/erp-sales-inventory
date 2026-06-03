import 'codegen_diagnostic.dart';
import 'handler_descriptor.dart';

abstract final class HandlerRegistryValidator {
  static void validate(List<HandlerDescriptor> descriptors) {
    _validateDuplicates(
      descriptors.where((d) => d.kind == HandlerKind.business),
      (d) => d.commandTypeName,
      'command',
    );
    _validateDuplicates(
      descriptors.where((d) => d.kind == HandlerKind.internal),
      (d) => d.commandTypeName,
      'internal command',
    );
    _validateDuplicates(
      descriptors.where((d) => d.kind == HandlerKind.query),
      (d) => d.queryTypeName!,
      'query',
    );
  }

  static void _validateDuplicates(
    Iterable<HandlerDescriptor> handlers,
    String Function(HandlerDescriptor) typeKey,
    String label,
  ) {
    final seen = <String, String>{};
    for (final handler in handlers) {
      final typeName = typeKey(handler);
      final previous = seen[typeName];
      if (previous != null) {
        throw CodegenDiagnostic(
          'HB',
          'Duplicate $label handler for $typeName: '
          '$previous and ${handler.className}',
        );
      }
      seen[typeName] = handler.className;
    }
  }

  static void validateCommandHandlerAnnotation({
    required String className,
    required String? annotatedType,
    required String? interfaceType,
  }) {
    if (annotatedType == null || interfaceType == null) {
      return;
    }
    if (annotatedType != interfaceType) {
      throw CodegenDiagnostic(
        'HB',
        '@CommandHandlerFor($annotatedType) conflicts with '
        'ICommandHandler<$interfaceType, …> on $className',
      );
    }
  }

  static void validateQueryHandlerAnnotation({
    required String className,
    required String? annotatedType,
    required String? interfaceType,
  }) {
    if (annotatedType == null || interfaceType == null) {
      return;
    }
    if (annotatedType != interfaceType) {
      throw CodegenDiagnostic(
        'HB',
        '@QueryHandlerFor($annotatedType) conflicts with '
        'IQueryHandler<$interfaceType, …> on $className',
      );
    }
  }

  static void validateCommandHandlerForPresent({
    required String className,
    required String? annotatedType,
    required String? interfaceType,
  }) {
    if (annotatedType != null && interfaceType == null) {
      throw CodegenDiagnostic(
        'HB',
        '@CommandHandlerFor on $className requires ICommandHandler implementation',
      );
    }
  }

  static void validateQueryHandlerForPresent({
    required String className,
    required String? annotatedType,
    required String? interfaceType,
  }) {
    if (annotatedType != null && interfaceType == null) {
      throw CodegenDiagnostic(
        'HB',
        '@QueryHandlerFor on $className requires IQueryHandler implementation',
      );
    }
  }
}
