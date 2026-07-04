import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;
import 'package:vet45_generator/src/constructor_dependency_parser.dart';

import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late String fixtureRoot;

  setUpAll(() {
    final packageRoot = resolveGeneratorPackageRoot();
    fixtureRoot = p.canonicalize(p.join(packageRoot, 'test', 'fixtures', 'lib', 'src'));
  });

  group('ConstructorDependencyParser', () {
    test('parses required named dependencies and skips optional defaults', () async {
      final collection = AnalysisContextCollection(
        includedPaths: [fixtureRoot],
      );
      final filePath = p.canonicalize(p.join(fixtureRoot, 'checkout_command_handler.dart'));
      final result = await collection.contextFor(filePath).currentSession.getResolvedLibrary(filePath);
      expect(result, isA<ResolvedLibraryResult>());

      final handler = (result as ResolvedLibraryResult)
          .element
          .classes
          .singleWhere((element) => element.name == 'CheckoutHandler');

      final dependencies = ConstructorDependencyParser.parse(handler);

      expect(dependencies.map((dep) => dep.name).toList(), [
        'draftRepository',
        'commandGateway',
        'productLookup',
      ]);
      expect(
        dependencies.map((dep) => dep.typeName).toList(),
        ['DraftRepository', 'CommandGateway', 'ProductLookup'],
      );
    });

    test('parses single required dependency for internal handler', () async {
      final collection = AnalysisContextCollection(
        includedPaths: [fixtureRoot],
      );
      final filePath = p.canonicalize(p.join(fixtureRoot, 'attach_customer_command_handler.dart'));
      final result = await collection.contextFor(filePath).currentSession.getResolvedLibrary(filePath);
      expect(result, isA<ResolvedLibraryResult>());

      final handler = (result as ResolvedLibraryResult)
          .element
          .classes
          .singleWhere((element) => element.name == 'AttachCustomerHandler');

      final dependencies = ConstructorDependencyParser.parse(handler);

      expect(dependencies, hasLength(1));
      expect(dependencies.single.name, 'draftRepository');
      expect(dependencies.single.typeName, 'DraftRepository');
    });
  });
}
