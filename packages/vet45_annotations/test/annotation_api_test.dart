import 'package:test/test.dart';
import 'package:vet45_annotations/vet45_annotations.dart';

final class _SampleCommand {}

final class _SampleQuery {}

void main() {
  group('handler annotations', () {
    test('CommandHandlerFor is const', () {
      const annotation = CommandHandlerFor(_SampleCommand);
      expect(annotation.commandType, _SampleCommand);
    });

    test('QueryHandlerFor is const', () {
      const annotation = QueryHandlerFor(_SampleQuery);
      expect(annotation.queryType, _SampleQuery);
    });
  });

  group('access annotations', () {
    test('RequiresPermission is const', () {
      const annotation = RequiresPermission('task.create');
      expect(annotation.code, 'task.create');
    });

    test('PublicAccess is const', () {
      expect(const PublicAccess(), isA<PublicAccess>());
    });

    test('RequiresTenant is const', () {
      expect(const RequiresTenant(), isA<RequiresTenant>());
    });

    test('Idempotent supports keyField', () {
      const annotation = Idempotent(keyField: 'requestId');
      expect(annotation.keyField, 'requestId');
    });
  });

  group('module annotations', () {
    test('ModuleManifest is const', () {
      const manifest = ModuleManifest(
        name: 'task',
        permissions: ['task.create', 'task.view'],
        version: '1.0.0',
      );
      expect(manifest.name, 'task');
      expect(manifest.permissions, ['task.create', 'task.view']);
      expect(manifest.version, '1.0.0');
    });
  });

  group('legacy cqrs annotations', () {
    test('CqrsExclude is const', () {
      expect(const CqrsExclude(), isA<CqrsExclude>());
    });
  });
}
