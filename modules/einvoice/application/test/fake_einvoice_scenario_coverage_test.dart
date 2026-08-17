import 'package:test/test.dart';
import 'package:vet45_einvoice_application/testing.dart';

void main() {
  test('every FakeEInvoiceScenario is registered for handling', () {
    for (final scenario in FakeEInvoiceScenario.values) {
      expect(
        FakeEInvoiceModule.handlesScenario(scenario),
        isTrue,
        reason: '${scenario.scenarioId} must be handled',
      );
    }
    expect(FakeEInvoiceScenario.values.length, 77);
  });
}
