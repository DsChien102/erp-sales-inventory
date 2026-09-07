import 'package:vet45_einvoice_domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('refreshes expired available official view', () {
    expect(
      OfficialViewOperationPolicy.decide(
        status: InvoiceDocumentStatus.available,
        expiresAt: DateTime.utc(2026, 8, 31, 9),
        now: DateTime.utc(2026, 8, 31, 9, 0, 1),
      ),
      OfficialViewOperationDecision.createNextGeneration,
    );
  });

  test('re-arms the same operation after ambiguous outcome', () {
    expect(
      OfficialViewOperationPolicy.decide(
        status: InvoiceDocumentStatus.checkRequired,
        expiresAt: null,
        now: DateTime.utc(2026, 8, 31, 9),
      ),
      OfficialViewOperationDecision.rearmSameOperation,
    );
  });

  test('reuses pending and unexpired available operations', () {
    final now = DateTime.utc(2026, 8, 31, 9);
    expect(
      OfficialViewOperationPolicy.decide(
        status: InvoiceDocumentStatus.pending,
        expiresAt: null,
        now: now,
      ),
      OfficialViewOperationDecision.reuse,
    );
    expect(
      OfficialViewOperationPolicy.decide(
        status: InvoiceDocumentStatus.available,
        expiresAt: now.add(const Duration(minutes: 5)),
        now: now,
      ),
      OfficialViewOperationDecision.reuse,
    );
  });

  test('creates next generation after definite failure', () {
    expect(
      OfficialViewOperationPolicy.decide(
        status: InvoiceDocumentStatus.failed,
        expiresAt: null,
        now: DateTime.utc(2026, 8, 31, 9),
      ),
      OfficialViewOperationDecision.createNextGeneration,
    );
  });
}
