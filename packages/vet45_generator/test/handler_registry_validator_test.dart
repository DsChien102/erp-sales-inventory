import 'package:test/test.dart';
import 'package:vet45_generator/src/codegen_diagnostic.dart';
import 'package:vet45_generator/src/handler_descriptor.dart';
import 'package:vet45_generator/src/handler_registry_validator.dart';

void main() {
  group('HandlerRegistryValidator', () {
    test('throws on duplicate command handlers', () {
      expect(
        () => HandlerRegistryValidator.validate([
          _business('CreateTaskCommand', 'HandlerA'),
          _business('CreateTaskCommand', 'HandlerB'),
        ]),
        throwsA(isA<CodegenDiagnostic>()),
      );
    });
  });
}

HandlerDescriptor _business(String command, String handler) => HandlerDescriptor(
  kind: HandlerKind.business,
  className: handler,
  commandTypeName: command,
  resultTypeName: 'void',
);
