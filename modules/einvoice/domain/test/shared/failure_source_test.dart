import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  test('failure source has exactly provider and internal', () {
    expect(FailureSource.values, [
      FailureSource.provider,
      FailureSource.internal,
    ]);
  });
}
